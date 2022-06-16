// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:github/github.dart' as github;
import 'package:github/hooks.dart';

import '../foundation/github_checks_util.dart';
import '../foundation/utils.dart';
import '../model/appengine/commit.dart';
import '../model/appengine/task.dart';
import '../model/ci_yaml/target.dart';
import '../model/github/checks.dart' as cocoon_checks;
import '../model/luci/buildbucket.dart';
import '../model/luci/push_message.dart' as push_message;
import '../request_handling/exceptions.dart';
import '../request_handling/pubsub.dart';
import '../service/datastore.dart';
import '../service/logging.dart';
import 'buildbucket.dart';
import 'config.dart';
import 'gerrit_service.dart';

const Set<String> taskFailStatusSet = <String>{Task.statusInfraFailure, Task.statusFailed};

/// Class to interact with LUCI buildbucket to get, trigger
/// and cancel builds for github repos. It uses [config.luciTryBuilders] to
/// get the list of available builders.
class LuciBuildService {
  LuciBuildService(
    this.config,
    this.buildBucketClient, {
    GithubChecksUtil? githubChecksUtil,
    GerritService? gerritService,
    this.pubsub = const PubSub(),
  })  : githubChecksUtil = githubChecksUtil ?? const GithubChecksUtil(),
        gerritService = gerritService ?? GerritService();

  BuildBucketClient buildBucketClient;
  Config config;
  GithubChecksUtil githubChecksUtil;
  GerritService gerritService;

  final PubSub pubsub;

  static const Set<Status> failStatusSet = <Status>{Status.canceled, Status.failure, Status.infraFailure};

  static const int kBackfillPriority = 35;
  static const int kDefaultPriority = 30;
  static const int kRerunPriority = 29;

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
    final BatchResponse batch = await buildBucketClient.batch(BatchRequest(requests: <Request>[
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
    ]));
    final Iterable<Build> builds = batch.responses!
        .map((Response response) => response.searchBuilds)
        .expand((SearchBuildsResponse? response) => response!.builds ?? <Build>[]);
    return builds;
  }

  /// Returns a map of the BuildBucket builds for a given Github [PullRequest]
  /// using the [builderName] as key and [Build] as value.
  Future<Map<String?, Build?>> tryBuildsForPullRequest(
    github.PullRequest pullRequest,
  ) async {
    final BatchResponse batch = await buildBucketClient.batch(BatchRequest(requests: <Request>[
      // Builds created by Cocoon
      Request(
        searchBuilds: SearchBuildsRequest(
          predicate: BuildPredicate(
            builderId: const BuilderId(
              project: 'flutter',
              bucket: 'try',
            ),
            createdBy: 'cocoon',
            tags: <String, List<String>>{
              'buildset': <String>['pr/git/${pullRequest.number}'],
              'github_link': <String>[
                'https://github.com/${pullRequest.base!.repo!.fullName}/pull/${pullRequest.number}'
              ],
              'user_agent': const <String>['flutter-cocoon'],
            },
          ),
        ),
      ),
      // Builds created by recipe (via swarming create task)
      Request(
        searchBuilds: SearchBuildsRequest(
          predicate: BuildPredicate(
            builderId: const BuilderId(
              project: 'flutter',
              bucket: 'try',
            ),
            tags: <String, List<String>>{
              'buildset': <String>['pr/git/${pullRequest.number}'],
              'user_agent': const <String>['recipe'],
            },
          ),
        ),
      ),
    ]));
    final Iterable<Build> builds = batch.responses!
        .map((Response response) => response.searchBuilds)
        .expand((SearchBuildsResponse? response) => response?.builds ?? <Build>[]);
    return {for (Build b in builds) b.builderId.builder: b};
  }

  /// Creates BuildBucket [Request] using [checkSuiteEvent], [pullRequest], [builder], [builderId], and [userData].
  Future<Request> _createBuildRequest({
    CheckSuiteEvent? checkSuiteEvent,
    required github.PullRequest pullRequest,
    String? builder,
    required BuilderId builderId,
    required Map<String, dynamic> userData,
    Map<String, dynamic>? properties,
    List<RequestedDimension>? dimensions,
    List<String>? branches,
  }) async {
    int? checkRunId;
    if (checkSuiteEvent != null || config.githubPresubmitSupportedRepo(pullRequest.base!.repo!.slug())) {
      final github.CheckRun checkRun = await githubChecksUtil.createCheckRun(
        config,
        pullRequest.base!.repo!.slug(),
        pullRequest.head!.sha!,
        builder!,
      );
      userData['check_run_id'] = checkRun.id;
      checkRunId = checkRun.id;
      userData['commit_sha'] = pullRequest.head!.sha!;
      userData['commit_branch'] = pullRequest.base!.ref!.replaceAll('refs/heads/', '');
      userData['builder_name'] = builder;
    }
    String cipdVersion = 'refs/heads/${pullRequest.base!.ref!}';
    log.info('Branches from recipes repo: $branches, expected ref $cipdVersion');
    cipdVersion = branches != null && branches.contains(cipdVersion) ? cipdVersion : config.defaultRecipeBundleRef;
    properties ??= <String, dynamic>{};
    properties.addAll(<String, String>{
      'git_branch': pullRequest.base!.ref!.replaceAll('refs/heads/', ''),
      'git_url': 'https://github.com/${pullRequest.base!.repo!.fullName}',
      'git_ref': 'refs/pull/${pullRequest.number}/head',
      'exe_cipd_version': cipdVersion,
    });
    return Request(
      scheduleBuild: ScheduleBuildRequest(
        builderId: builderId,
        tags: <String, List<String>>{
          'buildset': <String>['pr/git/${pullRequest.number}', 'sha/git/${pullRequest.head!.sha}'],
          'user_agent': const <String>['flutter-cocoon'],
          'github_link': <String>['https://github.com/${pullRequest.base!.repo!.fullName}/pull/${pullRequest.number}'],
          'github_checkrun': <String>[checkRunId.toString()],
          'cipd_version': <String>[cipdVersion],
        },
        properties: properties,
        dimensions: dimensions,
        notify: NotificationConfig(
          pubsubTopic: 'projects/flutter-dashboard/topics/luci-builds',
          userData: base64Encode(json.encode(userData).codeUnits),
        ),
        fields: 'id,builder,number,status,tags',
        exe: <String, dynamic>{
          'cipdVersion': cipdVersion,
        },
      ),
    );
  }

  /// Schedules presubmit [targets] on BuildBucket for [pullRequest].
  Future<List<Target>> scheduleTryBuilds({
    required List<Target> targets,
    required github.PullRequest pullRequest,
    CheckSuiteEvent? checkSuiteEvent,
  }) async {
    if (!config.githubPresubmitSupportedRepo(pullRequest.base!.repo!.slug())) {
      throw BadRequestException('${pullRequest.base!.repo!.slug()} is not supported by this service.');
    }
    targets = await _targetsToSchedule(targets, pullRequest);
    await _scheduleTryBuilds(
      targets: targets,
      pullRequest: pullRequest,
      checkSuiteEvent: checkSuiteEvent,
    );

    return targets;
  }

  /// List of targets that should be scheduled.
  ///
  /// If a [Target] has a [Build] that is already scheduled or was successful, it shouldn't be scheduled again.
  ///
  /// Throws [InternalServerError] is [targets] is empty.
  Future<List<Target>> _targetsToSchedule(List<Target> targets, github.PullRequest pullRequest) async {
    if (targets.isEmpty) {
      throw InternalServerError('${pullRequest.base!.repo!.slug()} does not have any targets');
    }

    final Map<String?, Build?> tryBuilds = await tryBuildsForPullRequest(pullRequest);
    final Iterable<Build?> runningOrCompletedBuilds = tryBuilds.values.where((Build? build) =>
        build?.status == Status.scheduled || build?.status == Status.started || build?.status == Status.success);
    final List<Target> targetsToSchedule = <Target>[];
    for (Target target in targets) {
      if (runningOrCompletedBuilds.any((Build? build) => build?.builderId.builder == target.value.name)) {
        log.info('${target.value.name} has already been scheduled for this pull request');
        continue;
      }
      targetsToSchedule.add(target);
    }

    return targetsToSchedule;
  }

  /// Schedules [targets] against [pullRequest].
  Future<void> _scheduleTryBuilds({
    required List<Target> targets,
    required github.PullRequest pullRequest,
    CheckSuiteEvent? checkSuiteEvent,
  }) async {
    final List<Request> requests = <Request>[];
    final List<String> branches =
        await gerritService.branches('flutter-review.googlesource.com', 'recipes', 'flutter-');
    for (Target target in targets) {
      final BuilderId builderId = BuilderId(
        project: 'flutter',
        bucket: 'try',
        builder: target.value.name,
      );
      final Map<String, dynamic> userData = <String, dynamic>{
        'repo_owner': pullRequest.base!.repo!.owner!.login,
        'repo_name': pullRequest.base!.repo!.name,
        'user_agent': 'flutter-cocoon',
      };
      requests.add(await _createBuildRequest(
        checkSuiteEvent: checkSuiteEvent,
        pullRequest: pullRequest,
        builder: target.value.name,
        builderId: builderId,
        userData: userData,
        properties: target.getProperties(),
        dimensions: target.getDimensions(),
        branches: branches,
      ));
    }
    final Iterable<List<Request>> requestPartitions = await shard(requests, config.schedulingShardSize);
    for (List<Request> requestPartition in requestPartitions) {
      final BatchRequest batchRequest = BatchRequest(requests: requestPartition);
      await pubsub.publish('scheduler-requests', batchRequest);
    }
  }

  /// Cancels all the current builds on [pullRequest] with [reason].
  ///
  /// Builds are queried based on the [RepositorySlug] and pull request number.
  Future<void> cancelBuilds(github.PullRequest pullRequest, String reason) async {
    if (!config.githubPresubmitSupportedRepo(pullRequest.base!.repo!.slug())) {
      throw BadRequestException('This service does not support ${pullRequest.base!.repo}');
    }
    final Map<String?, Build?> builds = await tryBuildsForPullRequest(pullRequest);
    if (!builds.values.any((Build? build) {
      return build!.status == Status.scheduled || build.status == Status.started;
    })) {
      return;
    }
    final List<Request> requests = <Request>[];
    for (Build? build in builds.values) {
      requests.add(
        Request(
          cancelBuild: CancelBuildRequest(id: build!.id, summaryMarkdown: reason),
        ),
      );
    }
    await buildBucketClient.batch(BatchRequest(requests: requests));
  }

  /// Filters [builders] to only those that failed on [pullRequest].
  Future<List<Build?>> failedBuilds(
    github.PullRequest pullRequest,
    List<Target> targets,
  ) async {
    final Map<String?, Build?> builds = await tryBuildsForPullRequest(pullRequest);
    final Iterable<String> builderNames = targets.map((Target target) => target.value.name);
    // Return only builds that exist in the configuration file.
    final Iterable<Build?> failedBuilds = builds.values.where((Build? build) => failStatusSet.contains(build!.status));
    final Iterable<Build?> expectedFailedBuilds =
        failedBuilds.where((Build? build) => builderNames.contains(build!.builderId.builder));
    return expectedFailedBuilds.toList();
  }

  /// Sends [ScheduleBuildRequest] the buildset, user_agent, and
  /// github_link tags are applied to match the original build. The build
  /// properties from the original build are also preserved.
  Future<bool> rescheduleBuild({
    required String commitSha,
    required String builderName,
    required push_message.BuildPushMessage buildPushMessage,
  }) async {
    // Ensure we are using V2 bucket name istead of V1.
    // V1 bucket name  is "luci.flutter.prod" while the api
    // is expecting just the last part after "."(prod).
    final String bucketName = buildPushMessage.build!.bucket!.split('.').last;
    final Map<String, dynamic>? userData = jsonDecode(buildPushMessage.userData!) as Map<String, dynamic>?;
    await buildBucketClient.scheduleBuild(ScheduleBuildRequest(
      builderId: BuilderId(
        project: buildPushMessage.build!.project,
        bucket: bucketName,
        builder: builderName,
      ),
      tags: <String, List<String>>{
        'buildset': buildPushMessage.build!.tagsByName('buildset'),
        'user_agent': buildPushMessage.build!.tagsByName('user_agent'),
        'github_link': buildPushMessage.build!.tagsByName('github_link'),
      },
      properties:
          (buildPushMessage.build!.buildParameters!['properties'] as Map<String, dynamic>).cast<String, String>(),
      notify: NotificationConfig(
        pubsubTopic: 'projects/flutter-dashboard/topics/luci-builds',
        userData: json.encode(userData),
      ),
    ));
    return true;
  }

  /// Sends [ScheduleBuildRequest] for [pullRequest] using [checkRunEvent].
  ///
  /// Returns true if it is able to send the scheduleBuildRequest. Otherwise, false.
  Future<bool> rescheduleUsingCheckRunEvent(cocoon_checks.CheckRunEvent checkRunEvent) async {
    final github.RepositorySlug slug = checkRunEvent.repository!.slug();
    final Map<String, dynamic> userData = <String, dynamic>{};
    final String sha = checkRunEvent.checkRun!.headSha!;
    final String checkName = checkRunEvent.checkRun!.name!;
    final github.CheckRun githubCheckRun = await githubChecksUtil.createCheckRun(
      config,
      slug,
      sha,
      checkName,
    );
    final Iterable<Build> builds = await getTryBuilds(slug, sha, checkName);

    final Build build = builds.first;
    final String prString = build.tags!['buildset']!.firstWhere((String? element) => element!.startsWith('pr/git/'))!;
    final String cipdVersion = build.tags!['cipd_version']![0]!;
    final int prNumber = int.parse(prString.split('/')[2]);
    log.info('input ${build.input!} properties ${build.input!.properties!}');
    Map<String, dynamic> properties = <String, dynamic>{};
    properties.addAll(build.input!.properties!);
    properties.addEntries(
      <String, dynamic>{
        'git_url': 'https://github.com/${slug.owner}/${slug.name}',
        'git_ref': 'refs/pull/$prNumber/head',
        'exe_cipd_version': cipdVersion,
      }.entries,
    );
    userData['check_run_id'] = githubCheckRun.id;
    userData['repo_owner'] = slug.owner;
    userData['repo_name'] = slug.name;
    userData['user_agent'] = 'flutter-cocoon';
    final Build scheduleBuild = await buildBucketClient.scheduleBuild(ScheduleBuildRequest(
      builderId: BuilderId(
        project: 'flutter',
        bucket: 'try',
        builder: checkRunEvent.checkRun!.name,
      ),
      tags: <String, List<String>>{
        'buildset': <String>['pr/git/$prNumber', 'sha/git/$sha'],
        'user_agent': const <String>['flutter-cocoon'],
        'github_link': <String>['https://github.com/${slug.owner}/${slug.name}/pull/$prNumber'],
      },
      properties: properties,
      notify: NotificationConfig(
        pubsubTopic: 'projects/flutter-dashboard/topics/luci-builds',
        userData: base64Encode(json.encode(userData).codeUnits),
      ),
      exe: <String, dynamic>{
        'cipdVersion': cipdVersion,
      },
    ));
    final String buildUrl = 'https://ci.chromium.org/ui/b/${scheduleBuild.id}';
    await githubChecksUtil.updateCheckRun(config, slug, githubCheckRun, detailsUrl: buildUrl);
    return true;
  }

  /// Gets [Build] using its [id] and passing the additional
  /// fields to be populated in the response.
  Future<Build> getTryBuildById(String? id, {String? fields}) async {
    final GetBuildRequest request = GetBuildRequest(id: id, fields: fields);
    return buildBucketClient.getBuild(request);
  }

  /// Get builder list whose config is pre-defined in LUCI.
  Future<Set<String>> getAvailableBuilderSet({
    String project = 'flutter',
    String bucket = 'prod',
  }) async {
    Set<String> availableBuilderSet = <String>{};
    String? token;
    do {
      final ListBuildersResponse listBuildersResponse = await buildBucketClient
          .listBuilders(ListBuildersRequest(project: 'flutter', bucket: 'prod', pageToken: token));
      final List<String> availableBuilderList = listBuildersResponse.builders!.map((e) => e.id!.builder!).toList();
      availableBuilderSet.addAll(<String>{...availableBuilderList});
      token = listBuildersResponse.nextPageToken;
    } while (token != null);
    return availableBuilderSet;
  }

  /// Schedules list of post-submit builds deferring work to [schedulePostsubmitBuild].
  Future<void> schedulePostsubmitBuilds({
    required Commit commit,
    required List<Tuple<Target, Task, int>> toBeScheduled,
  }) async {
    if (toBeScheduled.isEmpty) {
      log.fine('Skipping schedulePostsubmitBuilds as there are no targets to be scheduled by Cocoon');
      return;
    }
    final List<Request> buildRequests = <Request>[];
    final Set<String> availableBuilderSet = await getAvailableBuilderSet(project: 'flutter', bucket: 'prod');
    log.info('Available builder list: $availableBuilderSet');
    for (Tuple<Target, Task, int> tuple in toBeScheduled) {
      // Non-existing builder target will be skipped from scheduling.
      if (!availableBuilderSet.contains(tuple.first.value.name)) {
        continue;
      }
      final ScheduleBuildRequest scheduleBuildRequest = _createPostsubmitScheduleBuild(
        commit: commit,
        target: tuple.first,
        task: tuple.second,
        priority: tuple.third,
      );
      buildRequests.add(Request(scheduleBuild: scheduleBuildRequest));
    }
    final BatchRequest batchRequest = BatchRequest(requests: buildRequests);
    log.fine(batchRequest);
    await pubsub.publish('scheduler-requests', batchRequest);
    log.info('Published a request with ${buildRequests.length} builds');
  }

  /// Creates a [ScheduleBuildRequest] for [target] and [task] against [commit].
  ///
  /// By default, build [priority] is increased for release branches.
  ScheduleBuildRequest _createPostsubmitScheduleBuild({
    required Commit commit,
    required Target target,
    required Task task,
    Map<String, Object>? properties,
    Map<String, List<String>>? tags,
    int priority = kDefaultPriority,
  }) {
    tags ??= <String, List<String>>{};
    tags.addAll(<String, List<String>>{
      'buildset': <String>[
        'commit/git/${commit.sha}',
        'commit/gitiles/flutter.googlesource.com/mirrors/${commit.slug.name}/+/${commit.sha}',
      ],
    });

    final String commitKey = task.parentKey!.id.toString();
    final String taskKey = task.key.id.toString();
    log.info('Scheduling builder: ${target.value.name}');
    log.info('Task commit_key: $commitKey for task name: ${task.name}');
    log.info('Task task_key: $taskKey for task name: ${task.name}');

    final Map<String, String> rawUserData = <String, String>{
      'commit_key': commitKey,
      'task_key': taskKey,
    };
    tags['user_agent'] = <String>['flutter-cocoon'];
    // Tag `scheduler_job_id` is needed when calling buildbucket search build API.
    tags['scheduler_job_id'] = <String>['flutter/${target.value.name}'];
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
    );
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
    Map<String, List<String>>? tags,
    bool ignoreChecks = false,
  }) async {
    if (ignoreChecks == false && await _shouldRerunBuilder(task, commit, datastore) == false) {
      return false;
    }
    log.info('Rerun builder: ${target.value.name} for commit ${commit.sha}');
    tags ??= <String, List<String>>{};
    tags['trigger_type'] = <String>['retry'];

    final BatchRequest request = BatchRequest(
      requests: <Request>[
        Request(
          scheduleBuild: _createPostsubmitScheduleBuild(
            commit: commit,
            target: target,
            task: task,
            priority: kRerunPriority,
            properties: commit.slug == Config.engineSlug ? Config.engineDefaultProperties : null,
            tags: tags,
          ),
        ),
      ],
    );
    await pubsub.publish('scheduler-requests', request);

    task.attempts = (task.attempts ?? 0) + 1;
    task.status = Task.statusNew;
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
        )
        .single;
    return latestCommit.sha == commit.sha;
  }
}
