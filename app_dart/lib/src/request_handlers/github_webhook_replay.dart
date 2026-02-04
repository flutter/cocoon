// Copyright 2024 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:cocoon_server/logging.dart';
import 'package:meta/meta.dart';

import '../../cocoon_service.dart';
import '../model/firestore/github_webhook_message.dart';
import '../request_handling/api_request_handler.dart';
import '../request_handling/exceptions.dart';

/// Re-publishes a GitHub webhook message to Pub/Sub.
///
/// This handler retrieves a previously stored [GithubWebhookMessage] from
/// Firestore and uses the [GithubWebhook] handler to re-publish it.
///
/// This is useful for re-triggering CI tasks for events that were not
/// successfully processed or were missed.
@immutable
final class GithubWebhookReplay extends ApiRequestHandler {
  const GithubWebhookReplay({
    required super.config,
    required super.authenticationProvider,
    required this.firestoreService,
    required this.githubWebhook,
  });

  final FirestoreService firestoreService;
  final GithubWebhook githubWebhook;

  /// Replays the message specified by the `id` query parameter.
  ///
  /// The user must be authenticated with a `@google.com` email address.
  @override
  Future<Response> post(Request request) async {
    // Ensure the user is from google.com
    if (authContext?.email == null ||
        !authContext!.email.endsWith('@google.com')) {
      throw const Forbidden('Only @google.com users are allowed');
    }

    final id = request.uri.queryParameters['id'];
    if (id == null) {
      throw const BadRequestException('Missing id parameter');
    }

    final documentName =
        'projects/${Config.flutterGcpProjectId}/databases/'
        '${Config.flutterGcpFirestoreDatabase}/documents/'
        '${GithubWebhookMessage.metadata.collectionId}/$id';

    final GithubWebhookMessage message;
    try {
      final document = await firestoreService.getDocument(documentName);
      message = GithubWebhookMessage.fromDocument(document);
    } catch (e) {
      throw const NotFoundException('Message not found');
    }

    log.info(
      'Replaying GitHub webhook message locally ${(id: id, event: message.event)}',
    );
    await githubWebhook.publish(message.event, message.jsonString);
    return Response.emptyOk;
  }
}
