// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:buildbucket/buildbucket_pb.dart' as bbv2;
import 'package:cocoon_server/logging.dart';
import 'package:collection/collection.dart';
import 'package:github/github.dart';
import 'package:meta/meta.dart';
import 'package:retry/retry.dart';

import '../../../cocoon_service.dart';
import '../../request_handling/exceptions.dart';
import '../../request_handling/subscription_handler.dart';

/// Subscription for making requests to BuildBucket.
///
/// The PubSub subscription is set up here:
/// https://console.cloud.google.com/cloudpubsub/subscription/detail/cocoon-scheduler-requests-sub?project=flutter-dashboard
///
/// This endpoint allows Cocoon to defer BuildBucket requests off the main request loop. This is critical when new
/// commits are pushed, and they can schedule 100+ builds at once.
///
/// This endpoint takes in a POST request with the JSON of a [bbv2.BatchRequest]. In practice, the
/// [bbv2.BatchRequest] should contain a single request.
@immutable
class SchedulerRequestSubscription extends SubscriptionHandler {
  /// Creates a subscription for sending BuildBucket requests.
  const SchedulerRequestSubscription({
    required super.cache,
    required super.config,
    required this.buildBucketClient,
    super.authProvider,
    this.retryOptions = Config.schedulerRetry,
  }) : super(subscriptionName: 'cocoon-scheduler-requests-sub');

  final BuildBucketClient buildBucketClient;

  final RetryOptions retryOptions;

  @override
  Future<Body> post() async {
    if (message.data == null) {
      log2.info('no data in message');
      throw const BadRequestException('no data in message');
    }

    // final String data = message.data!;
    log2.debug('attempting to read message ${message.data}');

    final batchRequest = bbv2.BatchRequest.create();

    // Merge from json only works with the integer field names.
    batchRequest.mergeFromProto3Json(
      jsonDecode(message.data!) as Map<String, dynamic>,
    );

    log2.info(
      'Read the following data: ${batchRequest.toProto3Json().toString()}',
    );

    /// Retry scheduling builds upto 3 times.
    ///
    /// Log error message when still failing after retry. Avoid endless rescheduling
    /// by acking the pub/sub message without throwing an exception.
    ///
    /// Inform check_runs of failures so they are not infinitely scheduled.
    final errors = <String>[];
    var unscheduledWarning = '';
    try {
      await retryOptions.retry(() async {
        final requestsToRetry = await _sendBatchRequest(batchRequest);

        // Reset the batch requests to retry scheduling of failed entries.
        batchRequest.requests.clear();
        batchRequest.requests.addAll(requestsToRetry.retries);
        errors
          ..clear()
          ..addAll(requestsToRetry.errors);
        if (requestsToRetry.retries.isNotEmpty) {
          unscheduledWarning =
              '${requestsToRetry.retries.map((e) => e.scheduleBuild.builder)}';
          throw InternalServerError(
            'Failed to schedule builds: $unscheduledWarning.',
          );
        }
      }, retryIf: (Exception e) => e is InternalServerError);
    } catch (e) {
      log2.warn(
        'Failed to schedule builds on exception: $unscheduledWarning.',
        e,
      );

      await _failUnscheduledCheckRuns(batchRequest, errors);

      return Body.forString('Failed to schedule builds: $unscheduledWarning.');
    }

    return Body.empty;
  }

  Future<void> _failUnscheduledCheckRuns(
    bbv2.BatchRequest batchRequest,
    List<String> errors,
  ) async {
    for (var failed in batchRequest.requests) {
      final url =
          failed.scheduleBuild.properties.fields['git_url']?.stringValue;
      final builder = failed.scheduleBuild.builder.builder;
      final checkRunId =
          failed.scheduleBuild.tags
              .firstWhereOrNull((t) => t.key == 'github_checkrun')
              ?.value;
      final pathSegments = Uri.tryParse(url ?? '')?.pathSegments ?? [];
      if (url == null ||
          pathSegments.length != 2 ||
          int.tryParse(checkRunId ?? '') == null) {
        log2.warn('missing url / github_checkrun for $builder');
        continue;
      }

      final slug = RepositorySlug(pathSegments[0], pathSegments[1]);
      final githubService = await config.createGithubService(slug);
      final checkRun = CheckRun.fromJson({
        'id': int.parse(checkRunId!),
        'status': CheckRunStatus.completed,
        'check_suite': const {'id': null},
        'started_at': '${DateTime.now()}',
        'conclusion': null,
        'name': builder,
      });

      await githubService.updateCheckRun(
        slug: slug,
        checkRun: checkRun,
        status: CheckRunStatus.completed,
        conclusion: CheckRunConclusion.failure,
        output: CheckRunOutput(
          title: 'Failed to schedule build',
          summary: '''
Failed to schedule `$builder`:

```
${errors.isEmpty ? 'unknown' : errors.map((t) => t.trim()).join('\n')}
```
''',
        ),
      );
    }
  }

  /// Returns [List<bbv2.BatchRequest_Request>] of requests that need to be retried.
  Future<({List<bbv2.BatchRequest_Request> retries, List<String> errors})>
  _sendBatchRequest(bbv2.BatchRequest request) async {
    log2.info('Sending batch request for ${request.toProto3Json().toString()}');

    final errors = <String>[];

    bbv2.BatchResponse response;
    try {
      response = await buildBucketClient.batch(request);
    } catch (e) {
      log2.error('Exception making batch Requests.', e);
      rethrow;
    }

    log2.info(
      'Made ${request.requests.length} and received ${response.responses.length}',
    );
    log2.info('Responses: ${response.responses}');

    final retry = <bbv2.BatchRequest_Request>[...request.requests];
    for (final batchResponseResponse in response.responses) {
      if (batchResponseResponse.hasScheduleBuild()) {
        retry.removeWhere(
          (t) =>
              t.scheduleBuild.builder ==
              batchResponseResponse.scheduleBuild.builder,
        );
      } else {
        log2.warn(
          'Response does not have schedule build: $batchResponseResponse',
        );
        errors.add('$batchResponseResponse');
      }

      if (batchResponseResponse.hasError() &&
          batchResponseResponse.error.code != 0) {
        log2.info('Non-zero grpc code: $batchResponseResponse');
      }
    }

    return (retries: retry, errors: errors);
  }
}
