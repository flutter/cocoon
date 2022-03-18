// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

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
  Future<PullResponse> pull(int maxMessages, String subscription) async {
    // The list will be empty if there are no more messages available in the backlog.
    List<ReceivedMessage> receivedMessages = <ReceivedMessage>[];
    if (messagesQueue.isNotEmpty) {
      final PullResponse response = PullResponse(receivedMessages: <ReceivedMessage>[
        ReceivedMessage(message: PubsubMessage(data: messagesQueue.last), ackId: '1'),
      ]);
      return response;
    }
    return PullResponse(receivedMessages: receivedMessages);
  }

  @override
  Future<void> acknowledge(String ackId, String subscription) async {
    if (messagesQueue.isNotEmpty) {
      messagesQueue.removeAt(messagesQueue.length - 1);
    }
  }
}
