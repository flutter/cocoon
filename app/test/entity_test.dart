// Copyright (c) 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

@TestOn('vm')

import 'package:test/test.dart';

import 'package:cocoon/entity.dart';

void main() {
  group('Entity', () {
    test('sets and serializes properties', () {
      TestEntity e = new TestEntity();
      e['foo'] = 123;
      expect(e['foo'], 123);
      expect(e.toJson(), {'foo': 123});
    });

    test('accepts pre-filled properties', () {
      TestEntity e = new TestEntity({'foo': 123});
      expect(e['foo'], 123);
    });
  });

  group('string', () {
    test('serializes and deserializes strings', () {
      expect(string().serialize('hello'), 'hello');
      expect(string().deserialize('hello'), 'hello');
      expect(() => string().deserialize(1), throws);
    });
  });

  group('listOf', () {
    test('serializes and deserializes lists', () {
      expect(
        listOf(TestEntity._serializer).serialize([new TestEntity()..foo = 123]),
        [{'foo': 123}]
      );
      expect(() => listOf(null), throws);
      expect(() => listOf(TestEntity._serializer).deserialize(1), throws);
    });
  });

  group('number', () {
    test('serializes and deserializes ints and doubles', () {
      expect(number().serialize(1), 1);
      expect(number().deserialize(1), 1);
      expect(number().serialize(1.2), 1.2);
      expect(number().deserialize(1.2), 1.2);
      expect(() => number().deserialize('hello'), throws);
    });
  });

  group('dateTime', () {
    var testDate = new DateTime(2016, 6, 28);
    var testMillis = testDate.millisecondsSinceEpoch;

    test('serialize DateTime', () {
      expect(dateTime().serialize(testDate), testMillis);
      expect(dateTime().serialize(null), 0);
    });

    test('deserialize DateTime', () {
      expect(
        dateTime().deserialize(testMillis),
        testDate
      );
      expect(dateTime().deserialize(0), null);
    });
  });
}

class TestEntity extends Entity {
  static final _serializer = new EntitySerializer(
    (Map<String, dynamic> props) => new TestEntity(props),
    <String, JsonSerializer>{
      'foo': number(),
    });

  TestEntity([Map<String, dynamic> props]) : super(_serializer, props);

  int get foo => this['foo'];
  set foo(int v) {
    this['foo'] = v;
  }
}
