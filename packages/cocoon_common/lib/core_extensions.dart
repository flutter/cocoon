// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:typed_data';

export 'src/time_range.dart';

extension BytesStreamExtension on Stream<List<int>> {
  /// Collects and returns all of the integer lists as list of bytes.
  Future<Uint8List> collectBytes({bool copy = true}) async {
    final builder = await fold(BytesBuilder(copy: copy), (builder, data) {
      builder.add(data);
      return builder;
    });
    return builder.takeBytes();
  }
}

/// A singleton instance of [JsonUtf8Decoder].
const Converter<List<int>, Object?> jsonUtf8Decoder = JsonUtf8Decoder();

/// A special decoder that decodes UTF-8 bytes into JSON values.
///
/// Backend implementations in the Dart SDK typically optimize this fused
/// decoder compared to the default [dart.JsonDecoder] which operates on
/// UTF-16 strings.
///
/// See <https://github.com/dart-lang/sdk/issues/55996> for more information.
final class JsonUtf8Decoder extends Converter<List<int>, Object?> {
  /// Creates a decoder.
  ///
  /// See [jsonUtf8Decoder] for a singleton instance.
  const JsonUtf8Decoder();

  /// A special decoder that decodes UTF-8 bytes into JSON values.
  ///
  /// Backend implementations in the Dart SDK typically optimize this fused
  /// decoder compared to the default [dart.JsonDecoder] which operates on
  /// UTF-16 strings.
  ///
  /// See <https://github.com/dart-lang/sdk/issues/55996> for more information.
  static final _utf8JsonDecoder = utf8.decoder.fuse(json.decoder);

  @override
  Object? convert(List<int> input) {
    return _utf8JsonDecoder.convert(input);
  }
}

extension BytesExtension on Uint8List {
  /// Parses a collection of bytes as a UTF-8 encoded JSON value.
  T parseAsJson<T extends Object?>() {
    final result = jsonUtf8Decoder.convert(this);
    if (result is T) {
      return result;
    }
    throw FormatException(
      'JSON result was of type ${result.runtimeType}, not $T',
      result,
    );
  }

  /// Parses a collection of bytes as a UTF-8 encoded JSON object.
  Map<String, Object?> parseAsJsonObject() => parseAsJson();
}
