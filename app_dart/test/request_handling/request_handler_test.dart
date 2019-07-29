// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cocoon_service/src/request_handling/body.dart';
import 'package:cocoon_service/src/request_handling/exceptions.dart';
import 'package:cocoon_service/src/request_handling/request_handler.dart';
import 'package:test/test.dart';

import '../src/datastore/fake_cocoon_config.dart';

void main() {
  group('RequestHandler', () {
    HttpServer server;
    StringBuffer serverOutput;
    RequestHandler<dynamic> handler;

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

    Future<HttpClientResponse> issueRequest(String method) async {
      final HttpClient client = HttpClient();
      final Uri url = Uri(scheme: 'http', host: 'localhost', port: server.port, path: '/path');
      final HttpClientRequest request = await client.openUrl(method, url);
      return await request.close();
    }

    Future<HttpClientResponse> issueGet() => issueRequest('get');

    Future<HttpClientResponse> issuePost() => issueRequest('post');

    test('Unimplemented methods yield HTTP method not allowed', () async {
      handler = MethodNotAllowed();
      HttpClientResponse response = await issueGet();
      expect(response.statusCode, HttpStatus.methodNotAllowed);
      response = await issuePost();
      expect(response.statusCode, HttpStatus.methodNotAllowed);
      expect(serverOutput.toString(), isEmpty);
    });

    test('empty body yields empty HTTP response body', () async {
      handler = EmptyBody();
      final HttpClientResponse response = await issueGet();
      expect(response.statusCode, HttpStatus.ok);
      expect(await response.toList(), isEmpty);
      expect(serverOutput.toString(), isEmpty);
    });

    test('non-empty body yields JSON HTTP response body', () async {
      handler = NonNullBody();
      final HttpClientResponse response = await issueGet();
      expect(response.statusCode, HttpStatus.ok);
      expect(await utf8.decoder.bind(response).join(), '{"key":"value"}');
      expect(serverOutput.toString(), isEmpty);
    });

    test('throwing HttpException yields corresponding HTTP status', () async {
      handler = ThrowsHttpException();
      final HttpClientResponse response = await issueGet();
      expect(response.statusCode, HttpStatus.badRequest);
      expect(await utf8.decoder.bind(response).join(), 'Bad request');
      expect(serverOutput.toString(), isEmpty);
    });

    test('throwing general exception yields HTTP 500 and logs to server logs', () async {
      handler = ThrowsStateError();
      final HttpClientResponse response = await issueGet();
      expect(response.statusCode, HttpStatus.internalServerError);
      expect(await utf8.decoder.bind(response).join(), contains('error message'));
      expect(serverOutput.toString(), contains('error message'));
    });

    test('may access the request and response directly', () async {
      handler = AccessesRequestAndResponseDirectly();
      final HttpClientResponse response = await issueGet();
      expect(response.headers.value('X-Test-Path'), '/path');
      expect(serverOutput.toString(), isEmpty);
    });

    test('may implement both GET and POST', () async {
      handler = ImplementsBothGetAndPost();
      HttpClientResponse response = await issueGet();
      expect(response.headers.value('X-Test-Get'), 'true');
      expect(response.headers.value('X-Test-Post'), isNull);
      response = await issuePost();
      expect(response.headers.value('X-Test-Get'), isNull);
      expect(response.headers.value('X-Test-Post'), 'true');
      expect(serverOutput.toString(), isEmpty);
    });

    test('may implement only POST', () async {
      handler = ImplementsOnlyPost();
      HttpClientResponse response = await issueGet();
      expect(response.statusCode, HttpStatus.methodNotAllowed);
      response = await issuePost();
      expect(response.statusCode, HttpStatus.ok);
      expect(serverOutput.toString(), isEmpty);
    });
  });
}

class TestBody extends Body {
  const TestBody();

  @override
  Map<String, dynamic> toJson() => const <String, dynamic>{'key': 'value'};
}

class MethodNotAllowed extends RequestHandler<Body> {
  MethodNotAllowed() : super(config: FakeConfig());
}

class EmptyBody extends RequestHandler<Body> {
  EmptyBody() : super(config: FakeConfig());

  @override
  Future<Body> get() async => Body.empty;
}

class NonNullBody extends RequestHandler<TestBody> {
  NonNullBody() : super(config: FakeConfig());

  @override
  Future<TestBody> get() async => const TestBody();
}

class ThrowsHttpException extends RequestHandler<Body> {
  ThrowsHttpException() : super(config: FakeConfig());

  @override
  Future<Body> get() async => throw BadRequestException();
}

class ThrowsStateError extends RequestHandler<Body> {
  ThrowsStateError() : super(config: FakeConfig());

  @override
  Future<Body> get() async => throw StateError('error message');
}

class AccessesRequestAndResponseDirectly extends RequestHandler<Body> {
  AccessesRequestAndResponseDirectly() : super(config: FakeConfig());

  @override
  Future<Body> get() async {
    response.headers.add('X-Test-Path', request.uri.path);
    return Body.empty;
  }
}

class ImplementsBothGetAndPost extends RequestHandler<Body> {
  ImplementsBothGetAndPost() : super(config: FakeConfig());

  @override
  Future<Body> get() async {
    response.headers.add('X-Test-Get', 'true');
    return Body.empty;
  }

  @override
  Future<Body> post() async {
    response.headers.add('X-Test-Post', 'true');
    return Body.empty;
  }
}

class ImplementsOnlyPost extends RequestHandler<Body> {
  ImplementsOnlyPost() : super(config: FakeConfig());

  @override
  Future<Body> post() async => Body.empty;
}
