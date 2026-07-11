// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:buildbucket/buildbucket_pb.dart' as bbv2;
import 'package:cocoon_server/logging.dart';
import 'package:meta/meta.dart';

import '../../cocoon_service.dart';
import '../service/luci_build_service/build_tags.dart';
import '../service/luci_build_service/user_data.dart';

/// An endpoint for listening to LUCI status updates for scheduled builds.
///
/// [ScheduleBuildRequest.notify] property is set to tell LUCI to use this
/// PubSub topic. LUCI then publishes updates about build status to that topic,
/// which we listen to on the github-updater subscription. When new messages
/// arrive, they are posted to this web service.
///
/// The PubSub subscription is set up here:
/// https://console.cloud.google.com/cloudpubsub/subscription/detail/build-bucket-presubmit-sub?project=flutter-dashboard
///
/// This endpoint is responsible for updating GitHub with the status of
/// completed builds from LUCI.
@immutable
final class PresubmitLuciSubscriptionUnordered
    extends PresubmitLuciSubscription {
  /// Creates an endpoint for listening to unordered LUCI status updates.
  const PresubmitLuciSubscriptionUnordered({
    required super.cache,
    required super.config,
    required super.luciBuildService,
    required super.githubChecksService,
    required super.ciYamlFetcher,
    required super.scheduler,
    required super.firestore,
    this.pubsub = const PubSub(),
    super.authProvider,
  }) : super(subscriptionName: 'build-bucket-presubmit-sub');

  final PubSub pubsub;

  @override
  Future<Response> post(Request request) async {
    if (message.data == null) {
      log.info('no data in message');
      return Response.emptyOk;
    }

    final pubSubCallBack = bbv2.PubSubCallBack();
    pubSubCallBack.mergeFromProto3Json(
      jsonDecode(message.data!) as Map<String, dynamic>,
    );

    final buildsPubSub = pubSubCallBack.buildPubsub;

    if (!buildsPubSub.hasBuild()) {
      log.info('no build information in message');
      return Response.emptyOk;
    }

    final build = buildsPubSub.build;

    // Add build fields that are stored in a separate compressed buffer.
    build.mergeFromBuffer(
      const ZLibDecoder().decodeBytes(buildsPubSub.buildLargeFields),
    );

    final builderName = build.builder.builder;
    final tagSet = BuildTags.fromStringPairs(build.tags);

    log.info('Available tags: ${build.tags}');

    // Skip status update if we can not get the sha tag.
    if (tagSet.buildTags.whereType<BuildSetBuildTag>().isEmpty) {
      log.warn('Buildset tag not included, skipping Status Updates');
      return Response.emptyOk;
    }

    log.info(
      'Setting status (${build.status}) for build id: ${build.id} named: $builderName',
    );

    if (!pubSubCallBack.hasUserData()) {
      log.info('No user data was found in this request');
      return Response.emptyOk;
    }

    final userData = PresubmitUserData.fromBytes(pubSubCallBack.userData);
    log.info('User Data Json: ${userData.toJson()}');

    final orderingKey = tagSet.getTagOfType<OrderingKeyTag>()?.orderingKey;
    if (orderingKey != null) {
      log.info(
        'Ordering key $orderingKey found, forwarding message to ordered-presubmit topic',
      );
      await pubsub.publish(
        'ordered-presubmit',
        message.data!,
        orderingKey: orderingKey,
      );
      return Response.emptyOk;
    }

    await processBuild(build: build, userData: userData, tagSet: tagSet);
    return Response.emptyOk;
  }
}
