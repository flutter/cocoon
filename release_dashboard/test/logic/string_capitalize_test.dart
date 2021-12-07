// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:conductor_ui/logic/string_capitalize.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('String capitalize extension tests', () {
    test('Returns the empty string', () {
      expect(('').capitalize(), equals(''));
    });
    test('Returns a single letter capitalized', () {
      expect(('a').capitalize(), equals('A'));
    });
    test('Returns a string with the first letter capitalized', () {
      expect(('aabasss').capitalize(), equals('Aabasss'));
    });
    test('Returns a single whitespace unchanged', () {
      expect((' ').capitalize(), equals(' '));
    });
    test('Returns a string with a leading whitespace unchanged', () {
      expect((' aabasss').capitalize(), equals(' aabasss'));
    });
    test('Returns a string with a leading non-letter char unchanged', () {
      expect(('1aabasss').capitalize(), equals('1aabasss'));
    });
  });
}
