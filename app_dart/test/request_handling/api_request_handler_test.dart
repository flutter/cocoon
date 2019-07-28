// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cocoon_service/src/request_handling/api_request_handler.dart';
import 'package:cocoon_service/src/request_handling/body.dart';
import 'package:test/test.dart';

import '../src/datastore/fake_cocoon_config.dart';
import '../src/request_handling/fake_authentication.dart';

void main() {
  group('ApiRequestHandler', () {
    HttpServer server;
    StringBuffer serverOutput;
    ApiRequestHandler<dynamic> handler;

    setUpAll(() async {
      server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      server.listen((HttpRequest request) {
        final ZoneSpecification spec = ZoneSpecification(
          print: (Zone self, ZoneDelegate parent, Zone zone, String line) {
            serverOutput.write(line);
          },
        );
        return runZoned<Future<void>>(() => handler.service(request), zoneSpecification: spec);
      });
    });

    tearDownAll(() async {
      await server.close();
    });

    setUp(() {
      serverOutput = StringBuffer();
    });

    Future<HttpClientResponse> issueRequest({String body}) async {
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
      handler = Unauth();
      final HttpClientResponse response = await issueRequest();
      expect(response.statusCode, HttpStatus.unauthorized);
      expect(await utf8.decoder.bind(response).join(), 'Not authenticated');
      expect(serverOutput.toString(), isEmpty);
    });

    test('empty request body yields empty requestData', () async {
      handler = ReadParams();
      final HttpClientResponse response = await issueRequest();
      expect(response.headers.value('X-Test-Params'), '{}');
      expect(response.statusCode, HttpStatus.ok);
      expect(await response.toList(), isEmpty);
      expect(serverOutput.toString(), isEmpty);
    });

    test('JSON request body yields valid requestData', () async {
      handler = ReadParams();
      final HttpClientResponse response = await issueRequest(body: '{"param1":"value1"}');
      expect(response.headers.value('X-Test-Params'), '{param1: value1}');
      expect(response.statusCode, HttpStatus.ok);
      expect(await response.toList(), isEmpty);
      expect(serverOutput.toString(), isEmpty);
    });

    test('non-JSON request body yields HTTP bad request', () async {
      handler = ReadParams();
      final HttpClientResponse response = await issueRequest(body: 'malformed content');
      expect(response.statusCode, HttpStatus.badRequest);
      expect(await utf8.decoder.bind(response).join(), contains('FormatException'));
      expect(serverOutput.toString(), isEmpty);
    });

    test('can access authContext', () async {
      handler = AccessAuth();
      final HttpClientResponse response = await issueRequest();
      expect(response.headers.value('X-Test-IsAgent'), 'false');
      expect(response.headers.value('X-Test-IsDev'), 'true');
      expect(response.statusCode, HttpStatus.ok);
      expect(serverOutput.toString(), isEmpty);
    });

    test('missing required request parameters yields HTTP bad request', () async {
      handler = NeedsParams();
      HttpClientResponse response = await issueRequest();
      expect(response.statusCode, HttpStatus.badRequest);
      response = await issueRequest(body: '{"param1":"value1"}');
      expect(response.statusCode, HttpStatus.badRequest);
      response = await issueRequest(body: '{"param2":"value2"}');
      expect(response.statusCode, HttpStatus.badRequest);
      response = await issueRequest(body: '{"param1":"value1","param2":"value2"}');
      expect(response.statusCode, HttpStatus.ok);
      response = await issueRequest(body: '{"param1":"value1","param2":"value2","extra":"yes"}');
      expect(response.statusCode, HttpStatus.ok);
      expect(serverOutput.toString(), isEmpty);
    });
  });
}

class Unauth extends ApiRequestHandler<Body> {
  Unauth()
      : super(
          config: FakeConfig(),
          authenticationProvider: FakeAuthenticationProvider(authenticated: false),
        );

  @override
  Future<Body> get() async => throw StateError('Unreachable');
}

class Auth extends ApiRequestHandler<Body> {
  Auth() : super(config: FakeConfig(), authenticationProvider: FakeAuthenticationProvider());

  @override
  Future<Body> get() async => null;
}

class ReadParams extends ApiRequestHandler<Body> {
  ReadParams() : super(config: FakeConfig(), authenticationProvider: FakeAuthenticationProvider());

  @override
  Future<Body> get() async {
    response.headers.add('X-Test-Params', requestData.toString());
    return null;
  }
}

class NeedsParams extends ApiRequestHandler<Body> {
  NeedsParams() : super(config: FakeConfig(), authenticationProvider: FakeAuthenticationProvider());

  @override
  Future<Body> get() async {
    checkRequiredParameters(<String>['param1', 'param2']);
    return null;
  }
}

class AccessAuth extends ApiRequestHandler<Body> {
  AccessAuth() : super(config: FakeConfig(), authenticationProvider: FakeAuthenticationProvider());

  @override
  Future<Body> get() async {
    response.headers.add('X-Test-IsAgent', authContext.agent != null);
    response.headers.add('X-Test-IsDev', authContext.clientContext.isDevelopmentEnvironment);
    return null;
  }
}
