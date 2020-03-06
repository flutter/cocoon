// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:github/server.dart';
import 'package:googleapis/oauth2/v2.dart';
import 'package:http/http.dart' as http;
import 'package:meta/meta.dart';

import '../datastore/cocoon_config.dart';
import '../model/appengine/service_account_info.dart';
import '../model/luci/buildbucket.dart' as bb;
import '../model/luci/push_message.dart';
import '../request_handling/body.dart';
import '../request_handling/exceptions.dart';
import '../request_handling/request_handler.dart';
import '../service/buildbucket.dart';

/// An endpoint for listening to LUCI status updates for scheduled builds.
///
/// The [ScheduleBuildRequest.notify] property is set to tell LUCI to use our
/// PubSub topic. LUCI then publishes updates about build status to that topic,
/// which we listen to on the github-updater subscription. When new messages
/// arrive, they are posted to this web service.
///
/// The PubSub subscription is set up here:
/// https://console.cloud.google.com/cloudpubsub/subscription/detail/github-updater?project=flutter-dashboard
///
/// This endpoing is responsible for updating GitHub with the status of
/// completed builds.
///
/// This currently uses the GitHub Status API, but could be refactored at some
/// point to use the Checks API, which may offer some more knobs to turn
/// on the GitHub page. In particular, it might offer a nice way to retry a
/// failed build - which right now would require removing and re-applying the
/// label, or pushing a new commit.
@immutable
class LuciStatusHandler extends RequestHandler<Body> {
  /// Creates an endpoint for listening to LUCI status updates.
  const LuciStatusHandler(Config config, this.buildBucketClient)
      : assert(buildBucketClient != null),
        super(config: config);

  final BuildBucketClient buildBucketClient;

  @override
  Future<Body> post() async {
    if (!await _authenticateRequest(request.headers)) {
      throw const Unauthorized();
    }
    final String requestString = await utf8.decodeStream(request);
    final PushMessageEnvelope envelope = PushMessageEnvelope.fromJson(
      json.decode(requestString) as Map<String, dynamic>,
    );
    final BuildPushMessage buildMessage = BuildPushMessage.fromJson(
        json.decode(envelope.message.data) as Map<String, dynamic>);
    final Build build = buildMessage.build;
    final Map<String, dynamic> userData =
        jsonDecode(buildMessage.userData) as Map<String, dynamic>;
    final String builderName = build.tagsByName('builder').single;

    const String shaPrefix = 'sha/git/';
    final String sha = build
        .tagsByName('buildset')
        .firstWhere((String tag) => tag.startsWith(shaPrefix))
        .substring(shaPrefix.length);

    switch (buildMessage.build.status) {
      case Status.completed:
        await _rescheduleOrMarkCompleted(
          sha: sha,
          builderName: builderName,
          build: build,
          retries: userData['retries'] as int,
        );
        break;
      case Status.scheduled:
      case Status.started:
        await _setPendingStatus(
          ref: sha,
          builderName: builderName,
          buildUrl: build.url,
        );
        break;
    }
    return Body.empty;
  }

  /// Reschedules jobs that failed for infra reasons up to
  /// [CocoonConfig.luciTryInfraFailureRetries] times, and updates statuses on
  /// GitHub for all other cases.
  Future<void> _rescheduleOrMarkCompleted({
    @required String sha,
    @required String builderName,
    @required Build build,
    @required int retries,
  }) async {
    assert(sha != null);
    assert(builderName != null);
    assert(build != null);
    if (build.result == Result.failure) {
      switch (build.failureReason) {
        case FailureReason.buildbucketFailure:
        case FailureReason.infraFailure:
          // infra failed
          await _rescheduleBuild(
            sha: sha,
            builderName: builderName,
            build: build,
            retries: retries,
          );
          return;
        case FailureReason.invalidBuildDefinition:
        case FailureReason.buildFailure:
          // the commit failed
          break;
      }
    }
    await _setCompletedStatus(
      ref: sha,
      builderName: builderName,
      buildUrl: build.url,
      result: build.result,
    );
  }

  /// Sends a [BuildBucket.scheduleBuild] request as long as the `retries`
  /// parameter has not exceeded [CocoonConfig.luciTryInfraFailureRetries].
  ///
  /// If the retries have been exhausted, it sets the GitHub status to failure.
  ///
  /// The buildset, user_agent, and github_link tags are applied to match the
  /// original build. The build properties from the original build are also
  /// preserved.
  Future<void> _rescheduleBuild({
    @required String sha,
    @required String builderName,
    @required Build build,
    @required int retries,
  }) async {
    if (retries >= config.luciTryInfraFailureRetries) {
      // Too many retries.
      await _setCompletedStatus(
        ref: sha,
        builderName: builderName,
        buildUrl: build.url,
        result: build.result,
      );
      return;
    }
    await buildBucketClient.scheduleBuild(bb.ScheduleBuildRequest(
      builderId: bb.BuilderId(
        project: build.project,
        bucket: 'try',
        builder: builderName,
      ),
      tags: <String, List<String>>{
        'buildset': build.tagsByName('buildset'),
        'user_agent': build.tagsByName('user_agent'),
        'github_link': build.tagsByName('github_link'),
      },
      properties: (build.buildParameters['properties'] as Map<String, dynamic>)
          .cast<String, String>(),
      notify: bb.NotificationConfig(
        pubsubTopic: 'projects/flutter-dashboard/topics/luci-builds',
        userData: json.encode(<String, dynamic>{
          'retries': retries + 1,
        }),
      ),
    ));
  }

  Future<bool> _authenticateRequest(HttpHeaders headers) async {
    final http.Client client = httpClient;
    final Oauth2Api oauth2api = Oauth2Api(client);
    final String idToken = headers.value(HttpHeaders.authorizationHeader);
    if (idToken == null || !idToken.startsWith('Bearer ')) {
      return false;
    }
    final Tokeninfo info = await oauth2api.tokeninfo(
      idToken: idToken.substring('Bearer '.length),
    );
    if (info.expiresIn == null || info.expiresIn < 1) {
      return false;
    }
    final ServiceAccountInfo devicelabServiceAccount =
        await config.deviceLabServiceAccount;
    return info.email == devicelabServiceAccount.email;
  }

  Future<RepositorySlug> _getRepoNameForBuilder(String builderName) async {
    final List<Map<String, dynamic>> builders = config.luciTryBuilders;
    final String repoName = builders.firstWhere(
        (Map<String, dynamic> builder) =>
            builder['name'] == builderName)['repo'] as String;
    return RepositorySlug('flutter', repoName);
  }

  CreateStatus _statusForResult(Result result) {
    switch (result) {
      case Result.canceled:
      case Result.failure:
        return CreateStatus('failure');
        break;
      case Result.success:
        return CreateStatus('success');
        break;
    }
    throw StateError('unreachable');
  }

  Future<void> _setCompletedStatus({
    @required String ref,
    @required String builderName,
    @required String buildUrl,
    @required Result result,
  }) async {
    final RepositorySlug slug = await _getRepoNameForBuilder(builderName);
    final GitHub gitHubClient = await config.createGitHubClient();
    final CreateStatus status = _statusForResult(result)
      ..context = builderName
      ..description = 'Flutter LUCI Build: $builderName'
      ..targetUrl = buildUrl;
    await gitHubClient.repositories.createStatus(slug, ref, status);
  }

  Future<void> _setPendingStatus({
    @required String ref,
    @required String builderName,
    @required String buildUrl,
  }) async {
    final RepositorySlug slug = await _getRepoNameForBuilder(builderName);
    final GitHub gitHubClient = await config.createGitHubClient();
    // GitHub "only" allows setting a status for a context/ref pair 1000 times.
    // We should avoid unnecessarily setting a pending status, e.g. if we get
    // started and pending messages close together.
    // We have to check for both because sometimes one or the other might come
    // in.
    // However, we should keep going if the _most recent_ status is not pending.
    await for (RepositoryStatus status
        in gitHubClient.repositories.listStatuses(slug, ref)) {
      if (status.context == builderName) {
        if (status.state == 'pending') {
          return;
        }
        break;
      }
    }

    final CreateStatus status = CreateStatus('pending')
      ..context = builderName
      ..description = 'Flutter LUCI Build: $builderName'
      ..targetUrl = '$buildUrl${buildUrl.contains('?') ? '&' : '?'}reload=30';
    await gitHubClient.repositories.createStatus(slug, ref, status);
  }
}
