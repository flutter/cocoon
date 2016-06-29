// Copyright (c) 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:test/test.dart';

import 'package:cocoon/entity.dart';

main() {
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
    test('serialize DateTime', () {
      expect(dateTime().serialize(new DateTime(2016, 6, 28)), '2016-06-28T00:00:00Z');
      expect(
        dateTime().serialize(new DateTime(2016, 6, 27, 21, 20, 53, 0, 123)),
        '2016-06-27T21:20:53.123000Z'
      );
      expect(
        dateTime().serialize(new DateTime(2016, 6, 27, 21, 20, 53, 123, 456)),
        '2016-06-27T21:20:53.123456000Z'
      );
      expect(dateTime().serialize(null), '0001-01-01T00:00:00Z');
    });
    test('deserialize DateTime', () {
      expect(
        dateTime().deserialize('2016-06-27T21:20:53.698152Z'),
        new DateTime(2016, 6, 27, 21, 20, 53, 0, 698)
      );
      expect(
        dateTime().deserialize('2016-06-27T21:20:53.123456789Z'),
        new DateTime(2016, 6, 27, 21, 20, 53, 123, 456)
      );
      expect(
        dateTime().deserialize('2016-06-27T21:20:53Z'),
        new DateTime(2016, 6, 27, 21, 20, 53)
      );
      expect(dateTime().deserialize('0001-01-01T00:00:00Z'), null);
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
