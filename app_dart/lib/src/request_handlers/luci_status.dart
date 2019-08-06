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
import '../model/luci/push_message.dart';
import '../request_handling/body.dart';
import '../request_handling/exceptions.dart';
import '../request_handling/request_handler.dart';

/// An endpoint for listening to LUCI status updates for scheduled builds.
///
/// This endpoing is responsible for retrying a failed build if it has not been
/// retried, and for updating GitHub with the status of completed builds.
///
/// The PubSub subscription is set up here:
/// https://console.cloud.google.com/cloudpubsub/subscription/detail/github-updater?project=flutter-dashboard
///
/// This currently uses the GitHub Status API, but could be refactored at some
/// point to use the Checks API, which may offer some more knobs to turn
/// on the GitHub page. In particular, it might offer a nice way to retry a
/// failed build - which right now would require removing and re-applying the
/// label, or pushing a new commit.
@immutable
class LuciStatusHandler extends RequestHandler<Body> {
  /// Creates an endpoint for listening to LUCI status updates.
  const LuciStatusHandler(Config config) : super(config: config);

  @override
  Future<Body> post() async {
    if (!await _authenticateRequest(request.headers)) {
      throw const Unauthorized();
    }
    final String requestString = await utf8.decodeStream(request);
    final PushMessageEnvelope envelope = PushMessageEnvelope.fromJson(
      json.decode(requestString),
    );
    final BuildPushMessage buildMessage =
        BuildPushMessage.fromJson(json.decode(envelope.message.data));
    final Build build = buildMessage.build;
    final String builderName = build.tagsByName('builder').single;

    const String shaPrefix = 'sha/git/';
    final String sha = build
        .tagsByName('buildset')
        .firstWhere((String tag) => tag.startsWith(shaPrefix))
        .substring(shaPrefix.length);

    switch (buildMessage.build.status) {
      case Status.completed:
        await _setCompletedStatus(
          ref: sha,
          builderName: builderName,
          buildUrl: build.url,
          result: build.result,
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
    final ServiceAccountInfo devicelabServiceAccount = await config.deviceLabServiceAccount;
    return info.email == devicelabServiceAccount.email;
  }

  Future<RepositorySlug> _getRepoNameForBuilder(String builderName) async {
    final List<Map<String, dynamic>> builders = await config.luciBuilders;
    final String repoName = builders
        .firstWhere((Map<String, dynamic> builder) => builder['name'] == builderName)['repo'];
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
    await for (RepositoryStatus status in gitHubClient.repositories.listStatuses(slug, ref)) {
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
      ..targetUrl = buildUrl;
    await gitHubClient.repositories.createStatus(slug, ref, status);
  }
}
