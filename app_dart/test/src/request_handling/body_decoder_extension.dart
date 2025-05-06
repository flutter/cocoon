// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:cocoon_common/bytes_stream.dart';
import 'package:cocoon_service/src/request_handling/request_handler.dart';

extension BodyDecoder on Body {
  Future<R> readAsJson<R extends Object?>() async {
    final bytes = await contents.collectBytes();
    final object = _utf8JsonDecoder.convert(bytes);
    return object as R;
  }

  Future<String> readAsString() async {
    final bytes = await contents.collectBytes();
    return utf8.decode(bytes);
  }

  /// A special decoder that decodes UTF-8 bytes into JSON values.
  ///
  /// Backend implementations in the Dart SDK typically optimize this fused
  /// decoder compared to the default [dart.JsonDecoder] which operates on
  /// UTF-16 strings.
  ///
  /// See <https://github.com/dart-lang/sdk/issues/55996> for more information.
  static final _utf8JsonDecoder = utf8.decoder.fuse(json.decoder);
}
