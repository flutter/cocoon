// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:conductor_ui/widgets/engine_cherrypicks_substeps.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Engine cherrypick substeps tests', () {
    testWidgets('Continue button appears when all substeps are checked', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: EngineCherrypicksSubsteps(nextStep: () {}),
          ),
        ),
      );

      expect(find.byKey(const Key('applyEngineCherrypicksContinue')), findsNothing);
      for (final String substep in EngineCherrypicksSubsteps.substepTitles.values) {
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
            child: EngineCherrypicksSubsteps(nextStep: nextStep),
          ),
        ),
      );

      for (final String substep in EngineCherrypicksSubsteps.substepTitles.values) {
        await tester.tap(find.text(substep));
      }
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('applyEngineCherrypicksContinue')));
      await tester.pumpAndSettle();
      expect(isNextStep, equals(true));
    });
  });
}
