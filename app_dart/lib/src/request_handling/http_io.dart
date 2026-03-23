// Copyright 2026 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:cocoon_common/core_extensions.dart';
import 'package:http/http.dart' as http;

import 'http_utils.dart' as http_utils;
import 'request_handler.dart';

/// Creates a [Request] by wrapping an existing [HttpRequest].
extension ToRequest on HttpRequest {
  Request toRequest() => _HttpRequest(this);
}

/// A request that is backed by an [HttpRequest].
final class _HttpRequest implements Request {
  _HttpRequest(this._request);
  final HttpRequest _request;

  @override
  Uri get uri => _request.uri;

  @override
  String get method => _request.method;

  @override
  late final RequestResponse response = _HttpResponse(_request.response);

  @override
  String? header(String name) {
    return _request.headers.value(name);
  }

  @override
  Future<Uint8List> readBodyAsBytes() async {
    if (_bodyAsBytes case final previousCall?) {
      return previousCall;
    }
    final builder = await _request.fold(BytesBuilder(copy: false), (
      builder,
      data,
    ) {
      builder.add(data);
      return builder;
    });
    return _bodyAsBytes = builder.takeBytes();
  }

  Uint8List? _bodyAsBytes;

  @override
  Future<String> readBodyAsString() async {
    return utf8.decode(await readBodyAsBytes());
  }

  @override
  Future<Map<String, Object?>> readBodyAsJson() async {
    final bytes = await readBodyAsBytes();
    return bytes.isEmpty ? {} : bytes.parseAsJsonObject();
  }
}

final class _HttpResponse implements RequestResponse {
  _HttpResponse(this._response);
  final HttpResponse _response;

  @override
  int get statusCode => _response.statusCode;
  @override
  set statusCode(int value) => _response.statusCode = value;

  @override
  set contentType(http_utils.MediaType? value) {
    if (value != null) {
      _response.headers.contentType = ContentType(
        value.type,
        value.subtype,
        charset: value.parameters['charset'],
      );
    } else {
      _response.headers.contentType = null;
    }
  }

  @override
  Future<void> addStream(Stream<Uint8List> stream) =>
      _response.addStream(stream);

  @override
  Future<void> flush() => _response.flush();

  @override
  Future<void> close() => _response.close();

  @override
  Future<dynamic> redirect(
    Uri location, {
    int status = http_utils.HttpStatus.movedTemporarily,
  }) => _response.redirect(location, status: status);
}

/// An [http.Client] that maps [SocketException] from dart:io to the cocoon
/// [http_utils.SocketException].
///
/// This is used to maintain platform neutrality in the core of app_dart.
class MappingHttpClient extends http.BaseClient {
  MappingHttpClient(this._inner);

  final http.Client _inner;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    try {
      return await _inner.send(request);
    } on SocketException catch (e) {
      throw http_utils.SocketException('$e');
    } on HttpException catch (e) {
      throw http_utils.HttpException('$e');
    }
  }

  @override
  void close() => _inner.close();
}
