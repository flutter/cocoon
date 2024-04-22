// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import 'package:cocoon_service/cocoon_service.dart';
import 'package:collection/collection.dart';
import 'package:fixnum/fixnum.dart';
import 'package:github/github.dart' as github;
import 'package:github/hooks.dart';
import 'package:googleapis/firestore/v1.dart' hide Status;
import 'package:buildbucket/buildbucket_pb.dart' as bbv2;

import '../foundation/github_checks_util.dart';
import '../model/appengine/commit.dart';
import '../model/appengine/task.dart';
import '../model/firestore/commit.dart' as firestore_commit;
import '../model/firestore/task.dart' as firestore;
import '../model/ci_yaml/target.dart';
import '../model/github/checks.dart' as cocoon_checks;
import '../model/luci/buildbucket.dart'; // targets use their own RequestedDimension which is defined here for some reason.
import '../model/luci/user_data.dart';
import '../service/datastore.dart';
import '../service/logging.dart';
import 'build_bucket_v2_client.dart';
import 'exceptions.dart';
import 'github_service.dart';

/// Class to interact with LUCI buildbucket to get, trigger
/// and cancel builds for github repos. It uses [config.luciTryBuilders] to
/// get the list of available builders.
class LuciBuildServiceV2 {
  LuciBuildServiceV2({
    required this.config,
    required this.cache,
    required this.buildBucketV2Client,
    GithubChecksUtil? githubChecksUtil,
    GerritService? gerritService,
    this.pubsub = const PubSub(),
  })  : githubChecksUtil = githubChecksUtil ?? const GithubChecksUtil(),
        gerritService = gerritService ?? GerritService(config: config);

  BuildBucketV2Client buildBucketV2Client;
  final CacheService cache;
  Config config;
  GithubChecksUtil githubChecksUtil;
  GerritService gerritService;

  final PubSub pubsub;

  static const Set<bbv2.Status> failStatusSet = <bbv2.Status>{
    bbv2.Status.CANCELED,
    bbv2.Status.FAILURE,
    bbv2.Status.INFRA_FAILURE,
  };

  static const int kBackfillPriority = 35;
  static const int kDefaultPriority = 30;
  static const int kRerunPriority = 29;

  /// Github labels have a max length of 100, so conserve chars here.
  /// This is currently used by packages repo only.
  /// See: https://github.com/flutter/flutter/issues/130076
  static const String githubBuildLabelPrefix = 'override:';
  static const String propertiesGithubBuildLabelName = 'overrides';

  /// Name of the subcache to store luci build related values in redis.
  static const String subCacheName = 'luci';

  // the Request objects here are the BatchRequest object in bbv2.
  /// Shards [rows] into several sublists of size [maxEntityGroups].
  Future<List<List<bbv2.BatchRequest_Request>>> shard({
    required List<bbv2.BatchRequest_Request> requests,
    required int maxShardSize,
  }) async {
    final List<List<bbv2.BatchRequest_Request>> shards = [];
    for (int i = 0; i < requests.length; i += maxShardSize) {
      shards.add(requests.sublist(i, i + min<int>(requests.length - i, maxShardSize)));
    }
    return shards;
  }

  /// Fetches an Iterable of try BuildBucket [Build]s.
  /// 
  /// Returns a list of BuildBucket [Build]s for a given Github [slug], [sha],
  /// and [builderName].
  Future<Iterable<bbv2.Build>> getTryBuilds({
    required github.RepositorySlug slug,
    required String sha,
    String? builderName,
  }) async {
    final List<bbv2.StringPair> tags = [
      bbv2.StringPair(
        key: 'buildset',
        value: 'sha/git/$sha',
      ),
      bbv2.StringPair(
        key: 'user_agent',
        value: 'flutter-cocoon',
      ),
    ];
    return getBuilds(
      slug: slug,
      commitSha: sha,
      builderName: builderName,
      bucket: 'try',
      tags: tags,
    );
  }

  /// Fetches an Iterable of try BuildBucket [Build]s.
  /// 
  /// Returns a list of BuildBucket [Build]s for a given Github [PullRequest].
  Future<Iterable<bbv2.Build>> getTryBuildsByPullRequest({
    required github.PullRequest pullRequest,
  }) async {
    final github.RepositorySlug slug = pullRequest.base!.repo!.slug();
    final List<bbv2.StringPair> tags = [
      bbv2.StringPair(
        key: 'buildset',
        value: 'pr/git/${pullRequest.number}',
      ),
      bbv2.StringPair(
        key: 'github_link',
        value: 'https://github.com/${slug.fullName}/pull/${pullRequest.number}',
      ),
      bbv2.StringPair(
        key: 'user_agent',
        value: 'flutter-cocoon',
      ),
    ];
    return getBuilds(
      slug: slug,
      commitSha: null,
      builderName: null,
      bucket: 'try',
      tags: tags,
    );
  }

  /// Fetches an Iterable of prod BuildBucket [Build]s.
  /// 
  /// Returns an Iterable of prod BuildBucket [Build]s for a given Github
  /// [slug], [sha], and [builderName].
  Future<Iterable<bbv2.Build>> getProdBuilds({
    required github.RepositorySlug slug,
    required String commitSha,
    String? builderName,
  }) async {
    final List<bbv2.StringPair> tags = [];
    return getBuilds(
      slug: slug,
      commitSha: commitSha,
      builderName: builderName,
      bucket: 'prod',
      tags: tags,
    );
  }

  /// Fetches an Iterable of try BuildBucket [Build]s.
  /// 
  /// Returns an iterable of try BuildBucket [Build]s for a given Github [slug],
  /// [sha], [builderName], [bucket], and [tags].
  Future<Iterable<bbv2.Build>> getBuilds({
    required github.RepositorySlug? slug,
    required String? commitSha,
    required String? builderName,
    required String bucket,
    required List<bbv2.StringPair> tags,
  }) async {
    final bbv2.FieldMask fieldMask = bbv2.FieldMask(
      paths: {
        'id',
        'builder',
        'tags',
        'status',
        'input.properties',
      },
    );

    final bbv2.BuildMask buildMask = bbv2.BuildMask(fields: fieldMask);

    final bbv2.BuildPredicate buildPredicate = bbv2.BuildPredicate(
      builder: bbv2.BuilderID(
        project: 'flutter',
        bucket: bucket,
        builder: builderName,
      ),
      tags: tags,
    );

    final bbv2.SearchBuildsRequest searchBuildsRequest = bbv2.SearchBuildsRequest(
      predicate: buildPredicate,
      mask: buildMask,
    );

    // Need to create one of these for each request in the batch.
    final bbv2.BatchRequest_Request batchRequestRequest = bbv2.BatchRequest_Request(
      searchBuilds: searchBuildsRequest,
    );

    final bbv2.BatchResponse batchResponse = await buildBucketV2Client.batch(
      bbv2.BatchRequest(
        requests: {batchRequestRequest},
      ),
    );

    log.info('Reponses from get builds batch request = ${batchResponse.responses.length}');
    for (bbv2.BatchResponse_Response response in batchResponse.responses) {
      log.info('Found a response: ${response.toString()}');
    }

    final Iterable<bbv2.Build> builds = batchResponse.responses
        .map((bbv2.BatchResponse_Response response) => response.searchBuilds)
        .expand((bbv2.SearchBuildsResponse? response) => response!.builds);
    return builds;
  }

  /// Schedules presubmit [targets] on BuildBucket for [pullRequest].
  Future<List<Target>> scheduleTryBuilds({
    required List<Target> targets,
    required github.PullRequest pullRequest,
    CheckSuiteEvent? checkSuiteEvent,
  }) async {
    if (targets.isEmpty) {
      return targets;
    }

    // final bbv2.BatchRequest batchRequest = bbv2.BatchRequest().createEmptyInstance();
    final List<bbv2.BatchRequest_Request> batchRequestList = [];
    final List<String> branches = await gerritService.branches(
      'flutter-review.googlesource.com',
      'recipes',
      filterRegex: 'flutter-.*|fuchsia.*',
    );
    log.info('Available release branches: $branches');

    final String sha = pullRequest.head!.sha!;
    String cipdVersion = 'refs/heads/${pullRequest.base!.ref!}';
    cipdVersion = branches.contains(cipdVersion) ? cipdVersion : config.defaultRecipeBundleRef;

    for (Target target in targets) {
      final github.CheckRun checkRun = await githubChecksUtil.createCheckRun(
        config,
        target.slug,
        sha,
        target.value.name,
      );

      final github.RepositorySlug slug = pullRequest.base!.repo!.slug();

      final Map<String, dynamic> userData = <String, dynamic>{
        'builder_name': target.value.name,
        'check_run_id': checkRun.id,
        'commit_sha': sha,
        'commit_branch': pullRequest.base!.ref!.replaceAll('refs/heads/', ''),
      };

      final List<bbv2.StringPair> tags = [
        bbv2.StringPair(
          key: 'github_checkrun',
          value: checkRun.id.toString(),
        ),
      ];

      final Map<String, Object> properties = target.getProperties();
      properties.putIfAbsent(
        'git_branch',
        () => pullRequest.base!.ref!.replaceAll('refs/heads/', ''),
      );

      // final String json = jsonEncode(properties);
      final bbv2.Struct struct = bbv2.Struct.create();
      struct.mergeFromProto3Json(properties);

      final List<String>? labels = extractPrefixedLabels(
        issueLabels: pullRequest.labels,
        prefix: githubBuildLabelPrefix,
      );

      if (labels != null && labels.isNotEmpty) {
        properties[propertiesGithubBuildLabelName] = labels;
      }

      // Convert from target RequestedDimensions to bbv2.RequestedDimensions.
      final List<RequestedDimension> targetDimensions = target.getDimensions();
      final List<bbv2.RequestedDimension> requestedDimensions = <bbv2.RequestedDimension>[];
      for (RequestedDimension requestedDimension in targetDimensions) {
        requestedDimensions.add(bbv2.RequestedDimension(key: requestedDimension.key, value: requestedDimension.value));
      }

      batchRequestList.add(
        bbv2.BatchRequest_Request(
          scheduleBuild: await _createPresubmitScheduleBuild(
            slug: slug,
            sha: pullRequest.head!.sha!,
            //Use target.value.name here otherwise tests will die due to null checkRun.name.
            checkName: target.value.name,
            pullRequestNumber: pullRequest.number!,
            cipdVersion: cipdVersion,
            userData: userData,
            properties: properties,
            tags: tags,
            dimensions: requestedDimensions,
          ),
        ),
      );
    }

    final Iterable<List<bbv2.BatchRequest_Request>> requestPartitions = await shard(
      requests: batchRequestList,
      maxShardSize: config.schedulingShardSize,
    );
    for (List<bbv2.BatchRequest_Request> requestPartition in requestPartitions) {
      final bbv2.BatchRequest batchRequest = bbv2.BatchRequest(requests: requestPartition);
      await pubsub.publish('cocoon-scheduler-requests', batchRequest.toProto3Json());
    }

    return targets;
  }

  /// Cancels all the current builds on [pullRequest] with [reason].
  ///
  /// Builds are queried based on the [RepositorySlug] and pull request number.
  //
  Future<void> cancelBuilds({
    required github.PullRequest pullRequest,
    required String reason,
  }) async {
    log.info(
      'Attempting to cancel builds (v2) for pullrequest ${pullRequest.base!.repo!.fullName}/${pullRequest.number}',
    );

    final Iterable<bbv2.Build> builds = await getTryBuildsByPullRequest(pullRequest: pullRequest);
    log.info('Found ${builds.length} builds.');

    if (builds.isEmpty) {
      log.warning('No builds were found for pull request ${pullRequest.base!.repo!.fullName}.');
      return;
    }

    final List<bbv2.BatchRequest_Request> requests = <bbv2.BatchRequest_Request>[];
    for (bbv2.Build build in builds) {
      if (build.status == bbv2.Status.SCHEDULED || build.status == bbv2.Status.STARTED) {
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
      await buildBucketV2Client.batch(bbv2.BatchRequest(requests: requests));
    }
  }

  /// Filters [builders] to only those that failed on [pullRequest].
  Future<List<bbv2.Build?>> failedBuilds({
    required github.PullRequest pullRequest,
    required List<Target> targets,
  }) async {
    final Iterable<bbv2.Build> builds = await getTryBuilds(
      slug: pullRequest.base!.repo!.slug(),
      sha: pullRequest.head!.sha!,
      builderName: null,
    );
    final Iterable<String> builderNames = targets.map((Target target) => target.value.name);
    // Return only builds that exist in the configuration file.
    final Iterable<bbv2.Build?> failedBuilds =
        builds.where((bbv2.Build? build) => failStatusSet.contains(build!.status));
    final Iterable<bbv2.Build?> expectedFailedBuilds =
        failedBuilds.where((bbv2.Build? build) => builderNames.contains(build!.builder.builder));
    return expectedFailedBuilds.toList();
  }

  /// Sends [ScheduleBuildRequest] using information from a given build's
  /// [BuildPushMessage].
  ///
  /// The buildset, user_agent, and github_link tags are applied to match the
  /// original build. The build properties and user data from the original build
  /// are also preserved.
  ///
  /// The [currentAttempt] is used to track the number of current build attempt.
  Future<bbv2.Build> rescheduleBuild({
    required String builderName,
    required bbv2.Build build,
    required int rescheduleAttempt,
    required Map<String, dynamic> userDataMap,
  }) async {
    final List<bbv2.StringPair> tags = build.tags;
    // need to replace the current_attempt
    bbv2.StringPair attempt;
    final (int, bbv2.StringPair)? record =
        tags.indexed.firstWhereOrNull((element) => element.$2.key == 'current_attempt');
    if (record == null) {
      attempt = bbv2.StringPair(
        key: 'current_attempt',
        value: rescheduleAttempt.toString(),
      );
    } else {
      attempt = tags.removeAt(record.$1);
      attempt.value = rescheduleAttempt.toString();
    }
    tags.add(attempt);

    return buildBucketV2Client.scheduleBuild(
      bbv2.ScheduleBuildRequest(
        builder: build.builder,
        tags: tags,
        properties: build.input.properties,
        notify: bbv2.NotificationConfig(
          pubsubTopic: 'projects/flutter-dashboard/topics/build-bucket-presubmit',
          userData: UserData.encodeUserDataToBytes(userDataMap),
        ),
      ),
    );
  }

  /// Sends presubmit [ScheduleBuildRequest] for a pull request using [checkRunEvent].
  ///
  /// Returns the [bbv2.Build] returned by scheduleBuildRequest.
  Future<bbv2.Build> reschedulePresubmitBuildUsingCheckRunEvent({
    required cocoon_checks.CheckRunEvent checkRunEvent,
  }) async {
    final github.RepositorySlug slug = checkRunEvent.repository!.slug();

    final String sha = checkRunEvent.checkRun!.headSha!;
    final String checkName = checkRunEvent.checkRun!.name!;

    final github.CheckRun githubCheckRun = await githubChecksUtil.createCheckRun(
      config,
      slug,
      sha,
      checkName,
    );

    final Iterable<bbv2.Build> builds = await getTryBuilds(
      slug: slug,
      sha: sha,
      builderName: checkName,
    );
    if (builds.isEmpty) {
      throw NoBuildFoundException('Unable to find try build.');
    }

    final bbv2.Build build = builds.first;

    // Assumes that the tags are already defined.
    final List<bbv2.StringPair> tags = build.tags;
    final String prString =
        tags.firstWhere((element) => element.key == 'buildset' && element.value.startsWith('pr/git')).value;
    final String cipdVersion = tags.firstWhere((element) => element.key == 'cipd_version').value;
    final String githubLink = tags.firstWhere((element) => element.key == 'github_link').value;

    final String repoName = githubLink.split('/')[4];
    final String branch = Config.defaultBranch(github.RepositorySlug('flutter', repoName));
    final int prNumber = int.parse(prString.split('/')[2]);

    final Map<String, dynamic> userData = <String, dynamic>{
      'check_run_id': githubCheckRun.id,
      'commit_branch': branch,
      'commit_sha': sha,
    };

    final bbv2.Struct propertiesStruct =
        (build.input.hasProperties()) ? build.input.properties : bbv2.Struct().createEmptyInstance();
    final Map<String, Object?> properties = propertiesStruct.toProto3Json() as Map<String, Object?>;
    final GithubService githubService = await config.createGithubService(slug);

    final List<github.IssueLabel> issueLabels = await githubService.getIssueLabels(
      slug,
      prNumber,
    );
    final List<String>? labels = extractPrefixedLabels(
      issueLabels: issueLabels,
      prefix: githubBuildLabelPrefix,
    );

    if (labels != null && labels.isNotEmpty) {
      properties[propertiesGithubBuildLabelName] = labels;
    }

    final bbv2.ScheduleBuildRequest scheduleBuildRequest = await _createPresubmitScheduleBuild(
      slug: slug,
      sha: sha,
      checkName: checkName,
      pullRequestNumber: prNumber,
      cipdVersion: cipdVersion,
      properties: properties,
      userData: userData,
    );

    final bbv2.Build scheduleBuild = await buildBucketV2Client.scheduleBuild(scheduleBuildRequest);
    final String buildUrl = 'https://ci.chromium.org/ui/b/${scheduleBuild.id}';
    await githubChecksUtil.updateCheckRun(config, slug, githubCheckRun, detailsUrl: buildUrl);
    return scheduleBuild;
  }

  /// Collect any label whose name is prefixed by the prefix [String].
  ///
  /// Returns a [List] of prefixed label names as [String]s.
  List<String>? extractPrefixedLabels({
    List<github.IssueLabel>? issueLabels,
    required String prefix,
  }) {
    return issueLabels?.where((label) => label.name.startsWith(prefix)).map((obj) => obj.name).toList();
  }

  /// Sends postsubmit [ScheduleBuildRequest] for a commit using [checkRunEvent], [Commit], [Task], and [Target].
  ///
  /// Returns the [bbv2.Build] returned by scheduleBuildRequest.
  Future<bbv2.Build> reschedulePostsubmitBuildUsingCheckRunEvent(
    cocoon_checks.CheckRunEvent checkRunEvent, {
    required Commit commit,
    required Task task,
    required Target target,
  }) async {
    final github.RepositorySlug slug = checkRunEvent.repository!.slug();
    final String sha = checkRunEvent.checkRun!.headSha!;
    final String checkName = checkRunEvent.checkRun!.name!;

    final Iterable<bbv2.Build> builds = await getProdBuilds(
      slug: slug,
      commitSha: sha,
      builderName: checkName,
    );
    if (builds.isEmpty) {
      throw NoBuildFoundException('Unable to find prod build.');
    }

    final bbv2.Build build = builds.first;

    // get it as a struct first and convert it.
    final bbv2.Struct propertiesStruct = build.input.properties;
    final Map<String, Object> properties = propertiesStruct.toProto3Json() as Map<String, Object>;

    // final Map<String, Object>? properties = build.input.properties;
    log.info('input ${build.input} properties $properties');

    final bbv2.ScheduleBuildRequest scheduleBuildRequest = await _createPostsubmitScheduleBuild(
      commit: commit,
      target: target,
      task: task,
      properties: properties,
    );
    final bbv2.Build scheduleBuild = await buildBucketV2Client.scheduleBuild(scheduleBuildRequest);
    return scheduleBuild;
  }

  /// Gets [bbv2.Build] using its [id] and passing the additional
  /// fields to be populated in the response.
  Future<bbv2.Build> getBuildById(
    Int64 id, {
    bbv2.BuildMask? buildMask,
  }) async {
    final bbv2.GetBuildRequest request = bbv2.GetBuildRequest(
      id: id,
      mask: buildMask,
    );
    return buildBucketV2Client.getBuild(request);
  }

  /// Gets builder list whose config is pre-defined in LUCI.
  ///
  /// Returns cache if existing. Otherwise make the RPC call to fetch list.
  Future<Set<String>> getAvailableBuilderSet({
    String project = 'flutter',
    String bucket = 'prod',
  }) async {
    final Uint8List? cacheValue = await cache.getOrCreate(
      subCacheName,
      'builderlist',
      createFn: () => _getAvailableBuilderSet(
        project: project,
        bucket: bucket,
      ),
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
    log.info('No cached value for builderList, start fetching via the rpc call.');
    final Set<String> availableBuilderSet = <String>{};
    bool hasToken = true;
    String? token;
    do {
      final bbv2.ListBuildersResponse listBuildersResponse = await buildBucketV2Client.listBuilders(
        bbv2.ListBuildersRequest(
          project: project,
          bucket: bucket,
          pageToken: token,
        ),
      );
      final List<String> availableBuilderList = listBuildersResponse.builders.map((e) => e.id.builder).toList();
      availableBuilderSet.addAll(<String>{...availableBuilderList});
      hasToken = listBuildersResponse.hasNextPageToken();
      if (hasToken) {
        token = listBuildersResponse.nextPageToken;
      }
    } while (hasToken && token != null);
    final String joinedBuilderSet = availableBuilderSet.toList().join(',');
    log.info('successfully fetched the builderSet: $joinedBuilderSet');
    return Uint8List.fromList(joinedBuilderSet.codeUnits);
  }

  /// Schedules list of post-submit builds deferring work to [schedulePostsubmitBuild].
  ///
  /// Returns empty list if all targets are successfully published to pub/sub. Otherwise,
  /// returns the original list.
  Future<List<Tuple<Target, Task, int>>> schedulePostsubmitBuilds({
    required Commit commit,
    required List<Tuple<Target, Task, int>> toBeScheduled,
  }) async {
    if (toBeScheduled.isEmpty) {
      log.fine('Skipping schedulePostsubmitBuilds as there are no targets to be scheduled by Cocoon');
      return toBeScheduled;
    }
    final List<bbv2.BatchRequest_Request> buildRequests = [];
    // bbv2.BatchRequest_Request batchRequest_Request = bbv2.BatchRequest_Request();

    Set<String> availableBuilderSet;
    try {
      availableBuilderSet = await getAvailableBuilderSet(
        project: 'flutter',
        bucket: 'prod',
      );
    } catch (error) {
      log.severe('Failed to get buildbucket builder list due to $error');
      return toBeScheduled;
    }
    log.info('Available builder list: $availableBuilderSet');
    for (Tuple<Target, Task, int> tuple in toBeScheduled) {
      // Non-existing builder target will be skipped from scheduling.
      if (!availableBuilderSet.contains(tuple.first.value.name)) {
        log.warning('Found no available builder for ${tuple.first.value.name}, commit ${commit.sha}');
        continue;
      }
      log.info('create postsubmit schedule request for target: ${tuple.first.value} in commit ${commit.sha}');
      final bbv2.ScheduleBuildRequest scheduleBuildRequest = await _createPostsubmitScheduleBuild(
        commit: commit,
        target: tuple.first,
        task: tuple.second,
        priority: tuple.third,
      );
      buildRequests.add(bbv2.BatchRequest_Request(scheduleBuild: scheduleBuildRequest));
      log.info('created postsubmit schedule request for target: ${tuple.first.value} in commit ${commit.sha}');
    }

    final bbv2.BatchRequest batchRequest = bbv2.BatchRequest(requests: buildRequests);
    log.fine(batchRequest);
    List<String> messageIds;

    try {
      messageIds = await pubsub.publish('cocoon-scheduler-requests', batchRequest.toProto3Json());
      log.info('Published $messageIds for commit ${commit.sha}');
    } catch (error) {
      log.severe('Failed to publish message to pub/sub due to $error');
      return toBeScheduled;
    }
    log.info('Published a request with ${buildRequests.length} builds');
    return <Tuple<Target, Task, int>>[];
  }

  /// Create a Presubmit ScheduleBuildRequest using the [slug], [sha], and
  /// [checkName] for the provided [build] with the provided [checkRunId].
  Future<bbv2.ScheduleBuildRequest> _createPresubmitScheduleBuild({
    required github.RepositorySlug slug,
    required String sha,
    required String checkName,
    required int pullRequestNumber,
    required String cipdVersion,
    Map<String, Object?>? properties,
    List<bbv2.StringPair>? tags,
    Map<String, dynamic>? userData,
    List<bbv2.RequestedDimension>? dimensions,
  }) async {
    final Map<String, dynamic> processedUserData = userData ?? <String, dynamic>{};
    processedUserData['repo_owner'] = slug.owner;
    processedUserData['repo_name'] = slug.name;
    processedUserData['user_agent'] = 'flutter-cocoon';

    final bbv2.BuilderID builderId = bbv2.BuilderID.create();
    builderId.bucket = 'try';
    builderId.project = 'flutter';
    builderId.builder = checkName;

    // Add the builderId.
    final bbv2.ScheduleBuildRequest scheduleBuildRequest = bbv2.ScheduleBuildRequest.create();
    scheduleBuildRequest.builder = builderId;

    final List<String> fields = [
      'id',
      'builder',
      'number',
      'status',
      'tags',
    ];
    final bbv2.FieldMask fieldMask = bbv2.FieldMask(paths: fields);
    final bbv2.BuildMask buildMask = bbv2.BuildMask(fields: fieldMask);
    scheduleBuildRequest.mask = buildMask;

    // Set the executable.
    final bbv2.Executable executable = bbv2.Executable(cipdVersion: cipdVersion);
    scheduleBuildRequest.exe = executable;

    // Add the dimensions to the instance.
    final List<bbv2.RequestedDimension> instanceDimensions = scheduleBuildRequest.dimensions;
    instanceDimensions.addAll(dimensions ?? []);

    // Create the notification configuration for pubsub processing.
    final bbv2.NotificationConfig notificationConfig = bbv2.NotificationConfig().createEmptyInstance();
    notificationConfig.pubsubTopic = 'projects/flutter-dashboard/topics/build-bucket-presubmit';
    notificationConfig.userData = UserData.encodeUserDataToBytes(processedUserData)!;
    scheduleBuildRequest.notify = notificationConfig;

    // Add tags to the instance.
    final List<bbv2.StringPair> processTags = tags ?? <bbv2.StringPair>[];
    processTags.add(
      bbv2.StringPair(
        key: 'buildset',
        value: 'pr/git/$pullRequestNumber',
      ),
    );
    processTags.add(
      bbv2.StringPair(
        key: 'buildset',
        value: 'sha/git/$sha',
      ),
    );
    processTags.add(
      bbv2.StringPair(
        key: 'user_agent',
        value: 'flutter-cocoon',
      ),
    );
    processTags.add(
      bbv2.StringPair(
        key: 'github_link',
        value: 'https://github.com/${slug.owner}/${slug.name}/pull/$pullRequestNumber',
      ),
    );
    processTags.add(
      bbv2.StringPair(
        key: 'cipd_version',
        value: cipdVersion,
      ),
    );
    final List<bbv2.StringPair> instanceTags = scheduleBuildRequest.tags;
    instanceTags.addAll(processTags);

    properties ??= {};
    properties['git_url'] = 'https://github.com/${slug.owner}/${slug.name}';
    properties['git_ref'] = 'refs/pull/$pullRequestNumber/head';
    properties['exe_cipd_version'] = cipdVersion;

    final bbv2.Struct propertiesStruct = bbv2.Struct.create();
    propertiesStruct.mergeFromProto3Json(properties);

    scheduleBuildRequest.properties = propertiesStruct;

    return scheduleBuildRequest;
  }

  /// Creates a [ScheduleBuildRequest] for [target] and [task] against [commit].
  ///
  /// By default, build [priority] is increased for release branches.
  Future<bbv2.ScheduleBuildRequest> _createPostsubmitScheduleBuild({
    required Commit commit,
    required Target target,
    required Task task,
    Map<String, Object>? properties,
    List<bbv2.StringPair>? tags,
    int priority = kDefaultPriority,
  }) async {
    log.info('Creating postsubmit schedule builder for ${target.value.name} on commit ${commit.sha}');
    tags ??= [];
    tags.addAll([
      bbv2.StringPair(
        key: 'buildset',
        value: 'commit/git/${commit.sha}',
      ),
      bbv2.StringPair(
        key: 'buildset',
        value: 'commit/gitiles/flutter.googlesource.com/mirrors/${commit.slug.name}/+/${commit.sha}',
      ),
    ]);

    final String commitKey = task.parentKey!.id.toString();
    final String taskKey = task.key.id.toString();
    log.info('Scheduling builder: ${target.value.name} for commit ${commit.sha}');
    log.info('Task commit_key: $commitKey for task name: ${task.name}');
    log.info('Task task_key: $taskKey for task name: ${task.name}');

    final Map<String, dynamic> rawUserData = <String, dynamic>{
      'commit_key': commitKey,
      'task_key': taskKey,
      'firestore_commit_document_name': commit.sha,
    };

    // Creates post submit checkrun only for unflaky targets from [config.postsubmitSupportedRepos].
    if (!target.value.bringup && config.postsubmitSupportedRepos.contains(target.slug)) {
      await createPostsubmitCheckRun(
        commit,
        target,
        rawUserData,
      );
    }

    tags.add(
      bbv2.StringPair(
        key: 'user_agent',
        value: 'flutter-cocoon',
      ),
    );
    // Tag `scheduler_job_id` is needed when calling buildbucket search build API.
    tags.add(
      bbv2.StringPair(
        key: 'scheduler_job_id',
        value: 'flutter/${target.value.name}',
      ),
    );
    // Default attempt is the initial attempt, which is 1.
    final bbv2.StringPair? attemptTag = tags.singleWhereOrNull((tag) => tag.key == 'current_attempt');
    if (attemptTag == null) {
      tags.add(
        bbv2.StringPair(
          key: 'current_attempt',
          value: '1',
        ),
      );
    }

    final String currentAttemptStr = tags.firstWhere((tag) => tag.key == 'current_attempt').value;
    rawUserData['firestore_task_document_name'] = '${commit.sha}_${task.name}_$currentAttemptStr';

    final Map<String, Object> processedProperties = target.getProperties();
    processedProperties.addAll(properties ?? <String, Object>{});
    processedProperties['git_branch'] = commit.branch!;
    final String cipdExe = 'refs/heads/${commit.branch}';
    processedProperties['exe_cipd_version'] = cipdExe;

    final bbv2.Struct propertiesStruct = bbv2.Struct.create();
    propertiesStruct.mergeFromProto3Json(processedProperties);

    // Convert from target RequestedDimensions to bbv2.RequestedDimensions.
    final List<RequestedDimension> targetDimensions = target.getDimensions();
    final List<bbv2.RequestedDimension> requestedDimensions = <bbv2.RequestedDimension>[];
    for (RequestedDimension requestedDimension in targetDimensions) {
      requestedDimensions.add(bbv2.RequestedDimension(key: requestedDimension.key, value: requestedDimension.value));
    }

    final bbv2.Executable executable = bbv2.Executable(cipdVersion: cipdExe);

    log.info('Constructing the postsubmit schedule build request for ${target.value.name} on commit ${commit.sha}.');

    return bbv2.ScheduleBuildRequest(
      builder: bbv2.BuilderID(
        project: 'flutter',
        bucket: target.getBucket(),
        builder: target.value.name,
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
        pubsubTopic: 'projects/flutter-dashboard/topics/build-bucket-postsubmit',
        userData: UserData.encodeUserDataToBytes(rawUserData),
      ),
      tags: tags,
      properties: propertiesStruct,
      priority: priority,
    );
  }

  /// Creates postsubmit check runs for prod targets in supported repositories.
  Future<void> createPostsubmitCheckRun(
    Commit commit,
    Target target,
    Map<String, dynamic> rawUserData,
  ) async {
    final github.CheckRun checkRun = await githubChecksUtil.createCheckRun(
      config,
      target.slug,
      commit.sha!,
      target.value.name,
    );
    rawUserData['check_run_id'] = checkRun.id;
    rawUserData['commit_sha'] = commit.sha;
    rawUserData['commit_branch'] = commit.branch;
    rawUserData['builder_name'] = target.value.name;
    rawUserData['repo_owner'] = target.slug.owner;
    rawUserData['repo_name'] = target.slug.name;
  }

  /// Check to auto-rerun TOT test failures.
  ///
  /// A builder will be retried if:
  ///   1. It has been tried below the max retry limit
  ///   2. It is for the tip of tree
  ///   3. The last known status is not green
  ///   4. [ignoreChecks] is false. This allows manual reruns to bypass the Cocoon state.
  Future<bool> checkRerunBuilder({
    required Commit commit,
    required Target target,
    required Task task,
    required DatastoreService datastore,
    required firestore.Task taskDocument,
    required FirestoreService firestoreService,
    List<bbv2.StringPair>? tags,
    bool ignoreChecks = false,
  }) async {
    if (ignoreChecks == false && await _shouldRerunBuilderFirestore(taskDocument, firestoreService) == false) {
      return false;
    }

    log.info('Rerun builder: ${target.value.name} for commit ${commit.sha}');
    tags ??= <bbv2.StringPair>[];
    final bbv2.StringPair? triggerTag =
        tags.singleWhereOrNull((element) => element.key == 'trigger_type' && element.value == 'auto_retry');
    if (triggerTag == null) {
      tags.add(
        bbv2.StringPair(
          key: 'trigger_type',
          value: 'auto_retry',
        ),
      );
    }

    try {
      // Updates task status in Datastore.
      task.attempts = (task.attempts ?? 0) + 1;
      // Mark task as in progress to ensure it isn't scheduled over
      task.status = Task.statusInProgress;
      await datastore.insert(<Task>[task]);

      // Updates task status in Firestore.
      final int newAttempt = int.parse(taskDocument.name!.split('_').last) + 1;
      tags.add(bbv2.StringPair(key: 'current_attempt', value: newAttempt.toString()));
      taskDocument.resetAsRetry(attempt: newAttempt);
      taskDocument.setStatus(firestore.Task.statusInProgress);
      final List<Write> writes = documentsToWrites([taskDocument], exists: false);
      await firestoreService.batchWriteDocuments(BatchWriteRequest(writes: writes), kDatabase);
    } catch (error) {
      log.severe(
        'updating task ${taskDocument.taskName} of commit ${taskDocument.commitSha} failure: $error. Skipping rescheduling.',
      );
      return false;
    }

    final bbv2.BatchRequest request = bbv2.BatchRequest(
      requests: <bbv2.BatchRequest_Request>[
        bbv2.BatchRequest_Request(
          scheduleBuild: await _createPostsubmitScheduleBuild(
            commit: commit,
            target: target,
            task: task,
            priority: kRerunPriority,
            properties: Config.defaultProperties,
            tags: tags,
          ),
        ),
      ],
    );

    await pubsub.publish(
      'cocoon-scheduler-requests',
      request.toProto3Json(),
    );

    return true;
  }

  /// Check if a builder should be rerun.
  ///
  /// A rerun happens when a build fails, the retry number hasn't reached the limit, and the build is on TOT.
  Future<bool> _shouldRerunBuilderFirestore(firestore.Task task, FirestoreService firestoreService) async {
    if (!firestore.Task.taskFailStatusSet.contains(task.status)) {
      return false;
    }
    final int retries = task.attempts ?? 1;
    if (retries > config.maxLuciTaskRetries) {
      log.warning('Max retries reached');
      return false;
    }

    final String commitDocumentName = '$kDatabase/documents/${firestore_commit.kCommitCollectionId}/${task.commitSha}';
    final firestore_commit.Commit currentCommit = await firestore_commit.Commit.fromFirestore(
      firestoreService: firestoreService,
      documentName: commitDocumentName,
    );
    final List<firestore_commit.Commit> commitList = await firestoreService.queryRecentCommits(
      limit: 1,
      slug: currentCommit.slug,
      branch: currentCommit.branch,
    );
    final firestore_commit.Commit latestCommit = commitList.single;
    return latestCommit.sha == currentCommit.sha;
  }
}
