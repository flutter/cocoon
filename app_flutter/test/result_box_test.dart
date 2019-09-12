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

    expect(ResultColorByMessage(Colors.green), findsOneWidget);
  });

  testWidgets('ResultBox is the color black when given an unknown message',
      (WidgetTester tester) async {
    await tester.pumpWidget(ResultBox(message: '404'));

    expect(ResultColorByMessage(Colors.black), findsOneWidget);
  });
}

/// Checks if the color of an existing ResultBox matches [Color]
class ResultColorByMessage extends MatchFinder {
  ResultColorByMessage(this.color, {bool skipOffstage = true})
      : super(skipOffstage: skipOffstage);

  final Color color;

  @override
  String get description => 'ResultBox{color: "$color"}';

  @override
  bool matches(Element candidate) {
    if (candidate.widget is Container) {
      final Container resultBoxWidget = candidate.widget;
      if (resultBoxWidget.decoration is BoxDecoration) {
        final BoxDecoration decoration = resultBoxWidget.decoration;
        return decoration.color == color;
      }
    }

    return false;
  }
}
