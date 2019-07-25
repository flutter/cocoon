// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:cocoon_service/cocoon_service.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

void main() {
  HttpServer destServer;

  setUpAll(() async {
    destServer = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    destServer.defaultResponseHeaders.clear();
    destServer.serverHeader = null;
    destServer.listen((HttpRequest request) async {
      final HttpResponse response = request.response;
      response.headers.add('X-Single-Header', 'SingleValue');
      response.headers.add('X-Multi-Header', 'Value1');
      response.headers.add('X-Multi-Header', 'Value2');

      switch (request.uri.path) {
        case '/ok':
          response.statusCode = HttpStatus.ok;
          break;
        case '/notFound':
          response.statusCode = HttpStatus.notFound;
          break;
        case '/redirect':
          response.headers.add(HttpHeaders.locationHeader, '/foo');
          response.statusCode = HttpStatus.movedTemporarily;
          break;
        case '/rawBody':
          response.write('hello world');
          await response.flush();
          await response.close();
          return;
        default:
          response.statusCode = HttpStatus.methodNotAllowed;
      }

      bool isIgnoredHeader(String key, String value) {
        return key.toLowerCase() == HttpHeaders.contentLengthHeader.toLowerCase();
      }

      Map<String, String> headers = <String, String>{};
      request.headers.forEach((String name, List<String> values) => headers[name] = values.single);
      response.write(json.encode(<String, dynamic>{
        'headers': headers..removeWhere(isIgnoredHeader),
        'path': request.uri.path,
        'query': request.uri.query,
        'fragment': request.uri.fragment,
        'body': await utf8.decoder.bind(request).join(),
      }));
      await response.flush();
      await response.close();
    });
  });

  tearDownAll(() async {
    await destServer.close();
  });

  group('ProxyRequestHandler', () {
    ProxyRequestHandler handler;
    HttpServer proxyServer;
    HttpClient client;
    Uri url;

    HttpClientRequest request;
    HttpClientResponse response;

    setUp(() async {
      handler = ProxyRequestHandler(
        config: MockConfig(),
        scheme: 'http',
        host: 'localhost',
        port: destServer.port,
      );
      proxyServer = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      proxyServer.listen(handler.service);
      client = HttpClient()..userAgent = null;
      url = Uri(scheme: 'http', host: 'localhost', port: proxyServer.port);
    });

    tearDown(() async {
      await proxyServer.close();
    });

    test('forwards basic request', () async {
      request = await client.getUrl(url.replace(path: '/ok'));
      request.headers.clear();
      response = await request.close();
      Map<String, dynamic> data = await utf8.decoder.bind(response).transform(json.decoder).single;
      expect(data['headers'], isEmpty);
      expect(data['path'], '/ok');
      expect(data['query'], isEmpty);
      expect(data['fragment'], isEmpty);
      expect(data['body'], isEmpty);
    });

    test('forwards HTTP request headers', () async {
      request = await client.getUrl(url.replace(path: '/ok'));
      request.headers.clear();
      request.headers.add('foo', 'bar');
      request.headers.add('baz', 'qux');
      request.headers.add('multi', 'value1');
      request.headers.add('multi', 'value2');
      response = await request.close();
      Map<String, dynamic> data = await utf8.decoder.bind(response).transform(json.decoder).single;
      expect(data['headers'], <String, dynamic>{
        'foo': 'bar',
        'baz': 'qux',
        'multi': 'value1, value2',
      });
    });

    test('forwards HTTP request body', () async {
      request = await client.getUrl(url.replace(path: '/ok'));
      request.contentLength = 'request body'.length;
      request.write('request body');
      await request.flush();
      response = await request.close();
      Map<String, dynamic> data = await utf8.decoder.bind(response).transform(json.decoder).single;
      expect(data['body'], 'request body');
    });

    test('forwards HTTP request query parameters', () async {
      request = await client.getUrl(url.replace(path: '/ok', query: 'foo=bar&baz=qux%26quz%3Dquw'));
      response = await request.close();
      Map<String, dynamic> data = await utf8.decoder.bind(response).transform(json.decoder).single;
      expect(data['query'], 'foo=bar&baz=qux%26quz%3Dquw');
    });

    test('URL fragment is dropped', () async {
      request = await client.getUrl(url.replace(path: '/ok', fragment: 'foo&bar=baz'));
      response = await request.close();
      Map<String, dynamic> data = await utf8.decoder.bind(response).transform(json.decoder).single;
      expect(data['fragment'], isEmpty);
    });

    test('forwards HTTP response status code', () async {
      request = await client.getUrl(url.replace(path: '/ok'));
      response = await request.close();
      expect(response.statusCode, HttpStatus.ok);
      request = await client.getUrl(url.replace(path: '/notFound'));
      response = await request.close();
      expect(response.statusCode, HttpStatus.notFound);
      request = await client.getUrl(url.replace(path: '/redirect'));
      request.followRedirects = false;
      response = await request.close();
      expect(response.statusCode, HttpStatus.movedTemporarily);
      expect(response.headers.value(HttpHeaders.locationHeader), '/foo');
    });

    test('forwards HTTP response headers', () async {
      request = await client.getUrl(url.replace(path: '/ok'));
      response = await request.close();
      expect(response.headers.value('X-Single-Header'), 'SingleValue');
      expect(response.headers.value('X-Multi-Header'), 'Value1, Value2');
    });

    test('forwards HTTP response body', () async {
      request = await client.getUrl(url.replace(path: '/rawBody'));
      response = await request.close();
      expect(await utf8.decoder.bind(response).join(), 'hello world');
    });
  });
}

// ignore: must_be_immutable
class MockConfig extends Mock implements Config {}
