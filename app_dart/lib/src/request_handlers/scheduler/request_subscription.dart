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
      final String rawJson = String.fromCharCodes(base64Decode(message.data!));
      log.info('rawJson: $rawJson');
      final Map<String, dynamic> json = jsonDecode(rawJson) as Map<String, dynamic>;
      request = BatchRequest.fromJson(json);
    } catch (e) {
      log.severe('Failed to construct BatchRequest from message');
      log.severe(e);
      throw BadRequestException(e.toString());
    }

    List<Request> requests = request.requests!;
    int attempts = 0;
    while (requests.isNotEmpty && attempts < config.schedulerRetries) {
      requests = await _sendRequest(BatchRequest(requests: requests));
      attempts += 1;
    }
    if (requests.isNotEmpty) {
      log.warning('Failed to send BatchRequest');
      log.warning(requests);
    }
    return Body.empty;
  }

  /// Internal wrapper around [BuildBucketClient.batch] to make it easily retryable.
  ///
  /// Returns [List<Request>] that exited with non-zero error codes or empty errors.
  Future<List<Request>> _sendRequest(BatchRequest batchRequest) async {
    log.fine('Sending BatchRequest');
    log.fine(batchRequest);
    final BatchResponse batchResponse = await buildBucketClient.batch(batchRequest);

    final List<Request> failedRequests = <Request>[];
    for (Response response in batchResponse.responses!) {
      if (response.error != null && response.error?.code != 0) {
        log.info('BatchResponse error: ${response.error}, code=${response.error?.code}');
        if (response.scheduleBuild?.builderId.builder != null) {
          final Request failedRequest = batchRequest.requests!.singleWhere((Request request) =>
              request.scheduleBuild?.builderId.builder == response.scheduleBuild?.builderId.builder);
          failedRequests.add(failedRequest);
        }
      }
    }
    return failedRequests;
  }
}
