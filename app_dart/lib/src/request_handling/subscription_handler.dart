// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:meta/meta.dart';

import '../model/luci/push_message.dart';
import '../service/cache_service.dart';
import '../service/config.dart';
import '../service/logging.dart';
import 'api_request_handler.dart';
import 'authentication.dart';
import 'body.dart';

/// An [ApiRequestHandler] that handles PubSub subscription messages.
///
/// Messages adhere to a specific contract, as follows:
///
///  * All requests must be authenticated per [AuthenticationProvider].
///  * Request body is passed following the format of [PushMessageEnvelope].
///
/// Messages are idempotent, and guranteed to be run only once by Cocoon.
// ignore: must_be_immutable
abstract class SubscriptionHandler extends ApiRequestHandler<Body> {
  /// Creates a new [SubscriptionHandler].
  SubscriptionHandler({
    required this.topicName,
    required this.cache,
    required Config config,
    required AuthenticationProvider authenticationProvider,
  }) : super(config: config, authenticationProvider: authenticationProvider);

  final CacheService cache;

  /// Unique identifier in the Google Cloud project.
  ///
  /// This is used for ensuring messages are idempotent.
  final String topicName;

  /// Pubsub message from [requestBody].
  PushMessage get message => _message!;
  PushMessage? _message;

  @override
  Future<void> service(HttpRequest request) async {
    final Uint8List requestBody = Uint8List.fromList(await request.expand<int>((List<int> chunk) => chunk).toList());
    final String requestString = String.fromCharCodes(requestBody);
    log.fine(requestString);
    final PushMessageEnvelope envelope =
        PushMessageEnvelope.fromJson(json.decode(requestString) as Map<String, dynamic>);
    _message = envelope.message;
    final String messageId = message.messageId!;
    final Uint8List? messageEntry = await cache.getOrCreate(topicName, messageId);
    if (messageEntry != null) {
      log.info('Skipping $messageId as it has already been processed');
      return;
    }

    final Uint8List trueByte = Uint8List.fromList(<int>[true as int]);
    await cache.set(
      topicName,
      messageId,
      trueByte,
      ttl: const Duration(days: 10),
    );
    log.fine('Marked $messageId with true');

    try {
      await super.service(request);
    } catch (e) {
      await cache.purge(topicName, messageId);
      log.warning('Purged cache entry for $messageId');
      rethrow;
    }
  }
}
