// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:github/github.dart';
import 'package:meta/meta.dart';

import '../model/luci/push_message.dart';
import '../request_handling/authentication.dart';
import '../request_handling/body.dart';
import '../request_handling/subscription_handler.dart';
import '../service/buildbucket.dart';
import '../service/cache_service.dart';
import '../service/config.dart';
import '../service/github_checks_service.dart';
import '../service/logging.dart';
import '../service/luci_build_service.dart';

/// An endpoint for listening to LUCI status updates for scheduled builds.
///
/// [ScheduleBuildRequest.notify] property is set to tell LUCI to use this
/// PubSub topic. LUCI then publishes updates about build status to that topic,
/// which we listen to on the github-updater subscription. When new messages
/// arrive, they are posted to this web service.
///
/// The PubSub subscription is set up here:
/// https://console.cloud.google.com/cloudpubsub/subscription/detail/github-updater?project=flutter-dashboard
///
/// This endpoint is responsible for updating GitHub with the status of
/// completed builds from LUCI.
@immutable
class PresubmitLuciSubscription extends SubscriptionHandler {
  /// Creates an endpoint for listening to LUCI status updates.
  const PresubmitLuciSubscription(
    CacheService cache,
    Config config,
    this.buildBucketClient,
    this.luciBuildService,
    this.githubChecksService, {
    AuthenticationProvider? authProvider,
  }) : super(
          cache: cache,
          config: config,
          authProvider: authProvider,
          topicName: 'github-updater',
        );

  final BuildBucketClient buildBucketClient;
  final LuciBuildService luciBuildService;
  final GithubChecksService githubChecksService;

  @override
  Future<Body> post() async {
    RepositorySlug slug;
    final String data = message.data!;
    final BuildPushMessage buildPushMessage =
        BuildPushMessage.fromJson(json.decode(String.fromCharCodes(base64.decode(data))) as Map<String, dynamic>);
    final Build build = buildPushMessage.build!;
    final String builderName = build.tagsByName('builder').single;
    log.fine('Available tags: ${build.tags.toString()}');
    // Skip status update if we can not get the sha tag.
    if (build.tagsByName('buildset').isEmpty) {
      log.warning('Buildset tag not included, skipping Status Updates');
      return Body.empty;
    }
    log.fine('Setting status: ${buildPushMessage.toJson()} for $builderName');

    Map<String, dynamic> userData;
    try {
      userData = jsonDecode(buildPushMessage.userData!) as Map<String, dynamic>;
    } on FormatException {
      userData = jsonDecode(String.fromCharCodes(base64.decode(buildPushMessage.userData!))) as Map<String, dynamic>;
    }

    if (userData != null && userData.containsKey('repo_owner') && userData.containsKey('repo_name')) {
      // Message is coming from a github checks api enabled repo. We need to
      // create the slug from the data in the message and send the check status
      // update.
      slug = RepositorySlug(
        userData['repo_owner'] as String,
        userData['repo_name'] as String,
      );
      await githubChecksService.updateCheckStatus(
        buildPushMessage,
        luciBuildService,
        slug,
      );
    } else {
      log.shout('This repo does not support checks API');
    }
    return Body.empty;
  }
}
