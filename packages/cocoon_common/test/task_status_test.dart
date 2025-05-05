// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_common/task_status.dart';
import 'package:test/test.dart';

void main() {
  group('TaskStatus.from', () {
    for (final value in TaskStatus.values) {
      test('$value', () {
        expect(TaskStatus.from(value.value), same(value));
      });
    }

    test('fails with an invalid status', () {
      expect(() => TaskStatus.from('INVALID'), throwsArgumentError);
    });
  });

  group('TaskStatus.tryFrom', () {
    for (final value in TaskStatus.values) {
      test('$value', () {
        expect(TaskStatus.tryFrom(value.value), same(value));
      });
    }

    test('returns null with an invalid status', () {
      expect(TaskStatus.tryFrom('INVALID'), isNull);
    });
  });

  group('.value', () {
    for (final MapEntry(key: value, value: expectation)
        in {
          TaskStatus.cancelled: 'Cancelled',
          TaskStatus.queuedForBackfill: 'New',
          TaskStatus.infraFailure: 'Infra Failure',
          TaskStatus.failed: 'Failed',
          TaskStatus.succeeded: 'Succeeded',
          TaskStatus.skipped: 'Skipped',
        }.entries) {
      test('$value == $expectation', () {
        expect(value.value, expectation);
      });
    }
  });

  group('isSuccess', () {
    test('true for succeeded', () {
      expect(TaskStatus.succeeded.isSuccess, isTrue);
    });

    test('false for everything else', () {
      expect(
        TaskStatus.values
            .where((v) => v != TaskStatus.succeeded)
            .map((t) => t.isSuccess),
        everyElement(isFalse),
      );
    });
  });

  group('isComplete', () {
    group('true for failed tasks', () {
      for (final status in TaskStatus.values.where((v) => v.isFailure)) {
        test('$status', () {
          expect(status.isComplete, isTrue);
        });
      }
    });

    group('true for successful tasks', () {
      for (final status in TaskStatus.values.where((v) => v.isSuccess)) {
        test('$status', () {
          expect(status.isComplete, isTrue);
        });
      }
    });

    group('true for skipped tasks', () {
      for (final status in TaskStatus.values.where((v) => v.isSkipped)) {
        test('$status', () {
          expect(status.isComplete, isTrue);
        });
      }
    });

    group('false otherwise', () {
      for (final status in TaskStatus.values.where(
        (v) => !v.isFailure && !v.isSuccess && !v.isSkipped,
      )) {
        test('$status', () {
          expect(status.isComplete, isFalse);
        });
      }
    });
  });

  group('isFailure', () {
    const failures = [
      TaskStatus.failed,
      TaskStatus.infraFailure,
      TaskStatus.cancelled,
    ];

    for (final failure in failures) {
      test('true for $failure', () {
        expect(failure.isFailure, isTrue);
      });
    }

    group('false otherwise', () {
      for (final status in TaskStatus.values.where(
        (v) => !failures.contains(v),
      )) {
        test('$status', () {
          expect(status.isFailure, isFalse);
        });
      }
    });
  });

  test('isSuccess', () {
    expect(TaskStatus.succeeded.isSuccess, isTrue);
    expect(
      TaskStatus.values.where((v) => v != TaskStatus.succeeded),
      everyElement(
        isA<TaskStatus>().having((t) => t.isSuccess, 'isSuccess', isFalse),
      ),
    );
  });

  test('isSkipped', () {
    expect(TaskStatus.skipped.isSkipped, isTrue);
    expect(
      TaskStatus.values.where((v) => v != TaskStatus.skipped),
      everyElement(
        isA<TaskStatus>().having((t) => t.isSkipped, 'isSkipped', isFalse),
      ),
    );
  });

  test('isRunning', () {
    expect(TaskStatus.inProgress.isRunning, isTrue);
    expect(
      TaskStatus.values.where((v) => v != TaskStatus.inProgress),
      everyElement(
        isA<TaskStatus>().having((t) => t.isRunning, 'isRunning', isFalse),
      ),
    );
  });
}
