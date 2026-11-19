// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cocoon_integration_test/testing.dart';
import 'package:cocoon_server_test/test_logging.dart';
import 'package:cocoon_service/src/model/luci/pubsub_message.dart';
import 'package:cocoon_service/src/request_handling/exceptions.dart';
import 'package:cocoon_service/src/request_handling/http_io.dart';
import 'package:cocoon_service/src/request_handling/response.dart';
import 'package:cocoon_service/src/request_handling/subscription_handler.dart';
import 'package:cocoon_service/src/service/cache_service.dart';
import 'package:gcloud/service_scope.dart' as ss;
import 'package:test/test.dart';

void main() {
  useTestLoggerPerTest();

  group('Subscription', () {
    late HttpServer server;
    late SubscriptionHandler subscription;

    const testEnvelope = PubSubPushMessage(
      message: PushMessage(data: 'test', messageId: '123'),
      subscription:
          'https://flutter-dashboard.appspot.com/api/luci-status-handler',
    );

    setUp(() async {
      server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      server.listen((HttpRequest request) {
        runZoned<dynamic>(() {
          return ss.fork(() {
            return subscription.service(request.toRequest());
          });
        });
      });
    });

    tearDown(() async {
      await server.close();
    });

    Future<HttpClientResponse> issueRequest({String? body}) async {
      final client = HttpClient();
      final url = Uri(
        scheme: 'http',
        host: 'localhost',
        port: server.port,
        path: '/path',
      );
      final request = await client.getUrl(url);
      if (body != null) {
        request.contentLength = body.length;
        request.write(body);
        await request.flush();
      }
      return request.close();
    }

    test('failed authentication yields HTTP unauthorized', () async {
      subscription = UnauthTest();
      final response = await issueRequest();
      expect(response.statusCode, HttpStatus.unauthorized);
      expect(await utf8.decoder.bind(response).join(), 'Not authenticated');
    });

    test('passed authentication yields empty body', () async {
      subscription = AuthTest();
      final response = await issueRequest(body: jsonEncode(testEnvelope));
      expect(response.statusCode, HttpStatus.ok);
    });

    test('pubsub message is parsed', () async {
      subscription = ReadMessageTest();
      final response = await issueRequest(body: jsonEncode(testEnvelope));
      expect(response.statusCode, HttpStatus.ok);
      final responseBody = String.fromCharCodes(
        (await response.toList()).first,
      );
      expect(responseBody, 'test');
    });

    test('ensure message ids are idempotent', () async {
      final cache = CacheService.inMemory();
      subscription = ReadMessageTest(cache);
      var response = await issueRequest(body: jsonEncode(testEnvelope));
      var responseBody = String.fromCharCodes((await response.toList()).first);
      expect(response.statusCode, HttpStatus.ok);
      // 1. Expected message for this was processed
      expect(responseBody, 'test');

      response = await issueRequest(body: jsonEncode(testEnvelope));
      responseBody = String.fromCharCodes((await response.toList()).first);
      expect(response.statusCode, HttpStatus.ok);
      // 2. Empty message is returned as this was already processed
      expect(responseBody, '123 was already processed');
      expect(
        await cache.getOrCreate(
          subscription.subscriptionName,
          '123',
          createFn: null,
        ),
        isNotNull,
      );
    });

    test('ensure messages can be retried due to an uncaught error', () async {
      final cache = CacheService.inMemory();
      subscription = ErrorTest(cache);
      var response = await issueRequest(body: jsonEncode(testEnvelope));
      var messageLock = await cache.getOrCreate('error', '123', createFn: null);
      expect(response.statusCode, HttpStatus.internalServerError);
      expect(messageLock, isNull);

      response = await issueRequest(body: jsonEncode(testEnvelope));
      messageLock = await cache.getOrCreate('error', '123', createFn: null);
      expect(response.statusCode, HttpStatus.internalServerError);
      expect(messageLock, isNull);
    });

    test('ensure messages can be retried due to setting a 5XX', () async {
      final cache = CacheService.inMemory();
      subscription = ErrorCodeTest(cache);
      var response = await issueRequest(body: jsonEncode(testEnvelope));
      var messageLock = await cache.getOrCreate('error', '123', createFn: null);
      expect(response.statusCode, HttpStatus.serviceUnavailable);
      expect(messageLock, isNull);

      response = await issueRequest(body: jsonEncode(testEnvelope));
      messageLock = await cache.getOrCreate('error', '123', createFn: null);
      expect(response.statusCode, HttpStatus.serviceUnavailable);
      expect(messageLock, isNull);
    });

    test(
      'purges write lock before sending 5XX response so immediate retry succeeds',
      () async {
        final cache = _DelayedPurgeCacheService(
          const Duration(milliseconds: 50),
        );
        subscription = FailOnceThenSucceedTest(cache);

        // First attempt fails with 500; when response arrives, lock must
        // already be purged even though purge() took 50ms.
        final firstResponse = await issueRequest(
          body: jsonEncode(testEnvelope),
        );
        expect(firstResponse.statusCode, HttpStatus.internalServerError);
        await firstResponse.drain<void>();

        // Immediate retry must succeed and execute the handler rather than
        // returning "123 was already processed".
        final retryResponse = await issueRequest(
          body: jsonEncode(testEnvelope),
        );
        final retryBody = await utf8.decoder.bind(retryResponse).join();
        expect(retryResponse.statusCode, HttpStatus.ok);
        expect(retryBody, 'processed:test');
      },
    );

    test(
      'returns 503 NACK (not 200 ACK) for concurrent redelivery while message is still in progress',
      () async {
        final cache = CacheService.inMemory();
        final firstAttemptStarted = Completer<void>();
        final completeFirstAttempt = Completer<Response>();
        subscription = ControlledAsyncTest(
          cache: cache,
          onFirstCallStarted: firstAttemptStarted,
          firstCallResult: completeFirstAttempt,
        );

        // Start first delivery and wait until it is actively processing.
        final firstResponseFuture = issueRequest(
          body: jsonEncode(testEnvelope),
        );
        await firstAttemptStarted.future;

        // Simulate Pub/Sub ack-deadline redelivery while first request is in flight.
        final concurrentResponse = await issueRequest(
          body: jsonEncode(testEnvelope),
        );
        final concurrentBody = await utf8.decoder
            .bind(concurrentResponse)
            .join();
        expect(concurrentResponse.statusCode, HttpStatus.serviceUnavailable);
        expect(concurrentBody, '123 is currently being processed');

        // Now fail the first delivery with a retriable 500 error.
        completeFirstAttempt.completeError(
          const InternalServerError('Transient failure'),
        );
        final firstResponse = await firstResponseFuture;
        expect(firstResponse.statusCode, HttpStatus.internalServerError);
        await firstResponse.drain<void>();

        // Subsequent Pub/Sub retry should now acquire the lock and succeed.
        final retryResponse = await issueRequest(
          body: jsonEncode(testEnvelope),
        );
        final retryBody = await utf8.decoder.bind(retryResponse).join();
        expect(retryResponse.statusCode, HttpStatus.ok);
        expect(retryBody, 'recovered:test');

        // Any duplicate after success should be ACKed as already processed.
        final duplicateResponse = await issueRequest(
          body: jsonEncode(testEnvelope),
        );
        final duplicateBody = await utf8.decoder.bind(duplicateResponse).join();
        expect(duplicateResponse.statusCode, HttpStatus.ok);
        expect(duplicateBody, '123 was already processed');
      },
    );
  });
}

/// Test stub of [SubscriptionHandler] to validate unauthenticated requests.
final class UnauthTest extends SubscriptionHandler {
  UnauthTest()
    : super(
        cache: CacheService.inMemory(),
        config: FakeConfig(),
        authProvider: FakeDashboardAuthentication(authenticated: false),
        subscriptionName: 'unauth',
      );

  @override
  Future<Response> get(_) async => throw StateError('Unreachable');
}

/// Test stub of [SubscriptionHandler] to validate authenticated requests.
final class AuthTest extends SubscriptionHandler {
  AuthTest()
    : super(
        cache: CacheService.inMemory(),
        config: FakeConfig(),
        authProvider: FakeDashboardAuthentication(),
        subscriptionName: 'auth',
      );

  @override
  Future<Response> get(_) async => Response.emptyOk;
}

/// Test stub of [SubscriptionHandler] to validate push messages can be read.
final class ErrorTest extends SubscriptionHandler {
  ErrorTest([CacheService? cache])
    : super(
        cache: cache ?? CacheService.inMemory(),
        config: FakeConfig(),
        authProvider: FakeDashboardAuthentication(),
        subscriptionName: 'error',
      );

  @override
  Future<Response> get(_) async =>
      throw const InternalServerError('Test error!');
}

/// Test stub of [SubscriptionHandler] to validate push messages can be read.
final class ErrorCodeTest extends SubscriptionHandler {
  ErrorCodeTest([CacheService? cache])
    : super(
        cache: cache ?? CacheService.inMemory(),
        config: FakeConfig(),
        authProvider: FakeDashboardAuthentication(),
        subscriptionName: 'error',
      );

  @override
  Future<Response> get(_) async {
    throw const ServiceUnavailable('Intentional 404');
  }
}

/// Test stub of [SubscriptionHandler] to validate push messages can be read.
final class ReadMessageTest extends SubscriptionHandler {
  ReadMessageTest([CacheService? cache])
    : super(
        cache: cache ?? CacheService.inMemory(),
        config: FakeConfig(),
        authProvider: FakeDashboardAuthentication(),
        subscriptionName: 'read',
      );

  @override
  Future<Response> get(_) async => Response.string(message.data!);
}

class _DelayedPurgeCacheService extends InMemoryCacheService {
  _DelayedPurgeCacheService(this.purgeDelay);

  final Duration purgeDelay;

  @override
  Future<void> purge(String subcacheName, String key) async {
    await Future<void>.delayed(purgeDelay);
    await super.purge(subcacheName, key);
  }
}

// ignore: must_be_immutable
final class FailOnceThenSucceedTest extends SubscriptionHandler {
  FailOnceThenSucceedTest(CacheService cache)
    : super(
        cache: cache,
        config: FakeConfig(),
        authProvider: FakeDashboardAuthentication(),
        subscriptionName: 'fail-once',
      );

  int _attempts = 0;

  @override
  Future<Response> get(_) async {
    _attempts++;
    if (_attempts == 1) {
      throw const InternalServerError('Transient publish failure');
    }
    return Response.string('processed:${message.data}');
  }
}

// ignore: must_be_immutable
final class ControlledAsyncTest extends SubscriptionHandler {
  ControlledAsyncTest({
    required super.cache,
    required this.onFirstCallStarted,
    required this.firstCallResult,
  }) : super(
         config: FakeConfig(),
         authProvider: FakeDashboardAuthentication(),
         subscriptionName: 'controlled',
       );

  final Completer<void> onFirstCallStarted;
  final Completer<Response> firstCallResult;
  int _calls = 0;

  @override
  Future<Response> get(_) async {
    _calls++;
    if (_calls == 1) {
      onFirstCallStarted.complete();
      return firstCallResult.future;
    }
    return Response.string('recovered:${message.data}');
  }
}
