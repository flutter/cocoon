// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:meta/meta.dart';
import 'package:gcloud/pubsub.dart';

// import '../model/luci/push_message.dart';
import '../model/luci/pubsub_message_v2.dart';
import '../service/cache_service.dart';
import '../service/logging.dart';
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
///  * Request body is passed following the format of [PushMessageEnvelope].
@immutable
abstract class SubscriptionHandlerV2 extends RequestHandler<Body> {
  /// Creates a new [SubscriptionHandlerV2].
  const SubscriptionHandlerV2({
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
  AuthenticatedContext get authContext => getValue<AuthenticatedContext>(ApiKey.authContext)!;

  /// The [PushMessage] from this [HttpRequest].
  @protected
  Message get message => getValue<Message>(PubSubKey.message)!;

  @override
  Future<void> service(
    HttpRequest request, {
    Future<void> Function(HttpStatusException)? onError,
  }) async {
    AuthenticatedContext authContext;
    final AuthenticationProvider auth = authProvider ?? PubsubAuthenticationProvider(config: config);
    try {
      authContext = await auth.authenticate(request);
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

    log.fine('Request body: ${utf8.decode(body)}');
    PushEvent? pushEvent;

    if (body.isNotEmpty) {
      try {
        pushEvent = PushEvent.fromJson(utf8.decode(body));
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

    if (pushEvent == null) {
      throw const BadRequestException('Failed to get message');
    }

    log.finer(pushEvent.toString());
    final PubSubMessageV2 pubSubMessageV2 =
        PubSubMessageV2.fromJson(jsonDecode(pushEvent.message.asString) as Map<String, dynamic>);

    final String messageId = pubSubMessageV2.messageId!;

    final Uint8List? messageLock = await cache.getOrCreate(
      subscriptionName,
      messageId,
      createFn: null,
    );
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
          log.warning('Failed to process $message. (${exception.statusCode}) ${exception.message}');
          await cache.purge(subscriptionName, messageId);
          log.info('Purged write lock from cache');
        },
      ),
      zoneValues: <RequestKey<dynamic>, Object?>{
        PubSubKey.message: pushEvent.message,
        ApiKey.authContext: authContext,
      },
    );
  }
}

@visibleForTesting
class PubSubKey<T> extends RequestKey<T> {
  const PubSubKey._(super.name);

  static const PubSubKey<Message> message = PubSubKey<Message>._('message');
}
