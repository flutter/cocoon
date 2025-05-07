// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:meta/meta.dart';

/// Class that represents an HTTP response body before it has been serialized.
@immutable
abstract final class Body {
  /// Creates a new [Body].
  const Body();

  /// Creates a [Body] that serializes the specified String [content].
  factory Body.forString(
    String content, { //
    ContentType? contentType,
  }) = _StringBody;

  /// Creates a [Body] that passes through the already-serialized [stream].
  factory Body.forStream(
    Stream<Uint8List> stream, { //
    ContentType? contentType,
  }) = _StreamBody;

  /// Creates a [Body] that serializes the specified JSON [value].
  ///
  /// The [value] argument may be any JSON tyope (any scalar value, any object
  /// that defines a `toJson()` method that returns a JSON type, or a [List] or
  /// [Map] of other JSON types).
  factory Body.forJson(Object? value) = _JsonBody;

  /// Value indicating that the HTTP response body should be empty.
  static const Body empty = _EmptyBody();

  /// The format of the body.
  ContentType? get contentType;

  /// Serializes this response body to bytes.
  Stream<Uint8List> serialize();
}

final class _EmptyBody extends Body {
  const _EmptyBody();

  @override
  ContentType? get contentType => null;

  @override
  Stream<Uint8List> serialize() => const Stream<Uint8List>.empty();
}

final class _StringBody extends Body {
  const _StringBody(
    this._content, { //
    ContentType? contentType,
  }) : _contentType = contentType;

  final String _content;

  @override
  ContentType get contentType => _contentType ?? ContentType.text;
  final ContentType? _contentType;

  @override
  Stream<Uint8List> serialize() {
    return Stream.fromIterable([utf8.encode(_content)]);
  }

  @override
  String toString() {
    return 'Body.forString($_content)';
  }
}

final class _JsonBody extends Body {
  const _JsonBody(this._content);
  final Object? _content;

  @override
  ContentType get contentType => ContentType.json;
  static final _utf8JsonEncoder = JsonUtf8Encoder();

  @override
  Stream<Uint8List> serialize() {
    return Stream.fromIterable([
      _utf8JsonEncoder.convert(_content) as Uint8List,
    ]);
  }

  @override
  String toString() {
    return 'Body.forString($_content)';
  }
}

final class _StreamBody extends Body {
  const _StreamBody(
    this._stream, { //
    this.contentType,
  });

  @override
  final ContentType? contentType;

  final Stream<Uint8List> _stream;

  @override
  Stream<Uint8List> serialize() => _stream;
}
