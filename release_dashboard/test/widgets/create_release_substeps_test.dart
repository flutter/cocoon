// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:conductor_ui/logic/git.dart';
import 'package:conductor_ui/widgets/create_release_substeps.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const String candidateBranch = 'flutter-1.2-candidate.3';
  const String releaseChannel = 'dev';
  const String frameworkMirror = 'git@github.com:test/flutter.git';
  const String engineMirror = 'git@github.com:test/engine.git';
  const String validGitHash1 = '5f9a38fc310908c832810f9d875ed8b56ecc7f75';
  const String validGitHash2 = 'bfadad702e9f699f4ab024c335e7498152d26e34';
  const String validGitHash3 = 'bfadad702e9f699f4ab024c335e7498152d26e35';
  const String increment = 'y';

  /// Construct test inputs in a map that has the same names as [CreateReleaseSubsteps.substepTitles].
  Map<String, String> testInputsCorrect = <String, String>{
    CreateReleaseSubsteps.substepTitles[CreateReleaseSubstepType.candidateBranch]!: candidateBranch,
    CreateReleaseSubsteps.substepTitles[CreateReleaseSubstepType.releaseChannel]!: releaseChannel,
    CreateReleaseSubsteps.substepTitles[CreateReleaseSubstepType.frameworkMirror]!: frameworkMirror,
    CreateReleaseSubsteps.substepTitles[CreateReleaseSubstepType.engineMirror]!: engineMirror,
    CreateReleaseSubsteps.substepTitles[CreateReleaseSubstepType.frameworkCherrypicks]!: validGitHash1,
    CreateReleaseSubsteps.substepTitles[CreateReleaseSubstepType.engineCherrypicks]!: validGitHash2,
    CreateReleaseSubsteps.substepTitles[CreateReleaseSubstepType.dartRevision]!: validGitHash3,
    CreateReleaseSubsteps.substepTitles[CreateReleaseSubstepType.increment]!: increment,
  };

  group('Dropdown validator', () {
    for (final String parameterName in CreateReleaseSubsteps.substepTitles.values) {
      if (parameterName == CreateReleaseSubsteps.substepTitles[CreateReleaseSubstepType.releaseChannel]! ||
          parameterName == CreateReleaseSubsteps.substepTitles[CreateReleaseSubstepType.increment]!) {
        testWidgets('$parameterName dropdown test', (WidgetTester tester) async {
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
          await tester.tap(find.text(testInputsCorrect[parameterName]!).last);
          await tester.pumpAndSettle();
          isEachInputValid[parameterName] = true;
        });
      }
    }
  });

  group("Input textfield validator", () {
    for (final String parameterName in CreateReleaseSubsteps.substepTitles.values) {
      if (parameterName != CreateReleaseSubsteps.substepTitles[CreateReleaseSubstepType.releaseChannel]! &&
          parameterName != CreateReleaseSubsteps.substepTitles[CreateReleaseSubstepType.increment]!) {
        testWidgets('$parameterName input test', (WidgetTester tester) async {
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

          await tester.enterText(find.byKey(Key(parameterName)), testInputsCorrect[parameterName]!);
          isEachInputValid[parameterName] = true;
          await tester.enterText(find.byKey(Key(parameterName)), '@@invalidInput@@!!');
          isEachInputValid[parameterName] = false;
        });
      }
    }
  });

  group('Input textfields whitespaces', () {
    for (final String parameterName in CreateReleaseSubsteps.substepTitles.values) {
      // the test does not apply to dropdowns
      if (parameterName != CreateReleaseSubsteps.substepTitles[CreateReleaseSubstepType.releaseChannel]! &&
          parameterName != CreateReleaseSubsteps.substepTitles[CreateReleaseSubstepType.increment]!) {
        if (parameterName != CreateReleaseSubsteps.substepTitles[CreateReleaseSubstepType.engineCherrypicks]! &&
            parameterName != CreateReleaseSubsteps.substepTitles[CreateReleaseSubstepType.frameworkCherrypicks]!) {
          testWidgets('$parameterName should trim leading and trailing whitespaces before validating',
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
            await tester.enterText(find.byKey(Key(parameterName)), '   ${testInputsCorrect[parameterName]!}  ');
            isEachInputValid[parameterName] = true;
          });

          testWidgets('$parameterName should trim leading and trailing whitespaces before saving the value',
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

            await tester.enterText(find.byKey(Key(parameterName)), '   ${testInputsCorrect[parameterName]!}  ');
            expect(createReleaseSubstepsState.releaseData[parameterName], equals(testInputsCorrect[parameterName]!));
          });
        } else {
          testWidgets('$parameterName should remove any whitespace before validating', (WidgetTester tester) async {
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
            // input field should remove any whitespace present
            await tester.enterText(find.byKey(Key(parameterName)), '   $validGitHash1  ,  $validGitHash2    ');
            isEachInputValid[parameterName] = true;
          });
          testWidgets('$parameterName should remove any whitespace before saving the value',
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

            await tester.enterText(find.byKey(Key(parameterName)), '   $validGitHash1  ,  $validGitHash2    ');
            expect(createReleaseSubstepsState.releaseData[parameterName], equals('$validGitHash1,$validGitHash2'));
          });
        }
      }
    }
  });

  group('Input textfields validator error messages', () {
    final GitValidation gitHash = GitHash();
    final GitValidation multiGitHash = MultiGitHash();
    final GitValidation gitRemote = GitRemote();
    final GitValidation candidateBranch = CandidateBranch();
    for (final String parameterName in CreateReleaseSubsteps.substepTitles.values) {
      // the test does not apply to dropdowns
      if (parameterName != CreateReleaseSubsteps.substepTitles[CreateReleaseSubstepType.releaseChannel]! &&
          parameterName != CreateReleaseSubsteps.substepTitles[CreateReleaseSubstepType.increment]!) {
        // assign the corresponding error message manually to each type of input
        late final String validatorErrorMsg;
        switch (parameterName) {
          case 'Candidate Branch':
            validatorErrorMsg = candidateBranch.errorMsg;
            break;
          case 'Framework Mirror':
          case 'Engine Mirror':
            validatorErrorMsg = gitRemote.errorMsg;
            break;
          case 'Engine Cherrypicks (if necessary)':
          case 'Framework Cherrypicks (if necessary)':
            validatorErrorMsg = multiGitHash.errorMsg;
            break;
          case 'Dart Revision (if necessary)':
            validatorErrorMsg = gitHash.errorMsg;
            break;
          default:
            break;
        }
        testWidgets('$parameterName validator error message displays correctly', (WidgetTester tester) async {
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

      await tester.enterText(find.byKey(const Key('Candidate Branch')), testInputsCorrect['Candidate Branch']!);

      final StatefulElement createReleaseSubsteps = tester.element(find.byType(CreateReleaseSubsteps));
      final CreateReleaseSubstepsState createReleaseSubstepsState =
          createReleaseSubsteps.state as CreateReleaseSubstepsState;

      /// Tests the Release Channel dropdown menu.
      await tester.tap(find.byKey(const Key('Release Channel')));
      await tester.pumpAndSettle(); // finish the menu animation
      expect(createReleaseSubstepsState.releaseData['Release Channel'], equals(null));
      await tester.tap(find.text(testInputsCorrect['Release Channel']!).last);
      await tester.pumpAndSettle(); // finish the menu animation

      await tester.enterText(find.byKey(const Key('Framework Mirror')), testInputsCorrect['Framework Mirror']!);
      await tester.enterText(find.byKey(const Key('Engine Mirror')), testInputsCorrect['Engine Mirror']!);
      await tester.enterText(find.byKey(const Key('Engine Cherrypicks (if necessary)')),
          testInputsCorrect['Engine Cherrypicks (if necessary)']!);
      await tester.enterText(find.byKey(const Key('Framework Cherrypicks (if necessary)')),
          testInputsCorrect['Framework Cherrypicks (if necessary)']!);
      await tester.enterText(
          find.byKey(const Key('Dart Revision (if necessary)')), testInputsCorrect['Dart Revision (if necessary)']!);

      /// Tests the Increment dropdown menu.
      await tester.tap(find.byKey(const Key('Increment')));
      await tester.pumpAndSettle(); // finish the menu animation
      expect(createReleaseSubstepsState.releaseData['Increment'], equals(null));
      await tester.tap(find.text(testInputsCorrect['Increment']!).last);
      await tester.pumpAndSettle(); // finish the menu animation

      expect(
          createReleaseSubstepsState.releaseData,
          equals(<String, String>{
            'Candidate Branch': testInputsCorrect['Candidate Branch']!,
            'Release Channel': testInputsCorrect['Release Channel']!,
            'Framework Mirror': testInputsCorrect['Framework Mirror']!,
            'Engine Mirror': testInputsCorrect['Engine Mirror']!,
            'Engine Cherrypicks (if necessary)': testInputsCorrect['Engine Cherrypicks (if necessary)']!,
            'Framework Cherrypicks (if necessary)': testInputsCorrect['Framework Cherrypicks (if necessary)']!,
            'Dart Revision (if necessary)': testInputsCorrect['Dart Revision (if necessary)']!,
            'Increment': testInputsCorrect['Increment']!,
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

      // provide all correct parameter inputs
      await tester.enterText(find.byKey(const Key('Candidate Branch')), testInputsCorrect['Candidate Branch']!);
      await tester.tap(find.byKey(const Key('Release Channel')));
      await tester.pumpAndSettle();
      await tester.tap(find.text(testInputsCorrect['Release Channel']!).last);
      await tester.enterText(find.byKey(const Key('Framework Mirror')), testInputsCorrect['Framework Mirror']!);
      await tester.enterText(find.byKey(const Key('Engine Mirror')), testInputsCorrect['Engine Mirror']!);
      await tester.enterText(find.byKey(const Key('Engine Cherrypicks (if necessary)')),
          testInputsCorrect['Engine Cherrypicks (if necessary)']!);
      await tester.enterText(find.byKey(const Key('Framework Cherrypicks (if necessary)')),
          testInputsCorrect['Framework Cherrypicks (if necessary)']!);
      await tester.enterText(
          find.byKey(const Key('Dart Revision (if necessary)')), testInputsCorrect['Dart Revision (if necessary)']!);
      await tester.tap(find.byKey(const Key('Increment')));
      await tester.pumpAndSettle();
      await tester.tap(find.text(testInputsCorrect['Increment']!).last);

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
