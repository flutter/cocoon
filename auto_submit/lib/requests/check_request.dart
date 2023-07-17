// Copyright 2023 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:auto_submit/server/authenticated_request_handler.dart';
import 'package:auto_submit/service/approver_service.dart';
import 'package:googleapis/pubsub/v1.dart' as pub;
import 'package:shelf/shelf.dart';

import '../request_handling/pubsub.dart';

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
