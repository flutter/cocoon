// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:typed_data';

import 'package:meta/meta.dart';

/// Class that represents an HTTP response body before it has been serialized.
@immutable
abstract class Body {
  /// Creates a new [Body].
  const Body();

  /// Creates a [Body] that serializes the specified String [content].
  factory Body.forString(String content) => _StringBody(content);

  /// Creates a [Body] that passes through the already-serialized [stream].
  factory Body.forStream(Stream<Uint8List?> stream) => _StreamBody(stream);

  /// Creates a [Body] that serializes the specified JSON [value].
  ///
  /// The [value] argument may be any JSON tyope (any scalar value, any object
  /// that defines a `toJson()` method that returns a JSON type, or a [List] or
  /// [Map] of other JSON types).
  factory Body.forJson(dynamic value) => Body.forString(json.encode(value));

  /// Value indicating that the HTTP response body should be empty.
  static const Body empty = _EmptyBody();

  /// Serializes this response body to bytes.
  Stream<Uint8List?> serialize();
}

abstract class JsonBody extends Body {
  const JsonBody();

  @override
  Stream<Uint8List> serialize() {
    final raw = json.encoder.bind(
      Stream<Object>.fromIterable(<Object>[toJson()]),
    );
    return utf8.encoder.bind(raw).cast<Uint8List>();
  }

  /// Serializes this response body to a JSON-primitive map.
  Map<String, dynamic> toJson();
}

class _EmptyBody extends Body {
  const _EmptyBody();

  @override
  Stream<Uint8List> serialize() => const Stream<Uint8List>.empty();
}

class _StringBody extends Body {
  const _StringBody(this.content);

  final String content;

  @override
  Stream<Uint8List> serialize() {
    return utf8.encoder
        .bind(Stream<String>.fromIterable(<String>[content]))
        .cast<Uint8List>();
  }
}

class _StreamBody extends Body {
  const _StreamBody(this.stream);

  final Stream<Uint8List?> stream;

  @override
  Stream<Uint8List?> serialize() => stream;
}
