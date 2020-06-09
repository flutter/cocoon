// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:cocoon_service/src/request_handling/exceptions.dart';
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
  LuciBuildService(this.config, this.buildBucketClient, this.serviceAccount);

  BuildBucketClient buildBucketClient;
  Config config;
  ServiceAccountInfo serviceAccount;
  static const Set<Status> failStatusSet = <Status>{
    Status.canceled,
    Status.failure,
    Status.infraFailure
  };

  /// Returns a map of the BuildBucket builds for a given [repositoryName]
  /// [prNumber] and [commitSha] using the [builderName] as key and [Build]
  /// as value.
  Future<Map<String, Build>> buildsForRepositoryAndPr(
    String repositoryName,
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
                'https://github.com/flutter/$repositoryName/pull/$prNumber'
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
  /// and repositoryName. It returns [true] if it was able to schedule
  /// build or [false] otherwise.
  Future<bool> scheduleBuilds({
    @required int prNumber,
    @required String commitSha,
    @required String repositoryName,
  }) async {
    assert(prNumber != null);
    assert(commitSha != null);
    assert(repositoryName != null);
    if (!config.githubPresubmitSupportedRepo(repositoryName)) {
      throw BadRequestException(
          'Repository $repositoryName is not supported by this service.');
    }

    final Map<String, Build> builds = await buildsForRepositoryAndPr(
      repositoryName,
      prNumber,
      commitSha,
    );

    if (builds != null &&
        builds.values.any((Build build) {
          return build.status == Status.scheduled ||
              build.status == Status.started;
        })) {
      return false;
    }

    final List<Map<String, dynamic>> builders = config.luciTryBuilders;
    final List<String> builderNames = builders
        .where(
            (Map<String, dynamic> builder) => builder['repo'] == repositoryName)
        .map<String>(
            (Map<String, dynamic> builder) => builder['name'] as String)
        .toList();
    if (builderNames.isEmpty) {
      throw InternalServerError('$repositoryName does not have any builders');
    }

    final List<Request> requests = <Request>[];
    for (String builder in builderNames) {
      final BuilderId builderId = BuilderId(
        project: 'flutter',
        bucket: 'try',
        builder: builder,
      );
      requests.add(
        Request(
          scheduleBuild: ScheduleBuildRequest(
            builderId: builderId,
            tags: <String, List<String>>{
              'buildset': <String>['pr/git/$prNumber', 'sha/git/$commitSha'],
              'user_agent': const <String>['flutter-cocoon'],
              'github_link': <String>[
                'https://github.com/flutter/$repositoryName/pull/$prNumber'
              ],
            },
            properties: <String, String>{
              'git_url': 'https://github.com/flutter/$repositoryName',
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
  Future<void> cancelBuilds(String repositoryName, int prNumber,
      String commitSha, String reason) async {
    if (!config.githubPresubmitSupportedRepo(repositoryName)) {
      throw BadRequestException(
          'This service does not support repository $repositoryName.');
    }
    final Map<String, Build> builds = await buildsForRepositoryAndPr(
      repositoryName,
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
    String repositoryName,
    int prNumber,
    String commitSha,
  ) async {
    final Map<String, Build> builds =
        await buildsForRepositoryAndPr(repositoryName, prNumber, commitSha);
    return builds.values
        .where((Build build) => failStatusSet.contains(build.status))
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
  Future<void> rescheduleBuild({
    @required String commitSha,
    @required String builderName,
    @required push_message.Build build,
    @required int retries,
  }) async {
    if (retries >= config.luciTryInfraFailureRetries) {
      // Too many retries.
      return;
    }
    await buildBucketClient.scheduleBuild(ScheduleBuildRequest(
      builderId: BuilderId(
        project: build.project,
        bucket: build.bucket,
        builder: builderName,
      ),
      tags: <String, List<String>>{
        'buildset': build.tagsByName('buildset'),
        'user_agent': build.tagsByName('user_agent'),
        'github_link': build.tagsByName('github_link'),
      },
      properties: (build.buildParameters['properties'] as Map<String, dynamic>)
          .cast<String, String>(),
      notify: NotificationConfig(
        pubsubTopic: 'projects/flutter-dashboard/topics/luci-builds',
        userData: json.encode(<String, dynamic>{
          'retries': retries + 1,
        }),
      ),
    ));
  }
}
