// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:cocoon_server/logging.dart';
import 'package:meta/meta.dart';

import '../model/luci/pubsub_message.dart';
import '../service/cache_service.dart';
import 'api_request_handler.dart';
import 'authentication.dart';
import 'exceptions.dart';
import 'http_utils.dart';
import 'pubsub_authentication.dart';
import 'request_handler.dart';
import 'response.dart';

/// An [ApiRequestHandler] that handles PubSub subscription messages.
///
/// Messages adhere to a specific contract, as follows:
///
///  * All requests must be authenticated per [AuthenticationProvider].
///  * Request body is passed following the format of [PubSubPushMessage].
abstract base class SubscriptionHandler extends RequestHandler {
  /// Creates a new [SubscriptionHandler].
  const SubscriptionHandler({
    required this.cache,
    required super.config,
    this.authProvider,
    required this.subscriptionName,
  });

  static final Uint8List _processingLockValue = Uint8List.fromList(
    'p'.codeUnits,
  );
  static final Uint8List _processedLockValue = Uint8List.fromList(
    'l'.codeUnits,
  );
  static const Duration _processingLockTtl = Duration(minutes: 10);
  static const Duration _processedLockTtl = Duration(days: 1);

  final CacheService cache;

  /// Service responsible for authenticating this [HttpRequest].
  final AuthenticationProvider? authProvider;

  /// Unique identifier of the PubSub subscription in this cloud project.
  final String subscriptionName;

  /// The authentication context associated with the HTTP request.
  ///
  /// This is guaranteed to be non-null. If the request was unauthenticated,
  /// the request will be denied.
  @protected
  AuthenticatedContext get authContext =>
      getValue<AuthenticatedContext>(ApiKey.authContext)!;

  /// The [PushMessage] from this [HttpRequest].
  // TODO(dmgr): Message should be either input param of a post or a method.
  @protected
  PushMessage get message => getValue<PushMessage>(PubSubKey.message)!;

  @override
  Future<void> service(
    Request request, {
    Future<void> Function(HttpStatusException)? onError,
  }) async {
    AuthenticatedContext authContext;
    final auth = authProvider ?? PubsubAuthenticationProvider(config: config);
    try {
      authContext = await auth.authenticate(request);
    } on Unauthenticated catch (error) {
      final response = request.response;
      response.statusCode = HttpStatus.unauthorized;
      await response.addStream(Stream.value(utf8.encode(error.message)));
      await response.flush();
      await response.close();
      return;
    }

    Uint8List body;
    try {
      body = await request.readBodyAsBytes();
    } catch (error) {
      final response = request.response;
      response.statusCode = HttpStatus.internalServerError;
      await response.addStream(Stream.value(utf8.encode('$error')));
      await response.flush();
      await response.close();
      return;
    }

    log.info('Request body: ${utf8.decode(body)}');
    PubSubPushMessage? pubSubPushMessage;
    if (body.isNotEmpty) {
      try {
        final json = jsonDecode(utf8.decode(body)) as Map<String, dynamic>;
        pubSubPushMessage = PubSubPushMessage.fromJson(json);
      } catch (error) {
        final response = request.response;
        response.statusCode = HttpStatus.internalServerError;
        await response.addStream(Stream.value(utf8.encode('$error')));
        await response.flush();
        await response.close();
        return;
      }
    }

    if (pubSubPushMessage == null) {
      throw const BadRequestException('Failed to get message');
    }

    log.debug(pubSubPushMessage.toString());

    final messageId = pubSubPushMessage.message!.messageId!;

    // Acquire an in-progress write lock in the cache to ensure requests are
    // only processed once concurrently.
    final lockAcquired = await cache.setIfNotExists(
      subscriptionName,
      messageId,
      _processingLockValue,
      ttl: _processingLockTtl,
    );

    if (!lockAcquired) {
      final existingLock = await cache.get(subscriptionName, messageId);
      if (existingLock != null &&
          existingLock.length == 1 &&
          existingLock.first == _processedLockValue.first) {
        // No-op - This message has already finished processing.
        log.info('Ignoring $messageId, message was already processed');
        final response = request.response;
        response.statusCode = HttpStatus.ok;
        await response.addStream(
          Stream.value(utf8.encode('$messageId was already processed')),
        );
        await response.flush();
        await response.close();
        return;
      }

      // Another request is still processing this message (or the lock could not
      // be acquired). Return 503 (NACK) instead of 200 (ACK) so Pub/Sub does
      // not acknowledge and delete the message if the in-flight attempt fails.
      log.info(
        'Message $messageId is currently being processed; returning 503 for retry',
      );
      final response = request.response;
      response.statusCode = HttpStatus.serviceUnavailable;
      await response.addStream(
        Stream.value(utf8.encode('$messageId is currently being processed')),
      );
      await response.flush();
      await response.close();
      return;
    }

    log.info('Processing message $messageId');
    final Response responseBody;
    try {
      responseBody = await runZoned<Future<Response>>(
        () => dispatch(
          request,
          onError: (e) async {
            log.warn(
              'Failed to process $message. (${e.statusCode}) ${e.message}',
              e,
            );
          },
        ),
        zoneValues: <RequestKey<dynamic>, Object?>{
          PubSubKey.message: pubSubPushMessage.message!,
          ApiKey.authContext: authContext,
        },
      );
    } catch (_) {
      await cache.purge(subscriptionName, messageId);
      log.info('Purged write lock from cache');
      rethrow;
    }

    // Update or clear the lock BEFORE sending the HTTP response so that an
    // immediate Pub/Sub retry never observes a stale in-progress lock.
    //
    // See https://github.com/flutter/flutter/issues/166475.
    if (responseBody.statusCode >= HttpStatus.internalServerError) {
      await cache.purge(subscriptionName, messageId);
      log.info('Purged write lock from cache');
    } else {
      await cache.set(
        subscriptionName,
        messageId,
        _processedLockValue,
        ttl: _processedLockTtl,
      );
    }

    await respond(request.response, responseBody);
  }
}

@visibleForTesting
class PubSubKey<T> extends RequestKey<T> {
  const PubSubKey._(super.name);

  static const PubSubKey<PushMessage> message = PubSubKey<PushMessage>._(
    'message',
  );
}
