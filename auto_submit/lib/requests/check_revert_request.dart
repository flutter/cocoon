// Copyright 2023 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:auto_submit/request_handling/pubsub.dart';
import 'package:auto_submit/requests/check_request.dart';
import 'package:auto_submit/service/approver_service.dart';
import 'package:auto_submit/service/log.dart';
import 'package:auto_submit/service/revert_request_validation_service.dart';
import 'package:github/github.dart';
import 'package:googleapis/pubsub/v1.dart' as pub;
import 'package:shelf/shelf.dart';

// TODO (ricardoamador): provide implementation in https://github.com/flutter/flutter/issues/113867

/// Handler for processing pull requests with 'revert' label.
///
/// For pull requests where an 'revert' label was added in pubsub,
/// check if the revert request is mergable.
class CheckRevertRequest extends CheckRequest {
  const CheckRevertRequest({
    required super.config,
    required super.cronAuthProvider,
    super.approverProvider = ApproverService.defaultProvider,
    super.pubsub = const PubSub(),
  });

  @override
  Future<Response> get() async {
    /// Currently this is unused and cannot be called.
    return process(
      config.pubsubRevertRequestSubscription,
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

    final RevertRequestValidationService validationService = RevertRequestValidationService(config);

    final List<Future<void>> futures = <Future<void>>[];

    for (pub.ReceivedMessage message in messageList) {
      log.info(message.toJson());
      assert(message.message != null);
      assert(message.message!.data != null);
      final String messageData = message.message!.data!;

      final Map<String, dynamic> rawBody =
          json.decode(String.fromCharCodes(base64.decode(messageData))) as Map<String, dynamic>;
      log.info('request raw body = $rawBody');

      // Need to collect the sender so we know who to assign the original issue
      // to in the event the repo does not support review-less reverts.
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
        validationService.processMessage(
          // pullRequestMessage,
          pullRequest,
          message.ackId!,
          pubsub,
        ),
      );
    }
    await Future.wait(futures);
    return Response.ok('Finished processing changes');
  }
}
