// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:test/test.dart';
import 'package:triage_bot/json.dart';

void main() {
  test('json', () {
    expect(Json.parse('null').toScalar(), null);
    expect(Json.parse('1.0').toScalar() is double, isTrue);
    expect(Json.parse('1.0').toScalar(), 1.0);
    expect(Json.parse('2').toScalar() is double, isTrue);
    expect(Json.parse('2').toScalar(), 2.0);
    expect(Json.parse('true').toScalar(), true);
    expect(Json.parse('false').toScalar(), false);
    expect(Json.parse('[1, 2, 3]').toList(), <double>[1.0, 2.0, 3.0]);
    expect(Json.parse('{"1": 2, "3": 4}').toMap(), <String, double>{'1': 2.0, '3': 4.0});
    expect((Json.parse('{"a": {"b": {"c": "d"}}}') as dynamic).a.b.c.toString(), 'd');
  });
}
