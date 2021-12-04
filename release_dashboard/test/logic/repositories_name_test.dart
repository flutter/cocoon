// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:conductor_ui/logic/repositories_name.dart';
import 'package:conductor_ui/logic/string_capitalize.dart';
import 'package:conductor_ui/models/repositories.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Capitalize first letter helper function tests', () {
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

  group('repositoryName tests', () {
    group('Not capitalized', () {
      test('engine', () {
        expect(repositoryName(Repositories.engine), equals('engine'));
      });

      test('framework', () {
        expect(repositoryName(Repositories.framework), equals('framework'));
      });
    });

    group('Capitalized', () {
      test('Engine', () {
        expect(repositoryName(Repositories.engine, true), equals('Engine'));
      });

      test('Framework', () {
        expect(repositoryName(Repositories.framework, true), equals('Framework'));
      });
    });
  });

  group('repositoryNameAlt tests', () {
    group('Not capitalized', () {
      test('engine', () {
        expect(repositoryNameAlt(Repositories.engine), equals('engine'));
      });

      test('flutter', () {
        expect(repositoryNameAlt(Repositories.framework), equals('flutter'));
      });
    });

    group('Capitalized', () {
      test('Engine', () {
        expect(repositoryNameAlt(Repositories.engine, true), equals('Engine'));
      });

      test('Flutter', () {
        expect(repositoryNameAlt(Repositories.framework, true), equals('Flutter'));
      });
    });
  });
}
