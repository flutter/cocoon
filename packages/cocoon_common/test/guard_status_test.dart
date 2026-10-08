// Copyright 2026 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_common/guard_status.dart';
import 'package:cocoon_common/task_status.dart';
import 'package:test/test.dart';

void main() {
  group('GuardStatus.calculate', () {
    test('returns succeeded if all statuses are success', () {
      expect(
        GuardStatus.calculate([
          TaskStatus.succeeded,
          TaskStatus.skipped,
          TaskStatus.neutral,
        ]),
        GuardStatus.succeeded,
      );
    });

    test('returns failed if at least one status is failure', () {
      expect(
        GuardStatus.calculate([
          TaskStatus.failed,
          TaskStatus.inProgress,
          TaskStatus.succeeded,
        ]),
        GuardStatus.failed,
      );
    });

    test('returns inProgress otherwise', () {
      expect(
        GuardStatus.calculate([
          TaskStatus.waitingForBackfill,
          TaskStatus.succeeded,
        ]),
        GuardStatus.inProgress,
      );
      expect(
        GuardStatus.calculate([TaskStatus.waitingForBackfill]),
        GuardStatus.inProgress,
      );
    });
  });
}
