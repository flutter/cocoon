// Copyright 2016 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:test/test.dart';
import 'package:device_doctor/src/utils.dart';

void main() {
  group('grep', () {
    test('greps lines', () {
      expect(grep('b', from: 'ab\ncd\nba'), ['ab', 'ba']);
    });

    test('understands RegExp', () {
      expect(grep(RegExp('^b'), from: 'ab\nba'), ['ba']);
    });
  });
}
