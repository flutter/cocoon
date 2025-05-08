// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cocoon_common_test/cocoon_common_test.dart';
import 'package:cocoon_server/logging.dart';
import 'package:cocoon_server_test/test_logging.dart';
import 'package:cocoon_service/src/request_handling/api_request_handler.dart';
import 'package:cocoon_service/src/request_handling/body.dart';
import 'package:cocoon_service/src/request_handling/request_handler.dart';
import 'package:gcloud/service_scope.dart' as ss;
import 'package:test/test.dart';

import '../src/fake_config.dart';
import '../src/request_handling/fake_dashboard_authentication.dart';

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
            return handler.service(request);
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
      expect(response.headers.value('X-Test-RequestBody'), '[]');
      expect(response.headers.value('X-Test-RequestData'), '{}');
      expect(response.statusCode, HttpStatus.ok);
      expect(await response.toList(), isEmpty);
      expect(log, bufferedLoggerOf(isEmpty));
    });

    test('JSON request body yields valid requestData', () async {
      handler = ReadParams();
      final response = await issueRequest(body: '{"param1":"value1"}');
      expect(response.headers.value('X-Test-RequestBody'), isNotEmpty);
      expect(response.headers.value('X-Test-RequestData'), '{param1: value1}');
      expect(response.statusCode, HttpStatus.ok);
      expect(await response.toList(), isEmpty);
      expect(log, bufferedLoggerOf(isEmpty));
    });

    test('can access authContext', () async {
      handler = AccessAuth();
      final response = await issueRequest();
      expect(response.headers.value('X-Test-IsDev'), 'true');
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
  Future<Body> get(_) async => throw StateError('Unreachable');
}

final class ReadParams extends ApiRequestHandler {
  ReadParams()
    : super(
        config: FakeConfig(),
        authenticationProvider: FakeDashboardAuthentication(),
      );

  @override
  Future<Body> get(Request request) async {
    final requestBody = await request.readBodyAsBytes();
    final requestData = await request.readBodyAsJson();
    response!.headers.add('X-Test-RequestBody', requestBody.toString());
    response!.headers.add('X-Test-RequestData', requestData.toString());
    return Body.empty;
  }
}

final class NeedsParams extends ApiRequestHandler {
  NeedsParams()
    : super(
        config: FakeConfig(),
        authenticationProvider: FakeDashboardAuthentication(),
      );

  @override
  Future<Body> get(Request request) async {
    checkRequiredParameters(await request.readBodyAsJson(), <String>[
      'param1',
      'param2',
    ]);
    return Body.empty;
  }
}

final class AccessAuth extends ApiRequestHandler {
  AccessAuth()
    : super(
        config: FakeConfig(),
        authenticationProvider: FakeDashboardAuthentication(),
      );

  @override
  Future<Body> get(_) async {
    response!.headers.add(
      'X-Test-IsDev',
      authContext!.clientContext.isDevelopmentEnvironment,
    );
    return Body.empty;
  }
}
