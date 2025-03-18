// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_common/cocoon_common.dart';
import 'package:cocoon_common_test/cocoon_common_test.dart';
import 'package:test/test.dart';

void main() {
  group('atLeastSeverity', () {
    test('matches an exact', () {
      expect(Severity.warning, atLeastSeverity(Severity.warning));
    });

    test('matches a greater', () {
      expect(Severity.warning, atLeastSeverity(Severity.error));
    });

    test('does not match a lesser', () {
      expect(Severity.warning, isNot(atLeastSeverity(Severity.info)));
    });

    test('describes a failure', () {
      final description = atLeastSeverity(
        Severity.warning,
      ).describe(StringDescription());

      expect(description.toString(), '>= warning');
    });
  });

  group('atMostSeverity', () {
    test('matches an exact', () {
      expect(Severity.warning, atMostSeverity(Severity.warning));
    });

    test('does not match a greater', () {
      expect(Severity.warning, isNot(atMostSeverity(Severity.error)));
    });

    test('matches a lesser', () {
      expect(Severity.warning, atMostSeverity(Severity.info));
    });

    test('describes a failure', () {
      final description = atMostSeverity(
        Severity.warning,
      ).describe(StringDescription());

      expect(description.toString(), '<= warning');
    });
  });
}
