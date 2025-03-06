// Copyright 2023 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:http/http.dart';

class DebugHttpClient extends BaseClient {
  DebugHttpClient({final Client? client}) : _client = client ?? Client();

  final Client _client;

  @override
  Future<StreamedResponse> send(final BaseRequest request) async {
    final response = await _client.send(request);
    final bytes = await response.stream.toBytes();
    print(request.url);
    print(utf8.decode(bytes));
    return StreamedResponse(
      Stream<List<int>>.value(bytes),
      response.statusCode,
      contentLength: response.contentLength,
      request: response.request,
      headers: response.headers,
      isRedirect: response.isRedirect,
      persistentConnection: response.persistentConnection,
      reasonPhrase: response.reasonPhrase,
    );
  }

  @override
  void close() {
    _client.close();
  }
}
