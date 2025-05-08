// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:typed_data';

import 'package:cocoon_common/core_extensions.dart';
import 'package:test/test.dart';

void main() {
  group('BytesStreamExtension', () {
    test('collectBytes folds Stream<List<int>> into Uint8List', () async {
      final stream = Stream.fromIterable([
        [1, 2],
        [3, 4],
      ]);
      final bytes = await stream.collectBytes();
      expect(bytes, allOf(isA<Uint8List>(), [1, 2, 3, 4]));
    });
  });

  group('BytesExtension', () {
    final encoder = JsonUtf8Encoder().cast<Object?, Uint8List>();

    group('parseAsJson', () {
      test('fails due to an unexpected type', () {
        final bytes = encoder.convert('Hello I am a string not a bool');
        expect(() => bytes.parseAsJson<bool>(), throwsFormatException);
      });

      test('succeeds', () {
        final bytes = encoder.convert(true);
        expect(bytes.parseAsJson<bool>(), isTrue);
      });
    });

    group('parseAsJsonObject', () {
      test('fails due to an unexpected type', () {
        final bytes = encoder.convert('Hello I am a string not an object');
        expect(bytes.parseAsJsonObject, throwsFormatException);
      });

      test('succeeds', () {
        final bytes = encoder.convert({'hello': 'world'});
        expect(bytes.parseAsJsonObject(), {'hello': 'world'});
      });
    });
  });
}
