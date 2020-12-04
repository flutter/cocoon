// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:test/test.dart';

import 'package:device_doctor/src/utils.dart';

void main() {
  group('toLogString', () {
    test('DEBUG level', () {
      expect(toLogString('test', level: LogLevel.debug).substring(28), 'DEBUG test');
    });

    test('No level', () {
      expect(toLogString('test').substring(28), 'test');
    });
  });
}
