// Copyright 2023 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:auto_submit/server/authenticated_request_handler.dart';
import 'package:auto_submit/service/approver_service.dart';
import 'package:auto_submit/service/validation_service.dart';
import 'package:github/github.dart';
import 'package:googleapis/pubsub/v1.dart' as pub;
import 'package:shelf/shelf.dart';

import '../request_handling/pubsub.dart';

import '../service/log.dart';

abstract class CheckRequest extends AuthenticatedRequestHandler {
  const CheckRequest({
    required super.config,
    required super.cronAuthProvider,
    this.approverProvider = ApproverService.defaultProvider,
    this.pubsub = const PubSub(),
  });

  final PubSub pubsub;
  final ApproverServiceProvider approverProvider;

  @override
  Future<Response> get();

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
    final ValidationService validationService = ValidationService(config);
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

  /// Pulls queued Pub/Sub messages.
  ///
  /// Pub/Sub pull request API doesn't guarantee returning all messages each time. This
  /// loops to pull `kPubsubPullNumber` times to try covering all queued messages.
  Future<List<pub.ReceivedMessage>> pullMessages(
    String subscription,
    int pulls,
    int batchSize,
  ) async {
    final Map<String, pub.ReceivedMessage> messageMap = <String, pub.ReceivedMessage>{};
    for (int i = 0; i < pulls; i++) {
      final pub.PullResponse pullResponse = await pubsub.pull(
        subscription,
        batchSize,
      );
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
