// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:meta/meta.dart';
import 'package:retry/retry.dart';

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
    this.retryOptions = Config.schedulerRetry,
  }) : super(
          cache: cache,
          config: config,
          authProvider: authProvider,
          topicName: 'scheduler-requests',
        );

  final BuildBucketClient buildBucketClient;

  final RetryOptions retryOptions;

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

    /// Retry scheduling builds upto 3 times.
    ///
    /// Log error message when still failing after retry. Avoid endless rescheduling
    /// by acking the pub/sub message without throwing an exception.
    String? unScheduledBuilds;
    try {
      await retryOptions.retry(
        () async {
          final List<Request> requestsToRetry = await _sendBatchRequest(request);
          request = BatchRequest(requests: requestsToRetry);
          unScheduledBuilds = requestsToRetry.map((e) => e.scheduleBuild!.builderId.builder).toString();
          if (requestsToRetry.isNotEmpty) {
            throw InternalServerError('Failed to schedule builds: $unScheduledBuilds.');
          }
        },
        retryIf: (Exception e) => e is InternalServerError,
      );
    } catch (e) {
      log.warning('Failed to schedule builds: $unScheduledBuilds.');
      return Body.forString('Failed to schedule builds: $unScheduledBuilds.');
    }

    return Body.empty;
  }

  /// Wrapper around [BuildbucketClient.batch] to ensure all requests are made.
  ///
  /// Returns [List<Request>] of requests that need to be retried.
  Future<List<Request>> _sendBatchRequest(BatchRequest request) async {
    final BatchResponse response = await buildBucketClient.batch(request);
    log.fine('Made ${request.requests?.length} and received ${response.responses?.length}');
    log.fine('Responses: ${response.responses}');

    // By default, retry everything. Then remove requests with a verified response.
    final List<Request> retry = request.requests ?? <Request>[];
    response.responses?.forEach((Response subresponse) {
      if (subresponse.scheduleBuild != null) {
        retry
            .removeWhere((Request request) => request.scheduleBuild?.builderId == subresponse.scheduleBuild!.builderId);
      } else {
        log.warning('Response does not have schedule build: $subresponse');
      }
      if (subresponse.error?.code != 0) {
        log.fine('Non-zero grpc code: $subresponse');
      }
    });

    return retry;
  }
}
