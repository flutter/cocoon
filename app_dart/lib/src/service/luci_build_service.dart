// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:appengine/appengine.dart';
import 'package:cocoon_service/src/foundation/github_checks_util.dart';
import 'package:cocoon_service/src/model/github/checks.dart';
import 'package:cocoon_service/src/request_handling/exceptions.dart';
import 'package:github/github.dart' as github;
import 'package:github/github.dart';
import 'package:meta/meta.dart';

import '../../cocoon_service.dart';
import '../model/appengine/service_account_info.dart';
import '../model/luci/buildbucket.dart';
import '../model/luci/push_message.dart' as push_message;
import 'buildbucket.dart';

/// Class to interact with LUCI buildbucket to get, trigger
/// and cancel builds for github repos. It uses [config.luciTryBuilders] to
/// get the list of available builders.
class LuciBuildService {
  LuciBuildService(this.config, this.buildBucketClient, this.serviceAccount,
      {GithubChecksUtil githubChecksUtil})
      : githubChecksUtil = githubChecksUtil ?? const GithubChecksUtil();

  BuildBucketClient buildBucketClient;
  Config config;
  ServiceAccountInfo serviceAccount;
  Logging log;
  GithubChecksUtil githubChecksUtil;

  static const Set<Status> failStatusSet = <Status>{
    Status.canceled,
    Status.failure,
    Status.infraFailure
  };

  /// Sets the appengine [log] used by this class to log debug and error
  /// messages. This method has to be called before any other method in this
  /// class.
  void setLogger(Logging log) {
    this.log = log;
  }

  /// Returns a map of the BuildBucket builds for a given Github [slug]
  /// [prNumber] and [commitSha] using the [builderName] as key and [Build]
  /// as value.
  Future<Map<String, Build>> buildsForRepositoryAndPr(
    RepositorySlug slug,
    int prNumber,
    String commitSha,
  ) async {
    final BatchResponse batch =
        await buildBucketClient.batch(BatchRequest(requests: <Request>[
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
              'github_link': <String>[
                'https://github.com/${slug.owner}/${slug.name}/pull/$prNumber'
              ],
              'user_agent': const <String>['flutter-cocoon'],
            },
          ),
        ),
      ),
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
        .expand(
            (SearchBuildsResponse response) => response.builds ?? <Build>[]);
    return Map<String, Build>.fromIterable(builds,
        key: (dynamic b) => b.builderId.builder as String,
        value: (dynamic b) => b as Build);
  }

  /// Schedules BuildBucket builds for a given [prNumber], [commitSha]
  /// and Github [slug].
  Future<bool> scheduleBuilds({
    @required int prNumber,
    @required String commitSha,
    @required github.RepositorySlug slug,
    CheckSuiteEvent checkSuiteEvent,
  }) async {
    assert(prNumber != null);
    assert(commitSha != null);
    assert(slug != null);
    final github.GitHub githubClient =
        await config.createGitHubClient(slug.owner, slug.name);
    if (!config.githubPresubmitSupportedRepo(slug.name)) {
      throw BadRequestException(
          'Repository ${slug.name} is not supported by this service.');
    }

    final Map<String, Build> builds = await buildsForRepositoryAndPr(
      slug,
      prNumber,
      commitSha,
    );
    if (builds != null &&
        builds.values.any((Build build) {
          return build.status == Status.scheduled ||
              build.status == Status.started;
        })) {
      log.error(
          'Either builds are empty or they are already scheduled or started. '
          'PR: $prNumber, Commit: $commitSha, Owner: ${slug.owner} '
          'Repo: ${slug.name}');
      return false;
    }

    final List<Map<String, dynamic>> builders = config.luciTryBuilders;
    final List<String> builderNames = builders
        .where((Map<String, dynamic> builder) => builder['repo'] == slug.name)
        .map<String>(
            (Map<String, dynamic> builder) => builder['name'] as String)
        .toList();
    if (builderNames.isEmpty) {
      throw InternalServerError('${slug.name} does not have any builders');
    }

    final List<Request> requests = <Request>[];
    for (String builder in builderNames) {
      final BuilderId builderId = BuilderId(
        project: 'flutter',
        bucket: 'try',
        builder: builder,
      );
      final Map<String, dynamic> userData = <String, dynamic>{'retries': 0};
      if (checkSuiteEvent != null) {
        final github.CheckRun checkRun =
            await githubClient.checks.checkRuns.createCheckRun(
          checkSuiteEvent.repository.slug(),
          name: builder,
          headSha: commitSha,
        );
        userData['check_suite_id'] = checkSuiteEvent.checkSuite.id;
        userData['check_run_id'] = checkRun.id;
        userData['repo_owner'] = slug.owner;
        userData['repo_name'] = slug.name;
        userData['user_agent'] = 'flutter-cocoon';
      }
      requests.add(
        Request(
          scheduleBuild: ScheduleBuildRequest(
            builderId: builderId,
            tags: <String, List<String>>{
              'buildset': <String>['pr/git/$prNumber', 'sha/git/$commitSha'],
              'user_agent': const <String>['flutter-cocoon'],
              'github_link': <String>[
                'https://github.com/${slug.owner}/${slug.name}/pull/$prNumber'
              ],
            },
            properties: <String, String>{
              'git_url': 'https://github.com/${slug.owner}/${slug.name}',
              'git_ref': 'refs/pull/$prNumber/head',
            },
            notify: NotificationConfig(
              pubsubTopic: 'projects/flutter-dashboard/topics/luci-builds',
              userData: json.encode(const <String, dynamic>{
                'retries': 0,
              }),
            ),
          ),
        ),
      );
    }
    await buildBucketClient.batch(BatchRequest(requests: requests));
    return true;
  }

  /// Cancels all the current builds for a given [repositoryName], [prNumber]
  /// and [commitSha] adding a message for the cancelation reason.
  Future<void> cancelBuilds(RepositorySlug slug, int prNumber, String commitSha,
      String reason) async {
    if (!config.githubPresubmitSupportedRepo(slug.name)) {
      throw BadRequestException(
          'This service does not support repository ${slug.name}');
    }
    final Map<String, Build> builds = await buildsForRepositoryAndPr(
      slug,
      prNumber,
      commitSha,
    );
    if (builds == null ||
        !builds.values.any((Build build) {
          return build.status == Status.scheduled ||
              build.status == Status.started;
        })) {
      return;
    }
    final List<Request> requests = <Request>[];
    for (Build build in builds.values) {
      requests.add(
        Request(
          cancelBuild:
              CancelBuildRequest(id: build.id, summaryMarkdown: reason),
        ),
      );
    }
    await buildBucketClient.batch(BatchRequest(requests: requests));
  }

  /// Gets a list of failed builds for a given [repositoryName], [prNumber] and
  /// [commitSha].
  Future<List<Build>> failedBuilds(
    RepositorySlug slug,
    int prNumber,
    String commitSha,
  ) async {
    final Map<String, Build> builds =
        await buildsForRepositoryAndPr(slug, prNumber, commitSha);
    final List<String> builderNames = config.luciTryBuilders
        .map((Map<String, dynamic> entry) => entry['name'] as String)
        .toList();
    // Return only builds that exist in the configuration file.
    return builds.values
        .where((Build build) =>
            failStatusSet.contains(build.status) &&
            builderNames.contains(build.builderId.builder))
        .toList();
  }

  /// Sends a [BuildBucket.scheduleBuild] request as long as the `retries`
  /// parameter has not exceeded [CocoonConfig.luciTryInfraFailureRetries].
  ///
  /// If the retries have been exhausted, it sets the GitHub status to failure.
  ///
  /// The buildset, user_agent, and github_link tags are applied to match the
  /// original build. The build properties from the original build are also
  /// preserved.
  Future<bool> rescheduleBuild({
    @required String commitSha,
    @required String builderName,
    @required push_message.BuildPushMessage buildPushMessage,
    @required int retries,
  }) async {
    if (retries >= config.luciTryInfraFailureRetries) {
      // Too many retries.
      return false;
    }
    // Ensure we are using V2 bucket name istead of V1.
    // V1 bucket name  is "luci.flutter.prod" while the api
    // is expecting just the last part after "."(prod).
    final String bucketName = buildPushMessage.build.bucket.split('.').last;
    final Map<String, dynamic> userData =
        jsonDecode(buildPushMessage.userData) as Map<String, dynamic>;
    userData['retries'] += 1;
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
      properties: (buildPushMessage.build.buildParameters['properties']
              as Map<String, dynamic>)
          .cast<String, String>(),
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
    final github.PullRequest pr = checkRunEvent.checkRun.pullRequests[0];
    final github.GitHub gitHubClient =
        await config.createGitHubClient(slug.owner, slug.name);
    final github.CheckRun githubCheckRun =
        await githubChecksUtil.createCheckRun(
      gitHubClient,
      slug,
      checkRunEvent.checkRun.name,
      pr.head.sha,
    );
    userData['check_suite_id'] = checkRunEvent.checkRun.checkSuite.id;
    userData['check_run_id'] = githubCheckRun.id;
    userData['repo_owner'] = slug.owner;
    userData['repo_name'] = slug.name;
    userData['user_agent'] = 'flutter-cocoon';
    userData['retries'] = 1;
    await buildBucketClient.scheduleBuild(ScheduleBuildRequest(
      builderId: BuilderId(
        project: 'flutter',
        bucket: 'try',
        builder: checkRunEvent.checkRun.name,
      ),
      tags: <String, List<String>>{
        'buildset': <String>['pr/git/${pr.number}', 'sha/git/${pr.head.sha}'],
        'user_agent': const <String>['flutter-cocoon'],
        'github_link': <String>[
          'https://github.com/${slug.owner}/${slug.name}/pull/${pr.number}'
        ],
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

  /// Sends a [BuildBucket.scheduleBuild] request using [CheckSuiteEvent],
  /// [gitgub.CheckRun] and [RepositorySlug]. It returns [true] if it is able to
  /// send the scheduleBuildRequest or [false] if not.
  Future<bool> rescheduleUsingCheckSuiteEvent(
      CheckSuiteEvent checkSuiteEvent, github.CheckRun checkRun) async {
    final github.RepositorySlug slug = checkSuiteEvent.repository.slug();
    final Map<String, dynamic> userData = <String, dynamic>{};
    final github.PullRequest pr = checkSuiteEvent.checkSuite.pullRequests[0];
    final github.GitHub gitHubClient =
        await config.createGitHubClient(slug.owner, slug.name);
    final github.CheckRun githubCheckRun =
        await githubChecksUtil.createCheckRun(
      gitHubClient,
      slug,
      checkRun.name,
      pr.head.sha,
    );
    userData['check_suite_id'] = checkSuiteEvent.checkSuite.id;
    userData['check_run_id'] = githubCheckRun.id;
    userData['repo_owner'] = slug.owner;
    userData['repo_name'] = slug.name;
    userData['user_agent'] = 'flutter-cocoon';
    userData['retries'] = 1;
    await buildBucketClient.scheduleBuild(ScheduleBuildRequest(
      builderId: BuilderId(
        project: 'flutter',
        bucket: 'try',
        builder: checkRun.name,
      ),
      tags: <String, List<String>>{
        'buildset': <String>['pr/git/${pr.number}', 'sha/git/${pr.head.sha}'],
        'user_agent': const <String>['flutter-cocoon'],
        'github_link': <String>[
          'https://github.com/${slug.owner}/${slug.name}/pull/${pr.number}'
        ],
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
  Future<Build> getBuildById(int id, {String fields}) async {
    final GetBuildRequest request = GetBuildRequest(id: id, fields: fields);
    return buildBucketClient.getBuild(request);
  }
}
