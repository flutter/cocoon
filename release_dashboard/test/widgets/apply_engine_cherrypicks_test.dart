// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:conductor_ui/widgets/apply_engine_cherrypicks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Apply engine cherrypick tests', () {
    testWidgets('Continue button appears when all substeps are checked', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: ApplyEngineCherrypicks(nextStep: () {}),
          ),
        ),
      );

      expect(find.byKey(const Key('applyEngineCherrypicksContinue')), findsNothing);
      for (final String substep in ApplyEngineCherrypicks.substepTitles.values) {
        await tester.tap(find.text(substep));
      }
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('applyEngineCherrypicksContinue')), findsOneWidget);
    });

    testWidgets('Clicking on the continue button proceeds to the next step', (WidgetTester tester) async {
      bool isNextStep = false;
      void nextStep() => isNextStep = true;

      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: ApplyEngineCherrypicks(nextStep: nextStep),
          ),
        ),
      );

      for (final String substep in ApplyEngineCherrypicks.substepTitles.values) {
        await tester.tap(find.text(substep));
      }
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('applyEngineCherrypicksContinue')));
      await tester.pumpAndSettle();
      expect(isNextStep, equals(true));
    });
  });
}
