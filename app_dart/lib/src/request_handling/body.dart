// Copyright 2019 The Chromium Authors. All rights reserved.
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
  factory Body.forStream(Stream<Uint8List> stream) => _StreamBody(stream);

  /// Value indicating that the HTTP response body should be empty.
  static const Body empty = _EmptyBody();

  /// Serializes this response body to bytes.
  Stream<Uint8List> serialize();
}

abstract class JsonBody extends Body {
  const JsonBody();

  @override
  Stream<Uint8List> serialize() {
    return utf8.encoder.bind(json.encoder.bind(Stream<Object>.fromIterable(<Object>[toJson()])));
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
    return utf8.encoder.bind(Stream<String>.fromIterable(<String>[content]));
  }
}

class _StreamBody extends Body {
  const _StreamBody(this.stream);

  final Stream<Uint8List> stream;

  @override
  Stream<Uint8List> serialize() => stream;
}
