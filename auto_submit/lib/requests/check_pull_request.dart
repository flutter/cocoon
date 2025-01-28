// Copyright 2022 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:auto_submit/requests/check_request.dart';
import 'package:auto_submit/service/approver_service.dart';
import 'package:auto_submit/service/pull_request_validation_service.dart';
import 'package:cocoon_server/logging.dart';
import 'package:github/github.dart';
import 'package:googleapis/pubsub/v1.dart' as pub;
import 'package:shelf/shelf.dart';

import '../request_handling/pubsub.dart';

/// Handler for processing pull requests with 'autosubmit' label.
///
/// For pull requests where an 'autosubmit' label was added in pubsub,
/// check if the pull request is mergable.
class CheckPullRequest extends CheckRequest {
  const CheckPullRequest({
    required super.config,
    required super.cronAuthProvider,
    super.approverProvider = ApproverService.defaultProvider,
    super.pubsub = const PubSub(),
  });

  @override
  Future<Response> get() async {
    return process(
      config.pubsubPullRequestSubscription,
      config.kPubsubPullNumber,
      config.kPullMesssageBatchSize,
    );
  }

  /// Process pull request messages from Pubsub.
  Future<Response> process(
    String pubSubSubscription,
    int pubSubPulls,
    int pubSubBatchSize,
  ) async {
    final crumb = '$CheckPullRequest(root)';

    final List<pub.ReceivedMessage> messages = await pullMessages(
      pubSubSubscription,
      pubSubPulls,
      pubSubBatchSize,
    );

    log.info('$crumb: pulled message batch of size ${messages.length}');

    if (messages.isEmpty) {
      log.info('$crumb: nothing to do, exiting.');
      return Response.ok('$crumb: nothing to do, exiting.');
    }

    final workItems = await _extractPullRequestFromMessages(pubSubSubscription, messages);

    // Process pull requests in parallel.
    final List<Future<void>> futures = <Future<void>>[];
    for (final workItem in workItems) {
      futures.add(_processPullRequest(workItem.pullRequest, workItem.ackId));
    }
    await Future.wait(futures);

    return Response.ok('Finished processing changes');
  }

  Future<List<({PullRequest pullRequest, String ackId})>> _extractPullRequestFromMessages(
    String pubSubSubscription,
    List<pub.ReceivedMessage> messages,
  ) async {
    final crumb = '$CheckPullRequest(root)';
    final workItems = <int, ({PullRequest pullRequest, String ackId})>{};

    for (pub.ReceivedMessage message in messages) {
      assert(message.message != null);
      assert(message.message!.data != null);
      log.info(
        '$crumb: processing message: '
        'id = ${message.message?.messageId}, '
        'ackId = ${message.ackId}, '
        'JSON = ${json.encode(message.toJson())}',
      );

      final messageData = message.message!.data!;
      final requestBodyJson = String.fromCharCodes(base64.decode(messageData));
      log.info('$crumb: request JSON = $requestBodyJson');

      final requestBody = json.decode(requestBodyJson) as Map<String, Object?>;
      final pullRequest = PullRequest.fromJson(requestBody);

      if (workItems.containsKey(pullRequest.number)) {
        // Duplicate pull request. This can happen, for example, when multiple
        // labels (say, "autosubmit" and "emergency") are added, each inducing a
        // pubsub message. Such batches do not need to be processed individually
        // because PullRequestValidationService will consider the entire state
        // of the PR and decide to submit it or not based on all the labels set
        // on it. So the message is deduplicated but still ackowledged so it is
        // not delivered again.
        log.info('$crumb: deduplicated pull request #${pullRequest.number}');
        await pubsub.acknowledge(pubSubSubscription, message.ackId!);
        continue;
      } else {
        workItems[pullRequest.number!] = (pullRequest: pullRequest, ackId: message.ackId!);
      }
    }

    return workItems.values.toList();
  }

  Future<void> _processPullRequest(PullRequest pullRequest, String ackId) async {
    final crumb = '$CheckPullRequest(${pullRequest.repo?.fullName}/${pullRequest.number})';
    log.info('$crumb: Processing PR: ${pullRequest.toJson()}');

    try {
      final approver = approverProvider(config);
      await approver.autoApproval(pullRequest);

      final validationService = PullRequestValidationService(config);
      await validationService.processMessage(pullRequest, ackId, pubsub);
    } catch (error, stackTrace) {
      // Log at severe level but do not rethrow. Because this loop processes a
      // batch of messages, one for each pull request, we don't want one pull
      // request to affect the outcome of processing other pull requests.
      // Because each message is acked individually, the successful ones will
      // be acked, and the failed ones will not, and will be retried by pubsub
      // later according to the retry policy set up in Cocoon.
      log.severe('''$crumb: failed to process message.

Pull request: https://github.com/${pullRequest.repo?.fullName}/${pullRequest.number}
Parsed pull request: ${pullRequest.toJson()}

Error: $error
$stackTrace
''');
    }
  }
}
