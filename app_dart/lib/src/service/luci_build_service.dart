// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:cocoon_service/cocoon_service.dart';
import 'package:github/github.dart' as github;

import '../foundation/github_checks_util.dart';
import '../model/appengine/commit.dart';
import '../model/appengine/task.dart';
import '../model/ci_yaml/target.dart';
import '../model/github/checks.dart' as cocoon_checks;
import '../model/luci/push_message.dart' as push_message;
import '../model/luci/buildbucket.dart';
import '../service/logging.dart';
import 'build_bucket_v2_client.dart';
import 'exceptions.dart';

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

  static const Set<Status> failStatusSet = <Status>{
    Status.canceled,
    Status.failure,
    Status.infraFailure,
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
  Future<List<List<Request>>> shard(List<Request> requests, int max) async {
    final List<List<Request>> shards = <List<Request>>[];
    for (int i = 0; i < requests.length; i += max) {
      shards.add(requests.sublist(i, i + min<int>(requests.length - i, max)));
    }
    return shards;
  }

  /// Fetches an Iterable of try BuildBucket [Build]s.
  ///
  /// Returns a list of BuildBucket [Build]s for a given Github [slug], [sha],
  /// and [builderName].
  Future<Iterable<Build>> _getTryBuilds(
    github.RepositorySlug slug,
    String sha,
    String? builderName,
  ) async {
    final Map<String, List<String>> tags = <String, List<String>>{
      'buildset': <String>['sha/git/$sha'],
      'user_agent': const <String>['flutter-cocoon'],
    };
    return _getBuilds(slug, sha, builderName, 'try', tags);
  }

  /// Fetches an Iterable of prod BuildBucket [Build]s.
  ///
  /// Returns an Iterable of prod BuildBucket [Build]s for a given Github
  /// [slug], [sha], and [builderName].
  Future<Iterable<Build>> _getProdBuilds(
    github.RepositorySlug slug,
    String commitSha,
    String? builderName,
  ) async {
    final Map<String, List<String>> tags = <String, List<String>>{};
    return _getBuilds(slug, commitSha, builderName, 'prod', tags);
  }

  /// Fetches an Iterable of try BuildBucket [Build]s.
  ///
  /// Returns an iterable of try BuildBucket [Build]s for a given Github [slug],
  /// [sha], [builderName], [bucket], and [tags].
  Future<Iterable<Build>> _getBuilds(
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

  /// Filters [builders] to only those that failed on [pullRequest].
  Future<List<Build?>> failedBuilds(
    github.PullRequest pullRequest,
    List<Target> targets,
  ) async {
    final Iterable<Build> builds = await _getTryBuilds(pullRequest.base!.repo!.slug(), pullRequest.head!.sha!, null);
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

    final Iterable<Build> builds = await _getProdBuilds(slug, sha, checkName);
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
      'firestore_commit_document_name': commit.sha,
    };

    // Creates post submit checkrun only for unflaky targets from [config.postsubmitSupportedRepos].
    if (!target.value.bringup && config.postsubmitSupportedRepos.contains(target.slug)) {
      await _createPostsubmitCheckRun(commit, target, rawUserData);
    }

    tags['user_agent'] = <String>['flutter-cocoon'];
    // Tag `scheduler_job_id` is needed when calling buildbucket search build API.
    tags['scheduler_job_id'] = <String>['flutter/${target.value.name}'];
    // Default attempt is the initial attempt, which is 1.
    tags['current_attempt'] = tags['current_attempt'] ?? <String>['1'];
    final String currentAttempt = tags['current_attempt']!.single;
    rawUserData['firestore_task_document_name'] = '${commit.sha}_${task.name}_$currentAttempt';

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
  Future<void> _createPostsubmitCheckRun(
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
}
