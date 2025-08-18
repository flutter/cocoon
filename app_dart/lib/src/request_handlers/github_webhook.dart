// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// @docImport 'package:cocoon_service/src/model/proto/internal/github_webhook.pb.dart';
library;

import 'dart:async';
import 'dart:convert';

import 'package:cocoon_server/logging.dart';
import 'package:crypto/crypto.dart';

import '../model/proto/protos.dart' as pb;
import '../request_handling/exceptions.dart';
import '../request_handling/pubsub.dart';
import '../request_handling/request_handler.dart';
import '../request_handling/response.dart';

/// Processes GitHub webhooks and publishes valid events to PubSub.
///
/// Requests are only published as a [GithubWebhookMessage] iff they contain:
///   1. Event type from the header `X-GitHub-Event`
///   2. Event payload that was HMAC authenticated
final class GithubWebhook extends RequestHandler {
  GithubWebhook({
    required super.config,
    required PubSub pubsub,
    required Future<String> secret,
    required String topic,
  }) : _secret = secret,
       _topic = topic,
       _pubsub = pubsub;

  final PubSub _pubsub;

  /// PubSub topic to publish authenticated requests to.
  final String _topic;

  /// Future that resolves to the GitHub apps webhook secret.
  final Future<String> _secret;

  @override
  Future<Response> post(Request request) async {
    final event = request.header('X-GitHub-Event');

    if (event == null || request.header('X-Hub-Signature') == null) {
      throw const BadRequestException('Missing required headers.');
    }
    final requestBytes = await request.readBodyAsBytes();
    final hmacSignature = request.header('X-Hub-Signature');
    await _validateRequest(hmacSignature, requestBytes);

    final requestString = utf8.decode(requestBytes);

    final message = pb.GithubWebhookMessage.create()
      ..event = event
      ..payload = requestString;
    log.debug('$message');
    await _pubsub.publish(_topic, message.writeToJsonMap());

    return Response.emptyOk;
  }

  /// Ensures signature provided for the given payload matches what is expected.
  ///
  /// The expected key is the sha1 hash of the payload using the private key of
  /// the GitHub app.
  Future<void> _validateRequest(
    String? signature,
    List<int> requestBody,
  ) async {
    final rawKey = await _secret;
    final List<int> key = utf8.encode(rawKey);
    final hmac = Hmac(sha1, key);
    final digest = hmac.convert(requestBody);
    final bodySignature = 'sha1=$digest';
    if (bodySignature != signature) {
      throw const Forbidden('X-Hub-Signature does not match expected value');
    }
  }
}
