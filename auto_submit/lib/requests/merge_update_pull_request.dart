// Copyright 2023 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:auto_submit/model/merge_comment_message.dart';
import 'package:auto_submit/server/authenticated_request_handler.dart';
import 'package:auto_submit/service/merge_update_service.dart';
import 'package:shelf/shelf.dart';
import 'package:googleapis/pubsub/v1.dart' as pub;

import '../request_handling/pubsub.dart';

import '../service/config.dart';
import '../service/log.dart';

class MergeUpdatePullRequest extends AuthenticatedRequestHandler {
  const MergeUpdatePullRequest({
    required super.config,
    required super.cronAuthProvider,
    this.pubsub = const PubSub(),
  });

  final PubSub pubsub;
  static const int pullMesssageBatchSize = 100;
  static const int pubsubPullNumber = 5;

  @override
  Future<Response> get() async {
    final Set<int> processingLog = <int>{};
    final List<pub.ReceivedMessage> messageList = await pullMessages();
    if (messageList.isEmpty) {
      log.info('No messages are pulled.');
      return Response.ok('No messages are pulled.');
    }

    log.info('Processing ${messageList.length} messages');

    final List<Future<void>> futures = <Future<void>>[];
    final MergeUpdateService mergeUpdateService = MergeUpdateService(config);

    for (pub.ReceivedMessage message in messageList) {
      final String messageData = message.message!.data!;
      final rawBody = json.decode(String.fromCharCodes(base64.decode(messageData))) as Map<String, dynamic>;
      final MergeCommentMessage mergeCommentMessage = MergeCommentMessage.fromJson(rawBody);
      log.info('Processing message ackId: ${message.ackId}');
      log.info('Processing mesageId: ${message.message!.messageId}');
      log.info('Processing comment: $rawBody');

      if (processingLog.contains(mergeCommentMessage.comment!.id!)) {
        log.info('Ack the duplicated message : ${message.ackId!}.');
        await pubsub.acknowledge(
          Config.pubSubCommentSubscription,
          message.ackId!,
        );
        continue;
      } else {
        processingLog.add(mergeCommentMessage.comment!.id!);
      }
      futures.add(
        mergeUpdateService.processMessage(
          mergeCommentMessage,
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
  Future<List<pub.ReceivedMessage>> pullMessages() async {
    final Map<String, pub.ReceivedMessage> messageMap = <String, pub.ReceivedMessage>{};
    for (int i = 0; i < pubsubPullNumber; i++) {
      final pub.PullResponse pullResponse = await pubsub.pull(
        Config.pubSubCommentSubscription,
        pullMesssageBatchSize,
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
