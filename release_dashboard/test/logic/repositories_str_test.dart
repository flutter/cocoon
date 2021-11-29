// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:conductor_ui/logic/repositories_str.dart';
import 'package:conductor_ui/models/repositories.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Capitalize first letter helper function tests', () {
    test('Returns the empty string', () {
      expect(capitalizeFirstLetter(''), equals(''));
    });
    test('Returns a single letter capitalized', () {
      expect(capitalizeFirstLetter('a'), equals('A'));
    });
    test('Returns a string with the first letter capitalized', () {
      expect(capitalizeFirstLetter('aabasss'), equals('Aabasss'));
    });
    test('Returns a single whitespace unchanged', () {
      expect(capitalizeFirstLetter(' '), equals(' '));
    });
    test('Returns a string with a leading whitespace unchanged', () {
      expect(capitalizeFirstLetter(' aabasss'), equals(' aabasss'));
    });
    test('Returns a string with a leading non-letter char unchanged', () {
      expect(capitalizeFirstLetter('1aabasss'), equals('1aabasss'));
    });
  });

  group('repositoriesStr tests', () {
    group('Not capitalized', () {
      test('engine', () {
        expect(repositoriesStr(Repositories.engine), equals('engine'));
      });

      test('framework', () {
        expect(repositoriesStr(Repositories.framework), equals('framework'));
      });
    });

    group('Capitalized', () {
      test('Engine', () {
        expect(repositoriesStr(Repositories.engine, true), equals('Engine'));
      });

      test('Framework', () {
        expect(repositoriesStr(Repositories.framework, true), equals('Framework'));
      });
    });
  });

  group('repositoriesStrFlutter tests', () {
    group('Not capitalized', () {
      test('engine', () {
        expect(repositoriesStrFlutter(Repositories.engine), equals('engine'));
      });

      test('flutter', () {
        expect(repositoriesStrFlutter(Repositories.framework), equals('flutter'));
      });
    });

    group('Capitalized', () {
      test('Engine', () {
        expect(repositoriesStrFlutter(Repositories.engine, true), equals('Engine'));
      });

      test('Flutter', () {
        expect(repositoriesStrFlutter(Repositories.framework, true), equals('Flutter'));
      });
    });
  });
}
