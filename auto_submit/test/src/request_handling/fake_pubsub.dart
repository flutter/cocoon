// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:math';

import 'package:auto_submit/request_handling/pubsub.dart';
import 'package:googleapis/pubsub/v1.dart';

class FakePubSub extends PubSub {
  List<dynamic> messagesQueue = <dynamic>[];
  // The iteration of `pull` API calls.
  int iteration = -1;
  // Number of messages in each Pub/Sub pull call. This mocks the API
  // returning random number of messages each time.
  int messageSize = 2;

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
    final List<ReceivedMessage> receivedMessages = <ReceivedMessage>[];
    iteration++;
    if (messagesQueue.isNotEmpty) {
      int i = iteration * messageSize;
      // Returns only allowed max number of messages. The number should not be greater than
      // `maxMessages`, the available messages, and the number allowed in each call. The
      // last number is to mock real `pull` API call.
      while (i < min(min(maxMessages, messagesQueue.length), (iteration + 1) * messageSize)) {
        receivedMessages.add(
          ReceivedMessage(
            message: PubsubMessage(data: messagesQueue[i] as String, messageId: '$i'),
            ackId: 'ackId_$i',
          ),
        );
        i++;
      }
      return PullResponse(receivedMessages: receivedMessages);
    }
    return PullResponse(receivedMessages: receivedMessages);
  }

  final acks = <({String subscription, String ackId})>[];

  @override
  Future<void> acknowledge(String subscription, String ackId) async {
    acks.add((subscription: subscription, ackId: ackId));
    if (messagesQueue.isNotEmpty) {
      messagesQueue.removeAt(messagesQueue.length - 1);
    }
  }
}
