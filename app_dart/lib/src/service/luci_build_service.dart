// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:appengine/appengine.dart';
import 'package:cocoon_service/src/foundation/github_checks_util.dart';
import 'package:cocoon_service/src/model/github/checks.dart';
import 'package:cocoon_service/src/request_handling/exceptions.dart';
import 'package:cocoon_service/src/service/github_service.dart';
import 'package:github/github.dart' as github;
import 'package:meta/meta.dart';

import '../../cocoon_service.dart';
import '../foundation/utils.dart';
import '../model/appengine/service_account_info.dart';
import '../model/luci/buildbucket.dart';
import '../model/luci/push_message.dart' as push_message;
import 'buildbucket.dart';

/// Class to interact with LUCI buildbucket to get, trigger
/// and cancel builds for github repos. It uses [config.getRepoLuciBuilders] to
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

  /// Returns a BuildBucket build for a given Github [slug], [commitSha] and
  /// [builderName].
  Future<Build> getTryBuild(
    github.RepositorySlug slug,
    String commitSha,
    String builderName,
  ) async {
    final BatchResponse batch = await buildBucketClient.batch(BatchRequest(requests: <Request>[
      Request(
        searchBuilds: SearchBuildsRequest(
          predicate: BuildPredicate(
            builderId: BuilderId(
              project: 'flutter',
              bucket: 'try',
              builder: builderName,
            ),
            tags: <String, List<String>>{
              'buildset': <String>['sha/git/$commitSha'],
              'user_agent': const <String>['flutter-cocoon'],
            },
          ),
          fields: 'builds.*.id,builds.*.builder,builds.*.tags',
        ),
      ),
    ]));
    final Iterable<Build> builds = batch.responses
        .map((Response response) => response.searchBuilds)
        .expand((SearchBuildsResponse response) => response.builds ?? <Build>[]);
    return builds.first;
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
        .expand((SearchBuildsResponse response) => response.builds ?? <Build>[]);
    return Map<String, Build>.fromIterable(builds,
        key: (dynamic b) => b.builderId.builder as String, value: (dynamic b) => b as Build);
  }

  /// Schedules BuildBucket builds for a given [prNumber], [commitSha]
  /// and Github [slug].
  Future<bool> scheduleTryBuilds({
    @required int prNumber,
    @required String commitSha,
    @required github.RepositorySlug slug,
    CheckSuiteEvent checkSuiteEvent,
  }) async {
    assert(prNumber != null);
    assert(commitSha != null);
    assert(slug != null);
    if (!config.githubPresubmitSupportedRepo(slug.name)) {
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

    final List<Map<String, dynamic>> builders = await config.getRepoLuciBuilders('try', slug.name);
    final GithubService githubService = await config.createGithubService(slug.owner, slug.name);
    final List<String> files = await githubService.listFiles(slug, prNumber);
    final List<Map<String, dynamic>> filteredBuilders = await getFilteredBuilders(builders, files);
    final List<String> builderNames = filteredBuilders
        .where((Map<String, dynamic> builder) => builder['repo'] == slug.name)
        .map<String>((Map<String, dynamic> builder) => builder['name'] as String)
        .toList();
    if (builderNames.isEmpty) {
      throw InternalServerError('${slug.name} does not have any builders');
    }

    final List<Request> requests = <Request>[];
    for (String builder in builderNames) {
      final github.GitHub githubClient = await config.createGitHubClient(slug.owner, slug.name);
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
      if (checkSuiteEvent != null || config.isChecksSupportedRepo(slug)) {
        log.info('Creating check run for PR: $prNumber, Commit: $commitSha, '
            'Owner: ${slug.owner} and Repo: ${slug.name}');
        final github.CheckRun checkRun = await githubChecksUtil.createCheckRun(
          githubClient,
          slug,
          builder,
          commitSha,
        );
        userData['check_run_id'] = checkRun.id;
      }
      requests.add(
        Request(
          scheduleBuild: ScheduleBuildRequest(
            builderId: builderId,
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
          ),
        ),
      );
    }
    await buildBucketClient.batch(BatchRequest(requests: requests));
    return true;
  }

  /// Cancels all the current builds for a given [repositoryName], [prNumber]
  /// and [commitSha] adding a message for the cancelation reason.
  Future<void> cancelBuilds(github.RepositorySlug slug, int prNumber, String commitSha, String reason) async {
    if (!config.githubPresubmitSupportedRepo(slug.name)) {
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
  ) async {
    final Map<String, Build> builds = await tryBuildsForRepositoryAndPr(slug, prNumber, commitSha);
    final List<Map<String, dynamic>> luciTryBuilders = await config.getRepoLuciBuilders('try', slug.name);
    final GithubService githubService = await config.createGithubService(slug.owner, slug.name);
    final List<String> files = await githubService.listFiles(slug, prNumber);
    final List<Map<String, dynamic>> filteredBuilders = await getFilteredBuilders(luciTryBuilders, files);
    final List<String> builderNames =
        filteredBuilders.map((Map<String, dynamic> entry) => entry['name'] as String).toList();
    // Return only builds that exist in the configuration file.
    return builds.values
        .where((Build build) => failStatusSet.contains(build.status) && builderNames.contains(build.builderId.builder))
        .toList();
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

    final github.GitHub gitHubClient = await config.createGitHubClient(slug.owner, slug.name);
    final String commitSha = checkRunEvent.checkRun.headSha;
    final String builderName = checkRunEvent.checkRun.name;
    final github.CheckRun githubCheckRun = await githubChecksUtil.createCheckRun(
      gitHubClient,
      slug,
      checkRunEvent.checkRun.name,
      commitSha,
    );
    final Build build = await getTryBuild(slug, commitSha, builderName);
    final String prString = build.tags['buildset'].firstWhere((String element) => element.startsWith('pr/git/'));
    final int prNumber = int.parse(prString.split('/')[2]);
    userData['check_run_id'] = githubCheckRun.id;
    userData['repo_owner'] = slug.owner;
    userData['repo_name'] = slug.name;
    userData['user_agent'] = 'flutter-cocoon';
    await buildBucketClient.scheduleBuild(ScheduleBuildRequest(
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
    return true;
  }

  /// Sends a [BuildBucket.scheduleBuild] request using [CheckSuiteEvent],
  /// [gitgub.CheckRun] and [RepositorySlug]. It returns [true] if it is able to
  /// send the scheduleBuildRequest or [false] if not.
  Future<bool> rescheduleTryBuildUsingCheckSuiteEvent(CheckSuiteEvent checkSuiteEvent, github.CheckRun checkRun) async {
    final github.RepositorySlug slug = checkSuiteEvent.repository.slug();
    final Map<String, dynamic> userData = <String, dynamic>{};
    final github.PullRequest pr = checkSuiteEvent.checkSuite.pullRequests[0];
    final github.GitHub gitHubClient = await config.createGitHubClient(slug.owner, slug.name);
    final github.CheckRun githubCheckRun = await githubChecksUtil.createCheckRun(
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

  /// Reschedules a prod build using [commitSha], [builderName], [branch] and
  /// [repo]. Default value for [branch] is "master" and default value for
  /// [repo] is "flutter".
  Future<void> rescheduleProdBuild({
    @required String commitSha,
    @required String builderName,
    String branch = 'master',
    String repo = 'flutter',
  }) async {
    await buildBucketClient.scheduleBuild(ScheduleBuildRequest(
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
      tags: <String, List<String>>{
        'buildset': <String>[
          'commit/git/$commitSha',
        ],
        'user_agent': const <String>['luci-scheduler'],
      },
      properties: <String, String>{
        'git_ref': commitSha,
      },
    ));
  }
}
