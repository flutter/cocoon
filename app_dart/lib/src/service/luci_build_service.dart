// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:math';

import 'package:github/github.dart' as github;
import 'package:github/hooks.dart';

import '../foundation/github_checks_util.dart';
import '../model/appengine/commit.dart';
import '../model/appengine/task.dart';
import '../model/ci_yaml/target.dart';
import '../model/github/checks.dart' as cocoon_checks;
import '../model/luci/buildbucket.dart';
import '../model/luci/push_message.dart' as push_message;
import '../request_handling/exceptions.dart';
import '../service/config.dart';
import '../service/datastore.dart';
import '../service/logging.dart';
import 'buildbucket.dart';
import 'luci.dart';

const Set<String> taskFailStatusSet = <String>{Task.statusInfraFailure, Task.statusFailed};

/// Class to interact with LUCI buildbucket to get, trigger
/// and cancel builds for github repos. It uses [config.luciTryBuilders] to
/// get the list of available builders.
class LuciBuildService {
  LuciBuildService(
    this.config,
    this.buildBucketClient, {
    GithubChecksUtil? githubChecksUtil,
  }) : githubChecksUtil = githubChecksUtil ?? const GithubChecksUtil();

  BuildBucketClient buildBucketClient;
  Config config;
  GithubChecksUtil githubChecksUtil;

  static const Set<Status> failStatusSet = <Status>{Status.canceled, Status.failure, Status.infraFailure};

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
    github.RepositorySlug? slug,
    String commitSha,
    String? builderName,
    String repo,
  ) async {
    final Map<String, List<String>> tags = <String, List<String>>{
      'buildset': <String>['commit/gitiles/chromium.googlesource.com/external/github.com/flutter/$repo/+/$commitSha'],
    };
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
          fields: 'builds.*.id,builds.*.builder,builds.*.tags,builds.*.status',
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
    return Map<String?, Build?>.fromIterable(builds,
        key: (dynamic b) => b.builderId.builder as String?, value: (dynamic b) => b as Build?);
  }

  /// Creates BuildBucket [Request] using [checkSuiteEvent], [pullRequest], [builder], [builderId], and [userData].
  Future<Request> _createBuildRequest({
    CheckSuiteEvent? checkSuiteEvent,
    required github.PullRequest pullRequest,
    String? builder,
    required BuilderId builderId,
    required Map<String, dynamic> userData,
    Map<String, dynamic>? properties,
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
    }
    properties ??= <String, dynamic>{};
    properties.addAll(<String, String>{
      'git_url': 'https://github.com/${pullRequest.base!.repo!.fullName}',
      'git_ref': 'refs/pull/${pullRequest.number}/head',
    });
    return Request(
      scheduleBuild: ScheduleBuildRequest(
        builderId: builderId,
        tags: <String, List<String>>{
          'buildset': <String>['pr/git/${pullRequest.number}', 'sha/git/${pullRequest.head!.sha}'],
          'user_agent': const <String>['flutter-cocoon'],
          'github_link': <String>['https://github.com/${pullRequest.base!.repo!.fullName}/pull/${pullRequest.number}'],
          'github_checkrun': <String>[checkRunId.toString()],
        },
        properties: properties,
        notify: NotificationConfig(
          pubsubTopic: 'projects/flutter-dashboard/topics/luci-builds',
          userData: base64Encode(json.encode(userData).codeUnits),
        ),
        fields: 'id,builder,number,status,tags',
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
    int retryCount = 1;
    List<Target> remainingTargetsToSchedule = List<Target>.from(targets);
    while (remainingTargetsToSchedule.isNotEmpty) {
      remainingTargetsToSchedule = await _scheduleTryBuilds(
        targets: remainingTargetsToSchedule,
        pullRequest: pullRequest,
        checkSuiteEvent: checkSuiteEvent,
      );
      retryCount += 1;
      if (retryCount >= config.schedulerRetries) {
        break;
      }
    }

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
  Future<List<Target>> _scheduleTryBuilds({
    required List<Target> targets,
    required github.PullRequest pullRequest,
    CheckSuiteEvent? checkSuiteEvent,
  }) async {
    final List<Future<Request>> requestFutures = <Future<Request>>[];
    final List<Target> targetsToRetry = <Target>[];
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
      requestFutures.add(_createBuildRequest(
        checkSuiteEvent: checkSuiteEvent,
        pullRequest: pullRequest,
        builder: target.value.name,
        builderId: builderId,
        userData: userData,
        properties: target.getProperties(),
      ));
    }
    final List<Request> requests = await Future.wait(requestFutures);
    List<BatchResponse> batchResponseList;
    final List<Future<BatchResponse>> futureBatchResponses = <Future<BatchResponse>>[];
    final Iterable<List<Request>> requestPartitions = await shard(requests, config.schedulingShardSize);
    for (List<Request> requestPartition in requestPartitions) {
      futureBatchResponses.add(buildBucketClient.batch(BatchRequest(requests: requestPartition)));
    }
    batchResponseList = await Future.wait(futureBatchResponses);
    final Iterable<Response> responses =
        batchResponseList.expand((BatchResponse element) => element.responses as Iterable<Response>);
    String errorText;
    for (Response response in responses) {
      errorText = '';
      if (response.error != null && response.error?.code != 0) {
        errorText = 'BatchResponse error: ${response.error}';
        log.warning(errorText);
      }
      if (response.scheduleBuild == null) {
        log.warning('$response does not contain scheduleBuild');
        if (response.getBuild?.builderId.builder != null) {
          final Target failedTarget =
              targets.singleWhere((Target target) => target.value.name == response.getBuild!.builderId.builder!);
          targetsToRetry.add(failedTarget);
        }
        continue;
      }
      final Build? scheduleBuild = response.scheduleBuild;
      if (scheduleBuild?.tags == null) {
        // Nothing to update just continue.
        continue;
      }
      // Tags are List<String> so we need to decode to a single int
      final List<String?>? checkrunIdStrings = scheduleBuild?.tags!['github_checkrun']!;
      final int? checkRunId = checkrunIdStrings?.map((String? id) => int.parse(id!)).single;
      // Not all scheduled builds have check runs
      if (checkRunId != null) {
        final github.CheckRun checkRun =
            await githubChecksUtil.getCheckRun(config, pullRequest.base!.repo!.slug(), checkRunId);
        if (errorText.isNotEmpty) {
          if (response.getBuild?.builderId.builder != null) {
            final Target failedTarget =
                targets.singleWhere((Target target) => target.value.name == response.getBuild!.builderId.builder!);
            targetsToRetry.add(failedTarget);
          }
          await githubChecksUtil.updateCheckRun(
            config,
            pullRequest.base!.repo!.slug(),
            checkRun,
            status: github.CheckRunStatus.completed,
            conclusion: github.CheckRunConclusion.failure,
            output: github.CheckRunOutput(
              title: 'Scheduling error',
              summary: 'Error scheduling build',
              text: errorText,
            ),
          );
        }
      }
    }
    return targetsToRetry;
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
    final int prNumber = int.parse(prString.split('/')[2]);
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
      properties: <String, String>{
        'git_url': 'https://github.com/${slug.owner}/${slug.name}',
        'git_ref': 'refs/pull/$prNumber/head',
      },
      notify: NotificationConfig(
        pubsubTopic: 'projects/flutter-dashboard/topics/luci-builds',
        userData: base64Encode(json.encode(userData).codeUnits),
      ),
    ));
    final String buildUrl = 'https://ci.chromium.org/ui/b/${scheduleBuild.id}';
    await githubChecksUtil.updateCheckRun(config, slug, githubCheckRun, detailsUrl: buildUrl);
    return true;
  }

  /// Sends [ScheduleBuildRequest] for [pullRequest] using [checkSuiteEvent],
  ///
  /// Returns true if it is able to schedule a build. Otherwise, false.
  Future<bool> rescheduleTryBuildUsingCheckSuiteEvent(
      github.PullRequest pullRequest, CheckSuiteEvent checkSuiteEvent, github.CheckRun checkRun) async {
    final github.RepositorySlug slug = checkSuiteEvent.repository!.slug();
    final github.CheckRun githubCheckRun = await githubChecksUtil.createCheckRun(
      config,
      pullRequest.base!.repo!.slug(),
      pullRequest.head!.sha!,
      checkRun.name!,
    );
    final Map<String, dynamic> userData = <String, dynamic>{};
    userData['check_suite_id'] = checkSuiteEvent.checkSuite!.id;
    userData['check_run_id'] = githubCheckRun.id;
    userData['repo_owner'] = slug.owner;
    userData['repo_name'] = slug.name;
    userData['user_agent'] = 'flutter-cocoon';
    await buildBucketClient.scheduleBuild(ScheduleBuildRequest(
      builderId: BuilderId(
        project: 'flutter',
        bucket: 'try',
        builder: checkRun.name,
      ),
      tags: <String, List<String>>{
        'buildset': <String>['pr/git/${pullRequest.number}', 'sha/git/${pullRequest.head!.sha}'],
        'user_agent': const <String>['flutter-cocoon'],
        'github_link': <String>['https://github.com/${slug.fullName}/pull/${pullRequest.number}'],
      },
      properties: <String, String>{
        'git_url': 'https://github.com/${slug.fullName}',
        'git_ref': 'refs/pull/${pullRequest.number}/head',
      },
      notify: NotificationConfig(
        pubsubTopic: 'projects/flutter-dashboard/topics/luci-builds',
        userData: json.encode(userData),
      ),
    ));
    return true;
  }

  /// Gets [Build] using its [id] and passing the additional
  /// fields to be populated in the response.
  Future<Build> getTryBuildById(String? id, {String? fields}) async {
    final GetBuildRequest request = GetBuildRequest(id: id, fields: fields);
    return buildBucketClient.getBuild(request);
  }

  /// Reschedules a post-submit build using [commitSha], [builderName], [branch],
  /// [repo], [properties], [tags] and [bucket]. Default value for [branch] is "master", default value for
  /// [repo] is "flutter", default for [properties] is an empty map and default for [tags] is null. [bucket]
  /// is either `prod` or `staging`.
  Future<Build> reschedulePostsubmitBuild({
    required String commitSha,
    required String? builderName,
    String branch = 'master',
    String repo = 'flutter',
    Map<String, dynamic> properties = const <String, dynamic>{},
    Map<String, List<String?>>? tags,
    String? bucket,
  }) async {
    final Map<String, dynamic> localProperties = Map<String, dynamic>.from(properties);
    tags ??= <String, List<String>>{};
    tags['buildset'] = <String>[
      'commit/git/$commitSha',
      'commit/gitiles/chromium.googlesource.com/external/github.com/flutter/$repo/+/$commitSha',
    ];
    tags['user_agent'] = <String>['luci-scheduler'];
    // Tag `scheduler_job_id` is needed when calling buildbucket search build API.
    tags['scheduler_job_id'] = <String>['flutter/$builderName'];
    localProperties['git_ref'] = commitSha;
    return buildBucketClient.scheduleBuild(ScheduleBuildRequest(
      builderId: BuilderId(
        project: 'flutter',
        bucket: bucket,
        builder: builderName,
      ),
      gitilesCommit: GitilesCommit(
        project: 'external/github.com/flutter/$repo',
        host: 'chromium.googlesource.com',
        ref: 'refs/heads/$branch',
        hash: commitSha,
      ),
      tags: tags,
      properties: localProperties,
      // Run manual retries with higher priority to ensure tasks that can
      // potentially open the tree are not wating for ~30 mins in the queue.
      priority: 29,
    ));
  }

  /// Check to auto-rerun TOT test failures.
  Future<bool> checkRerunBuilder({
    required Commit commit,
    required LuciTask luciTask,
    required int retries,
    String repo = 'flutter',
    DatastoreService? datastore,
    bool? isFlaky,
  }) async {
    if (await _shouldRerunBuilder(luciTask, retries, commit, datastore)) {
      log.info('Rerun builder: ${luciTask.builderName} for commit ${commit.sha}');
      final Map<String, List<String>> tags = <String, List<String>>{
        'triggered_by': <String>['cocoon'],
        'trigger_type': <String>['retry'],
      };
      await reschedulePostsubmitBuild(
        commitSha: commit.sha!,
        builderName: luciTask.builderName,
        repo: repo,
        tags: tags,
        bucket: isFlaky ?? false ? 'staging' : 'prod',
      );
      return true;
    }
    return false;
  }

  /// Check if a builder should be rerun.
  ///
  /// A rerun happens when a build fails, the retry number hasn't reached the limit, and the build
  /// is on TOT.
  Future<bool> _shouldRerunBuilder(LuciTask luciTask, int retries, Commit commit, DatastoreService? datastore) async {
    if (!taskFailStatusSet.contains(luciTask.status) || retries >= config.maxLuciTaskRetries) {
      return false;
    }
    final Commit latestCommit = await datastore!.queryRecentCommits(limit: 1).single;
    return latestCommit.sha == commit.sha;
  }
}
