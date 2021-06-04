// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:appengine/appengine.dart';
import 'package:github/github.dart' as github;
import 'package:meta/meta.dart';
import 'package:retry/retry.dart';

import '../../cocoon_service.dart';
import '../foundation/github_checks_util.dart';
import '../model/appengine/service_account_info.dart';
import '../model/github/checks.dart';
import '../model/luci/buildbucket.dart';
import '../model/luci/push_message.dart' as push_message;
import '../request_handling/exceptions.dart';
import 'buildbucket.dart';
import 'luci.dart';

/// List of Mac builders that have shards, and hit -9 retcode issue:
/// https://github.com/flutter/flutter/issues/68322
const List<String> kMacBuildersWithShards = <String>['Mac build_tests', 'Mac framework_tests', 'Mac tool_tests'];

/// Class to interact with LUCI buildbucket to get, trigger
/// and cancel builds for github repos. It uses [config.luciTryBuilders] to
/// get the list of available builders.
class LuciBuildService {
  LuciBuildService(this.config, this.buildBucketClient, this.serviceAccount, {GithubChecksUtil githubChecksUtil})
      : githubChecksUtil = githubChecksUtil ?? const GithubChecksUtil();

  BuildBucketClient buildBucketClient;
  Config config;
  ServiceAccountInfo serviceAccount;
  Logging log;
  GithubChecksUtil githubChecksUtil;

  static const Set<Status> failStatusSet = <Status>{Status.canceled, Status.failure, Status.infraFailure};

  /// Sets the appengine [log] used by this class to log debug and error
  /// messages. This method has to be called before any other method in this
  /// class.
  void setLogger(Logging log) {
    this.log = log;
  }

  /// Returns an Iterable of try BuildBucket build for a given Github [slug], [commitSha],
  /// [builderName].
  Future<Iterable<Build>> getTryBuilds(
    github.RepositorySlug slug,
    String commitSha,
    String builderName,
  ) async {
    final Map<String, List<String>> tags = <String, List<String>>{
      'buildset': <String>['sha/git/$commitSha'],
      'user_agent': const <String>['flutter-cocoon'],
    };
    return getBuilds(slug, commitSha, builderName, 'try', tags);
  }

  /// Returns an Iterable of prod BuildBucket build for a given Github [slug], [commitSha],
  /// [builderName] and [repo].
  Future<Iterable<Build>> getProdBuilds(
    github.RepositorySlug slug,
    String commitSha,
    String builderName,
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
    github.RepositorySlug slug,
    String commitSha,
    String builderName,
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
    final Iterable<Build> builds = batch.responses
        .map((Response response) => response.searchBuilds)
        .expand((SearchBuildsResponse response) => response.builds ?? <Build>[]);
    return builds;
  }

  /// Returns a map of the BuildBucket builds for a given Github [slug]
  /// [prNumber] and [commitSha] using the [builderName] as key and [Build]
  /// as value.
  Future<Map<String, Build>> tryBuildsForRepositoryAndPr(
    github.RepositorySlug slug,
    int prNumber,
    String commitSha,
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
            createdBy: serviceAccount.email,
            tags: <String, List<String>>{
              'buildset': <String>['pr/git/$prNumber'],
              'github_link': <String>['https://github.com/${slug.owner}/${slug.name}/pull/$prNumber'],
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
              'buildset': <String>['pr/git/$prNumber'],
              'user_agent': const <String>['recipe'],
            },
          ),
        ),
      ),
    ]));
    final Iterable<Build> builds = batch.responses
        .map((Response response) => response.searchBuilds)
        .expand((SearchBuildsResponse response) => response?.builds ?? <Build>[]);
    return Map<String, Build>.fromIterable(builds,
        key: (dynamic b) => b.builderId.builder as String, value: (dynamic b) => b as Build);
  }

  /// Schedules BuildBucket builds for a given [prNumber], [commitSha]
  /// and Github [slug].
  Future<bool> scheduleTryBuilds({
    @required List<LuciBuilder> builders,
    @required int prNumber,
    @required String commitSha,
    @required github.RepositorySlug slug,
    CheckSuiteEvent checkSuiteEvent,
  }) async {
    assert(builders != null);
    assert(prNumber != null);
    assert(commitSha != null);
    assert(slug != null);
    if (!config.githubPresubmitSupportedRepo(slug)) {
      throw BadRequestException('Repository ${slug.name} is not supported by this service.');
    }

    final Map<String, Build> builds = await tryBuildsForRepositoryAndPr(
      slug,
      prNumber,
      commitSha,
    );
    if (builds != null &&
        builds.values.any((Build build) {
          return build.status == Status.scheduled || build.status == Status.started;
        })) {
      log.error('Either builds are empty or they are already scheduled or started. '
          'PR: $prNumber, Commit: $commitSha, Owner: ${slug.owner} '
          'Repo: ${slug.name}');
      return false;
    }

    final List<String> builderNames = builders
        .where((LuciBuilder builder) => builder.repo == slug.name)
        .map<String>((LuciBuilder builder) => builder.name)
        .toList();
    if (builderNames.isEmpty) {
      throw InternalServerError('${slug.name} does not have any builders');
    }

    final List<Request> requests = <Request>[];
    for (String builder in builderNames) {
      log.info('Trigger build for: $builder');
      final BuilderId builderId = BuilderId(
        project: 'flutter',
        bucket: 'try',
        builder: builder,
      );
      final Map<String, dynamic> userData = <String, dynamic>{
        'repo_owner': slug.owner,
        'repo_name': slug.name,
        'user_agent': 'flutter-cocoon',
      };
      int checkRunId;
      if (checkSuiteEvent != null || config.githubPresubmitSupportedRepo(slug)) {
        log.info('Creating check run for PR: $prNumber, Commit: $commitSha, Slug: $slug');
        final github.CheckRun checkRun = await githubChecksUtil.createCheckRun(
          config,
          slug,
          builder,
          commitSha,
        );
        userData['check_run_id'] = checkRun.id;
        checkRunId = checkRun.id;
      }
      requests.add(
        Request(
          scheduleBuild: ScheduleBuildRequest(
            builderId: builderId,
            tags: <String, List<String>>{
              'buildset': <String>['pr/git/$prNumber', 'sha/git/$commitSha'],
              'user_agent': const <String>['flutter-cocoon'],
              'github_link': <String>['https://github.com/${slug.fullName}/pull/$prNumber'],
              if (checkRunId != null) 'github_checkrun': <String>[checkRunId.toString()],
            },
            properties: <String, String>{
              'git_url': 'https://github.com/${slug.owner}/${slug.name}',
              'git_ref': 'refs/pull/$prNumber/head',
            },
            notify: NotificationConfig(
              pubsubTopic: 'projects/flutter-dashboard/topics/luci-builds',
              userData: json.encode(userData),
            ),
          ),
        ),
      );
    }
    const RetryOptions r = RetryOptions(
      maxAttempts: 3,
      delayFactor: Duration(seconds: 2),
    );
    BatchResponse batchResponse;
    log.debug('Making BatchRequest with ${requests.length} requests');
    await r.retry(
      () async {
        batchResponse = await buildBucketClient.batch(BatchRequest(requests: requests));
      },
      retryIf: (Exception e) => e is BuildBucketException,
    );
    for (Response response in batchResponse.responses) {
      if (response.error?.code != 0) {
        log.warning('BatchResponse error: $response');
        continue;
      }

      if (response.scheduleBuild == null) {
        log.warning('$response does not contain scheduleBuild');
        continue;
      }

      final Build scheduleBuild = response.scheduleBuild;
      // Tags are List<String> so we need to decode to a single int
      final List<String> checkrunIdStrings = scheduleBuild.tags['github_checkrun'];
      final int checkRunId = checkrunIdStrings.map((String id) => int.parse(id)).single;
      final String buildUrl = 'https://ci.chromium.org/ui/b/${scheduleBuild.id}';
      // Not all scheduled builds have check runs
      if (checkRunId != null) {
        final github.CheckRun checkRun = await githubChecksUtil.getCheckRun(config, slug, checkRunId);
        await githubChecksUtil.updateCheckRun(config, slug, checkRun, detailsUrl: buildUrl);
      }
    }

    return true;
  }

  /// Cancels all the current builds for a given [repositoryName], [prNumber]
  /// and [commitSha] adding a message for the cancelation reason.
  Future<void> cancelBuilds(github.RepositorySlug slug, int prNumber, String commitSha, String reason) async {
    if (!config.githubPresubmitSupportedRepo(slug)) {
      throw BadRequestException('This service does not support repository ${slug.name}');
    }
    final Map<String, Build> builds = await tryBuildsForRepositoryAndPr(
      slug,
      prNumber,
      commitSha,
    );
    if (builds == null ||
        !builds.values.any((Build build) {
          return build.status == Status.scheduled || build.status == Status.started;
        })) {
      return;
    }
    final List<Request> requests = <Request>[];
    for (Build build in builds.values) {
      requests.add(
        Request(
          cancelBuild: CancelBuildRequest(id: build.id, summaryMarkdown: reason),
        ),
      );
    }
    await buildBucketClient.batch(BatchRequest(requests: requests));
  }

  /// Gets a list of failed builds for a given [repositoryName], [prNumber] and
  /// [commitSha].
  Future<List<Build>> failedBuilds(
    github.RepositorySlug slug,
    int prNumber,
    String commitSha,
    List<LuciBuilder> builders,
  ) async {
    final Map<String, Build> builds = await tryBuildsForRepositoryAndPr(slug, prNumber, commitSha);
    final List<String> builderNames = builders.map((LuciBuilder entry) => entry.name).toList();
    // Return only builds that exist in the configuration file.
    final Iterable<Build> failedBuilds = builds.values.where((Build build) => failStatusSet.contains(build.status));
    final Iterable<Build> expectedFailedBuilds =
        failedBuilds.where((Build build) => builderNames.contains(build.builderId.builder));
    return expectedFailedBuilds.toList();
  }

  /// Sends a [BuildBucket.scheduleBuild] the buildset, user_agent, and
  /// github_link tags are applied to match the original build. The build
  /// properties from the original build are also preserved.
  Future<bool> rescheduleBuild({
    @required String commitSha,
    @required String builderName,
    @required push_message.BuildPushMessage buildPushMessage,
  }) async {
    // Ensure we are using V2 bucket name istead of V1.
    // V1 bucket name  is "luci.flutter.prod" while the api
    // is expecting just the last part after "."(prod).
    final String bucketName = buildPushMessage.build.bucket.split('.').last;
    final Map<String, dynamic> userData = jsonDecode(buildPushMessage.userData) as Map<String, dynamic>;
    await buildBucketClient.scheduleBuild(ScheduleBuildRequest(
      builderId: BuilderId(
        project: buildPushMessage.build.project,
        bucket: bucketName,
        builder: builderName,
      ),
      tags: <String, List<String>>{
        'buildset': buildPushMessage.build.tagsByName('buildset'),
        'user_agent': buildPushMessage.build.tagsByName('user_agent'),
        'github_link': buildPushMessage.build.tagsByName('github_link'),
      },
      properties: (buildPushMessage.build.buildParameters['properties'] as Map<String, dynamic>).cast<String, String>(),
      notify: NotificationConfig(
        pubsubTopic: 'projects/flutter-dashboard/topics/luci-builds',
        userData: json.encode(userData),
      ),
    ));
    return true;
  }

  /// Sends a [BuildBucket.scheduleBuild] request using [CheckRunEvent]. It
  /// returns [true] if it is able to send the scheduleBuildRequest or [false]
  /// if not.
  Future<bool> rescheduleUsingCheckRunEvent(CheckRunEvent checkRunEvent) async {
    final github.RepositorySlug slug = checkRunEvent.repository.slug();
    final Map<String, dynamic> userData = <String, dynamic>{};
    final String commitSha = checkRunEvent.checkRun.headSha;
    final String builderName = checkRunEvent.checkRun.name;
    final github.CheckRun githubCheckRun = await githubChecksUtil.createCheckRun(
      config,
      slug,
      checkRunEvent.checkRun.name,
      commitSha,
    );
    final Iterable<Build> builds = await getTryBuilds(slug, commitSha, builderName);
    final Build build = builds.isNotEmpty ? builds.first : null;
    final String prString = build.tags['buildset'].firstWhere((String element) => element.startsWith('pr/git/'));
    final int prNumber = int.parse(prString.split('/')[2]);
    userData['check_run_id'] = githubCheckRun.id;
    userData['repo_owner'] = slug.owner;
    userData['repo_name'] = slug.name;
    userData['user_agent'] = 'flutter-cocoon';
    final Build scheduleBuild = await buildBucketClient.scheduleBuild(ScheduleBuildRequest(
      builderId: BuilderId(
        project: 'flutter',
        bucket: 'try',
        builder: checkRunEvent.checkRun.name,
      ),
      tags: <String, List<String>>{
        'buildset': <String>['pr/git/$prNumber', 'sha/git/$commitSha'],
        'user_agent': const <String>['flutter-cocoon'],
        'github_link': <String>['https://github.com/${slug.owner}/${slug.name}/pull/$prNumber'],
      },
      properties: <String, String>{
        'git_url': 'https://github.com/${slug.owner}/${slug.name}',
        'git_ref': 'refs/pull/$prNumber/head',
      },
      notify: NotificationConfig(
        pubsubTopic: 'projects/flutter-dashboard/topics/luci-builds',
        userData: json.encode(userData),
      ),
    ));
    final String buildUrl = 'https://ci.chromium.org/ui/b/${scheduleBuild.id}';
    await githubChecksUtil.updateCheckRun(config, slug, githubCheckRun, detailsUrl: buildUrl);
    return true;
  }

  /// Sends a [BuildBucket.scheduleBuild] request using [CheckSuiteEvent],
  /// [gitgub.CheckRun] and [RepositorySlug]. It returns [true] if it is able to
  /// send the scheduleBuildRequest or [false] if not.
  Future<bool> rescheduleTryBuildUsingCheckSuiteEvent(CheckSuiteEvent checkSuiteEvent, github.CheckRun checkRun) async {
    final github.RepositorySlug slug = checkSuiteEvent.repository.slug();
    final Map<String, dynamic> userData = <String, dynamic>{};
    final github.PullRequest pr = checkSuiteEvent.checkSuite.pullRequests[0];
    final github.CheckRun githubCheckRun = await githubChecksUtil.createCheckRun(
      config,
      slug,
      checkRun.name,
      pr.head.sha,
    );
    userData['check_suite_id'] = checkSuiteEvent.checkSuite.id;
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
        'buildset': <String>['pr/git/${pr.number}', 'sha/git/${pr.head.sha}'],
        'user_agent': const <String>['flutter-cocoon'],
        'github_link': <String>['https://github.com/${slug.owner}/${slug.name}/pull/${pr.number}'],
      },
      properties: <String, String>{
        'git_url': 'https://github.com/${slug.owner}/${slug.name}',
        'git_ref': 'refs/pull/${pr.number}/head',
      },
      notify: NotificationConfig(
        pubsubTopic: 'projects/flutter-dashboard/topics/luci-builds',
        userData: json.encode(userData),
      ),
    ));
    return true;
  }

  /// Gets a [buildbucket.Build] using its [id] and passing the additional
  /// fields to be populated in the response.
  Future<Build> getTryBuildById(int id, {String fields}) async {
    final GetBuildRequest request = GetBuildRequest(id: id, fields: fields);
    return buildBucketClient.getBuild(request);
  }

  /// Reschedules a prod build using [commitSha], [builderName], [branch],
  /// [repo] and [properties]. Default value for [branch] is "master", default value for
  /// [repo] is "flutter", default for [properties] is an empty map and default for [tags] is null.
  Future<Build> rescheduleProdBuild({
    @required String commitSha,
    @required String builderName,
    String branch = 'master',
    String repo = 'flutter',
    Map<String, dynamic> properties = const <String, dynamic>{},
    Map<String, List<String>> tags,
  }) async {
    final Map<String, dynamic> localProperties = Map<String, dynamic>.from(properties);
    tags ??= <String, List<String>>{};
    tags['buildset'] = <String>[
      'commit/git/$commitSha',
      'commit/gitiles/chromium.googlesource.com/external/github.com/flutter/$repo/+/$commitSha',
    ];
    tags['user_agent'] = <String>['luci-scheduler'];
    localProperties['git_ref'] = commitSha;
    return buildBucketClient.scheduleBuild(ScheduleBuildRequest(
      builderId: BuilderId(
        project: 'flutter',
        bucket: 'prod',
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

  /// Check to auto-rerun Mac builders with `infra failure`.
  ///
  /// This is a workaround for -9 retcode issue: https://github.com/flutter/flutter/issues/68322.
  Future<bool> checkRerunBuilder({
    @required String commitSha,
    @required LuciTask luciTask,
    @required int retries,
    String repo = 'flutter',
  }) async {
    if (_shouldRerunBuilder(luciTask, repo) && retries < config.maxLuciTaskRetries) {
      log.info('Rerun Mac builder: ${luciTask.builderName} for commit $commitSha');
      await rescheduleProdBuild(
        commitSha: commitSha,
        builderName: luciTask.builderName,
        repo: repo,
      );
      return true;
    }
    return false;
  }

  bool _shouldRerunBuilder(LuciTask luciTask, String repo) {
    if (luciTask.summaryMarkdown == null || !luciTask.builderName.contains('Mac')) {
      return false;
    }
    switch (repo) {
      case 'flutter':
        return luciTask.summaryMarkdown.contains('retcode: -9') ||
            (kMacBuildersWithShards.contains(luciTask.builderName) &&
                luciTask.summaryMarkdown ==
                    'recipe infra failure: Infra Failure: Step(\'display builds.build(s) failed\') (retcode: 1)');
      case 'engine':
        return luciTask.summaryMarkdown.contains('retcode: -9');
    }
    return false;
  }
}
