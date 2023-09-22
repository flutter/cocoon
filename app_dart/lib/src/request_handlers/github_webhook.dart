// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import '../model/proto/protos.dart' as pb;
import '../request_handling/body.dart';
import '../request_handling/exceptions.dart';
import '../request_handling/pubsub.dart';
import '../request_handling/request_handler.dart';
import '../service/logging.dart';

/// The [RequestHandler] for processing GitHub webhooks and publishing valid events to PubSub.
///
/// Requests are only published as a [GithubWebhookMessage] iff they contain:
///   1. Event type from the header `X-GitHub-Event`
///   2. Event payload that was HMAC authenticated
class GithubWebhook extends RequestHandler<Body> {
  GithubWebhook({
    required super.config,
    required this.pubsub,
    required this.secret,
    required this.topic,
  });

  final PubSub pubsub;
  
  /// PubSub topic to publish authenticated requests to.
  final String topic;

  /// Future that resolves to the GitHub apps webhook secret.
  final Future<String> secret;

  @override
  Future<Body> post() async {
    final String? event = request!.headers.value('X-GitHub-Event');

    if (event == null || request!.headers.value('X-Hub-Signature') == null) {
      throw const BadRequestException('Missing required headers.');
    }
    final List<int> requestBytes = await request!.expand((_) => _).toList();
    final String? hmacSignature = request!.headers.value('X-Hub-Signature');
    await _validateRequest(hmacSignature, requestBytes);

    final String requestString = utf8.decode(requestBytes);

    final pb.GithubWebhookMessage message = pb.GithubWebhookMessage.create()
      ..event = event
      ..payload = requestString;
    log.fine(message);
    await pubsub.publish(topic, message.writeToJsonMap());

    return Body.empty;
  }

  /// Ensures the signature provided for the given payload matches what is expected.
  ///
  /// The expected key is the sha1 hash of the payload using the private key of the GitHub app.
  Future<void> _validateRequest(
    String? signature,
    List<int> requestBody,
  ) async {
    final String rawKey = await secret;
    final List<int> key = utf8.encode(rawKey);
    final Hmac hmac = Hmac(sha1, key);
    final Digest digest = hmac.convert(requestBody);
    final String bodySignature = 'sha1=$digest';
    if (bodySignature != signature) {
      throw const Forbidden('X-Hub-Signature does not match expected value');
    }
  }
}
