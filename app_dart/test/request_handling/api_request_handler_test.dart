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
import 'package:cocoon_service/src/request_handling/api_request_handler.dart';
import 'package:cocoon_service/src/request_handling/http_io.dart';
import 'package:cocoon_service/src/request_handling/request_handler.dart';
import 'package:cocoon_service/src/request_handling/response.dart';
import 'package:gcloud/service_scope.dart' as ss;
import 'package:test/test.dart';

void main() {
  useTestLoggerPerTest();

  group('ApiRequestHandler', () {
    late HttpServer server;
    late ApiRequestHandler handler;

    setUpAll(() async {
      server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      server.listen((HttpRequest request) {
        runZoned<dynamic>(() {
          return ss.fork(() {
            ss.register(#appengine.logging, log);
            return handler.service(request.toRequest());
          });
        });
      });
    });

    tearDownAll(() async {
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
      handler = Unauth();
      final response = await issueRequest();
      expect(response.statusCode, HttpStatus.unauthorized);
      expect(await utf8.decoder.bind(response).join(), 'Not authenticated');
      expect(log, bufferedLoggerOf(isEmpty));
    });

    test('empty request body yields empty requestData', () async {
      handler = ReadParams();
      final response = await issueRequest();
      await expectLater(
        response.collectBytes(),
        completion(decodedAsJson({'requestBody': '[]', 'requestData': '{}'})),
      );
      expect(response.statusCode, HttpStatus.ok);
      expect(log, bufferedLoggerOf(isEmpty));
    });

    test('JSON request body yields valid requestData', () async {
      handler = ReadParams();
      final response = await issueRequest(body: '{"param1":"value1"}');
      await expectLater(
        response.collectBytes(),
        completion(
          decodedAsJson({
            'requestBody': isNotEmpty,
            'requestData': '{param1: value1}',
          }),
        ),
      );
      expect(response.statusCode, HttpStatus.ok);
      expect(log, bufferedLoggerOf(isEmpty));
    });

    test('can access authContext', () async {
      handler = AccessAuth();
      final response = await issueRequest();
      await expectLater(
        response.collectBytes(),
        completion(decodedAsJson({'isDevelopmentEnvironment': true})),
      );
      expect(response.statusCode, HttpStatus.ok);
      expect(log, bufferedLoggerOf(isEmpty));
    });

    test(
      'missing required request parameters yields HTTP bad request',
      () async {
        handler = NeedsParams();
        var response = await issueRequest();
        expect(response.statusCode, HttpStatus.badRequest);
        response = await issueRequest(body: '{"param1":"value1"}');
        expect(response.statusCode, HttpStatus.badRequest);
        response = await issueRequest(body: '{"param2":"value2"}');
        expect(response.statusCode, HttpStatus.badRequest);
        response = await issueRequest(
          body: '{"param1":"value1","param2":"value2"}',
        );
        expect(response.statusCode, HttpStatus.ok);
        response = await issueRequest(
          body: '{"param1":"value1","param2":"value2","extra":"yes"}',
        );
        expect(response.statusCode, HttpStatus.ok);
        expect(log, bufferedLoggerOf(isEmpty));
      },
    );
  });
}

final class Unauth extends ApiRequestHandler {
  Unauth()
    : super(
        config: FakeConfig(),
        authenticationProvider: FakeDashboardAuthentication(
          authenticated: false,
        ),
      );

  @override
  Future<Response> get(_) async => throw StateError('Unreachable');
}

final class ReadParams extends ApiRequestHandler {
  ReadParams()
    : super(
        config: FakeConfig(),
        authenticationProvider: FakeDashboardAuthentication(),
      );

  @override
  Future<Response> get(Request request) async {
    final requestBody = await request.readBodyAsBytes();
    final requestData = await request.readBodyAsJson();
    return Response.json({
      'requestBody': '$requestBody',
      'requestData': '$requestData',
    });
  }
}

final class NeedsParams extends ApiRequestHandler {
  NeedsParams()
    : super(
        config: FakeConfig(),
        authenticationProvider: FakeDashboardAuthentication(),
      );

  @override
  Future<Response> get(Request request) async {
    checkRequiredParameters(await request.readBodyAsJson(), <String>[
      'param1',
      'param2',
    ]);
    return Response.emptyOk;
  }
}

final class AccessAuth extends ApiRequestHandler {
  AccessAuth()
    : super(
        config: FakeConfig(),
        authenticationProvider: FakeDashboardAuthentication(),
      );

  @override
  Future<Response> get(_) async {
    return Response.json({
      'isDevelopmentEnvironment':
          authContext!.clientContext.isDevelopmentEnvironment,
    });
  }
}
