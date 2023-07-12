// Copyright 2022 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:auto_submit/requests/check_request.dart';
import 'package:auto_submit/service/approver_service.dart';
import 'package:auto_submit/service/log.dart';
import 'package:auto_submit/service/pull_request_validation_service.dart';
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
    final Set<int> processingLog = <int>{};
    final List<pub.ReceivedMessage> messageList = await pullMessages(
      pubSubSubscription,
      pubSubPulls,
      pubSubBatchSize,
    );
    if (messageList.isEmpty) {
      log.info('No messages are pulled.');
      return Response.ok('No messages are pulled.');
    }

    log.info('Processing ${messageList.length} messages');

    final PullRequestValidationService validationService = PullRequestValidationService(config);

    final List<Future<void>> futures = <Future<void>>[];

    for (pub.ReceivedMessage message in messageList) {
      log.info(message.toJson());
      assert(message.message != null);
      assert(message.message!.data != null);
      final String messageData = message.message!.data!;

      final Map<String, dynamic> rawBody =
          json.decode(String.fromCharCodes(base64.decode(messageData))) as Map<String, dynamic>;
      log.info('request raw body = $rawBody');

      final PullRequest pullRequest = PullRequest.fromJson(rawBody);

      log.info('Processing message ackId: ${message.ackId}');
      log.info('Processing mesageId: ${message.message!.messageId}');
      log.info('Processing PR: $rawBody');
      if (processingLog.contains(pullRequest.number)) {
        // Ack duplicate.
        log.info('Ack the duplicated message : ${message.ackId!}.');
        await pubsub.acknowledge(
          pubSubSubscription,
          message.ackId!,
        );

        continue;
      } else {
        final ApproverService approver = approverProvider(config);
        log.info('Checking auto approval of pull request: $rawBody');
        await approver.autoApproval(pullRequest);
        processingLog.add(pullRequest.number!);
      }

      futures.add(
        validationService.processMessage(pullRequest, message.ackId!, pubsub),
      );
    }
    await Future.wait(futures);
    return Response.ok('Finished processing changes');
  }
}
