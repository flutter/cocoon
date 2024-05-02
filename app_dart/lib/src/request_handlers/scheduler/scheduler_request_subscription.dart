// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:cocoon_service/src/request_handling/subscription_handler_v2.dart';
import 'package:meta/meta.dart';
import 'package:retry/retry.dart';

import '../../../cocoon_service.dart';
import 'package:buildbucket/buildbucket_pb.dart' as bbv2;
import '../../request_handling/exceptions.dart';
import '../../service/logging.dart';

/// Subscription for making requests to BuildBucket.
///
/// The PubSub subscription is set up here:
/// https://console.cloud.google.com/cloudpubsub/subscription/detail/cocoon-scheduler-requests?project=flutter-dashboard
///
/// This endpoint allows Cocoon to defer BuildBucket requests off the main request loop. This is critical when new
/// commits are pushed, and they can schedule 100+ builds at once.
///
/// This endpoint takes in a POST request with the JSON of a [bbv2.BatchRequest]. In practice, the
/// [bbv2.BatchRequest] should contain a single request.
@immutable
class SchedulerRequestSubscriptionV2 extends SubscriptionHandlerV2 {
  /// Creates a subscription for sending BuildBucket requests.
  const SchedulerRequestSubscriptionV2({
    required super.cache,
    required super.config,
    required this.buildBucketClient,
    super.authProvider,
    this.retryOptions = Config.schedulerRetry,
  }) : super(subscriptionName: 'cocoon-scheduler-requests-sub');

  final BuildBucketV2Client buildBucketClient;

  final RetryOptions retryOptions;

  @override
  Future<Body> post() async {
    if (message.data == null) {
      log.info('no data in message');
      throw const BadRequestException('no data in message');
    }

    // final String data = message.data!;
    log.fine('attempting to read message ${message.data}');

    final bbv2.BatchRequest batchRequest = bbv2.BatchRequest.create();

    // Merge from json only works with the integer field names.
    batchRequest.mergeFromProto3Json(jsonDecode(message.data!) as Map<String, dynamic>);

    log.info('Read the following data: ${batchRequest.toProto3Json().toString()}');

    /// Retry scheduling builds upto 3 times.
    ///
    /// Log error message when still failing after retry. Avoid endless rescheduling
    /// by acking the pub/sub message without throwing an exception.
    String? unscheduledBuilds;
    try {
      await retryOptions.retry(
        () async {
          final List<bbv2.BatchRequest_Request> requestsToRetry = await _sendBatchRequest(batchRequest);

          // Make a copy of the requests that are passed in as if simply access the list
          // we make changes for all instances.
          final List<bbv2.BatchRequest_Request> requestListCopy = [];
          requestListCopy.addAll(requestsToRetry);
          batchRequest.requests.clear();
          batchRequest.requests.addAll(requestListCopy);

          unscheduledBuilds = requestsToRetry.map((e) => e.scheduleBuild.builder).toString();
          if (requestsToRetry.isNotEmpty) {
            throw InternalServerError('Failed to schedule builds: $unscheduledBuilds.');
          }
        },
        retryIf: (Exception e) => e is InternalServerError,
      );
    } catch (e) {
      log.warning('Failed to schedule builds on exception: $unscheduledBuilds.');
      return Body.forString('Failed to schedule builds: $unscheduledBuilds.');
    }

    return Body.empty;
  }

  /// Returns [List<bbv2.BatchRequest_Request>] of requests that need to be retried.
  Future<List<bbv2.BatchRequest_Request>> _sendBatchRequest(bbv2.BatchRequest request) async {
    log.info('Sending batch request for ${request.toProto3Json().toString()}');

    bbv2.BatchResponse response;
    try {
      response = await buildBucketClient.batch(request);
    } catch (e) {
      log.severe('Exception making batch Requests.');
      rethrow;
    }

    log.info('Made ${request.requests.length} and received ${response.responses.length}');
    log.info('Responses: ${response.responses}');

    // By default, retry everything. Then remove requests with a verified response.
    // THese are the requests in the batch request object. Just requests.
    final List<bbv2.BatchRequest_Request> retry = request.requests;

    for (bbv2.BatchResponse_Response batchResponseResponse in response.responses) {
      if (batchResponseResponse.hasScheduleBuild()) {
        retry.removeWhere((element) => batchResponseResponse.scheduleBuild.builder == element.scheduleBuild.builder);
      } else {
        log.warning('Response does not have schedule build: $batchResponseResponse');
      }

      if (batchResponseResponse.hasError() && batchResponseResponse.error.code != 0) {
        log.info('Non-zero grpc code: $batchResponseResponse');
      }
    }

    return retry;
  }
}
