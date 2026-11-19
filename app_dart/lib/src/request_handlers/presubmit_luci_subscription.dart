// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_server/logging.dart';
import 'package:meta/meta.dart';

import '../../cocoon_service.dart';
import '../request_handling/exceptions.dart';
import '../service/luci_build_service/build_tags.dart';

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
final class PresubmitLuciSubscription extends PresubmitSubscription {
  /// Creates an endpoint for listening to unordered LUCI status updates.
  const PresubmitLuciSubscription({
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
  Future<bool> interceptBuild(BuildTags tags) async {
    final orderingKey = tags.getTagOfType<OrderingKeyTag>()?.orderingKey;
    if (orderingKey != null && orderingKey.isNotEmpty) {
      log.info(
        'Ordering key $orderingKey found, forwarding message to ordered-presubmit topic',
      );
      try {
        await pubsub.publish(
          'ordered-presubmit',
          message.data!,
          orderingKey: orderingKey,
        );
      } on HttpStatusException {
        rethrow;
      } catch (e, s) {
        log.error(
          'Failed to publish message to ordered-presubmit topic for ordering key $orderingKey',
          e,
          s,
        );
        throw InternalServerError('$e\n$s');
      }
      return true;
    }
    return false;
  }
}
