// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:cocoon_service/src/model/luci/pubsub_message.dart';
import 'package:cocoon_service/src/request_handling/body.dart';
import 'package:cocoon_service/src/request_handling/exceptions.dart';
import 'package:cocoon_service/src/request_handling/subscription_handler.dart';
import 'package:cocoon_service/src/service/cache_service.dart';
import 'package:gcloud/service_scope.dart' as ss;
import 'package:test/test.dart';

import '../src/datastore/fake_config.dart';
import '../src/request_handling/fake_authentication.dart';

void main() {
  group('Subscription', () {
    late HttpServer server;
    late SubscriptionHandler subscription;

    const PubSubPushMessage testEnvelope = PubSubPushMessage(
      message: PushMessage(
        data: 'test',
        messageId: '123',
      ),
      subscription: 'https://flutter-dashboard.appspot.com/api/luci-status-handler',
    );

    setUp(() async {
      server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      server.listen((HttpRequest request) {
        runZoned<dynamic>(
          () {
            return ss.fork(() {
              return subscription.service(request);
            });
          },
        );
      });
    });

    tearDown(() async {
      await server.close();
    });

    Future<HttpClientResponse> issueRequest({String? body}) async {
      final HttpClient client = HttpClient();
      final Uri url = Uri(scheme: 'http', host: 'localhost', port: server.port, path: '/path');
      final HttpClientRequest request = await client.getUrl(url);
      if (body != null) {
        request.contentLength = body.length;
        request.write(body);
        await request.flush();
      }
      return request.close();
    }

    test('failed authentication yields HTTP unauthorized', () async {
      subscription = UnauthTest();
      final HttpClientResponse response = await issueRequest();
      expect(response.statusCode, HttpStatus.unauthorized);
      expect(await utf8.decoder.bind(response).join(), 'Not authenticated');
    });

    test('passed authentication yields empty body', () async {
      subscription = AuthTest();
      final HttpClientResponse response = await issueRequest(body: jsonEncode(testEnvelope));
      expect(response.statusCode, HttpStatus.ok);
    });

    test('pubsub message is parsed', () async {
      subscription = ReadMessageTest();
      final HttpClientResponse response = await issueRequest(body: jsonEncode(testEnvelope));
      expect(response.statusCode, HttpStatus.ok);
      final String responseBody = String.fromCharCodes((await response.toList()).first);
      expect(responseBody, 'test');
    });

    test('ensure message ids are idempotent', () async {
      final CacheService cache = CacheService(inMemory: true);
      subscription = ReadMessageTest(cache);
      HttpClientResponse response = await issueRequest(body: jsonEncode(testEnvelope));
      String responseBody = String.fromCharCodes((await response.toList()).first);
      expect(response.statusCode, HttpStatus.ok);
      // 1. Expected message for this was processed
      expect(responseBody, 'test');

      response = await issueRequest(body: jsonEncode(testEnvelope));
      responseBody = String.fromCharCodes((await response.toList()).first);
      expect(response.statusCode, HttpStatus.ok);
      // 2. Empty message is returned as this was already processed
      expect(responseBody, '123 was already processed');
      expect(await cache.getOrCreate(subscription.subscriptionName, '123', createFn: null), isNotNull);
    });

    test('ensure messages can be retried', () async {
      final CacheService cache = CacheService(inMemory: true);
      subscription = ErrorTest(cache);
      HttpClientResponse response = await issueRequest(body: jsonEncode(testEnvelope));
      Uint8List? messageLock = await cache.getOrCreate('error', '123', createFn: null);
      expect(response.statusCode, HttpStatus.internalServerError);
      expect(messageLock, isNull);

      response = await issueRequest(body: jsonEncode(testEnvelope));
      messageLock = await cache.getOrCreate('error', '123', createFn: null);
      expect(response.statusCode, HttpStatus.internalServerError);
      expect(messageLock, isNull);
    });
  });
}

/// Test stub of [SubscriptionHandler] to validate unauthenticated requests.
class UnauthTest extends SubscriptionHandler {
  UnauthTest()
      : super(
          cache: CacheService(inMemory: true),
          config: FakeConfig(),
          authProvider: FakeAuthenticationProvider(authenticated: false),
          subscriptionName: 'unauth',
        );

  @override
  Future<Body> get() async => throw StateError('Unreachable');
}

/// Test stub of [SubscriptionHandler] to validate authenticated requests.
class AuthTest extends SubscriptionHandler {
  AuthTest()
      : super(
          cache: CacheService(inMemory: true),
          config: FakeConfig(),
          authProvider: FakeAuthenticationProvider(),
          subscriptionName: 'auth',
        );

  @override
  Future<Body> get() async => Body.empty;
}

/// Test stub of [SubscriptionHandler] to validate push messages can be read.
class ErrorTest extends SubscriptionHandler {
  ErrorTest([CacheService? cache])
      : super(
          cache: cache ?? CacheService(inMemory: true),
          config: FakeConfig(),
          authProvider: FakeAuthenticationProvider(),
          subscriptionName: 'error',
        );

  @override
  Future<Body> get() async => throw const InternalServerError('Test error!');
}

/// Test stub of [SubscriptionHandler] to validate push messages can be read.
class ReadMessageTest extends SubscriptionHandler {
  ReadMessageTest([CacheService? cache])
      : super(
          cache: cache ?? CacheService(inMemory: true),
          config: FakeConfig(),
          authProvider: FakeAuthenticationProvider(),
          subscriptionName: 'read',
        );

  @override
  Future<Body> get() async => Body.forString(message.data!);
}
