// Copyright 2026 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_common/guard_status.dart';
import 'package:test/test.dart';

void main() {
  group('GuardStatus.calculate', () {
    test('returns failed if there are failed builds', () {
      expect(
        GuardStatus.calculate(
          failedBuilds: 1,
          remainingBuilds: 0,
          totalBuilds: 10,
        ),
        GuardStatus.failed,
      );
    });

    test('returns succeeded if no failures and no remaining builds', () {
      expect(
        GuardStatus.calculate(
          failedBuilds: 0,
          remainingBuilds: 0,
          totalBuilds: 10,
        ),
        GuardStatus.succeeded,
      );
    });

    test('returns waitingForBackfill if all builds are remaining', () {
      expect(
        GuardStatus.calculate(
          failedBuilds: 0,
          remainingBuilds: 10,
          totalBuilds: 10,
        ),
        GuardStatus.waitingForBackfill,
      );
    });

    test('returns inProgress if some builds are done and no failures yet', () {
      expect(
        GuardStatus.calculate(
          failedBuilds: 0,
          remainingBuilds: 5,
          totalBuilds: 10,
        ),
        GuardStatus.inProgress,
      );
    });
  });
}
