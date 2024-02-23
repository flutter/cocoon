// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:cocoon_service/cocoon_service.dart';
import 'package:github/github.dart' as github;
import 'package:github/hooks.dart';
import 'package:googleapis/firestore/v1.dart' hide Status;
import 'package:googleapis/pubsub/v1.dart';
import 'package:buildbucket/buildbucket_pb.dart' as bbv2;

import '../foundation/github_checks_util.dart';
import '../model/appengine/commit.dart';
import '../model/appengine/task.dart';
import '../model/firestore/task.dart' as f;
import '../model/ci_yaml/target.dart';
import '../model/github/checks.dart' as cocoon_checks;
import '../model/luci/buildbucket.dart';
import '../model/luci/push_message.dart' as push_message;
import '../service/datastore.dart';
import '../service/logging.dart';
import 'build_bucket_v2_client.dart';
import 'buildbucket.dart';
import 'cache_service.dart';
import 'config.dart';
import 'exceptions.dart';
import 'github_service.dart';

const Set<String> taskFailStatusSet = <String>{
  Task.statusInfraFailure,
  Task.statusFailed,
  Task.statusCancelled,
};

/// Class to interact with LUCI buildbucket to get, trigger
/// and cancel builds for github repos. It uses [config.luciTryBuilders] to
/// get the list of available builders.
class LuciBuildService {
  LuciBuildService({
    required this.config,
    required this.cache,
    required this.buildBucketClient,
    required this.buildBucketV2Client,
    GithubChecksUtil? githubChecksUtil,
    GerritService? gerritService,
    this.pubsub = const PubSub(),
  })  : githubChecksUtil = githubChecksUtil ?? const GithubChecksUtil(),
        gerritService = gerritService ?? GerritService(config: config);

  BuildBucketClient buildBucketClient;
  BuildBucketV2Client buildBucketV2Client;
  final CacheService cache;
  Config config;
  GithubChecksUtil githubChecksUtil;
  GerritService gerritService;

  final PubSub pubsub;

  static const Set<Status> failStatusSet = <Status>{Status.canceled, Status.failure, Status.infraFailure};

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

  /// Shards [rows] into several sublists of size [maxEntityGroups].
  Future<List<List<Request>>> shard(List<Request> requests, int max) async {
    final List<List<Request>> shards = <List<Request>>[];
    for (int i = 0; i < requests.length; i += max) {
      shards.add(requests.sublist(i, i + min<int>(requests.length - i, max)));
    }
    return shards;
  }

  /// Returns an Iterable of try BuildBucket build for a given Github [slug], [sha], [builderName].
  Future<Iterable<Build>> getTryBuilds(
    github.RepositorySlug slug,
    String sha,
    String? builderName,
  ) async {
    final Map<String, List<String>> tags = <String, List<String>>{
      'buildset': <String>['sha/git/$sha'],
      'user_agent': const <String>['flutter-cocoon'],
    };
    return getBuilds(slug, sha, builderName, 'try', tags);
  }

  /// Returns an Iterable of try Buildbucket [Build]s for a given [PullRequest].
  Future<Iterable<Build>> getTryBuildsByPullRequest(
    github.PullRequest pullRequest,
  ) async {
    final github.RepositorySlug slug = pullRequest.base!.repo!.slug();
    final Map<String, List<String>> tags = <String, List<String>>{
      'buildset': <String>['pr/git/${pullRequest.number}'],
      'github_link': <String>['https://github.com/${slug.fullName}/pull/${pullRequest.number}'],
      'user_agent': const <String>['flutter-cocoon'],
    };
    return getBuilds(slug, null, null, 'try', tags);
  }

  /// Returns an Iterable of prod BuildBucket build for a given Github [slug], [commitSha],
  /// [builderName] and [repo].
  Future<Iterable<Build>> getProdBuilds(
    github.RepositorySlug slug,
    String commitSha,
    String? builderName,
  ) async {
    final Map<String, List<String>> tags = <String, List<String>>{};
    return getBuilds(slug, commitSha, builderName, 'prod', tags);
  }

  /// Returns an iterable of BuildBucket builds for a given Github [slug], [commitSha],
  /// [builderName], [bucket] and [tags].
  Future<Iterable<Build>> getBuilds(
    github.RepositorySlug? slug,
    String? commitSha,
    String? builderName,
    String bucket,
    Map<String, List<String>> tags,
  ) async {
    final BatchResponse batch = await buildBucketClient.batch(
      BatchRequest(
        requests: <Request>[
          Request(
            searchBuilds: SearchBuildsRequest(
              predicate: BuildPredicate(
                builderId: BuilderId(
                  project: 'flutter',
                  bucket: bucket,
                  builder: builderName,
                ),
                tags: tags,
              ),
              fields: 'builds.*.id,builds.*.builder,builds.*.tags,builds.*.status,builds.*.input.properties',
            ),
          ),
        ],
      ),
    );

    log.info('Reponses from get builds batch request = ${batch.responses!.length}');
    for (Response response in batch.responses!) {
      log.info('Found a response: ${response.toString()}');
    }

    final Iterable<Build> builds = batch.responses!
        .map((Response response) => response.searchBuilds)
        .expand((SearchBuildsResponse? response) => response!.builds ?? <Build>[]);
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

    final List<Request> requests = <Request>[];
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

      final Map<String, List<String>> tags = <String, List<String>>{
        'github_checkrun': <String>[checkRun.id.toString()],
      };

      final Map<String, Object> properties = target.getProperties();
      properties.putIfAbsent('git_branch', () => pullRequest.base!.ref!.replaceAll('refs/heads/', ''));

      final List<String>? labels = extractPrefixedLabels(pullRequest.labels, githubBuildLabelPrefix);

      if (labels != null && labels.isNotEmpty) {
        properties[propertiesGithubBuildLabelName] = labels;
      }

      //TODO might be able to duplicate the work here so that we can see what this
      // pushes to the new sub.
      // bbv2.BatchRequest batchRequest = bbv2.BatchRequest.create();
      // _createPresubmitScheduleBuildV2(
      //   slug: slug,
      //   sha: sha,
      //   checkName: target.value.name,
      //   pullRequestNumber: pullRequest.number!,
      //   cipdVersion: cipdVersion
      //   );

      requests.add(
        Request(
          scheduleBuild: _createPresubmitScheduleBuild(
            slug: slug,
            sha: pullRequest.head!.sha!,
            //Use target.value.name here otherwise tests will die due to null checkRun.name.
            checkName: target.value.name,
            pullRequestNumber: pullRequest.number!,
            cipdVersion: cipdVersion,
            userData: userData,
            properties: properties,
            tags: tags,
            dimensions: target.getDimensions(),
          ),
        ),
      );
    }

    final Iterable<List<Request>> requestPartitions = await shard(requests, config.schedulingShardSize);
    for (List<Request> requestPartition in requestPartitions) {
      final BatchRequest batchRequest = BatchRequest(requests: requestPartition);
      await pubsub.publish('scheduler-requests', batchRequest);
    }

    return targets;
  }

  /// Cancels all the current builds on [pullRequest] with [reason].
  ///
  /// Builds are queried based on the [RepositorySlug] and pull request number.
  Future<void> cancelBuilds(github.PullRequest pullRequest, String reason) async {
    log.info(
      'Attempting to cancel builds for pullrequest ${pullRequest.base!.repo!.fullName}/${pullRequest.number}',
    );

    final Iterable<Build> builds = await getTryBuildsByPullRequest(pullRequest);
    log.info('Found ${builds.length} builds.');

    if (builds.isEmpty) {
      log.warning('No builds were found for pull request ${pullRequest.base!.repo!.fullName}.');
      return;
    }

    final List<Request> requests = <Request>[];
    for (Build build in builds) {
      if (build.status == Status.scheduled || build.status == Status.started) {
        // Scheduled status includes scheduled and pending tasks.
        log.info('Cancelling build with build id ${build.id}.');
        requests.add(
          Request(
            cancelBuild: CancelBuildRequest(
              id: build.id,
              summaryMarkdown: reason,
            ),
          ),
        );
      }
    }

    if (requests.isNotEmpty) {
      await buildBucketClient.batch(BatchRequest(requests: requests));
    }
  }

  /// Filters [builders] to only those that failed on [pullRequest].
  Future<List<Build?>> failedBuilds(
    github.PullRequest pullRequest,
    List<Target> targets,
  ) async {
    final Iterable<Build> builds = await getTryBuilds(pullRequest.base!.repo!.slug(), pullRequest.head!.sha!, null);
    final Iterable<String> builderNames = targets.map((Target target) => target.value.name);
    // Return only builds that exist in the configuration file.
    final Iterable<Build?> failedBuilds = builds.where((Build? build) => failStatusSet.contains(build!.status));
    final Iterable<Build?> expectedFailedBuilds =
        failedBuilds.where((Build? build) => builderNames.contains(build!.builderId.builder));
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
  Future<Build> rescheduleBuild({
    required String builderName,
    required push_message.BuildPushMessage buildPushMessage,
    required int rescheduleAttempt,
  }) async {
    // Ensure we are using V2 bucket name istead of V1.
    // V1 bucket name  is "luci.flutter.prod" while the api
    // is expecting just the last part after "."(prod).
    final String bucketName = buildPushMessage.build!.bucket!.split('.').last;
    final Map<String, List<String>> tags = <String, List<String>>{
      'buildset': buildPushMessage.build!.tagsByName('buildset'),
      'user_agent': buildPushMessage.build!.tagsByName('user_agent'),
      'github_link': buildPushMessage.build!.tagsByName('github_link'),
      'cipd_version': buildPushMessage.build!.tagsByName('cipd_version'),
      'github_checkrun': buildPushMessage.build!.tagsByName('github_checkrun'),
      'current_attempt': <String>[rescheduleAttempt.toString()],
    };

    return buildBucketClient.scheduleBuild(
      ScheduleBuildRequest(
        builderId: BuilderId(
          project: buildPushMessage.build!.project,
          bucket: bucketName,
          builder: builderName,
        ),
        tags: tags,
        // We need to cast to <String, Object> to bypass json.encode error when scheduling builds.
        properties:
            (buildPushMessage.build!.buildParameters!['properties'] as Map<String, Object?>).cast<String, Object>(),
        notify: NotificationConfig(
          pubsubTopic: 'projects/flutter-dashboard/topics/luci-builds',
          userData: base64Encode(json.encode(buildPushMessage.userData).codeUnits),
        ),
      ),
    );
  }

  bool _switchV2 = true;

  /// Sends presubmit [ScheduleBuildRequest] for a pull request using [checkRunEvent].
  ///
  /// Returns the [Build] returned by scheduleBuildRequest.
  Future<Build> reschedulePresubmitBuildUsingCheckRunEvent(cocoon_checks.CheckRunEvent checkRunEvent) async {
    final github.RepositorySlug slug = checkRunEvent.repository!.slug();

    final String sha = checkRunEvent.checkRun!.headSha!;
    final String checkName = checkRunEvent.checkRun!.name!;

    final github.CheckRun githubCheckRun = await githubChecksUtil.createCheckRun(config, slug, sha, checkName);

    final Iterable<Build> builds = await getTryBuilds(slug, sha, checkName);
    if (builds.isEmpty) {
      throw NoBuildFoundException('Unable to find try build.');
    }

    final Build build = builds.first;
    final String prString = build.tags!['buildset']!.firstWhere((String? element) => element!.startsWith('pr/git/'))!;
    final String cipdVersion = build.tags!['cipd_version']![0]!;
    final String githubLink = build.tags!['github_link']![0]!;
    final String repoName = githubLink.split('/')[4];
    final String branch = Config.defaultBranch(github.RepositorySlug('flutter', repoName));
    final int prNumber = int.parse(prString.split('/')[2]);

    final Map<String, dynamic> userData = <String, dynamic>{
      'check_run_id': githubCheckRun.id,
      'commit_branch': branch,
      'commit_sha': sha,
    };
    final Map<String, Object> properties = Map.of(build.input!.properties ?? <String, Object>{});
    final GithubService githubService = await config.createGithubService(slug);

    final List<github.IssueLabel> issueLabels = await githubService.getIssueLabels(slug, prNumber);
    final List<String>? labels = extractPrefixedLabels(issueLabels, githubBuildLabelPrefix);

    if (labels != null && labels.isNotEmpty) {
      properties[propertiesGithubBuildLabelName] = labels;
    }
    log.info('input ${build.input!} properties $properties');

    //TODO craft a v2 request here. It is hacky but better than attempting to pipe into something else.
    if (_switchV2) {
      final bbv2.ScheduleBuildRequest scheduleBuildRequestv2 = _createPresubmitScheduleBuildV2(
        slug: slug, sha: sha, checkName: checkName, pullRequestNumber: prNumber, cipdVersion: cipdVersion,);
      // ignore: unused_local_variable
      final bbv2.Build scheduleBuildV2 = await buildBucketV2Client.scheduleBuild(scheduleBuildRequestv2);
      _switchV2 = false;  
    }

    final ScheduleBuildRequest scheduleBuildRequest = _createPresubmitScheduleBuild(
      slug: slug,
      sha: sha,
      checkName: checkName,
      pullRequestNumber: prNumber,
      cipdVersion: cipdVersion,
      properties: properties,
      userData: userData,
    );

    final Build scheduleBuild = await buildBucketClient.scheduleBuild(scheduleBuildRequest);
    final String buildUrl = 'https://ci.chromium.org/ui/b/${scheduleBuild.id}';
    await githubChecksUtil.updateCheckRun(config, slug, githubCheckRun, detailsUrl: buildUrl);
    return scheduleBuild;
  }

  /// Collect any label whose name is prefixed by the prefix [String].
  ///
  /// Returns a [List] of prefixed label names as [String]s.
  List<String>? extractPrefixedLabels(List<github.IssueLabel>? issueLabels, String prefix) {
    return issueLabels?.where((label) => label.name.startsWith(prefix)).map((obj) => obj.name).toList();
  }

  /// Sends postsubmit [ScheduleBuildRequest] for a commit using [checkRunEvent], [Commit], [Task], and [Target].
  ///
  /// Returns the [Build] returned by scheduleBuildRequest.
  Future<Build> reschedulePostsubmitBuildUsingCheckRunEvent(
    cocoon_checks.CheckRunEvent checkRunEvent, {
    required Commit commit,
    required Task task,
    required Target target,
  }) async {
    final github.RepositorySlug slug = checkRunEvent.repository!.slug();
    final String sha = checkRunEvent.checkRun!.headSha!;
    final String checkName = checkRunEvent.checkRun!.name!;

    final Iterable<Build> builds = await getProdBuilds(slug, sha, checkName);
    if (builds.isEmpty) {
      throw NoBuildFoundException('Unable to find prod build.');
    }

    final Build build = builds.first;
    final Map<String, Object>? properties = build.input!.properties;
    log.info('input ${build.input!} properties $properties');

    final ScheduleBuildRequest scheduleBuildRequest =
        await _createPostsubmitScheduleBuild(commit: commit, target: target, task: task, properties: properties);
    final Build scheduleBuild = await buildBucketClient.scheduleBuild(scheduleBuildRequest);
    return scheduleBuild;
  }

  /// Gets [Build] using its [id] and passing the additional
  /// fields to be populated in the response.
  Future<Build> getBuildById(String? id, {String? fields}) async {
    final GetBuildRequest request = GetBuildRequest(id: id, fields: fields);
    return buildBucketClient.getBuild(request);
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
    log.info('No cached value for builderList, start fetching via the rpc call.');
    final Set<String> availableBuilderSet = <String>{};
    String? token;
    do {
      final ListBuildersResponse listBuildersResponse = await buildBucketClient.listBuilders(
        ListBuildersRequest(
          project: project,
          bucket: bucket,
          pageToken: token,
        ),
      );
      final List<String> availableBuilderList = listBuildersResponse.builders!.map((e) => e.id!.builder!).toList();
      availableBuilderSet.addAll(<String>{...availableBuilderList});
      token = listBuildersResponse.nextPageToken;
    } while (token != null);
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
    final List<Request> buildRequests = <Request>[];
    Set<String> availableBuilderSet;
    try {
      availableBuilderSet = await getAvailableBuilderSet(project: 'flutter', bucket: 'prod');
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
      final ScheduleBuildRequest scheduleBuildRequest = await _createPostsubmitScheduleBuild(
        commit: commit,
        target: tuple.first,
        task: tuple.second,
        priority: tuple.third,
      );
      buildRequests.add(Request(scheduleBuild: scheduleBuildRequest));
      log.info('created postsubmit schedule request for target: ${tuple.first.value} in commit ${commit.sha}');
    }
    final BatchRequest batchRequest = BatchRequest(requests: buildRequests);
    log.fine(batchRequest);
    List<String> messageIds;
    try {
      messageIds = await pubsub.publish('scheduler-requests', batchRequest);
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
  ScheduleBuildRequest _createPresubmitScheduleBuild({
    required github.RepositorySlug slug,
    required String sha,
    required String checkName,
    required int pullRequestNumber,
    required String cipdVersion,
    Map<String, Object>? properties,
    Map<String, List<String>>? tags,
    Map<String, dynamic>? userData,
    List<RequestedDimension>? dimensions,
  }) {
    final Map<String, Object> processedProperties = <String, Object>{};
    processedProperties.addAll(properties ?? <String, Object>{});
    processedProperties.addEntries(
      <String, Object>{
        'git_url': 'https://github.com/${slug.owner}/${slug.name}',
        'git_ref': 'refs/pull/$pullRequestNumber/head',
        'exe_cipd_version': cipdVersion,
      }.entries,
    );

    final Map<String, dynamic> processedUserData = userData ?? <String, dynamic>{};
    processedUserData['repo_owner'] = slug.owner;
    processedUserData['repo_name'] = slug.name;
    processedUserData['user_agent'] = 'flutter-cocoon';

    final BuilderId builderId = BuilderId(project: 'flutter', bucket: 'try', builder: checkName);

    final Map<String, List<String>> processedTags = tags ?? <String, List<String>>{};
    processedTags['buildset'] = <String>['pr/git/$pullRequestNumber', 'sha/git/$sha'];
    processedTags['user_agent'] = const <String>['flutter-cocoon'];
    processedTags['github_link'] = <String>['https://github.com/${slug.owner}/${slug.name}/pull/$pullRequestNumber'];
    processedTags['cipd_version'] = <String>[cipdVersion];

    final NotificationConfig notificationConfig = NotificationConfig(
      pubsubTopic: 'projects/flutter-dashboard/topics/luci-builds',
      userData: base64Encode(json.encode(processedUserData).codeUnits),
    );

    final Map<String, dynamic> exec = <String, dynamic>{'cipdVersion': cipdVersion};

    return ScheduleBuildRequest(
      builderId: builderId,
      tags: processedTags,
      properties: processedProperties,
      notify: notificationConfig,
      fields: 'id,builder,number,status,tags',
      exe: exec,
      dimensions: dimensions,
    );
  }

  // build the same objects using the v2 and publish along side the v1 objects.
  bbv2.ScheduleBuildRequest _createPresubmitScheduleBuildV2({
    required github.RepositorySlug slug,
    required String sha,
    required String checkName,
    required int pullRequestNumber,
    required String cipdVersion,
    Map<String, bbv2.Value>? properties,
    List<bbv2.StringPair>? tags,
    Map<String, dynamic>? userData,
    List<bbv2.RequestedDimension>? dimensions,}) {

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

    final List<String> fields = ['id','builder','number','status','tags'];
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
    notificationConfig.pubsubTopic = 'projects/flutter-dashboard/topics/bbv2-test-topic';
    notificationConfig.userData = json.encode(processedUserData).codeUnits;
    scheduleBuildRequest.notify = notificationConfig;

    // Add tags to the instance.
    final List<bbv2.StringPair> processTags = tags ?? <bbv2.StringPair>[];
    processTags.add(_createStringPair('buildset', 'pr/git/$pullRequestNumber'));
    processTags.add(_createStringPair('buildset', 'sha/git/$sha'));
    processTags.add(_createStringPair('user_agent', 'flutter-cocoon'));
    processTags.add(_createStringPair('github_link', 'https://github.com/${slug.owner}/${slug.name}/pull/$pullRequestNumber'));
    processTags.add(_createStringPair('cipd_version', cipdVersion));
    final List<bbv2.StringPair> instanceTags = scheduleBuildRequest.tags;
    instanceTags.addAll(processTags);
    
    // Add the properties to the instance. 
    final Map<String, bbv2.Value> processedProperties = <String, bbv2.Value>{};
    processedProperties.addAll(properties ?? <String, bbv2.Value>{});
    processedProperties.addEntries(
      <String, bbv2.Value>{
        'git_url': bbv2.Value(stringValue: 'https://github.com/${slug.owner}/${slug.name}'),
        'git_ref': bbv2.Value(stringValue: 'refs/pull/$pullRequestNumber/head'),
        'exe_cipd_version': bbv2.Value(stringValue: cipdVersion),
      }.entries,
    );
    scheduleBuildRequest.properties = bbv2.Struct(fields: processedProperties);
    
    return scheduleBuildRequest;
  }

  bbv2.StringPair _createStringPair(String key, String value) {
    final bbv2.StringPair stringPair = bbv2.StringPair.create();
    stringPair.key = key;
    stringPair.value = value;
    return stringPair;
  }

  List<bbv2.StringPair> _createStringPairList(String key, List<String> values) {
    final List<bbv2.StringPair> stringPairs = <bbv2.StringPair>[];
    for (String v in values) {
      final bbv2.StringPair stringPair = bbv2.StringPair.create();
      stringPair.key = key;
      stringPair.value = v;
      stringPairs.add(stringPair);
    }

    return stringPairs;
  }

  /// Creates a [ScheduleBuildRequest] for [target] and [task] against [commit].
  ///
  /// By default, build [priority] is increased for release branches.
  Future<ScheduleBuildRequest> _createPostsubmitScheduleBuild({
    required Commit commit,
    required Target target,
    required Task task,
    Map<String, Object>? properties,
    Map<String, List<String>>? tags,
    int priority = kDefaultPriority,
  }) async {
    tags ??= <String, List<String>>{};
    tags.addAll(<String, List<String>>{
      'buildset': <String>[
        'commit/git/${commit.sha}',
        'commit/gitiles/flutter.googlesource.com/mirrors/${commit.slug.name}/+/${commit.sha}',
      ],
    });

    final String commitKey = task.parentKey!.id.toString();
    final String taskKey = task.key.id.toString();
    log.info('Scheduling builder: ${target.value.name} for commit ${commit.sha}');
    log.info('Task commit_key: $commitKey for task name: ${task.name}');
    log.info('Task task_key: $taskKey for task name: ${task.name}');

    final Map<String, dynamic> rawUserData = <String, dynamic>{
      'commit_key': commitKey,
      'task_key': taskKey,
    };

    // Creates post submit checkrun only for unflaky targets from [config.postsubmitSupportedRepos].
    if (!target.value.bringup && config.postsubmitSupportedRepos.contains(target.slug)) {
      await createPostsubmitCheckRun(commit, target, rawUserData);
    }

    tags['user_agent'] = <String>['flutter-cocoon'];
    // Tag `scheduler_job_id` is needed when calling buildbucket search build API.
    tags['scheduler_job_id'] = <String>['flutter/${target.value.name}'];
    // Default attempt is the initial attempt, which is 1.
    tags['current_attempt'] = tags['current_attempt'] ?? <String>['1'];
    final Map<String, Object> processedProperties = target.getProperties();
    processedProperties.addAll(properties ?? <String, Object>{});
    processedProperties['git_branch'] = commit.branch!;
    final String cipdVersion = 'refs/heads/${commit.branch}';
    processedProperties['exe_cipd_version'] = cipdVersion;
    return ScheduleBuildRequest(
      builderId: BuilderId(
        project: 'flutter',
        bucket: target.getBucket(),
        builder: target.value.name,
      ),
      dimensions: target.getDimensions(),
      exe: <String, dynamic>{
        'cipdVersion': cipdVersion,
      },
      gitilesCommit: GitilesCommit(
        project: 'mirrors/${commit.slug.name}',
        host: 'flutter.googlesource.com',
        ref: 'refs/heads/${commit.branch}',
        hash: commit.sha,
      ),
      notify: NotificationConfig(
        pubsubTopic: 'projects/flutter-dashboard/topics/luci-builds-prod',
        userData: base64Encode(json.encode(rawUserData).codeUnits),
      ),
      tags: tags,
      properties: processedProperties,
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
    FirestoreService? firestoreService,
    Map<String, List<String>>? tags,
    bool ignoreChecks = false,
    f.Task? taskDocument,
  }) async {
    if (ignoreChecks == false && await _shouldRerunBuilder(task, commit, datastore) == false) {
      return false;
    }
    log.info('Rerun builder: ${target.value.name} for commit ${commit.sha}');
    tags ??= <String, List<String>>{};
    tags['trigger_type'] ??= <String>['auto_retry'];

    // TODO(keyonghan): remove check when [ResetProdTask] supports firestore update.
    if (taskDocument != null) {
      try {
        final int newAttempt = int.parse(taskDocument.name!.split('_').last) + 1;
        tags['current_attempt'] = <String>[newAttempt.toString()];
        taskDocument.resetAsRetry(attempt: newAttempt);
        final List<Write> writes = documentsToWrites([taskDocument]);
        await firestoreService!.batchWriteDocuments(BatchWriteRequest(writes: writes), kDatabase);
      } catch (error) {
        log.warning('Failed to insert retried task in Firestore: $error');
      }
    }

    final BatchRequest request = BatchRequest(
      requests: <Request>[
        Request(
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
    await pubsub.publish('scheduler-requests', request);

    task.attempts = (task.attempts ?? 0) + 1;
    // Mark task as in progress to ensure it isn't scheduled over
    task.status = Task.statusInProgress;
    await datastore.insert(<Task>[task]);

    return true;
  }

  /// Check if a builder should be rerun.
  ///
  /// A rerun happens when a build fails, the retry number hasn't reached the limit, and the build is on TOT.
  Future<bool> _shouldRerunBuilder(Task task, Commit commit, DatastoreService? datastore) async {
    if (!taskFailStatusSet.contains(task.status)) {
      return false;
    }
    final int retries = task.attempts ?? 1;
    if (retries > config.maxLuciTaskRetries) {
      log.warning('Max retries reached');
      return false;
    }

    final Commit latestCommit = await datastore!
        .queryRecentCommits(
          limit: 1,
          slug: commit.slug,
          branch: commit.branch,
        )
        .single;
    return latestCommit.sha == commit.sha;
  }
}
