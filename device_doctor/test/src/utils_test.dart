// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:test/test.dart';

import 'package:device_doctor/src/utils.dart';

void main() {
  group('grep', () {
    String pattern;
    String from;

    test('deviceDiscovery no retries', () async {
      pattern = 'abc';
      from = 'abc\n'
          'def\n'
          'abcd';
      expect(grep(pattern, from: from), equals(<String>['abc', 'abcd']));
    });
  });
}
