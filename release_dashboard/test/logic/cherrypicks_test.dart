// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:conductor_ui/logic/cherrypicks.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const String cherrypick1 = 'a5a25cd702b062c24b2c67b8d30b5cb33e0ef6f0';
  const String cherrypick2 = '94d06a2e1d01a3b0c693b94d70c5e1df9d78d249';
  const String cherrypick3 = '768cd702b691584b2c67b8d30b5cb33e0ef6f0bb';

  group('CherrypickStringtoArray tests', () {
    test('Converts null or empty string to an empty array', () {
      expect(cherrypickStringtoArray(null), equals(<String>[]));
      expect(cherrypickStringtoArray(''), equals(<String>[]));
    });

    test('Converts a single cherrypick string to an array of length one', () {
      expect(cherrypickStringtoArray(cherrypick1), equals(<String>[cherrypick1]));
    });

    test('Converts multiple cherrypicks delimited by coma to an array', () {
      expect(cherrypickStringtoArray('$cherrypick1,$cherrypick2,$cherrypick3'),
          equals(<String>[cherrypick1, cherrypick2, cherrypick3]));
    });

    test('If the cherrypick string ends on a comma, creates an extra entry', () {
      // This situation is prevented by [MultiGitHash]'s [isValid] method when
      // validating the input of a multi-hash.
      expect(cherrypickStringtoArray('$cherrypick1,$cherrypick2,'), equals(<String>[cherrypick1, cherrypick2, '']));
    });
  });
}
