// Copyright 2026 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:cocoon_common/rpc_model.dart';
import 'package:cocoon_integration_test/cocoon_integration_test.dart';
import 'package:cocoon_service/cocoon_service.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'appengine_cocoon.dart';
import 'cocoon.dart';
import 'data_seeder.dart';
import 'scenarios.dart';

/// Adapter to wrap the [IntegrationServer] and expose it as a [CocoonService].
///
/// This adapter intercepts HTTP requests and routes them to the in-memory
/// [IntegrationServer] instance.
class IntegrationServerAdapter extends AppEngineCocoonService {
  final DateTime _now;
  IntegrationServerAdapter(this._server, {bool seed = true, DateTime? now})
    : _now = now ?? DateTime.utc(2020),
      super(
        client: MockClient((http.Request request) async {
          final fakeRequest = _FakeRequest(
            uri: request.url,
            method: request.method,
            body: request.body,
            headers: request.headers,
          );

          await _server.server(fakeRequest);
          final fakeResponse = fakeRequest.response;

          return http.Response(
            fakeResponse.bodyString,
            fakeResponse.statusCode,
            headers: fakeResponse.contentType != null
                ? {
                    HttpHeaders.contentTypeHeader: fakeResponse.contentType
                        .toString(),
                  }
                : {},
          );
        }),
      ) {
    if (seed) {
      DataSeeder(_server).seed(now: _now);
    }
  }

  final IntegrationServer _server;

  bool _paused = false;

  /// Whether requests to this adapter are paused.
  ///
  /// When true, [fetchCommitStatuses] will not complete until [paused] is set
  /// back to false.
  bool get paused => _paused;
  set paused(bool value) {
    _paused = value;
    if (!_paused) {
      _pauseCompleter?.complete();
      _pauseCompleter = null;
    }
  }

  Completer<void>? _pauseCompleter;

  @override
  Future<CocoonResponse<List<CommitStatus>>> fetchCommitStatuses({
    CommitStatus? lastCommitStatus,
    String? branch,
    required String repo,
  }) async {
    if (_paused) {
      _pauseCompleter ??= Completer<void>();
      await _pauseCompleter!.future;
    }
    return super.fetchCommitStatuses(
      lastCommitStatus: lastCommitStatus,
      branch: branch,
      repo: repo,
    );
  }

  @override
  void resetScenario(Scenario scenario) {
    _server.firestore.reset();
    DataSeeder(_server, scenario: scenario).seed(now: _now);
  }
}

class _FakeRequest implements Request {
  _FakeRequest({
    required this.uri,
    required this.method,
    required this.body,
    required Map<String, String> headers,
  }) : _headers = headers.map((k, v) => MapEntry(k.toLowerCase(), v)),
       response = _FakeRequestResponse();

  @override
  final Uri uri;

  @override
  final String method;

  final String body;

  final Map<String, String> _headers;

  @override
  final _FakeRequestResponse response;

  @override
  String? header(String name) => _headers[name.toLowerCase()];

  @override
  Future<Uint8List> readBodyAsBytes() async =>
      Uint8List.fromList(utf8.encode(body));

  @override
  Future<String> readBodyAsString() async => body;

  @override
  Future<Map<String, Object?>> readBodyAsJson() async =>
      jsonDecode(body) as Map<String, Object?>;
}

class _FakeRequestResponse implements RequestResponse {
  final List<Uint8List> _chunks = [];

  @override
  int statusCode = HttpStatus.ok;

  @override
  MediaType? contentType;

  String get bodyString => utf8.decode(_chunks.expand((x) => x).toList());

  @override
  Future<void> addStream(Stream<Uint8List> stream) async {
    await for (final chunk in stream) {
      _chunks.add(chunk);
    }
  }

  @override
  Future<void> flush() async {}

  @override
  Future<void> close() async {}

  @override
  Future<dynamic> redirect(
    Uri location, {
    int status = HttpStatus.movedTemporarily,
  }) async {
    statusCode = status;
  }
}
