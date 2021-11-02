// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:conductor_ui/widgets/create_release_substeps.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  /// Construct test inputs in a map that has the same names as [CreateReleaseSubsteps.substepTitles].
  Map<String, String> testInputs = <String, String>{
    CreateReleaseSubsteps.substepTitles[0]: 'flutter-1.2-candidate.3',
    CreateReleaseSubsteps.substepTitles[1]: 'dev',
    CreateReleaseSubsteps.substepTitles[2]: 'git@github.com:test/flutter.git',
    CreateReleaseSubsteps.substepTitles[3]: 'git@github.com:test/engine.git',
    CreateReleaseSubsteps.substepTitles[4]: '5f9a38fc310908c832810f9d875ed8b56ecc7f75',
    CreateReleaseSubsteps.substepTitles[5]: 'bfadad702e9f699f4ab024c335e7498152d26e34',
    CreateReleaseSubsteps.substepTitles[6]: 'bfadad702e9f699f4ab024c335e7498152d26e35',
    CreateReleaseSubsteps.substepTitles[7]: 'y',
  };

  testWidgets('Widget should save all parameters correctly', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: ListView(
            children: <Widget>[
              CreateReleaseSubsteps(
                nextStep: () {},
              ),
            ],
          ),
        ),
      ),
    );

    await tester.enterText(find.byKey(const Key('Candidate Branch')), testInputs['Candidate Branch']!);

    final StatefulElement createReleaseSubsteps = tester.element(find.byType(CreateReleaseSubsteps));
    final CreateReleaseSubstepsState createReleaseSubstepsState =
        createReleaseSubsteps.state as CreateReleaseSubstepsState;

    /// Tests the Release Channel dropdown menu.
    await tester.tap(find.byKey(const Key('Release Channel')));
    await tester.pumpAndSettle(); // finish the menu animation
    expect(createReleaseSubstepsState.releaseData['Release Channel'], equals(null));
    await tester.tap(find.text(testInputs['Release Channel']!).last);
    await tester.pumpAndSettle(); // finish the menu animation

    await tester.enterText(find.byKey(const Key('Framework Mirror')), testInputs['Framework Mirror']!);
    await tester.enterText(find.byKey(const Key('Engine Mirror')), testInputs['Engine Mirror']!);
    await tester.enterText(
        find.byKey(const Key('Engine Cherrypicks (if necessary)')), testInputs['Engine Cherrypicks (if necessary)']!);
    await tester.enterText(find.byKey(const Key('Framework Cherrypicks (if necessary)')),
        testInputs['Framework Cherrypicks (if necessary)']!);
    await tester.enterText(
        find.byKey(const Key('Dart Revision (if necessary)')), testInputs['Dart Revision (if necessary)']!);

    /// Tests the Increment dropdown menu.
    await tester.tap(find.byKey(const Key('Increment')));
    await tester.pumpAndSettle(); // finish the menu animation
    expect(createReleaseSubstepsState.releaseData['Increment'], equals(null));
    await tester.tap(find.text(testInputs['Increment']!).last);
    await tester.pumpAndSettle(); // finish the menu animation

    expect(
        createReleaseSubstepsState.releaseData,
        equals(<String, String>{
          'Candidate Branch': testInputs['Candidate Branch']!,
          'Release Channel': testInputs['Release Channel']!,
          'Framework Mirror': testInputs['Framework Mirror']!,
          'Engine Mirror': testInputs['Engine Mirror']!,
          'Engine Cherrypicks (if necessary)': testInputs['Engine Cherrypicks (if necessary)']!,
          'Framework Cherrypicks (if necessary)': testInputs['Framework Cherrypicks (if necessary)']!,
          'Dart Revision (if necessary)': testInputs['Dart Revision (if necessary)']!,
          'Increment': testInputs['Increment']!,
        }));
  });

  group("Test if every parameter's validator catches bad inputs and allows valid inputs to pass", () {
    for (int i = 0; i < CreateReleaseSubsteps.substepTitles.length; i++) {
      final String parameterName = CreateReleaseSubsteps.substepTitles[i];

      if (parameterName == 'Release Channel' || parameterName == 'Increment') {
        testWidgets('${parameterName} dropdown test', (WidgetTester tester) async {
          await tester.pumpWidget(
            MaterialApp(
              home: Material(
                child: ListView(
                  children: <Widget>[
                    CreateReleaseSubsteps(
                      nextStep: () {},
                    ),
                  ],
                ),
              ),
            ),
          );

          final StatefulElement createReleaseSubsteps = tester.element(find.byType(CreateReleaseSubsteps));
          final CreateReleaseSubstepsState createReleaseSubstepsState =
              createReleaseSubsteps.state as CreateReleaseSubstepsState;
          final List<bool> isEachInputValid = createReleaseSubstepsState.isEachInputValid;

          isEachInputValid[i] = false;
          await tester.tap(find.byKey(Key(parameterName)));
          await tester.pumpAndSettle();
          await tester.tap(find.text(testInputs[parameterName]!).last);
          await tester.pumpAndSettle();
          isEachInputValid[i] = true;
        });
      } else {
        testWidgets('${parameterName} input test', (WidgetTester tester) async {
          await tester.pumpWidget(
            MaterialApp(
              home: Material(
                child: ListView(
                  children: <Widget>[
                    CreateReleaseSubsteps(
                      nextStep: () {},
                    ),
                  ],
                ),
              ),
            ),
          );

          await tester.enterText(find.byKey(Key(parameterName)), testInputs[parameterName]!);

          final StatefulElement createReleaseSubsteps = tester.element(find.byType(CreateReleaseSubsteps));
          final CreateReleaseSubstepsState createReleaseSubstepsState =
              createReleaseSubsteps.state as CreateReleaseSubstepsState;
          final List<bool> isEachInputValid = createReleaseSubstepsState.isEachInputValid;

          isEachInputValid[i] = true;
          await tester.enterText(find.byKey(Key(parameterName)), '@@invalidInput@@!!');
          isEachInputValid[i] = false;
        });
      }
    }
  });

  testWidgets('Continue button should be enabled when all the parameters are entered correctly',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: ListView(
            children: <Widget>[
              CreateReleaseSubsteps(
                nextStep: () {},
              ),
            ],
          ),
        ),
      ),
    );

    final StatefulElement createReleaseSubsteps = tester.element(find.byType(CreateReleaseSubsteps));
    final CreateReleaseSubstepsState createReleaseSubstepsState =
        createReleaseSubsteps.state as CreateReleaseSubstepsState;
    final List<bool> isEachInputValid = createReleaseSubstepsState.isEachInputValid;
    final Finder continueButton = find.byKey(const Key('step1continue'));
    // default isEachInputValid state values, optional fields are valid from the start
    expect(isEachInputValid, equals(<bool>[false, false, false, false, true, true, true, false]));

    expect(tester.widget<ElevatedButton>(continueButton).enabled, false);

    // provide all the correct parameter inputs
    await tester.enterText(find.byKey(const Key('Candidate Branch')), testInputs['Candidate Branch']!);
    await tester.tap(find.byKey(const Key('Release Channel')));
    await tester.pumpAndSettle();
    await tester.tap(find.text(testInputs['Release Channel']!).last);
    await tester.enterText(find.byKey(const Key('Framework Mirror')), testInputs['Framework Mirror']!);
    await tester.enterText(find.byKey(const Key('Engine Mirror')), testInputs['Engine Mirror']!);
    await tester.enterText(
        find.byKey(const Key('Engine Cherrypicks (if necessary)')), testInputs['Engine Cherrypicks (if necessary)']!);
    await tester.enterText(find.byKey(const Key('Framework Cherrypicks (if necessary)')),
        testInputs['Framework Cherrypicks (if necessary)']!);
    await tester.enterText(
        find.byKey(const Key('Dart Revision (if necessary)')), testInputs['Dart Revision (if necessary)']!);
    await tester.tap(find.byKey(const Key('Increment')));
    await tester.pumpAndSettle();
    await tester.tap(find.text(testInputs['Increment']!).last);

    await tester.pumpAndSettle();
    // continue button is enabled, and all the parameters are validated
    expect(tester.widget<ElevatedButton>(continueButton).enabled, true);
    expect(isEachInputValid, equals(<bool>[true, true, true, true, true, true, true, true]));
  });
}
