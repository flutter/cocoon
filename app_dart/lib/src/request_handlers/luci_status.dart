// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:appengine/appengine.dart';
import 'package:cocoon_service/src/foundation/providers.dart';
import 'package:cocoon_service/src/service/buildbucket.dart';
import 'package:cocoon_service/src/service/github_status_service.dart';
import 'package:cocoon_service/src/service/luci_build_service.dart';
import 'package:googleapis/oauth2/v2.dart';
import 'package:http/http.dart' as http;
import 'package:meta/meta.dart';

import '../datastore/cocoon_config.dart';
import '../foundation/typedefs.dart';
import '../model/appengine/service_account_info.dart';
import '../model/luci/push_message.dart';
import '../request_handling/body.dart';
import '../request_handling/exceptions.dart';
import '../request_handling/request_handler.dart';

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
  const LuciStatusHandler(
    Config config,
    this.buildBucketClient, {
    LoggingProvider loggingProvider,
  })  : assert(buildBucketClient != null),
        loggingProvider = loggingProvider ?? Providers.serviceScopeLogger,
        super(config: config);

  final BuildBucketClient buildBucketClient;
  final LoggingProvider loggingProvider;

  @override
  Future<Body> post() async {
    final ServiceAccountInfo serviceAccountInfo =
        await config.deviceLabServiceAccount;
    final LuciBuildService luciBuildService =
        LuciBuildService(config, buildBucketClient, serviceAccountInfo);
    final Logging log = loggingProvider();
    final GithubStatusService githubStatusService =
        GithubStatusService(config, luciBuildService);

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
    log.debug('Setting status: ${buildMessage.toJson()} for $builderName');
    switch (buildMessage.build.status) {
      case Status.completed:
        await _rescheduleOrMarkCompleted(
          sha: sha,
          builderName: builderName,
          build: build,
          retries: userData['retries'] as int,
          luciBuildService: luciBuildService,
          githubStatusService: githubStatusService,
        );
        break;
      case Status.scheduled:
      case Status.started:
        await githubStatusService.setPendingStatus(
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
  Future<void> _rescheduleOrMarkCompleted(
      {@required String sha,
      @required String builderName,
      @required Build build,
      @required int retries,
      @required LuciBuildService luciBuildService,
      @required GithubStatusService githubStatusService}) async {
    assert(sha != null);
    assert(builderName != null);
    assert(build != null);
    if (build.result == Result.failure) {
      switch (build.failureReason) {
        case FailureReason.buildbucketFailure:
        case FailureReason.infraFailure:
          log.info('Retrying: $builderName for $sha');
          final bool rescheduled = await luciBuildService.rescheduleBuild(
            commitSha: sha,
            builderName: builderName,
            build: build,
            retries: retries,
          );
          if (rescheduled) {
            await githubStatusService.setPendingStatus(
              ref: sha,
              builderName: builderName,
              buildUrl: '',
            );
            return;
          }
          break;
        case FailureReason.invalidBuildDefinition:
        case FailureReason.buildFailure:
          break;
      }
    }
    await githubStatusService.setCompletedStatus(
      ref: sha,
      builderName: builderName,
      buildUrl: build.url,
      result: build.result,
    );
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
}
