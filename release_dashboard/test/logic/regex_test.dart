// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:conductor_ui/logic/regex.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Regex tests', () {
    const String empty = '';
    const String validGitHash1 = '5f9a38fc310908c832810f9d875ed8b56ecc7f75';
    const String validGitHash2 = 'bfadad702e9f699f4ab024c335e7498152d26e34';
    const String invalidGitHash1 = '2oozzlqww';
    const String invalidGitHash2 = '5f9a38fc310908c832@';

    test('Single git hash tests', () {
      expect(gitHashRegex.hasMatch(empty), true);
      expect(gitHashRegex.hasMatch(validGitHash1), true);
      expect(gitHashRegex.hasMatch(validGitHash2), true);
      expect(gitHashRegex.hasMatch(invalidGitHash1), false);
      expect(gitHashRegex.hasMatch(invalidGitHash2), false);
    });

    test('Multi git hash tests', () {
      String validMultiHash1 = '$validGitHash1,$validGitHash2';
      String validMultiHash2 = '$validGitHash1,$validGitHash2,$validGitHash2';
      String validMultiHash3 = '$validGitHash1';
      String invalidMultiHash1 = '$validGitHash1,$validGitHash2,$validGitHash2,';
      String invalidMultiHash2 = '$validGitHash1,$invalidGitHash1,$validGitHash2';
      String invalidMultiHash3 = '$invalidGitHash1';

      expect(multiGitHashRegex.hasMatch(empty), true);
      expect(multiGitHashRegex.hasMatch(validMultiHash1), true);
      expect(multiGitHashRegex.hasMatch(validMultiHash2), true);
      expect(multiGitHashRegex.hasMatch(validMultiHash3), true);
      expect(multiGitHashRegex.hasMatch(invalidMultiHash1), false);
      expect(multiGitHashRegex.hasMatch(invalidMultiHash2), false);
      expect(multiGitHashRegex.hasMatch(invalidMultiHash3), false);
    });
  });
}
