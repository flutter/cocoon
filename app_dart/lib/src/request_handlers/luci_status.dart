// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:github/server.dart';
import 'package:meta/meta.dart';

import '../datastore/cocoon_config.dart';
import '../model/luci/push_message.dart';
import '../request_handling/body.dart';
import '../request_handling/request_handler.dart';
import '../service/buildbucket.dart';

/// An endpoint for listening to LUCI status updates for scheduled builds.
///
/// This endpoing is responsible for retrying a failed build if it has not been
/// retried, and for updating GitHub with the status of completed builds.
@immutable
class LuciStatusListener extends RequestHandler<Body> {
  /// Creates an endpoint for listening to LUCI status updates.
  const LuciStatusListener(Config config, this.buildBucketClient)
      : assert(buildBucketClient != null),
        super(config: config);

  /// A client for querying and scheduling LUCI Builds.
  final BuildBucketClient buildBucketClient;

  @override
  Future<Body> post() async {
    final String requestString = await utf8.decodeStream(request);
    final PushMessageEnvelope envelope = PushMessageEnvelope.fromJson(json.decode(requestString));
    final BuildPushMessage buildMessage =
        BuildPushMessage.fromJson(json.decode(envelope.message.data));
    switch (buildMessage.build.status) {
      case Status.completed:
        await _setCompletedStatus(
          buildMessage.build.buildParameters.builderName,
          buildMessage.build.result,
        );
        break;
      case Status.scheduled:
      case Status.started:
        await _setPendingStatus(buildMessage.build.buildParameters.builderName);
        break;
    }
    return Body.empty;
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

  Future<void> _setCompletedStatus(String context, Result result) async {
    final GitHub gitHubClient = await config.createGitHubClient();
    final RepositorySlug slug = RepositorySlug('flutter', 'flutter');
    const String ref = '';
    final CreateStatus status = _statusForResult(result)
      ..context = context
      ..description = 'Flutter LUCI Build: $context'
      ..targetUrl = 'https://ci.chromium.org/p/flutter';
    await gitHubClient.repositories.createStatus(slug, ref, status);
  }

  Future<void> _setPendingStatus(String context) async {
    final GitHub gitHubClient = await config.createGitHubClient();
    final RepositorySlug slug = RepositorySlug('flutter', 'flutter');
    const String ref = '';
    final CreateStatus status = CreateStatus('pending')
      ..context = context
      ..description = 'Flutter LUCI Build: $context'
      ..targetUrl = 'https://ci.chromium.org/p/flutter';
    await gitHubClient.repositories.createStatus(slug, ref, status);
  }
}
