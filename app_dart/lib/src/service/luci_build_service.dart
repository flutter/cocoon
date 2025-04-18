// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import 'package:buildbucket/buildbucket_pb.dart' as bbv2;
import 'package:cocoon_common/is_release_branch.dart';
import 'package:cocoon_server/logging.dart';
import 'package:fixnum/fixnum.dart';
import 'package:github/github.dart' as github;
import 'package:github/github.dart';
import 'package:googleapis/firestore/v1.dart' hide Status;
import 'package:meta/meta.dart';

import '../../cocoon_service.dart';
import '../foundation/github_checks_util.dart';
import '../model/appengine/commit.dart';
import '../model/appengine/task.dart';
import '../model/ci_yaml/target.dart';
import '../model/firestore/pr_check_runs.dart' as fs;
import '../model/firestore/task.dart' as fs;
import '../model/github/checks.dart' as cocoon_checks;
import '../service/datastore.dart';
import 'exceptions.dart';
import 'luci_build_service/build_tags.dart';
import 'luci_build_service/cipd_version.dart';
import 'luci_build_service/engine_artifacts.dart';
import 'luci_build_service/opaque_commit.dart';
import 'luci_build_service/pending_task.dart';
import 'luci_build_service/user_data.dart';

/// Class to interact with LUCI buildbucket to get, trigger
/// and cancel builds for github repos. It uses [_config.luciTryBuilders] to
/// get the list of available builders.
class LuciBuildService {
  LuciBuildService({
    required Config config,
    required CacheService cache,
    required BuildBucketClient buildBucketClient,
    required GerritService gerritService,
    required PubSub pubsub,
    GithubChecksUtil? githubChecksUtil,
  }) : _pubsub = pubsub,
       _config = config,
       _cache = cache,
       _buildBucketClient = buildBucketClient,
       _githubChecksUtil = githubChecksUtil ?? const GithubChecksUtil(),
       _gerritService = gerritService;

  final BuildBucketClient _buildBucketClient;
  final CacheService _cache;
  final Config _config;
  final GithubChecksUtil _githubChecksUtil;
  final GerritService _gerritService;
  final PubSub _pubsub;

  // TODO(matanlurey): Re-enable to true/remove.
  // See https://github.com/flutter/flutter/issues/167383.
  static final _useFlutterPrebuiltEngineForReleaseCandidateBuilds = false;

  static const int kBackfillPriority = 35;
  static const int kDefaultPriority = 30;
  static const int kRerunPriority = 29;

  /// LUCI builds that are in merge queues might be retried on flakes.
  static const String kMergeQueueKey = 'in_merge_queue';

  /// How many times to retry tests in the merge queue.
  ///
  /// Note: the math for max testing is "<" and starts at 1; hence 3 retries.
  static const int kMergeQueueMaxRetries = 4;

  /// Github labels have a max length of 100, so conserve chars here.
  /// This is currently used by packages repo only.
  /// See: https://github.com/flutter/flutter/issues/130076
  static const String githubBuildLabelPrefix = 'override:';
  static const String propertiesGithubBuildLabelName = 'overrides';

  /// Name of the subcache to store luci build related values in redis.
  static const String subCacheName = 'luci';

  // the Request objects here are the BatchRequest object in bbv2.
  /// Shards [rows] into several sublists of size [maxEntityGroups].
  Future<List<List<bbv2.BatchRequest_Request>>> _shard({
    required List<bbv2.BatchRequest_Request> requests,
    required int maxShardSize,
  }) async {
    final shards = <List<bbv2.BatchRequest_Request>>[];
    for (var i = 0; i < requests.length; i += maxShardSize) {
      shards.add(
        requests.sublist(i, i + min<int>(requests.length - i, maxShardSize)),
      );
    }
    return shards;
  }

  /// Fetches an Iterable of try BuildBucket [Build]s.
  ///
  /// Returns a list of BuildBucket [Build]s for a given Github [PullRequest].
  Future<Iterable<bbv2.Build>> getTryBuildsByPullRequest({
    required github.PullRequest pullRequest,
  }) async {
    final slug = pullRequest.base!.repo!.slug();
    return _getBuilds(
      builderName: null,
      bucket: 'try',
      tags: BuildTags([
        GitHubPullRequestBuildTag(
          pullRequestNumber: pullRequest.number!,
          slugOwner: slug.owner,
          slugName: slug.name,
        ),
        UserAgentBuildTag.flutterCocoon,
      ]),
    );
  }

  /// Fetches an Iterable of prod BuildBucket [Build]s.
  ///
  /// Returns an Iterable of prod BuildBucket [Build]s for a given
  /// [builderName].
  Future<Iterable<bbv2.Build>> getProdBuilds({
    String? builderName,
    String? sha,
  }) async {
    return _getBuilds(
      builderName: builderName,
      bucket: 'prod',
      tags: BuildTags([
        if (sha != null) ByPostsubmitCommitBuildSetBuildTag(commitSha: sha),

        // We only want to process (and eventually cancel or retry) jobs started
        // by Cocoon; for example, we do not want to cancel or retry manually
        // started jobs.
        UserAgentBuildTag.flutterCocoon,
      ]),
    );
  }

  /// Fetches an Iterable of try BuildBucket [Build]s.
  ///
  /// Returns an iterable of try BuildBucket [Build]s for a given
  /// [builderName], [bucket], and [tags].
  Future<Iterable<bbv2.Build>> _getBuilds({
    required String? builderName,
    required String bucket,
    required BuildTags tags,
  }) async {
    final fieldMask = bbv2.FieldMask(
      paths: {'id', 'builder', 'tags', 'status', 'input.properties'},
    );

    final buildMask = bbv2.BuildMask(fields: fieldMask);

    final buildPredicate = bbv2.BuildPredicate(
      builder: bbv2.BuilderID(
        project: 'flutter',
        bucket: bucket,
        builder: builderName,
      ),
      tags: tags.toStringPairs(),
    );

    final searchBuildsRequest = bbv2.SearchBuildsRequest(
      predicate: buildPredicate,
      mask: buildMask,
    );

    // Need to create one of these for each request in the batch.
    final batchRequestRequest = bbv2.BatchRequest_Request(
      searchBuilds: searchBuildsRequest,
    );

    final batchResponse = await _buildBucketClient.batch(
      bbv2.BatchRequest(requests: {batchRequestRequest}),
    );

    log.info(
      'Responses from get builds batch request = ${batchResponse.responses.length}',
    );
    for (var response in batchResponse.responses) {
      log.info('Found a response: ${response.toString()}');
    }

    final builds = batchResponse.responses
        .map((bbv2.BatchResponse_Response response) => response.searchBuilds)
        .expand((bbv2.SearchBuildsResponse? response) => response!.builds);
    return builds;
  }

  /// Schedules presubmit [targets] on BuildBucket for [pullRequest].
  ///
  /// [engineArtifacts] determines how framework tests download and use the Flutter engine by
  /// providing `FLUTTER_PREBUILT_ENGINE_VERISON` if set. For builds that are not running
  /// framework tests, provide [EngineArtifacts.noFrameworkTests].
  Future<List<Target>> scheduleTryBuilds({
    required List<Target> targets,
    required github.PullRequest pullRequest,
    required EngineArtifacts engineArtifacts,
  }) async {
    if (targets.isEmpty) {
      return targets;
    }

    final batchRequestList = <bbv2.BatchRequest_Request>[];
    final commitSha = pullRequest.head!.sha!;
    final isFusion = pullRequest.base!.repo!.slug() == Config.flutterSlug;
    final CipdVersion cipdVersion;
    {
      final baseRef = pullRequest.base!.ref!;

      // If this isn't flutter/flutter *OR* it's flutter/flutter master, use the default CIPD recipe.
      // We don't create CIPD recipes for other repositories (see https://github.com/flutter/flutter/issues/164592).
      if (!isFusion ||
          Config.defaultBranch(pullRequest.base!.repo!.slug()) == baseRef) {
        cipdVersion = CipdVersion.defaultRecipe;
      } else {
        final proposedVersion = CipdVersion(branch: pullRequest.base!.ref!);
        final branches = await _gerritService.branches(
          'flutter-review.googlesource.com',
          'recipes',
          filterRegex: 'flutter-.*|fuchsia.*',
        );
        if (branches.contains(proposedVersion.version)) {
          cipdVersion = proposedVersion;
        } else {
          log.warn(
            'Falling back to default recipe, could not find '
            '"${proposedVersion.version}" in $branches.',
          );
          cipdVersion = _config.defaultRecipeBundleRef;
        }
      }
    }

    final checkRuns = <github.CheckRun>[];
    for (var target in targets) {
      final checkRun = await _githubChecksUtil.createCheckRun(
        _config,
        target.slug,
        commitSha,
        target.name,
      );
      checkRuns.add(checkRun);

      final slug = pullRequest.base!.repo!.slug();
      final userData = PresubmitUserData(
        repoOwner: slug.owner,
        repoName: slug.name,
        commitSha: commitSha,
        commitBranch: pullRequest.base!.ref!.replaceAll('refs/heads/', ''),
        checkRunId: checkRun.id!,
      );

      final properties = target.getProperties();
      properties.putIfAbsent(
        'git_branch',
        () => pullRequest.base!.ref!.replaceAll('refs/heads/', ''),
      );

      final struct = bbv2.Struct.create();
      struct.mergeFromProto3Json(properties);

      final labels = _extractPrefixedLabels(
        issueLabels: pullRequest.labels,
        prefix: githubBuildLabelPrefix,
      );

      if (labels != null && labels.isNotEmpty) {
        properties[propertiesGithubBuildLabelName] = labels;
        log.info(
          'Found overrides: labels for PR#${pullRequest.number}: $labels.',
        );
      }

      if (isFusion) {
        properties['is_fusion'] = 'true';

        // Fusion *also* means "this is flutter/flutter", so determine how to specify the engine version and realm.
        switch (engineArtifacts) {
          case SpecifiedEngineArtifacts(:final commitSha, :final flutterRealm):
            properties['flutter_prebuilt_engine_version'] = commitSha;
            properties['flutter_realm'] = flutterRealm;
          case UnnecessaryEngineArtifacts(:final reason):
            log.debug(
              'No engineArtifacts were specified for PR#${pullRequest.number} (${pullRequest.head!.sha}): $reason.',
            );
        }
      } else if (engineArtifacts is! UnnecessaryEngineArtifacts) {
        // This is an error case, as we're setting artifacts for a PR that will never use them.
        throw StateError(
          'Unexpected engineArtifacts were specified for PR#${pullRequest.number} (${pullRequest.head!.sha})',
        );
      }

      final requestedDimensions = target.getDimensions();

      batchRequestList.add(
        bbv2.BatchRequest_Request(
          scheduleBuild: _createPresubmitScheduleBuild(
            slug: slug,
            sha: pullRequest.head!.sha!,
            //Use target.value.name here otherwise tests will die due to null checkRun.name.
            checkName: target.name,
            pullRequestNumber: pullRequest.number!,
            cipdVersion: cipdVersion,
            userData: userData,
            properties: properties,
            tags: BuildTags([
              GitHubCheckRunIdBuildTag(checkRunId: checkRun.id!),
            ]),
            dimensions: requestedDimensions,
          ),
        ),
      );
    }

    // All check runs created, now record them in firestore so we can
    // figure out which PR started what check run later (e.g. check_run completed).
    try {
      final firestore = await _config.createFirestoreService();
      final doc = await fs.PrCheckRuns.initializeDocument(
        firestoreService: firestore,
        pullRequest: pullRequest,
        checks: checkRuns,
      );
      log.info('scheduleTryBuilds: created PrCheckRuns doc ${doc.name}');
    } catch (e, s) {
      // We are not going to block on this error. If we cannot find this document
      // later, we'll fall back to the old github query method.
      log.warn('scheduleTryBuilds: error creating PrCheckRuns doc', e, s);
    }

    final Iterable<List<bbv2.BatchRequest_Request>> requestPartitions =
        await _shard(
          requests: batchRequestList,
          maxShardSize: _config.schedulingShardSize,
        );
    for (var requestPartition in requestPartitions) {
      final batchRequest = bbv2.BatchRequest(requests: requestPartition);
      await _pubsub.publish(
        'cocoon-scheduler-requests',
        batchRequest.toProto3Json(),
      );
    }

    return targets;
  }

  /// Cancels all the current builds on [pullRequest] with [reason].
  Future<void> cancelBuilds({
    required github.PullRequest pullRequest,
    required String reason,
  }) async {
    log.info(
      'Attempting to cancel builds (v2) for pullrequest ${pullRequest.base!.repo!.fullName}/${pullRequest.number}',
    );

    final builds = await getTryBuildsByPullRequest(pullRequest: pullRequest);

    if (builds.isEmpty) {
      log.info(
        'No builds were found for pull request ${pullRequest.base!.repo!.fullName}.',
      );
      return;
    }
    log.info('Found ${builds.length} builds.');

    final requests = <bbv2.BatchRequest_Request>[];
    for (var build in builds) {
      if (build.status == bbv2.Status.SCHEDULED ||
          build.status == bbv2.Status.STARTED) {
        // Scheduled status includes scheduled and pending tasks.
        log.info('Cancelling build with build id ${build.id}.');
        requests.add(
          bbv2.BatchRequest_Request(
            cancelBuild: bbv2.CancelBuildRequest(
              id: build.id,
              summaryMarkdown: reason,
            ),
          ),
        );
      }
    }

    if (requests.isNotEmpty) {
      await _buildBucketClient.batch(bbv2.BatchRequest(requests: requests));
    }
  }

  /// Cancels all the current builds against the give [sha] with [reason].
  Future<void> cancelBuildsBySha({
    required String sha,
    required String reason,
  }) async {
    log.info(
      'Attempting to cancel builds (v2) for git SHA $sha because $reason',
    );

    final builds = await getProdBuilds(sha: sha);

    if (builds.isEmpty) {
      log.info('No builds found. Will not request cancellation from LUCI.');
      return;
    }

    log.info('Found ${builds.length} builds.');

    final requests = <bbv2.BatchRequest_Request>[];
    for (final build in builds) {
      if (build.status == bbv2.Status.SCHEDULED ||
          build.status == bbv2.Status.STARTED) {
        // Scheduled status includes scheduled and pending tasks.
        log.info('Cancelling build with build id ${build.id}.');
        requests.add(
          bbv2.BatchRequest_Request(
            cancelBuild: bbv2.CancelBuildRequest(
              id: build.id,
              summaryMarkdown: reason,
            ),
          ),
        );
      }
    }

    if (requests.isNotEmpty) {
      await _buildBucketClient.batch(bbv2.BatchRequest(requests: requests));
    }
  }

  /// Sends [ScheduleBuildRequest] using information from a given build's
  /// [BuildPushMessage].
  ///
  /// The buildset, user_agent, and github_link tags are applied to match the
  /// original build. The build properties and user data from the original build
  /// are also preserved.
  ///
  /// The [currentAttempt] is used to track the number of current build attempt.
  Future<bbv2.Build> reschedulePresubmitBuild({
    required String builderName,
    required bbv2.Build build,
    required int nextAttempt,
    required PresubmitUserData userData,
  }) async {
    final tags = BuildTags.fromStringPairs(build.tags);
    tags.addOrReplace(CurrentAttemptBuildTag(attemptNumber: nextAttempt));

    final request = bbv2.ScheduleBuildRequest(
      builder: build.builder,
      tags: tags.toStringPairs(),
      properties: build.input.properties,
      notify: bbv2.NotificationConfig(
        pubsubTopic: 'projects/flutter-dashboard/topics/build-bucket-presubmit',
        userData: userData.toBytes(),
      ),
    );
    if (build.input.hasGitilesCommit()) {
      request.gitilesCommit = build.input.gitilesCommit;
    }

    return _buildBucketClient.scheduleBuild(request);
  }

  /// Collect any label whose name is prefixed by the prefix [String].
  ///
  /// Returns a [List] of prefixed label names as [String]s.
  static List<String>? _extractPrefixedLabels({
    List<github.IssueLabel>? issueLabels,
    required String prefix,
  }) {
    return issueLabels
        ?.where((label) => label.name.startsWith(prefix))
        .map((obj) => obj.name)
        .toList();
  }

  /// Sends postsubmit [ScheduleBuildRequest] for a commit using [checkRunEvent], [Commit], [Task], and [Target].
  Future<void> reschedulePostsubmitBuildUsingCheckRunEvent(
    cocoon_checks.CheckRunEvent checkRunEvent, {
    required OpaqueCommit commit,
    required Target target,
    required fs.Task task,
  }) async {
    final checkName = checkRunEvent.checkRun!.name!;

    final builds = await getProdBuilds(builderName: checkName);
    if (builds.isEmpty) {
      throw NoBuildFoundException('Unable to find prod build.');
    }

    final build = builds.first;

    // get it as a struct first and convert it.
    final propertiesStruct = build.input.properties;
    final properties = propertiesStruct.toProto3Json() as Map<String, Object?>;
    final tags = BuildTags.fromStringPairs(build.tags);

    log.info('input ${build.input} properties $properties');
    log.info('input ${build.input} tags $tags');

    tags.addOrReplace(TriggerTypeBuildTag.checkRunManualRetry);

    try {
      final newAttempt = await _updateTaskStatusInDatabaseForRetry(
        commit,
        task,
      );
      tags.addOrReplace(CurrentAttemptBuildTag(attemptNumber: newAttempt));
    } catch (e, s) {
      log.error(
        'updating task ${task.taskName} of commit '
        '${task.commitSha}. Skipping rescheduling.',
        e,
        s,
      );
      return;
    }
    log.info('Updated input ${build.input} tags $tags');
    final request = bbv2.BatchRequest(
      requests: <bbv2.BatchRequest_Request>[
        bbv2.BatchRequest_Request(
          scheduleBuild: await _createPostsubmitScheduleBuild(
            commit: commit,
            target: target,
            taskName: task.taskName,
            properties: properties,
            priority: kRerunPriority,
            tags: tags,
          ),
        ),
      ],
    );
    await _pubsub.publish('cocoon-scheduler-requests', request.toProto3Json());
  }

  /// Gets [bbv2.Build] using its [id] and passing the additional
  /// fields to be populated in the response.
  Future<bbv2.Build> getBuildById(Int64 id, {bbv2.BuildMask? buildMask}) async {
    final request = bbv2.GetBuildRequest(id: id, mask: buildMask);
    return _buildBucketClient.getBuild(request);
  }

  /// Gets builder list whose config is pre-defined in LUCI.
  ///
  /// Returns cache if existing. Otherwise make the RPC call to fetch list.
  Future<Set<String>> getAvailableBuilderSet({
    String project = 'flutter',
    String bucket = 'prod',
  }) async {
    final cacheValue = await _cache.getOrCreate(
      subCacheName,
      'builderlist/$project/$bucket',
      createFn: () => _getAvailableBuilderSet(project: project, bucket: bucket),
      // New commit triggering tasks should be finished within 5 mins.
      // The batch backfiller's execution frequency is also 5 mins.
      ttl: const Duration(minutes: 5),
    );

    return Set.from(String.fromCharCodes(cacheValue!).split(','));
  }

  /// Returns cache if existing, otherwise makes the RPC call to fetch list.
  ///
  /// Use [token] to make sure obtain all the list by calling RPC multiple times.
  Future<Uint8List> _getAvailableBuilderSet({
    String project = 'flutter',
    String bucket = 'prod',
  }) async {
    log.info(
      'No cached value for builderList, start fetching via the rpc call.',
    );
    final availableBuilderSet = <String>{};
    var hasToken = true;
    String? token;
    do {
      final listBuildersResponse = await _buildBucketClient.listBuilders(
        bbv2.ListBuildersRequest(
          project: project,
          bucket: bucket,
          pageToken: token,
        ),
      );
      final availableBuilderList =
          listBuildersResponse.builders.map((e) => e.id.builder).toList();
      availableBuilderSet.addAll(<String>{...availableBuilderList});
      hasToken = listBuildersResponse.hasNextPageToken();
      if (hasToken) {
        token = listBuildersResponse.nextPageToken;
      }
    } while (hasToken && token != null);
    final joinedBuilderSet = availableBuilderSet.toList().join(',');
    log.info('successfully fetched the builderSet: $joinedBuilderSet');
    return Uint8List.fromList(joinedBuilderSet.codeUnits);
  }

  /// Schedules list of post-submit builds deferring work to [schedulePostsubmitBuild].
  ///
  /// Returns empty list if all targets are successfully published to pub/sub. Otherwise,
  /// returns the original list.
  @useResult
  Future<List<PendingTask>> schedulePostsubmitBuilds({
    required OpaqueCommit commit,
    required List<PendingTask> toBeScheduled,
  }) async {
    if (toBeScheduled.isEmpty) {
      log.debug(
        'Skipping schedulePostsubmitBuilds as there are no targets to be '
        'scheduled by Cocoon',
      );
      return toBeScheduled;
    }
    final buildRequests = <bbv2.BatchRequest_Request>[];
    // bbv2.BatchRequest_Request batchRequest_Request = bbv2.BatchRequest_Request();

    Set<String> availableBuilderSet;
    try {
      availableBuilderSet = await getAvailableBuilderSet(
        project: 'flutter',
        bucket: 'prod',
      );
    } catch (e) {
      log.error('Failed to get buildbucket builder list', e);
      return toBeScheduled;
    }
    for (var pending in toBeScheduled) {
      // Non-existing builder target will be skipped from scheduling.
      if (!availableBuilderSet.contains(pending.target.name)) {
        log.warn(
          'Found no available builder for ${pending.target.name}, commit ${commit.sha}',
        );
        continue;
      }
      log.info(
        'create postsubmit schedule request for target: ${pending.target} in commit ${commit.sha}',
      );
      final scheduleBuildRequest = await _createPostsubmitScheduleBuild(
        commit: commit,
        target: pending.target,
        taskName: pending.taskName,
        priority: pending.priority,
      );
      buildRequests.add(
        bbv2.BatchRequest_Request(scheduleBuild: scheduleBuildRequest),
      );
      log.info(
        'created postsubmit schedule request for target: ${pending.target} in commit ${commit.sha}',
      );
    }

    final batchRequest = bbv2.BatchRequest(requests: buildRequests);
    log.debug('$batchRequest');
    List<String> messageIds;

    try {
      messageIds = await _pubsub.publish(
        'cocoon-scheduler-requests',
        batchRequest.toProto3Json(),
      );
      log.info('Published $messageIds for commit ${commit.sha}');
    } catch (e) {
      log.error('Failed to publish message to pub/sub', e);
      return toBeScheduled;
    }
    log.info('Published a request with ${buildRequests.length} builds');
    return <PendingTask>[];
  }

  /// Schedules [targets] for building of prod artifacts while in a merge queue.
  Future<void> scheduleMergeGroupBuilds({
    required Commit commit,
    required List<Target> targets,
  }) async {
    final buildRequests = <bbv2.BatchRequest_Request>[];

    final Set<String> availableBuilderSet;
    try {
      availableBuilderSet = await getAvailableBuilderSet(
        project: 'flutter',
        bucket: 'prod',
      );
    } catch (e) {
      log.warn('Failed to get buildbucket builder list', e);
      throw 'Failed to get buildbucket builder list due to $e';
    }
    for (var target in targets) {
      // Non-existing builder target will be skipped from scheduling.
      if (!availableBuilderSet.contains(target.name)) {
        log.warn(
          'Found no available builder for ${target.name}, commit '
          '${commit.sha}',
        );
        continue;
      }
      log.info(
        'create postsubmit schedule request for target: $target in commit ${commit.sha}',
      );

      final scheduleBuildRequest = await _createMergeGroupScheduleBuild(
        commit: OpaqueCommit.fromDatastore(commit),
        target: target,
      );
      buildRequests.add(
        bbv2.BatchRequest_Request(scheduleBuild: scheduleBuildRequest),
      );
      log.info(
        'created postsubmit schedule request for target: $target in commit ${commit.sha}',
      );
    }

    final batchRequest = bbv2.BatchRequest(requests: buildRequests);
    log.debug('$batchRequest');
    final List<String> messageIds;

    try {
      messageIds = await _pubsub.publish(
        'cocoon-scheduler-requests',
        batchRequest.toProto3Json(),
      );
      log.info('Published $messageIds for commit ${commit.sha}');
    } catch (e) {
      log.error('Failed to publish message to pub/sub', e);
      rethrow;
    }
    log.info('Published a request with ${buildRequests.length} builds');
  }

  /// Create a Presubmit ScheduleBuildRequest using the [slug], [sha], and
  /// [checkName] for the provided [build] with the provided [checkRunId].
  bbv2.ScheduleBuildRequest _createPresubmitScheduleBuild({
    required github.RepositorySlug slug,
    required String sha,
    required String checkName,
    required int pullRequestNumber,
    required CipdVersion cipdVersion,
    required PresubmitUserData userData,
    Map<String, Object?>? properties,
    BuildTags? tags,
    List<bbv2.RequestedDimension>? dimensions,
  }) {
    final builderId = bbv2.BuilderID.create();
    builderId.bucket = 'try';
    builderId.project = 'flutter';
    builderId.builder = checkName;

    // Add the builderId.
    final scheduleBuildRequest = bbv2.ScheduleBuildRequest.create();
    scheduleBuildRequest.builder = builderId;

    final fields = <String>['id', 'builder', 'number', 'status', 'tags'];
    final fieldMask = bbv2.FieldMask(paths: fields);
    final buildMask = bbv2.BuildMask(fields: fieldMask);
    scheduleBuildRequest.mask = buildMask;

    // Set the executable.
    final executable = bbv2.Executable(cipdVersion: cipdVersion.version);
    scheduleBuildRequest.exe = executable;

    // Add the dimensions to the instance.
    final instanceDimensions = scheduleBuildRequest.dimensions;
    instanceDimensions.addAll(dimensions ?? []);

    // Create the notification configuration for pubsub processing.
    final notificationConfig = bbv2.NotificationConfig().createEmptyInstance();
    notificationConfig.pubsubTopic =
        'projects/flutter-dashboard/topics/build-bucket-presubmit';
    notificationConfig.userData = userData.toBytes();
    scheduleBuildRequest.notify = notificationConfig;

    // If we received initial tags, create a defensive copy, otherwise create an empty list.
    tags = tags?.clone() ?? BuildTags();
    tags.addAll([
      ByPresubmitCommitBuildSetBuildTag(commitSha: sha),
      UserAgentBuildTag.flutterCocoon,
      GitHubPullRequestBuildTag(
        slugOwner: slug.owner,
        slugName: slug.name,
        pullRequestNumber: pullRequestNumber,
      ),
      CipdVersionBuildTag(cipdVersion),
    ]);
    scheduleBuildRequest.tags.addAll(tags.toStringPairs());

    properties ??= {};
    properties['git_url'] = 'https://github.com/${slug.owner}/${slug.name}';
    properties['git_ref'] = 'refs/pull/$pullRequestNumber/head';
    properties['git_repo'] = slug.name;
    properties['exe_cipd_version'] = cipdVersion.version;

    final propertiesStruct = bbv2.Struct.create();
    propertiesStruct.mergeFromProto3Json(properties);

    scheduleBuildRequest.properties = propertiesStruct;

    return scheduleBuildRequest;
  }

  /// Creates a [ScheduleBuildRequest] for [target] and [task] against [commit].
  ///
  /// By default, build [priority] is increased for release branches.
  Future<bbv2.ScheduleBuildRequest> _createPostsubmitScheduleBuild({
    required OpaqueCommit commit,
    required Target target,
    required String taskName,
    Map<String, Object?>? properties,
    BuildTags? tags,
    int priority = kDefaultPriority,
  }) async {
    log.info(
      'Creating postsubmit schedule builder for ${target.name} on commit ${commit.sha}',
    );
    tags ??= BuildTags([
      ByPostsubmitCommitBuildSetBuildTag(commitSha: commit.sha),
      ByCommitMirroredBuildSetBuildTag(
        commitSha: commit.sha,
        slugName: commit.slug.name,
      ),
    ]);

    // Creates post submit checkrun only for unflaky targets from [config.postsubmitSupportedRepos].
    final CheckRun? checkRun;
    if (!target.isBringup &&
        _config.postsubmitSupportedRepos.contains(target.slug)) {
      checkRun = await createPostsubmitCheckRun(commit, target);
    } else {
      checkRun = null;
    }

    tags.addOrReplace(UserAgentBuildTag.flutterCocoon);
    tags.addOrReplace(SchedulerJobIdBuildTag(targetName: target.name));
    final currentAttempt = tags.addIfAbsent(
      CurrentAttemptBuildTag(attemptNumber: 1),
    );

    final firestoreTask = fs.TaskId(
      commitSha: commit.sha,
      taskName: taskName,
      currentAttempt: currentAttempt.attemptNumber,
    );
    final userData = PostsubmitUserData(
      taskId: firestoreTask,
      checkRunId: checkRun?.id,
    );

    final processedProperties = target.getProperties().cast<String, Object?>();
    processedProperties.addAll(properties ?? <String, Object?>{});
    processedProperties['git_branch'] = commit.branch;
    processedProperties['git_repo'] = commit.slug.name;

    final cipdExe = 'refs/heads/${commit.branch}';
    processedProperties['exe_cipd_version'] = cipdExe;

    final isFusion = commit.slug == Config.flutterSlug;
    if (isFusion) {
      processedProperties['is_fusion'] = 'true';
      if (_useFlutterPrebuiltEngineForReleaseCandidateBuilds &&
          isReleaseCandidateBranch(branchName: commit.branch)) {
        processedProperties.addAll({
          // Always provide an engine version, just like we do in presubmit.
          // See https://github.com/flutter/flutter/issues/167010.
          'flutter_prebuilt_engine_version': commit.sha,

          // Prod build bucket, built during the merge queue.
          'flutter_realm': '',
        });
      }
    }
    final propertiesStruct = bbv2.Struct.create();
    propertiesStruct.mergeFromProto3Json(processedProperties);

    final requestedDimensions = target.getDimensions();

    final executable = bbv2.Executable(cipdVersion: cipdExe);

    log.info(
      'Constructing the postsubmit schedule build request for ${target.name} on commit ${commit.sha}.',
    );

    return bbv2.ScheduleBuildRequest(
      builder: bbv2.BuilderID(
        project: 'flutter',
        bucket: target.getBucket(),
        builder: target.name,
      ),
      dimensions: requestedDimensions,
      exe: executable,
      gitilesCommit: bbv2.GitilesCommit(
        project: 'mirrors/${commit.slug.name}',
        host: 'flutter.googlesource.com',
        ref: 'refs/heads/${commit.branch}',
        id: commit.sha,
      ),
      notify: bbv2.NotificationConfig(
        pubsubTopic:
            'projects/flutter-dashboard/topics/build-bucket-postsubmit',
        userData: userData.toBytes(),
      ),
      tags: tags.toStringPairs(),
      properties: propertiesStruct,
      priority: priority,
    );
  }

  /// Creates a build request for a commit in a merge queue which will notify
  /// presubmit channels.
  Future<bbv2.ScheduleBuildRequest> _createMergeGroupScheduleBuild({
    required OpaqueCommit commit,
    required Target target,
    int priority = kDefaultPriority,
  }) async {
    log.info(
      'Creating merge group schedule builder for ${target.name} on commit ${commit.sha}',
    );
    log.info('Scheduling builder: ${target.name} for commit ${commit.sha}');

    final checkRun = await createPostsubmitCheckRun(commit, target);
    final preUserData = PresubmitUserData(
      checkRunId: checkRun.id!,
      repoOwner: target.slug.owner,
      repoName: target.slug.name,
      commitBranch: commit.branch,
      commitSha: commit.sha,
    );
    final processedProperties = target.getProperties().cast<String, Object?>();
    processedProperties['git_branch'] = commit.branch;

    final mqBranch = tryParseGitHubMergeQueueBranch(commit.branch);
    log.info('parsed mqBranch: $mqBranch');

    final cipdExe = 'refs/heads/${mqBranch.branch}';
    processedProperties['exe_cipd_version'] = cipdExe;
    processedProperties['is_fusion'] = 'true';
    processedProperties[kMergeQueueKey] = true;
    processedProperties['git_repo'] = commit.slug.name;

    final propertiesStruct =
        bbv2.Struct()..mergeFromProto3Json(processedProperties);
    final requestedDimensions = target.getDimensions();
    final executable = bbv2.Executable(cipdVersion: cipdExe);

    log.info(
      'Constructing the merge group schedule build request for ${target.name} on commit ${commit.sha}.',
    );

    return bbv2.ScheduleBuildRequest(
      builder: bbv2.BuilderID(
        project: 'flutter',
        bucket: target.getBucket(),
        builder: target.name,
      ),
      dimensions: requestedDimensions,
      exe: executable,
      gitilesCommit: bbv2.GitilesCommit(
        project: 'mirrors/${commit.slug.name}',
        host: 'flutter.googlesource.com',
        ref: 'refs/heads/${commit.branch}',
        id: commit.sha,
      ),
      notify: bbv2.NotificationConfig(
        // IMPORTANT: We're not post-submit yet, so we want to handle updates to
        // the MQ differently.
        pubsubTopic: 'projects/flutter-dashboard/topics/build-bucket-presubmit',
        userData: preUserData.toBytes(),
      ),
      tags:
          BuildTags([
            ByPostsubmitCommitBuildSetBuildTag(commitSha: commit.sha),
            ByCommitMirroredBuildSetBuildTag(
              commitSha: commit.sha,
              slugName: commit.slug.name,
            ),
            UserAgentBuildTag.flutterCocoon,
            SchedulerJobIdBuildTag(targetName: target.name),
            CurrentAttemptBuildTag(attemptNumber: 1),
            InMergeQueueBuildTag(),
          ]).toStringPairs(),
      properties: propertiesStruct,
      priority: priority,
    );
  }

  /// Creates postsubmit check runs for prod targets in supported repositories.
  @useResult
  Future<CheckRun> createPostsubmitCheckRun(
    OpaqueCommit commit,
    Target target,
  ) async {
    // We are not tracking this check run in the PrCheckRuns firestore doc because
    // there is no PR to look up later. The check run is important because it
    // informs the staging document setup for Merge Groups in triggerMergeGroupTargets.
    return _githubChecksUtil.createCheckRun(
      _config,
      target.slug,
      commit.sha,
      target.name,
    );
  }

  /// Check to auto-rerun TOT test failures.
  ///
  /// A builder will be retried if:
  ///   1. It has been tried below the max retry limit
  ///   2. It is for the tip of tree
  ///   3. The last known status is not green
  ///   4. [ignoreChecks] is false. This allows manual reruns to bypass the Cocoon state.
  @useResult
  Future<bool> checkRerunBuilder({
    required OpaqueCommit commit,
    required Target target,
    required fs.Task taskDocument,
    Task? task,
    Iterable<BuildTag> tags = const [],
  }) async {
    log.info('Rerun builder: ${target.name} for commit ${commit.sha}');

    final buildTags = BuildTags(tags);
    buildTags.add(TriggerTypeBuildTag.autoRetry);

    try {
      final newAttempt = await _updateTaskStatusInDatabaseForRetry(
        commit,
        taskDocument,
      );
      buildTags.add(CurrentAttemptBuildTag(attemptNumber: newAttempt));
    } catch (e, s) {
      log.error(
        'Updating task ${taskDocument.taskName} of commit '
        '${taskDocument.commitSha} failure. Skipping rescheduling.',
        e,
        s,
      );
      return false;
    }

    log.info('Tags from rerun after update: $tags');

    final request = bbv2.BatchRequest(
      requests: <bbv2.BatchRequest_Request>[
        bbv2.BatchRequest_Request(
          scheduleBuild: await _createPostsubmitScheduleBuild(
            commit: commit,
            target: target,
            taskName: taskDocument.taskName,
            priority: kRerunPriority,
            properties: Config.defaultProperties,
            tags: buildTags,
          ),
        ),
      ],
    );

    await _pubsub.publish('cocoon-scheduler-requests', request.toProto3Json());

    return true;
  }

  /// Updates the status of [task] in the database to reflect that it is being
  /// re-run, and returns the new attempt number.
  @useResult
  Future<int> _updateTaskStatusInDatabaseForRetry(
    OpaqueCommit commit,
    fs.Task task,
  ) async {
    // Update task status in Firestore.
    task.resetAsRetry();
    task.setStatus(fs.Task.statusInProgress);

    final firestore = await _config.createFirestoreService();
    await firestore.batchWriteDocuments(
      BatchWriteRequest(writes: documentsToWrites([task], exists: false)),
      kDatabase,
    );

    // Legacy: Write task status to Datastore.
    if (await _config.useLegacyDatastore) {
      final datastore = DatastoreService.defaultProvider(_config.db);
      final commitKey = Commit.createKey(
        db: datastore.db,
        slug: commit.slug,
        gitBranch: commit.branch,
        sha: commit.sha,
      );
      final dsExistingTask = await Task.fromDatastore(
        datastore: datastore,
        commitKey: commitKey,
        name: task.taskName,
      );
      dsExistingTask
        ..attempts = task.currentAttempt
        ..status = Task.statusInProgress;
      await datastore.insert([dsExistingTask]);
    }

    return task.currentAttempt;
  }
}
