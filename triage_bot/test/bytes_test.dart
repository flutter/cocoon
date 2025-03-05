// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:test/test.dart';
import 'package:triage_bot/bytes.dart';

void main() {
  test('roundtrip null', () {
    final FileWriter writer = FileWriter();
    writer.writeNullOr<bool>(null, writer.writeBool);
    final FileReader reader = FileReader(writer.serialize());
    expect(reader.readNullOr<bool>(reader.readBool), isNull);
    reader.close();
  });

  test('roundtrip true', () {
    final FileWriter writer = FileWriter();
    writer.writeNullOr<bool>(true, writer.writeBool);
    final FileReader reader = FileReader(writer.serialize());
    expect(reader.readNullOr<bool>(reader.readBool), isTrue);
    reader.close();
  });

  test('roundtrip false', () {
    final FileWriter writer = FileWriter();
    writer.writeNullOr<bool>(false, writer.writeBool);
    final FileReader reader = FileReader(writer.serialize());
    expect(reader.readNullOr<bool>(reader.readBool), isFalse);
    reader.close();
  });

  test('roundtrip integer', () {
    final FileWriter writer = FileWriter();
    writer.writeInt(12345);
    final FileReader reader = FileReader(writer.serialize());
    expect(reader.readInt(), 12345);
    reader.close();
  });

  test('roundtrip String', () {
    final FileWriter writer = FileWriter();
    writer.writeString('');
    writer.writeString('abc');
    writer.writeString(String.fromCharCode(0));
    writer.writeString('🤷🏿');
    final FileReader reader = FileReader(writer.serialize());
    expect(reader.readString(), '');
    expect(reader.readString(), 'abc');
    expect(reader.readString(), '\x00');
    expect(reader.readString(), '🤷🏿');
    reader.close();
  });

  test('roundtrip DateTime', () {
    final FileWriter writer = FileWriter();
    writer.writeDateTime(DateTime.utc(2023, 6, 23, 15, 45));
    final FileReader reader = FileReader(writer.serialize());
    expect(reader.readDateTime().toIso8601String(), '2023-06-23T15:45:00.000Z');
    reader.close();
  });

  test('roundtrip Set', () {
    final FileWriter writer = FileWriter();
    writer.writeSet(writer.writeString, <String>{'a', 'b', 'c'});
    final FileReader reader = FileReader(writer.serialize());
    expect(reader.readSet(reader.readString), <String>{'c', 'b', 'a'});
    reader.close();
  });

  test('roundtrip Map', () {
    final FileWriter writer = FileWriter();
    writer.writeMap(writer.writeString, writer.writeInt,
        <String, int>{'a': 1, 'b': 2, 'c': 3});
    final FileReader reader = FileReader(writer.serialize());
    expect(reader.readMap(reader.readString, reader.readInt),
        <String, int>{'c': 3, 'b': 2, 'a': 1});
    reader.close();
  });
}
