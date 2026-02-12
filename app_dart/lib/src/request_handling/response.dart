// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:typed_data';

import 'package:meta/meta.dart';

import 'http_utils.dart';

/// An HTTP response returned by a request handler.
///
/// A response encapsulates:
/// - the [contentType], if omitted a default is used;
/// - the [statusCode], if omitted [HttpStatus.ok] is used;
/// - the [body] contents as `Stream<Uint8List>`.
///
/// To return a response of a different underlying data type, use a constructor:
/// - [Response.string] for UTF-8 strings;
/// - [Response.stream] for a stream of bytes;
/// - [Response.json] for a JSON-encodable object;
/// - or [Response.emptyOk] for a default (empty) resposne that is always `200`.
@immutable
abstract final class Response {
  const Response({this.statusCode = HttpStatus.ok});

  /// Creates an UTF-8 string response of [content].
  ///
  /// By default, uses [kContentTypeText] and [HttpStatus.ok].
  factory Response.string(
    String content, { //
    MediaType? contentType,
    int statusCode,
  }) = _StringBody;

  /// Creates a byte-encoded stream of [content].
  ///
  /// By default, uses [kContentTypeBinary] and [HttpStatus.ok].
  factory Response.stream(
    Stream<Uint8List> content, { //
    MediaType? contentType,
    int statusCode,
  }) = _StreamBody;

  /// Creates a [Response] that serializes the specified JSON [value].
  ///
  /// The [value] argument may be any JSON tyope (any scalar value, any object
  /// that defines a `toJson()` method that returns a JSON type, or a [List] or
  /// [Map] of other JSON types).
  ///
  /// By default, uses [kContentTypeJson] and [HttpStatus.ok].
  factory Response.json(Object? value, {int statusCode}) = _JsonBody;

  /// A [Response] with an _empty_ [body] and [HttpStatus.ok].
  static const Response emptyOk = _EmptyBody();

  /// Format of the body.
  MediaType? get contentType;

  /// Status code of the response.
  final int statusCode;

  /// Content type of the response body as bytes.
  ///
  /// **NOTE**: It is not guaranteed that the returned stream can be listened
  /// to more than once.
  Stream<Uint8List> get body;
}

final class _EmptyBody extends Response {
  const _EmptyBody();

  @override
  MediaType? get contentType => null;

  @override
  Stream<Uint8List> get body => const Stream<Uint8List>.empty();
}

final class _StringBody extends Response {
  const _StringBody(
    this._content, { //
    super.statusCode,
    MediaType? contentType,
  }) : _contentType = contentType;

  final String _content;

  @override
  MediaType get contentType => _contentType ?? kContentTypeText;
  final MediaType? _contentType;

  @override
  Stream<Uint8List> get body {
    return Stream.fromIterable([utf8.encode(_content)]);
  }

  @override
  String toString() {
    return 'Body.forString($_content)';
  }
}

final class _JsonBody extends Response {
  const _JsonBody(this._content, {super.statusCode});
  final Object? _content;

  @override
  MediaType get contentType => kContentTypeJson;
  static final _utf8JsonEncoder = JsonUtf8Encoder();

  @override
  Stream<Uint8List> get body {
    return Stream.fromIterable([
      _utf8JsonEncoder.convert(_content) as Uint8List,
    ]);
  }

  @override
  String toString() {
    return 'Body.forString($_content)';
  }
}

final class _StreamBody extends Response {
  const _StreamBody(
    this._stream, { //
    super.statusCode,
    MediaType? contentType,
  }) : _contentType = contentType;

  @override
  MediaType get contentType => _contentType ?? kContentTypeBinary;
  final MediaType? _contentType;

  final Stream<Uint8List> _stream;

  @override
  Stream<Uint8List> get body => _stream;
}
