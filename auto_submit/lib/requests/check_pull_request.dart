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

  ///TODO refactor this method out into the base class.
  /// Process pull request messages from Pubsub.
  Future<Response> process(
    String pubSubSubscription,
    int pubSubPulls,
    int pubSubBatchSize,
  ) async {
    final rootCrumb = '$CheckPullRequest(root)';

    final Set<int> processingLog = <int>{};
    final List<pub.ReceivedMessage> messageList = await pullMessages(
      pubSubSubscription,
      pubSubPulls,
      pubSubBatchSize,
    );
    if (messageList.isEmpty) {
      log.info('$rootCrumb: No messages are pulled.');
      return Response.ok('No messages are pulled.');
    }

    log.info('$rootCrumb: Processing ${messageList.length} messages');

    final List<Future<void>> futures = <Future<void>>[];

    for (pub.ReceivedMessage message in messageList) {
      log.info('$rootCrumb: ${message.toJson()}');
      assert(message.message != null);
      assert(message.message!.data != null);
      final String messageData = message.message!.data!;

      final Map<String, dynamic> rawBody =
          json.decode(String.fromCharCodes(base64.decode(messageData))) as Map<String, dynamic>;
      log.info('$rootCrumb: request raw body = $rawBody');

      final pullRequest = PullRequest.fromJson(rawBody);
      final prCrumb = '$CheckPullRequest(${pullRequest.repo?.fullName}/${pullRequest.number})';

      log.info('$prCrumb: Processing message ackId: ${message.ackId}');
      log.info('$prCrumb: Processing mesageId: ${message.message!.messageId}');
      log.info('$prCrumb: Processing PR: ${pullRequest.toJson()}');

      if (processingLog.contains(pullRequest.number)) {
        // Ack duplicate.
        log.info('$prCrumb: Ack the duplicated message : ${message.ackId!}.');
        await pubsub.acknowledge(
          pubSubSubscription,
          message.ackId!,
        );

        continue;
      } else {
        final ApproverService approver = approverProvider(config);
        log.info('$prCrumb: Checking auto approval of pull request: $rawBody');
        await approver.autoApproval(pullRequest);
        processingLog.add(pullRequest.number!);
      }

      // Log at severe level but do not rethrow. Because this loop processes a
      // batch of messages, one for each pull request, we don't want one pull
      // request to affect the outcome of processing other pull requests.
      // Because each message is acked individually, the successful ones will
      // be acked, and the failed ones will not, and will be retried by pubsub
      // later according to the retry policy set up in Cocoon.
      Future<void> onError(Object? error, Object? stackTrace) async {
        log.severe('''$prCrumb: failed to process message.

Pull request: https://github.com/${pullRequest.repo?.fullName}/${pullRequest.number}
Parsed pull request: ${pullRequest.toJson()}

Error: $error
$stackTrace
''');
      }

      final PullRequestValidationService validationService = PullRequestValidationService(config);
      final processFuture = validationService.processMessage(pullRequest, message.ackId!, pubsub).catchError(onError);
      futures.add(processFuture);
    }
    await Future.wait(futures);
    return Response.ok('Finished processing changes');
  }
}
