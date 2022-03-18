// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:googleapis/pubsub/v1.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart';

import '../foundation/providers.dart';
import '../foundation/typedefs.dart';
import '../service/log.dart';

/// Service class for interacting with PubSub.
class PubSub {
  const PubSub({
    this.httpClientProvider = Providers.freshHttpClient,
  });

  final HttpClientProvider httpClientProvider;

  /// Adds one or more messages to the topic.
  Future<void> publish(String topic, dynamic json) async {
    final Client httpClient = await clientViaApplicationDefaultCredentials(scopes: <String>[
      PubsubApi.pubsubScope,
    ]);
    final PubsubApi pubsubApi = PubsubApi(httpClient);
    final String messageData = jsonEncode(json);
    final List<int> messageBytes = utf8.encode(messageData);
    final String messageBase64 = base64Encode(messageBytes);
    final PublishRequest request = PublishRequest(messages: <PubsubMessage>[
      PubsubMessage(data: messageBase64),
    ]);
    final String _topic = 'projects/flutter-dashboard/topics/$topic';
    final PublishResponse response = await pubsubApi.projects.topics.publish(request, _topic);
    log.info('pubsub response messageId=${response.messageIds}');
  }

  /// Pulls messages from the server.
  Future<PullResponse> pull(int maxMessages, String subscription) async {
    final Client httpClient = await clientViaApplicationDefaultCredentials(scopes: <String>[
      PubsubApi.pubsubScope,
    ]);
    final PubsubApi pubsubApi = PubsubApi(httpClient);
    PullRequest pullRequest = PullRequest(maxMessages: maxMessages);
    final PullResponse pullResponse = await pubsubApi.projects.subscriptions
        .pull(pullRequest, 'projects/flutter-dashboard/subscriptions/$subscription');
    return pullResponse;
  }

  /// Acknowledges the messages associated with the `ack_ids` in the `AcknowledgeRequest`.
  ///
  /// The Pub/Sub system can remove the relevant messages from the subscription.
  Future<void> acknowledge(String ackId, String subscription) async {
    final Client httpClient = await clientViaApplicationDefaultCredentials(scopes: <String>[
      PubsubApi.pubsubScope,
    ]);
    final PubsubApi pubsubApi = PubsubApi(httpClient);
    final List<String> ackIds = [ackId];
    final AcknowledgeRequest acknowledgeRequest = AcknowledgeRequest(ackIds: ackIds);
    await pubsubApi.projects.subscriptions
        .acknowledge(acknowledgeRequest, 'projects/flutter-dashboard/subscriptions/$subscription');
  }
}
