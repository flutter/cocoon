// Copyright 2026 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:cocoon_service/src/request_handling/http_io.dart';
import 'package:http/http.dart' as http;

import '../testing.dart';
import 'server.dart';

class IntegrationHttpClient extends http.BaseClient {
  IntegrationHttpClient(this.server);

  final IntegrationServer server;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final bodyBytes = await request.finalize().toBytes();
    final body = utf8.decode(bodyBytes);

    final fakeResponse = FakeHttpResponse();
    final fakeRequest = FakeHttpRequest(
      method: request.method,
      body: body,
      path: request.url.path,
      queryParametersValue: request.url.queryParameters,
      response: fakeResponse,
    );

    request.headers.forEach((key, value) {
      fakeRequest.headers.add(key, value);
    });

    await server.server(fakeRequest.toRequest());

    final responseHeaders = <String, String>{};
    fakeResponse.headers.forEach((name, values) {
      responseHeaders[name] = values.join(',');
    });

    return http.StreamedResponse(
      Stream.value(utf8.encode(fakeResponse.body)),
      fakeResponse.statusCode,
      contentLength: fakeResponse.body.length,
      headers: responseHeaders,
    );
  }
}
