// Copyright 2022 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:auto_submit/requests/event_processor.dart';
import 'package:github/github.dart';
import 'package:shelf/shelf.dart';
import 'package:crypto/crypto.dart';

import '../model/merge_comment_message.dart';
import '../request_handling/pubsub.dart';
import '../service/config.dart';
import '../service/log.dart';
import '../server/request_handler.dart';
import '../requests/exceptions.dart';

/// Handler for processing GitHub webhooks.
///
/// On events where an 'autosubmit' label was added to a pull request,
/// check if the pull request is mergable and publish to pubsub.
class GithubWebhook extends RequestHandler {
  const GithubWebhook({
    required super.config,
    this.pubsub = const PubSub(),
  });

  final PubSub pubsub;

  @override
  Future<Response> post(Request request) async {
    final Map<String, String> reqHeader = request.headers;
    log.info('Header: $reqHeader');

    // this is how you know what was sent to the webhook.
    final String? gitHubEvent = request.headers['X-GitHub-Event'];

    if (gitHubEvent == null || request.headers['X-Hub-Signature'] == null) {
      throw const BadRequestException('Missing required headers.');
    }

    final List<int> requestBytes = await request.read().expand((_) => _).toList();
    final String? hmacSignature = request.headers['X-Hub-Signature'];

    if (!await _validateRequest(
      hmacSignature,
      requestBytes,
    )) {
      throw const Forbidden();
    }

    final EventProcessor eventProcessor = EventProcessor(gitHubEvent, config, pubsub);
    return eventProcessor.processEvent(requestBytes);
  }

  Future<bool> _validateRequest(
    String? signature,
    List<int> requestBody,
  ) async {
    final String rawKey = await config.getWebhookKey();
    final List<int> key = utf8.encode(rawKey);
    final Hmac hmac = Hmac(sha1, key);
    final Digest digest = hmac.convert(requestBody);
    final String bodySignature = 'sha1=$digest';
    return bodySignature == signature;
  }
}
