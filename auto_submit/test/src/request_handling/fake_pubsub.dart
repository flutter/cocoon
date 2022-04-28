// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:math';

import 'package:auto_submit/request_handling/pubsub.dart';
import 'package:googleapis/pubsub/v1.dart';

class FakePubSub extends PubSub {
  List<dynamic> messagesQueue = <dynamic>[];

  @override
  Future<void> publish(String topicName, dynamic json) async {
    final String messageData = jsonEncode(json);
    final List<int> messageBytes = utf8.encode(messageData);
    final String messageBase64 = base64Encode(messageBytes);
    messagesQueue.add(messageBase64);
  }

  @override
  Future<PullResponse> pull(String subscription, int maxMessages) async {
    // The list will be empty if there are no more messages available in the backlog.
    List<ReceivedMessage> receivedMessages = <ReceivedMessage>[];
    if (messagesQueue.isNotEmpty) {
      int i = 0;
      while (i < min(100, messagesQueue.length)) {
        receivedMessages.add(ReceivedMessage(message: PubsubMessage(data: messagesQueue[i] as String), ackId: '1'));
        i++;
      }
      return PullResponse(receivedMessages: receivedMessages);
    }
    return PullResponse(receivedMessages: receivedMessages);
  }

  @override
  Future<void> acknowledge(String subscription, String ackId) async {
    if (messagesQueue.isNotEmpty) {
      messagesQueue.removeAt(messagesQueue.length - 1);
    }
  }
}
