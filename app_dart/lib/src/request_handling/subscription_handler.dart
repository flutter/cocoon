// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:cocoon_server/logging.dart';
import 'package:meta/meta.dart';

import '../model/luci/pubsub_message.dart';
import '../service/cache_service.dart';
import 'api_request_handler.dart';
import 'authentication.dart';
import 'body.dart';
import 'exceptions.dart';
import 'pubsub_authentication.dart';
import 'request_handler.dart';

/// An [ApiRequestHandler] that handles PubSub subscription messages.
///
/// Messages adhere to a specific contract, as follows:
///
///  * All requests must be authenticated per [AuthenticationProvider].
///  * Request body is passed following the format of [PubSubPushMessage].
@immutable
abstract class SubscriptionHandler extends RequestHandler<Body> {
  /// Creates a new [SubscriptionHandler].
  const SubscriptionHandler({
    required this.cache,
    required super.config,
    this.authProvider,
    required this.subscriptionName,
  });

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
  @protected
  PushMessage get message => getValue<PushMessage>(PubSubKey.message)!;

  @override
  Future<void> service(
    HttpRequest request, {
    Future<void> Function(HttpStatusException)? onError,
  }) async {
    AuthenticatedContext authContext;
    final auth = authProvider ?? PubsubAuthenticationProvider(config: config);
    try {
      authContext = await auth.authenticate(request);
    } on Unauthenticated catch (error) {
      final response = request.response;
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
      final response = request.response;
      response
        ..statusCode = HttpStatus.internalServerError
        ..write('$error');
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
        response
          ..statusCode = HttpStatus.internalServerError
          ..write('$error');
        await response.flush();
        await response.close();
        return;
      }
    }

    if (pubSubPushMessage == null) {
      throw const BadRequestException('Failed to get message');
    }

    log.finer(pubSubPushMessage.toString());

    final messageId = pubSubPushMessage.message!.messageId!;

    final messageLock = await cache.getOrCreate(
      subscriptionName,
      messageId,
      createFn: null,
    );
    if (messageLock != null) {
      // No-op - There's already a write lock for this message
      final response =
          request.response
            ..statusCode = HttpStatus.ok
            ..write('$messageId was already processed');
      await response.flush();
      await response.close();
      return;
    }

    // Create a write lock in the cache to ensure requests are only processed once
    final lockValue = Uint8List.fromList('l'.codeUnits);
    await cache.set(
      subscriptionName,
      messageId,
      lockValue,
      ttl: const Duration(days: 1),
    );

    log.info('Processing message $messageId');
    await runZoned<Future<void>>(
      () async => super.service(
        request,
        onError: (HttpStatusException exception) async {
          log.warning(
            'Failed to process $message. (${exception.statusCode}) ${exception.message}',
          );
          await cache.purge(subscriptionName, messageId);
          log.info('Purged write lock from cache');
        },
      ),
      zoneValues: <RequestKey<dynamic>, Object?>{
        PubSubKey.message: pubSubPushMessage.message!,
        ApiKey.authContext: authContext,
      },
    );
  }
}

@visibleForTesting
class PubSubKey<T> extends RequestKey<T> {
  const PubSubKey._(super.name);

  static const PubSubKey<PushMessage> message = PubSubKey<PushMessage>._(
    'message',
  );
}
