// Copyright 2026 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:auto_submit/configuration/code_freeze_configuration.dart';
import 'package:github/github.dart';
import 'package:test/test.dart';

void main() {
  group('CodeFreezeConfiguration', () {
    test('parses YAML correctly', () {
      const yaml = '''
flutter/flutter:
  frozen_labels:
    - "f: material design"
    - "f: cupertino"
  frozen_paths:
    - "packages/flutter/lib/src/material/"
    - "packages/flutter/lib/src/cupertino/"
flutter/packages:
  frozen_labels:
    - "blocked"
''';
      final config = CodeFreezeConfiguration.fromYaml(yaml);

      final flutterCriteria = config.getFreezeCriteria(
        RepositorySlug('flutter', 'flutter'),
      );
      expect(
        flutterCriteria.frozenLabels,
        containsAll(['f: material design', 'f: cupertino']),
      );
      expect(
        flutterCriteria.frozenPaths,
        containsAll([
          'packages/flutter/lib/src/material/',
          'packages/flutter/lib/src/cupertino/',
        ]),
      );

      final packagesCriteria = config.getFreezeCriteria(
        RepositorySlug('flutter', 'packages'),
      );
      expect(packagesCriteria.frozenLabels, contains('blocked'));
      expect(packagesCriteria.frozenPaths, isEmpty);
    });

    test('returns empty criteria for unknown slug', () {
      final config = CodeFreezeConfiguration.fromYaml('{}');
      final criteria = config.getFreezeCriteria(
        RepositorySlug('unknown', 'unknown'),
      );
      expect(criteria.isEmpty, isTrue);
    });
  });
}
