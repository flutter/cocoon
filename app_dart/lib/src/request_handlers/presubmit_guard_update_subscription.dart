// Copyright 2026 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:cocoon_server/logging.dart';
import 'package:meta/meta.dart';

import '../../cocoon_service.dart';
import '../request_handling/subscription_handler.dart';

/// An endpoint for listening to PubSub updates to debounce and synchronize
/// [PresubmitGuard] state in Firestore and process stage completions.
@immutable
final class PresubmitGuardUpdateSubscription extends SubscriptionHandler {
  /// Creates an endpoint for processing debounced [PresubmitGuard] updates.
  const PresubmitGuardUpdateSubscription({
    required super.cache,
    required super.config,
    required Scheduler scheduler,
    super.authProvider,
  }) : _scheduler = scheduler,
       super(subscriptionName: 'presubmit-guard-update-sub');

  final Scheduler _scheduler;

  @override
  Future<Response> post(Request request) async {
    if (message.data == null || message.data!.isEmpty) {
      log.info('presubmit-guard-update: No data in message.');
      return Response.emptyOk;
    }

    late final Map<String, dynamic> messageJson;
    try {
      messageJson = jsonDecode(message.data!) as Map<String, dynamic>;
    } catch (e) {
      log.warn(
        'presubmit-guard-update: Failed to decode json data: ${message.data}',
        e,
      );
      return Response.emptyOk;
    }

    final guardDocumentName = messageJson['guard_document_name'] as String?;
    if (guardDocumentName == null || guardDocumentName.isEmpty) {
      log.warn(
        'presubmit-guard-update: Missing guard_document_name in message data.',
      );
      return Response.emptyOk;
    }

    try {
      await _scheduler.processPresubmitGuardUpdate(guardDocumentName);
    } catch (e, s) {
      log.error(
        'presubmit-guard-update: Error updating PresubmitGuard $guardDocumentName',
        e,
        s,
      );
      rethrow;
    }

    return Response.emptyOk;
  }
}
