// Copyright (c) 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

import 'package:app_flutter/result_box.dart';

void main() {
  testWidgets('ResultBox is the color red when given the message Failed',
      (WidgetTester tester) async {
    expectResultBoxColorWithMessage(tester, 'Failed', Colors.red);
  });

  testWidgets(
      'ResultBox is the color purple when given the message In Progress',
      (WidgetTester tester) async {
    expectResultBoxColorWithMessage(tester, 'In Progress', Colors.purple);
  });

  testWidgets('ResultBox is the color blue when given the message New',
      (WidgetTester tester) async {
    expectResultBoxColorWithMessage(tester, 'New', Colors.blue);
  });

  testWidgets('ResultBox is the color white when given the message Skipped',
      (WidgetTester tester) async {
    expectResultBoxColorWithMessage(tester, 'Skipped', Colors.white);
  });

  testWidgets('ResultBox is the color green when given the message Succeeded',
      (WidgetTester tester) async {
    expectResultBoxColorWithMessage(tester, 'Succeeded', Colors.green);
  });

  testWidgets(
      'ResultBox is the color orange when given the message Underperformed',
      (WidgetTester tester) async {
    expectResultBoxColorWithMessage(tester, 'Underperformed', Colors.orange);
  });

  testWidgets('ResultBox is the color black when given an unknown message',
      (WidgetTester tester) async {
    expectResultBoxColorWithMessage(tester, '404', Colors.black);
  });
}

void expectResultBoxColorWithMessage(
    WidgetTester tester, String message, Color expectedColor) async {
  await tester.pumpWidget(ResultBox(message: message));

  Container resultBoxWidget = find.byType(Container).evaluate().first.widget;
  BoxDecoration decoration = resultBoxWidget.decoration;
  expect(decoration.color, expectedColor);
}
