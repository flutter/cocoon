// Copyright 2022 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:auto_submit/service/approver_service.dart';
import 'package:github/github.dart';
import 'package:googleapis/pubsub/v1.dart' as pub;
import 'package:shelf/shelf.dart';
import '../service/validation_service.dart';

import '../request_handling/pubsub.dart';

import '../service/log.dart';
import '../server/authenticated_request_handler.dart';

/// Handler for processing pull requests with 'autosubmit' label.
///
/// For pull requests where an 'autosubmit' label was added in pubsub,
/// check if the pull request is mergable.
class CheckPullRequest extends AuthenticatedRequestHandler {
  const CheckPullRequest({
    required super.config,
    required super.cronAuthProvider,
    this.approverProvider = ApproverService.defaultProvider,
    this.pubsub = const PubSub(),
  });

  final PubSub pubsub;
  final ApproverServiceProvider approverProvider;

  static const int kPullMesssageBatchSize = 100;
  static const int kPubsubPullNumber = 5;

  @override
  Future<Response> get() async {
    final Set<int> processingLog = <int>{};
    final ApproverService approver = approverProvider(config);
    final List<pub.ReceivedMessage> messageList = await pullMessages();
    if (messageList.isEmpty) {
      log.info('No messages are pulled.');
      return Response.ok('No messages are pulled.');
    }
    log.info('Processing ${messageList.length} messages');
    final ValidationService validationService = ValidationService(config);
    final List<Future<void>> futures = <Future<void>>[];

    for (pub.ReceivedMessage message in messageList) {
      final String messageData = message.message!.data!;
      final rawBody = json.decode(String.fromCharCodes(base64.decode(messageData))) as Map<String, dynamic>;
      final PullRequest pullRequest = PullRequest.fromJson(rawBody);
      log.info('Processing message ackId: ${message.ackId}');
      log.info('Processing mesageId: ${message.message!.messageId}');
      log.info('Processing PR: $rawBody');
      if (processingLog.contains(pullRequest.number)) {
        // Ack duplicate.
        log.info('Ack the duplicated message : ${message.ackId!}.');
        await pubsub.acknowledge('auto-submit-queue-sub', message.ackId!);
        continue;
      } else {
        await approver.autoApproval(pullRequest);
        log.info('Approved pull request: $rawBody');
        processingLog.add(pullRequest.number!);
      }
      futures.add(validationService.processMessage(pullRequest, message.ackId!, pubsub));
    }
    await Future.wait(futures);
    return Response.ok('Finished processing changes');
  }

  /// Pulls queued Pub/Sub messages.
  ///
  /// Pub/Sub pull request API doesn't guarantee returning all messages each time. This
  /// loops to pull `kPubsubPullNumber` times to try covering all queued messages.
  Future<List<pub.ReceivedMessage>> pullMessages() async {
    final Map<String, pub.ReceivedMessage> messageMap = <String, pub.ReceivedMessage>{};
    for (int i = 0; i < kPubsubPullNumber; i++) {
      final pub.PullResponse pullResponse = await pubsub.pull('auto-submit-queue-sub', kPullMesssageBatchSize);
      final List<pub.ReceivedMessage>? receivedMessages = pullResponse.receivedMessages;
      if (receivedMessages == null) {
        continue;
      }
      for (pub.ReceivedMessage message in receivedMessages) {
        final String messageId = message.message!.messageId!;
        messageMap[messageId] = message;
      }
    }
    return messageMap.values.toList();
  }
}
