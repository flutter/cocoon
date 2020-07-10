// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:test/test.dart';

import 'package:cocoon_service/src/request_handlers/utils.dart';

void main() {
  group('GitHubBackoffCalculator', () {
    test('twoSecondLinearBackoff', () {
      expect(twoSecondLinearBackoff(0), const Duration(seconds: 2));
      expect(twoSecondLinearBackoff(1), const Duration(seconds: 4));
      expect(twoSecondLinearBackoff(2), const Duration(seconds: 6));
      expect(twoSecondLinearBackoff(3), const Duration(seconds: 8));
    });
  });
}
