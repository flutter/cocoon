// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:conductor_ui/logic/git.dart';
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

  group('Dropdown validator', () {
    for (final String parameterName in CreateReleaseSubsteps.substepTitles) {
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
          final Map<String, bool> isEachInputValid = createReleaseSubstepsState.isEachInputValid;

          isEachInputValid[parameterName] = false;
          await tester.tap(find.byKey(Key(parameterName)));
          await tester.pumpAndSettle();
          await tester.tap(find.text(testInputs[parameterName]!).last);
          await tester.pumpAndSettle();
          isEachInputValid[parameterName] = true;
        });
      }
    }
  });

  group("Input textfield validator", () {
    for (final String parameterName in CreateReleaseSubsteps.substepTitles) {
      if (parameterName != 'Release Channel' && parameterName != 'Increment') {
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

          final StatefulElement createReleaseSubsteps = tester.element(find.byType(CreateReleaseSubsteps));
          final CreateReleaseSubstepsState createReleaseSubstepsState =
              createReleaseSubsteps.state as CreateReleaseSubstepsState;
          final Map<String, bool> isEachInputValid = createReleaseSubstepsState.isEachInputValid;

          await tester.enterText(find.byKey(Key(parameterName)), testInputs[parameterName]!);
          isEachInputValid[parameterName] = true;
          await tester.enterText(find.byKey(Key(parameterName)), '@@invalidInput@@!!');
          isEachInputValid[parameterName] = false;
        });
      }
    }
  });

  group('Input textfields whitespaces', () {
    for (final String parameterName in CreateReleaseSubsteps.substepTitles) {
      // the test does not apply to dropdowns
      if (parameterName != 'Release Channel' && parameterName != 'Increment') {
        testWidgets('${parameterName} should trim leading and trailing whitespaces before validating',
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
          final Map<String, bool> isEachInputValid = createReleaseSubstepsState.isEachInputValid;

          isEachInputValid[parameterName] = false;
          // input field should trim any leading or trailing whitespaces
          await tester.enterText(find.byKey(Key(parameterName)), '   ${testInputs[parameterName]!}  ');
          isEachInputValid[parameterName] = true;
        });
      }
    }
  });

  group('Input textfields validator error messages', () {
    for (final String parameterName in CreateReleaseSubsteps.substepTitles) {
      // the test does not apply to dropdowns
      if (parameterName != 'Release Channel' && parameterName != 'Increment') {
        testWidgets('${parameterName} validator error message displays correctly', (WidgetTester tester) async {
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

          final String validatorErrorMsg = git(name: parameterName).getRegexAndErrorMsg()['errorMsg'] as String;
          await tester.enterText(find.byKey(Key(parameterName)), '@@invalidInput@@!!');
          await tester.pumpAndSettle();
          expect(find.text(validatorErrorMsg), findsOneWidget);
        });
      }
    }
  });

  group('Widget integration tests', () {
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
      final Finder continueButton = find.byKey(const Key('step1continue'));
      // default isEachInputValid state values, optional fields are valid from the start
      expect(
        createReleaseSubstepsState.isEachInputValid,
        equals(<String, bool>{
          'Candidate Branch': false,
          'Release Channel': false,
          'Framework Mirror': false,
          'Engine Mirror': false,
          'Engine Cherrypicks (if necessary)': true,
          'Framework Cherrypicks (if necessary)': true,
          'Dart Revision (if necessary)': true,
          'Increment': false,
        }),
      );

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
      expect(
        createReleaseSubstepsState.isEachInputValid,
        equals(<String, bool>{
          'Candidate Branch': true,
          'Release Channel': true,
          'Framework Mirror': true,
          'Engine Mirror': true,
          'Engine Cherrypicks (if necessary)': true,
          'Framework Cherrypicks (if necessary)': true,
          'Dart Revision (if necessary)': true,
          'Increment': true,
        }),
      );
    });
  });
}
