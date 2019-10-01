// Copyright (c) 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

import 'package:cocoon_service/protos.dart' show Task;

import 'package:app_flutter/task_box.dart';

void main() {
  group('TaskBox', () {
    // Table Driven Approach to ensure every message does show the corresponding color
    TaskBox.statusColor.forEach((String message, Color color) {
      testWidgets('is the color $color when given the message $message',
          (WidgetTester tester) async {
        expectTaskBoxColorWithMessage(tester, message, color);
      });
    });

    testWidgets('shows loading indicator for In Progress task',
        (WidgetTester tester) async {
      await tester
          .pumpWidget(TaskBox(task: Task()..status = TaskBox.statusInProgress));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('is the color black when given an unknown message',
        (WidgetTester tester) async {
      expectTaskBoxColorWithMessage(tester, '404', Colors.black);
    });
  });
}

void expectTaskBoxColorWithMessage(
    WidgetTester tester, String message, Color expectedColor) async {
  await tester.pumpWidget(TaskBox(task: Task()..status = message));

  Container taskBoxWidget = find.byType(Container).evaluate().first.widget;
  BoxDecoration decoration = taskBoxWidget.decoration;
  expect(decoration.color, expectedColor);
}
