// Copyright 2022 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:cocoon_server/logging.dart';
import 'package:crypto/crypto.dart';
import 'package:github/github.dart';
import 'package:shelf/shelf.dart';

import '../request_handling/pubsub.dart';
import '../requests/exceptions.dart';
import '../server/request_handler.dart';
import '../service/config.dart';
import 'github_pull_request_event.dart';

/// Handler for processing GitHub webhooks.
///
/// On events where an 'autosubmit' label was added to a pull request,
/// check if the pull request is mergable and publish to pubsub.
class GithubWebhook extends RequestHandler {
  const GithubWebhook({required super.config, this.pubsub = const PubSub()});

  final PubSub pubsub;

  static const String pullRequest = 'pull_request';
  static const String labels = 'labels';
  static const String action = 'action';
  static const String sender = 'sender';

  static const String eventTypeHeader = 'X-GitHub-Event';
  static const String signatureHeader = 'X-Hub-Signature';

  @override
  Future<Response> post(Request request) async {
    final reqHeader = request.headers;
    log.info('Header: $reqHeader');

    final gitHubEvent = request.headers[GithubWebhook.eventTypeHeader];

    if (gitHubEvent == null ||
        request.headers[GithubWebhook.signatureHeader] == null) {
      throw const BadRequestException('Missing required headers.');
    }
    final requestBytes =
        await request.read().expand((bodyBytes) => bodyBytes).toList();
    final hmacSignature = request.headers[GithubWebhook.signatureHeader];
    if (!await _validateRequest(hmacSignature, requestBytes)) {
      log.info('User is forbidden');
      throw const Forbidden();
    }

    var hasAutosubmit = false;
    var hasRevertLabel = false;
    final rawBody = utf8.decode(requestBytes);
    final body = json.decode(rawBody) as Map<String, dynamic>;

    if (!body.containsKey(GithubWebhook.pullRequest) ||
        !(body[GithubWebhook.pullRequest] as Map<String, dynamic>).containsKey(
          GithubWebhook.labels,
        )) {
      return Response.ok(jsonEncode(<String, String>{}));
    }

    final pullRequest = PullRequest.fromJson(
      body[GithubWebhook.pullRequest] as Map<String, dynamic>,
    );
    final action = body[GithubWebhook.action] as String;
    final sender = User.fromJson(
      body[GithubWebhook.sender] as Map<String, dynamic>,
    );

    hasAutosubmit = pullRequest.labels!.any(
      (label) => label.name == Config.kAutosubmitLabel,
    );
    hasRevertLabel = pullRequest.labels!.any(
      (label) =>
          label.name == Config.kRevertLabel ||
          label.name == Config.kRevertOfLabel,
    );

    // Check for revert label first.
    if (hasRevertLabel) {
      log.info('Found pull request with the revert label.');
      await pubsub.publish(
        config.pubsubRevertRequestTopic,
        GithubPullRequestEvent(
          pullRequest: pullRequest,
          action: action,
          sender: sender,
        ),
      );
    } else if (hasAutosubmit) {
      log.info('Found pull request with autosubmit label.');
      await pubsub.publish(config.pubsubPullRequestTopic, pullRequest);
    }

    return Response.ok(rawBody);
  }

  Future<bool> _validateRequest(
    String? signature,
    List<int> requestBody,
  ) async {
    final rawKey = await config.getWebhookKey();
    final List<int> key = utf8.encode(rawKey);
    final hmac = Hmac(sha1, key);
    final digest = hmac.convert(requestBody);
    final bodySignature = 'sha1=$digest';
    return bodySignature == signature;
  }
}
