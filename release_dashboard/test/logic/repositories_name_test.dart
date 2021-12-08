// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:conductor_ui/logic/repositories_name.dart';
import 'package:conductor_ui/models/repositories.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
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
