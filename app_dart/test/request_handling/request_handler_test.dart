// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cocoon_server/logging.dart';
import 'package:cocoon_service/src/request_handling/body.dart';
import 'package:cocoon_service/src/request_handling/exceptions.dart';
import 'package:cocoon_service/src/request_handling/request_handler.dart';
import 'package:gcloud/service_scope.dart' as ss;
import 'package:logging/logging.dart';
import 'package:test/test.dart';

import '../src/datastore/fake_config.dart';

void main() {
  group('RequestHandler', () {
    late HttpServer server;
    late RequestHandler<dynamic> handler;

    final records = <LogRecord>[];

    setUpAll(() async {
      server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      server.listen((HttpRequest request) {
        runZoned<dynamic>(() {
          return ss.fork(() {
            return handler.service(request);
          });
        });
      });
    });

    tearDownAll(() async {
      await server.close();
    });

    setUp(() {
      records.clear();
      log.onRecord.listen(records.add);
    });

    Future<HttpClientResponse> issueRequest(String method) async {
      final client = HttpClient();
      final url = Uri(
        scheme: 'http',
        host: 'localhost',
        port: server.port,
        path: '/path',
      );
      final request = await client.openUrl(method, url);
      return request.close();
    }

    Future<HttpClientResponse> issueGet() async => issueRequest('get');

    Future<HttpClientResponse> issuePost() async => issueRequest('post');

    test('Unimplemented methods yield HTTP method not allowed', () async {
      handler = MethodNotAllowed();
      var response = await issueGet();
      expect(response.statusCode, HttpStatus.methodNotAllowed);
      response = await issuePost();
      expect(response.statusCode, HttpStatus.methodNotAllowed);
      expect(records, isEmpty);
    });

    test('empty body yields empty HTTP response body', () async {
      handler = EmptyBodyHandler();
      final response = await issueGet();
      expect(response.statusCode, HttpStatus.ok);
      expect(await response.toList(), isEmpty);
      expect(records, isEmpty);
    });

    test('string body yields string HTTP response body', () async {
      handler = StringBodyHandler();
      final response = await issueGet();
      expect(response.statusCode, HttpStatus.ok);
      expect(await utf8.decoder.bind(response).join(), 'Hello world');
      expect(records, isEmpty);
    });

    test('JsonBody yields JSON HTTP response body', () async {
      handler = JsonBodyHandler();
      final response = await issueGet();
      expect(response.statusCode, HttpStatus.ok);
      expect(await utf8.decoder.bind(response).join(), '{"key":"value"}');
      expect(records, isEmpty);
    });

    test('throwing HttpException yields corresponding HTTP status', () async {
      handler = ThrowsHttpException();
      final response = await issueGet();
      expect(response.statusCode, HttpStatus.badRequest);
      expect(await utf8.decoder.bind(response).join(), 'Bad request');
      expect(records, isEmpty);
    });

    test(
      'throwing general exception yields HTTP 500 and logs to server logs',
      () async {
        handler = ThrowsStateError();
        final response = await issueGet();
        expect(response.statusCode, HttpStatus.internalServerError);
        expect(
          await utf8.decoder.bind(response).join(),
          contains('error message'),
        );
        expect(records.first.message, contains('error message'));
      },
    );

    test('may access the request and response directly', () async {
      handler = AccessesRequestAndResponseDirectly();
      final response = await issueGet();
      expect(response.headers.value('X-Test-Path'), '/path');
      expect(records, isEmpty);
    });

    test('may implement both GET and POST', () async {
      handler = ImplementsBothGetAndPost();
      var response = await issueGet();
      expect(response.headers.value('X-Test-Get'), 'true');
      expect(response.headers.value('X-Test-Post'), isNull);
      response = await issuePost();
      expect(response.headers.value('X-Test-Get'), isNull);
      expect(response.headers.value('X-Test-Post'), 'true');
      expect(records, isEmpty);
    });

    test('may implement only POST', () async {
      handler = ImplementsOnlyPost();
      var response = await issueGet();
      expect(response.statusCode, HttpStatus.methodNotAllowed);
      response = await issuePost();
      expect(response.statusCode, HttpStatus.ok);
      expect(records, isEmpty);
    });
  });
}

class TestBody extends JsonBody {
  const TestBody();

  @override
  Map<String, dynamic> toJson() => const <String, dynamic>{'key': 'value'};
}

class MethodNotAllowed extends RequestHandler<Body> {
  MethodNotAllowed() : super(config: FakeConfig());
}

class EmptyBodyHandler extends RequestHandler<Body> {
  EmptyBodyHandler() : super(config: FakeConfig());

  @override
  Future<Body> get() async => Body.empty;
}

class StringBodyHandler extends RequestHandler<Body> {
  StringBodyHandler() : super(config: FakeConfig());

  @override
  Future<Body> get() async => Body.forString('Hello world');
}

class JsonBodyHandler extends RequestHandler<TestBody> {
  JsonBodyHandler() : super(config: FakeConfig());

  @override
  Future<TestBody> get() async => const TestBody();
}

class ThrowsHttpException extends RequestHandler<Body> {
  ThrowsHttpException() : super(config: FakeConfig());

  @override
  Future<Body> get() async => throw const BadRequestException();
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
    response!.headers.add('X-Test-Path', request!.uri.path);
    return Body.empty;
  }
}

class ImplementsBothGetAndPost extends RequestHandler<Body> {
  ImplementsBothGetAndPost() : super(config: FakeConfig());

  @override
  Future<Body> get() async {
    response!.headers.add('X-Test-Get', 'true');
    return Body.empty;
  }

  @override
  Future<Body> post() async {
    response!.headers.add('X-Test-Post', 'true');
    return Body.empty;
  }
}

class ImplementsOnlyPost extends RequestHandler<Body> {
  ImplementsOnlyPost() : super(config: FakeConfig());

  @override
  Future<Body> post() async => Body.empty;
}
