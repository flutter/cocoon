// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_common/task_status.dart';
import 'package:flutter_dashboard/logic/task_sorting.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('compareTasks', () {
    test('sorts by status priority', () {
      final tasks = [
        ('a', TaskStatus.succeeded),
        ('b', TaskStatus.failed),
        ('c', TaskStatus.infraFailure),
        ('d', TaskStatus.inProgress),
        ('e', TaskStatus.waitingForBackfill),
        ('f', TaskStatus.cancelled),
        ('g', TaskStatus.skipped),
      ];

      tasks.sort((a, b) => compareTasks(a.$1, a.$2, b.$1, b.$2));

      expect(tasks, [
        ('b', TaskStatus.failed),
        ('c', TaskStatus.infraFailure),
        ('d', TaskStatus.inProgress),
        ('e', TaskStatus.waitingForBackfill),
        ('f', TaskStatus.cancelled),
        ('g', TaskStatus.skipped),
        ('a', TaskStatus.succeeded),
      ]);
    });

    test('sorts by name when status is the same', () {
      final tasks = [
        ('beta', TaskStatus.failed),
        ('alpha', TaskStatus.failed),
        ('gamma', TaskStatus.succeeded),
        ('delta', TaskStatus.succeeded),
      ];

      tasks.sort((a, b) => compareTasks(a.$1, a.$2, b.$1, b.$2));

      expect(tasks, [
        ('alpha', TaskStatus.failed),
        ('beta', TaskStatus.failed),
        ('delta', TaskStatus.succeeded),
        ('gamma', TaskStatus.succeeded),
      ]);
    });

    test('complex sorting', () {
      final tasks = [
        ('z', TaskStatus.succeeded),
        ('y', TaskStatus.failed),
        ('x', TaskStatus.infraFailure),
        ('w', TaskStatus.inProgress),
        ('v', TaskStatus.failed),
        ('u', TaskStatus.succeeded),
      ];

      tasks.sort((a, b) => compareTasks(a.$1, a.$2, b.$1, b.$2));

      expect(tasks, [
        ('v', TaskStatus.failed),
        ('y', TaskStatus.failed),
        ('x', TaskStatus.infraFailure),
        ('w', TaskStatus.inProgress),
        ('u', TaskStatus.succeeded),
        ('z', TaskStatus.succeeded),
      ]);
    });
  });
}
