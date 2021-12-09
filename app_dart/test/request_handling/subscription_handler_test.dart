// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cocoon_service/src/model/luci/push_message.dart';
import 'package:cocoon_service/src/request_handling/body.dart';
import 'package:cocoon_service/src/request_handling/subscription_handler.dart';
import 'package:cocoon_service/src/service/logging.dart';
import 'package:gcloud/service_scope.dart' as ss;
import 'package:test/test.dart';

import '../src/datastore/fake_config.dart';
import '../src/request_handling/fake_authentication.dart';

void main() {
  group('Subscription', () {
    late HttpServer server;
    late SubscriptionHandler subscription;

    setUpAll(() async {
      server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      server.listen((HttpRequest request) {
        final ZoneSpecification spec = ZoneSpecification(
          print: (Zone self, ZoneDelegate parent, Zone zone, String line) {
            log.fine(line);
          },
        );
        return runZoned<dynamic>(() {
          return ss.fork(() {
            ss.register(#appengine.logging, log);
            return subscription.service(request);
          });
        }, zoneSpecification: spec);
      });
    });

    tearDownAll(() async {
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
      return await request.close();
    }

    test('failed authentication yields HTTP unauthorized', () async {
      subscription = UnauthTest();
      final HttpClientResponse response = await issueRequest();
      expect(response.statusCode, HttpStatus.unauthorized);
      expect(await utf8.decoder.bind(response).join(), 'Not authenticated');
    });

    test('passed authentication yields empty body', () async {
      subscription = AuthTest();
      final HttpClientResponse response = await issueRequest();
      expect(response.statusCode, HttpStatus.ok);
    });

    test('pubsub message is parsed', () async {
      subscription = ReadMessageTest();
      const PushMessageEnvelope envelope = PushMessageEnvelope(
        message: PushMessage(
          data: 'test',
          messageId: '123',
        ),
        subscription: 'https://flutter-dashboard.appspot.com/api/luci-status-handler',
      );
      final HttpClientResponse response = await issueRequest(body: jsonEncode(envelope));
      expect(response.statusCode, HttpStatus.ok);
      final String responseBody = String.fromCharCodes((await response.toList()).first);
      expect(responseBody, 'test');
    });
  });
}

/// Test stub of [SubscriptionHandler] to validate unauthenticated requests.
class UnauthTest extends SubscriptionHandler {
  UnauthTest()
      : super(
          config: FakeConfig(),
          authenticationProvider: FakeAuthenticationProvider(authenticated: false),
        );

  @override
  Future<Body> get() async => throw StateError('Unreachable');
}

/// Test stub of [SubscriptionHandler] to validate authenticated requests.
class AuthTest extends SubscriptionHandler {
  AuthTest()
      : super(
          config: FakeConfig(),
          authenticationProvider: FakeAuthenticationProvider(),
        );

  @override
  Future<Body> get() async => Body.empty;
}

/// Test stub of [SubscriptionHandler] to validate push messages can be read.
class ReadMessageTest extends SubscriptionHandler {
  ReadMessageTest()
      : super(
          config: FakeConfig(),
          authenticationProvider: FakeAuthenticationProvider(),
        );

  @override
  Future<Body> get() async => Body.forString((await message)!.data!);
}
