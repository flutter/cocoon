// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cocoon_common/core_extensions.dart';
import 'package:cocoon_common_test/cocoon_common_test.dart';
import 'package:cocoon_integration_test/testing.dart';
import 'package:cocoon_server/logging.dart';
import 'package:cocoon_server_test/test_logging.dart';
import 'package:cocoon_service/src/request_handling/exceptions.dart';
import 'package:cocoon_service/src/request_handling/http_io.dart';
import 'package:cocoon_service/src/request_handling/request_handler.dart';
import 'package:cocoon_service/src/request_handling/response.dart';
import 'package:gcloud/service_scope.dart' as ss;
import 'package:test/test.dart';

void main() {
  useTestLoggerPerTest();

  group('RequestHandler', () {
    late HttpServer server;
    late RequestHandler handler;

    setUpAll(() async {
      server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      server.listen((HttpRequest request) {
        runZoned<dynamic>(() {
          return ss.fork(() {
            return handler.service(request.toRequest());
          });
        });
      });
    });

    tearDownAll(() async {
      await server.close();
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

    Future<Map<String, Object?>> decodeBody(HttpClientResponse response) async {
      final body = await response.collectBytes();
      return body.parseAsJsonObject();
    }

    test('Unimplemented methods yield HTTP method not allowed', () async {
      handler = MethodNotAllowed();
      var response = await issueGet();
      expect(response.statusCode, HttpStatus.methodNotAllowed);
      response = await issuePost();
      expect(response.statusCode, HttpStatus.methodNotAllowed);
      expect(log, bufferedLoggerOf(isEmpty));
    });

    test('empty body yields empty HTTP response body', () async {
      handler = EmptyBodyHandler();
      final response = await issueGet();
      expect(response.statusCode, HttpStatus.ok);
      expect(await response.toList(), isEmpty);
      expect(log, bufferedLoggerOf(isEmpty));
    });

    test('string body yields string HTTP response body', () async {
      handler = StringBodyHandler();
      final response = await issueGet();
      expect(response.statusCode, HttpStatus.ok);
      expect(await utf8.decoder.bind(response).join(), 'Hello world');
      expect(log, bufferedLoggerOf(isEmpty));
    });

    test('throwing HttpException yields corresponding HTTP status', () async {
      handler = ThrowsHttpException();
      final response = await issueGet();
      expect(response.statusCode, HttpStatus.badRequest);
      expect(
        await utf8.decoder.bind(response).join(),
        '{"error":"Bad request"}',
      );
      expect(log, bufferedLoggerOf(isEmpty));
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
        expect(
          log,
          bufferedLoggerOf(
            equals([
              logThat(
                message: contains('Internal server error'),
                error: isA<StateError>().having(
                  (e) => e.message,
                  'message',
                  contains('error message'),
                ),
              ),
            ]),
          ),
        );
      },
    );

    test('may access the request and response directly', () async {
      handler = AccessesRequestAndResponseDirectly();
      final response = await issueGet();
      final jsonBody = await decodeBody(response);
      expect(jsonBody, {'request.uri.path': '/path'});
      expect(log, bufferedLoggerOf(isEmpty));
    });

    test('may implement both GET and POST', () async {
      handler = ImplementsBothGetAndPost();
      var response = await issueGet();
      var jsonBody = await decodeBody(response);
      expect(jsonBody, {'method': 'GET'});
      response = await issuePost();
      jsonBody = await decodeBody(response);
      expect(jsonBody, {'method': 'POST'});
      expect(log, bufferedLoggerOf(isEmpty));
    });

    test('may implement only POST', () async {
      handler = ImplementsOnlyPost();
      var response = await issueGet();
      expect(response.statusCode, HttpStatus.methodNotAllowed);
      response = await issuePost();
      expect(response.statusCode, HttpStatus.ok);
      expect(log, bufferedLoggerOf(isEmpty));
    });
  });
}

final class MethodNotAllowed extends RequestHandler {
  MethodNotAllowed() : super(config: FakeConfig());
}

final class EmptyBodyHandler extends RequestHandler {
  EmptyBodyHandler() : super(config: FakeConfig());

  @override
  Future<Response> get(_) async => Response.emptyOk;
}

final class StringBodyHandler extends RequestHandler {
  StringBodyHandler() : super(config: FakeConfig());

  @override
  Future<Response> get(_) async => Response.string('Hello world');
}

final class ThrowsHttpException extends RequestHandler {
  ThrowsHttpException() : super(config: FakeConfig());

  @override
  Future<Response> get(_) async => throw const BadRequestException();
}

final class ThrowsStateError extends RequestHandler {
  ThrowsStateError() : super(config: FakeConfig());

  @override
  Future<Response> get(_) async => throw StateError('error message');
}

final class AccessesRequestAndResponseDirectly extends RequestHandler {
  AccessesRequestAndResponseDirectly() : super(config: FakeConfig());

  @override
  Future<Response> get(Request request) async {
    return Response.json({'request.uri.path': request.uri.path});
  }
}

final class ImplementsBothGetAndPost extends RequestHandler {
  ImplementsBothGetAndPost() : super(config: FakeConfig());

  @override
  Future<Response> get(_) async {
    return Response.json({'method': 'GET'});
  }

  @override
  Future<Response> post(_) async {
    return Response.json({'method': 'POST'});
  }
}

final class ImplementsOnlyPost extends RequestHandler {
  ImplementsOnlyPost() : super(config: FakeConfig());

  @override
  Future<Response> post(_) async => Response.emptyOk;
}
