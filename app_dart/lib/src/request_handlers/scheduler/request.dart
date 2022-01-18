// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:typed_data';

import 'package:meta/meta.dart';

import '../../../cocoon_service.dart';
import '../../model/luci/buildbucket.dart';
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
class SchedulerRequest extends SubscriptionHandler {
  /// Creates a subscription for sending BuildBucket requests.
  const SchedulerRequest(
    this.cache,
    Config config,
    AuthenticationProvider authenticationProvider, {
    required this.buildBucketClient,
  }) : super(config: config, authenticationProvider: authenticationProvider);

  final BuildBucketClient buildBucketClient;
  final CacheService cache;

  static const String topicName = 'scheduler-requests';

  @override
  Future<Body> post() async {
    // Store id in [Cache].
    final String messageId = (await message)!.messageId!;
    final Uint8List? messageEntry = await cache.getOrCreate(topicName, messageId);
    
    final String rawJson = (await message)!.data!;
    final Map<String, dynamic> json = jsonDecode(rawJson) as Map<String, dynamic>;
    final BatchRequest request = BatchRequest.fromJson(json);
    final BatchResponse response = await buildBucketClient.batch(request);
    response.responses?.map((Response subresponse) {
      if (subresponse.error?.code != 0) {
        log.fine('Non-zero grpc code: $subresponse');
      }
    });

    return Body.empty;
  }
}
