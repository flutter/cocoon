// Copyright (c) 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';

import 'package:cocoon_service/protos.dart' show Task;

import 'package:app_flutter/widgets/task_box.dart';

void main() {
  testWidgets('TaskBox.effectiveTaskStatus', (WidgetTester tester) async {
    expect(
        TaskBox.effectiveTaskStatus(Task()
          ..attempts = 1
          ..status = TaskBox.statusFailed),
        TaskBox.statusFailed);
    expect(
        TaskBox.effectiveTaskStatus(Task()
          ..attempts = 1
          ..status = TaskBox.statusNew),
        TaskBox.statusNew);
    expect(
        TaskBox.effectiveTaskStatus(Task()
          ..attempts = 1
          ..status = TaskBox.statusSkipped),
        TaskBox.statusSkipped);
    expect(
        TaskBox.effectiveTaskStatus(Task()
          ..attempts = 1
          ..status = TaskBox.statusSucceeded),
        TaskBox.statusSucceeded);
    expect(
        TaskBox.effectiveTaskStatus(Task()
          ..attempts = 1
          ..status = TaskBox.statusInProgress),
        TaskBox.statusInProgress);
    expect(
        TaskBox.effectiveTaskStatus(Task()
          ..attempts = 2
          ..status = TaskBox.statusFailed),
        TaskBox.statusFailed);
    expect(
        TaskBox.effectiveTaskStatus(Task()
          ..attempts = 2
          ..status = TaskBox.statusNew),
        TaskBox.statusUnderperformed);
    expect(
        TaskBox.effectiveTaskStatus(Task()
          ..attempts = 2
          ..status = TaskBox.statusSkipped),
        TaskBox.statusSkipped);
    expect(
        TaskBox.effectiveTaskStatus(Task()
          ..attempts = 2
          ..status = TaskBox.statusSucceeded),
        TaskBox.statusSucceededButFlaky);
    expect(
        TaskBox.effectiveTaskStatus(Task()
          ..attempts = 2
          ..status = TaskBox.statusInProgress),
        TaskBox.statusUnderperformedInProgress);
  });
}
