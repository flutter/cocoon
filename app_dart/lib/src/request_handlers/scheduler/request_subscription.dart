// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:meta/meta.dart';

import '../../../cocoon_service.dart';
import '../../model/luci/buildbucket.dart';
import '../../request_handling/exceptions.dart';
import '../../request_handling/subscription_handler.dart';
import '../../service/logging.dart';

/// Subscription for making requests to BuildBucket.
///
/// The PubSub subscription is set up here:
/// https://cloud.google.com/cloudpubsub/subscription/detail/scheduler-requests?project=flutter-dashboard&tab=overview
///
/// This endpoint allows Cocoon to defer BuildBucket requests off the main request loop. This is critical when new
/// commits are pushed, and they can schedule 100+ builds at once.
///
/// This endpoint takes in a POST request with the JSON of a [BatchRequest]. In practice, the
/// [BatchRequest] should contain a single request.
@immutable
class SchedulerRequestSubscription extends SubscriptionHandler {
  /// Creates a subscription for sending BuildBucket requests.
  const SchedulerRequestSubscription({
    required CacheService cache,
    required Config config,
    required this.buildBucketClient,
    AuthenticationProvider? authProvider,
  }) : super(
          cache: cache,
          config: config,
          authProvider: authProvider,
          topicName: 'scheduler-requests',
        );

  final BuildBucketClient buildBucketClient;

  @override
  Future<Body> post() async {
    BatchRequest request;
    try {
      final String rawJson = message.data!;
      log.info('rawJson: $rawJson');
      final Map<String, dynamic> json = jsonDecode(rawJson) as Map<String, dynamic>;
      request = BatchRequest.fromJson(json);
    } catch (e) {
      log.severe('Failed to construct BatchRequest from message');
      log.severe(e);
      throw BadRequestException(e.toString());
    }

    final BatchResponse response = await buildBucketClient.batch(request);
    response.responses?.map((Response subresponse) {
      if (subresponse.error?.code != 0) {
        log.fine('Non-zero grpc code: $subresponse');
      }
    });

    return Body.empty;
  }
}
