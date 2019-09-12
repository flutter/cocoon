// Copyright (c) 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

import 'package:app_flutter/result_box.dart';

void main() {
  testWidgets('ResultBox is the color green when given the message Succeeded',
      (WidgetTester tester) async {
    await tester.pumpWidget(ResultBox(message: 'Succeeded'));

    Container resultBoxWidget = find.byType(Container).evaluate().first.widget;
    BoxDecoration decoration = resultBoxWidget.decoration;
    expect(decoration.color, Colors.green);
  });

  testWidgets('ResultBox is the color black when given an unknown message',
      (WidgetTester tester) async {
    await tester.pumpWidget(ResultBox(message: '404'));

    Container resultBoxWidget = find.byType(Container).evaluate().first.widget;
    BoxDecoration decoration = resultBoxWidget.decoration;
    expect(decoration.color, Colors.black);
  });
}