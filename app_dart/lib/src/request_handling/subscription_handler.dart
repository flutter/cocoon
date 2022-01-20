// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
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
import 'exceptions.dart';
import 'request_handler.dart';

/// An [ApiRequestHandler] that handles PubSub subscription messages.
///
/// Messages adhere to a specific contract, as follows:
///
///  * All requests must be authenticated per [AuthenticationProvider].
///  * Request body is passed following the format of [PushMessageEnvelope].
@immutable
abstract class SubscriptionHandler extends RequestHandler<Body> {
  /// Creates a new [SubscriptionHandler].
  const SubscriptionHandler({
    required this.cache,
    required Config config,
    required this.authProvider,
    required this.topicName,
  }) : super(
          config: config,
        );

  final CacheService cache;

  /// Service responsible for authenticating this [HttpRequest].
  final AuthenticationProvider authProvider;

  /// Unique identifier of the PubSub in this cloud project.
  final String topicName;

  /// The authentication context associated with the HTTP request.
  ///
  /// This is guaranteed to be non-null. If the request was unauthenticated,
  /// the request will be denied.
  @protected
  AuthenticatedContext get authContext => getValue<AuthenticatedContext>(ApiKey.authContext)!;

  /// The [PushMessage] from this [HttpRequest].
  @protected
  PushMessage get message => getValue<PushMessage>(PubSubKey.message)!;

  @override
  Future<void> service(HttpRequest request) async {
    AuthenticatedContext authContext;
    try {
      authContext = await authProvider.authenticate(request);
    } on Unauthenticated catch (error) {
      final HttpResponse response = request.response;
      response
        ..statusCode = HttpStatus.unauthorized
        ..write(error.message);
      await response.flush();
      await response.close();
      return;
    }

    List<int> body;
    try {
      body = await request.expand<int>((List<int> chunk) => chunk).toList();
    } catch (error) {
      final HttpResponse response = request.response;
      response
        ..statusCode = HttpStatus.internalServerError
        ..write('$error');
      await response.flush();
      await response.close();
      return;
    }

    PushMessageEnvelope? envelope;
    if (body.isNotEmpty) {
      try {
        final Map<String, dynamic> json = jsonDecode(utf8.decode(body)) as Map<String, dynamic>;
        envelope = PushMessageEnvelope.fromJson(json);
      } catch (error) {
        final HttpResponse response = request.response;
        response
          ..statusCode = HttpStatus.internalServerError
          ..write('$error');
        await response.flush();
        await response.close();
        return;
      }
    }

    if (envelope == null) {
      throw const BadRequestException('Failed to get message');
    }
    log.finer(envelope.toJson());

    final String messageId = envelope.message!.messageId!;

    final Uint8List? messageLock = await cache.getOrCreate(topicName, messageId);
    if (messageLock != null) {
      // No-op - There's already a write lock for this message
      final HttpResponse response = request.response
        ..statusCode = HttpStatus.ok
        ..write('$messageId was already processed');
      await response.flush();
      await response.close();
      return;
    }

    // Create a write lock in the cache to ensure requests are only processed once
    final Uint8List lockValue = Uint8List.fromList('l'.codeUnits);
    await cache.set(
      topicName,
      messageId,
      lockValue,
      ttl: const Duration(days: 7),
    );

    await runZonedGuarded<Future<void>>(
      () async => await super.service(request),
      (Object obj, StackTrace stack) {
        // If there is a failure, clear the lock to allow it to be retried
        cache.purge(topicName, messageId);
      },
      zoneValues: <RequestKey<dynamic>, Object?>{
        PubSubKey.message: envelope.message,
        ApiKey.authContext: authContext,
      },
    );
  }
}

@visibleForTesting
class PubSubKey<T> extends RequestKey<T> {
  const PubSubKey._(String name) : super(name);

  static const PubSubKey<PushMessage> message = PubSubKey<PushMessage>._('message');
}
