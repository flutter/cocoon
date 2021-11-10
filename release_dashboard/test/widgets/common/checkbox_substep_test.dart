// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:conductor_ui/widgets/common/checkbox_substep.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Checkbox widget tests', () {
    const String substepName = 'substep1';
    const String substepSubtitle = 'subtitle1';
    testWidgets('Displays elements correctly', (WidgetTester tester) async {
      Map<String, bool> isEachSubstepChecked = <String, bool>{
        substepName: false,
      };

      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: CheckboxAsSubstep(
              isEachSubstepChecked: isEachSubstepChecked,
              clickCallback: (String data) {},
              substepName: substepName,
              subtitle: const SelectableText(substepSubtitle),
            ),
          ),
        ),
      );

      Finder checkboxListTile = find.byType(CheckboxListTile);
      expect(checkboxListTile, findsOneWidget);
      expect(find.text(substepName), findsOneWidget);
      expect(find.text(substepSubtitle), findsOneWidget);
    });

    testWidgets('Click on the checkbox checks or unchecks', (WidgetTester tester) async {
      Map<String, bool> isEachSubstepChecked = <String, bool>{
        substepName: false,
      };
      void updateSubstep(String substep) => isEachSubstepChecked[substep] = !isEachSubstepChecked[substep]!;

      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: CheckboxAsSubstep(
              isEachSubstepChecked: isEachSubstepChecked,
              clickCallback: updateSubstep,
              substepName: substepName,
              subtitle: const SelectableText(substepSubtitle),
            ),
          ),
        ),
      );

      Finder checkboxListTile = find.byType(CheckboxListTile);
      await tester.tap(checkboxListTile);
      await tester.pumpAndSettle();
      expect(isEachSubstepChecked[substepName], equals(true));

      await tester.tap(checkboxListTile);
      await tester.pumpAndSettle();
      expect(isEachSubstepChecked[substepName], equals(false));
    });
  });
}
