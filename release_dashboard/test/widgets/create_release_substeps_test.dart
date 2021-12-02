// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:conductor_core/conductor_core.dart';
import 'package:conductor_ui/logic/git.dart';
import 'package:conductor_ui/state/status_state.dart';
import 'package:conductor_ui/widgets/create_release_substeps.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import '../fakes/fake_process_manager.dart';
import '../fakes/fake_start_context.dart';
import '../fakes/services/fake_conductor.dart';

void main() {
  const String candidateBranch = 'flutter-1.2-candidate.3';
  const String releaseChannel = 'dev';
  const String frameworkMirror = 'git@github.com:test/flutter.git';
  const String engineMirror = 'git@github.com:test/engine.git';
  const String increment = 'y';
  const String validGitHash1 = '5f9a38fc310908c832810f9d875ed8b56ecc7f75';
  const String validGitHash2 = 'bfadad702e9f699f4ab024c335e7498152d26e34';
  const String validGitHash3 = 'bfadad702e9f699f4ab024c335e7498152d26e35';

  /// Construct test inputs in [Map<K, V>] that uses [CreateReleaseSubstep] as keys.
  Map<CreateReleaseSubstep, String> testInputsCorrect = <CreateReleaseSubstep, String>{
    CreateReleaseSubstep.candidateBranch: candidateBranch,
    CreateReleaseSubstep.releaseChannel: releaseChannel,
    CreateReleaseSubstep.frameworkMirror: frameworkMirror,
    CreateReleaseSubstep.engineMirror: engineMirror,
    CreateReleaseSubstep.frameworkCherrypicks: validGitHash1,
    CreateReleaseSubstep.engineCherrypicks: validGitHash2,
    CreateReleaseSubstep.dartRevision: validGitHash3,
    CreateReleaseSubstep.increment: increment,
  };

  group('Dropdown validator', () {
    for (final CreateReleaseSubstep substep in CreateReleaseSubstep.values) {
      if (CreateReleaseSubsteps.dropdownElements.contains(substep)) {
        testWidgets('$substep dropdown test', (WidgetTester tester) async {
          await tester.pumpWidget(ChangeNotifierProvider(
            create: (context) => StatusState(conductor: FakeConductor()),
            child: MaterialApp(
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
          ));

          final StatefulElement createReleaseSubsteps = tester.element(find.byType(CreateReleaseSubsteps));
          final CreateReleaseSubstepsState createReleaseSubstepsState =
              createReleaseSubsteps.state as CreateReleaseSubstepsState;
          final Map<CreateReleaseSubstep, bool> isEachInputValid = createReleaseSubstepsState.isEachInputValid;

          isEachInputValid[substep] = false;
          await tester.tap(find.byKey(Key(CreateReleaseSubsteps.substepTitles[substep]!)));
          await tester.pumpAndSettle();
          await tester.tap(find.text(testInputsCorrect[substep]!).last);
          await tester.pumpAndSettle();
          isEachInputValid[substep] = true;
        });
      }
    }
  });

  group("Input textfield validator", () {
    for (final CreateReleaseSubstep substep in CreateReleaseSubstep.values) {
      if (!CreateReleaseSubsteps.dropdownElements.contains(substep)) {
        testWidgets('$substep input test', (WidgetTester tester) async {
          await tester.pumpWidget(ChangeNotifierProvider(
            create: (context) => StatusState(conductor: FakeConductor()),
            child: MaterialApp(
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
          ));

          final StatefulElement createReleaseSubsteps = tester.element(find.byType(CreateReleaseSubsteps));
          final CreateReleaseSubstepsState createReleaseSubstepsState =
              createReleaseSubsteps.state as CreateReleaseSubstepsState;
          final Map<CreateReleaseSubstep, bool> isEachInputValid = createReleaseSubstepsState.isEachInputValid;

          await tester.enterText(
              find.byKey(Key(CreateReleaseSubsteps.substepTitles[substep]!)), testInputsCorrect[substep]!);
          isEachInputValid[substep] = true;
          await tester.enterText(find.byKey(Key(CreateReleaseSubsteps.substepTitles[substep]!)), '@@invalidInput@@!!');
          isEachInputValid[substep] = false;
        });
      }
    }
  });

  group('Input textfields whitespaces', () {
    for (final CreateReleaseSubstep substep in CreateReleaseSubstep.values) {
      // the test does not apply to dropdowns
      if (!CreateReleaseSubsteps.dropdownElements.contains(substep)) {
        if (substep != CreateReleaseSubstep.engineCherrypicks && substep != CreateReleaseSubstep.frameworkCherrypicks) {
          testWidgets('$substep should trim leading and trailing whitespaces before validating',
              (WidgetTester tester) async {
            await tester.pumpWidget(ChangeNotifierProvider(
              create: (context) => StatusState(conductor: FakeConductor()),
              child: MaterialApp(
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
            ));

            final StatefulElement createReleaseSubsteps = tester.element(find.byType(CreateReleaseSubsteps));
            final CreateReleaseSubstepsState createReleaseSubstepsState =
                createReleaseSubsteps.state as CreateReleaseSubstepsState;
            final Map<CreateReleaseSubstep, bool> isEachInputValid = createReleaseSubstepsState.isEachInputValid;

            isEachInputValid[substep] = false;
            // input field should trim any leading or trailing whitespaces
            await tester.enterText(
                find.byKey(Key(CreateReleaseSubsteps.substepTitles[substep]!)), '   ${testInputsCorrect[substep]!}  ');
            isEachInputValid[substep] = true;
          });

          testWidgets('$substep should trim leading and trailing whitespaces before saving the value',
              (WidgetTester tester) async {
            await tester.pumpWidget(ChangeNotifierProvider(
              create: (context) => StatusState(conductor: FakeConductor()),
              child: MaterialApp(
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
            ));

            final StatefulElement createReleaseSubsteps = tester.element(find.byType(CreateReleaseSubsteps));
            final CreateReleaseSubstepsState createReleaseSubstepsState =
                createReleaseSubsteps.state as CreateReleaseSubstepsState;

            await tester.enterText(
                find.byKey(Key(CreateReleaseSubsteps.substepTitles[substep]!)), '   ${testInputsCorrect[substep]!}  ');
            expect(createReleaseSubstepsState.releaseData[substep], equals(testInputsCorrect[substep]!));
          });
        } else {
          testWidgets('$substep should remove any whitespace before validating', (WidgetTester tester) async {
            await tester.pumpWidget(ChangeNotifierProvider(
              create: (context) => StatusState(conductor: FakeConductor()),
              child: MaterialApp(
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
            ));

            final StatefulElement createReleaseSubsteps = tester.element(find.byType(CreateReleaseSubsteps));
            final CreateReleaseSubstepsState createReleaseSubstepsState =
                createReleaseSubsteps.state as CreateReleaseSubstepsState;
            final Map<CreateReleaseSubstep, bool> isEachInputValid = createReleaseSubstepsState.isEachInputValid;

            isEachInputValid[substep] = false;
            // input field should remove any whitespace present
            await tester.enterText(find.byKey(Key(CreateReleaseSubsteps.substepTitles[substep]!)),
                '   $validGitHash1  ,  $validGitHash2    ');
            isEachInputValid[substep] = true;
          });
          testWidgets('$substep should remove any whitespace before saving the value', (WidgetTester tester) async {
            await tester.pumpWidget(ChangeNotifierProvider(
              create: (context) => StatusState(conductor: FakeConductor()),
              child: MaterialApp(
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
            ));

            final StatefulElement createReleaseSubsteps = tester.element(find.byType(CreateReleaseSubsteps));
            final CreateReleaseSubstepsState createReleaseSubstepsState =
                createReleaseSubsteps.state as CreateReleaseSubstepsState;

            await tester.enterText(find.byKey(Key(CreateReleaseSubsteps.substepTitles[substep]!)),
                '   $validGitHash1  ,  $validGitHash2    ');
            expect(createReleaseSubstepsState.releaseData[substep], equals('$validGitHash1,$validGitHash2'));
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
    for (final CreateReleaseSubstep substep in CreateReleaseSubstep.values) {
      // the test does not apply to dropdowns
      if (!CreateReleaseSubsteps.dropdownElements.contains(substep)) {
        // assign the corresponding error message manually to each type of input
        late final String validatorErrorMsg;
        switch (substep) {
          case CreateReleaseSubstep.candidateBranch:
            validatorErrorMsg = candidateBranch.errorMsg;
            break;
          case CreateReleaseSubstep.frameworkMirror:
          case CreateReleaseSubstep.engineMirror:
            validatorErrorMsg = gitRemote.errorMsg;
            break;
          case CreateReleaseSubstep.engineCherrypicks:
          case CreateReleaseSubstep.frameworkCherrypicks:
            validatorErrorMsg = multiGitHash.errorMsg;
            break;
          case CreateReleaseSubstep.dartRevision:
            validatorErrorMsg = gitHash.errorMsg;
            break;
          default:
            break;
        }
        testWidgets('$substep validator error message displays correctly', (WidgetTester tester) async {
          await tester.pumpWidget(ChangeNotifierProvider(
            create: (context) => StatusState(conductor: FakeConductor()),
            child: MaterialApp(
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
          ));

          await tester.enterText(find.byKey(Key(CreateReleaseSubsteps.substepTitles[substep]!)), '@@invalidInput@@!!');
          await tester.pumpAndSettle();
          expect(find.text(validatorErrorMsg), findsOneWidget);
        });
      }
    }
  });

  group('Widget integration tests', () {
    testWidgets('Widget should save all parameters correctly', (WidgetTester tester) async {
      await tester.pumpWidget(ChangeNotifierProvider(
        create: (context) => StatusState(conductor: FakeConductor()),
        child: MaterialApp(
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
      ));

      await tester.enterText(
          find.byKey(Key(CreateReleaseSubsteps.substepTitles[CreateReleaseSubstep.candidateBranch]!)),
          testInputsCorrect[CreateReleaseSubstep.candidateBranch]!);

      final StatefulElement createReleaseSubsteps = tester.element(find.byType(CreateReleaseSubsteps));
      final CreateReleaseSubstepsState createReleaseSubstepsState =
          createReleaseSubsteps.state as CreateReleaseSubstepsState;

      /// Tests the Release Channel dropdown menu.
      await tester.tap(find.byKey(Key(CreateReleaseSubsteps.substepTitles[CreateReleaseSubstep.releaseChannel]!)));
      await tester.pumpAndSettle(); // finish the menu animation
      expect(createReleaseSubstepsState.releaseData[CreateReleaseSubstep.releaseChannel], equals(null));
      await tester.tap(find.text(testInputsCorrect[CreateReleaseSubstep.releaseChannel]!).last);
      await tester.pumpAndSettle(); // finish the menu animation

      await tester.enterText(
          find.byKey(Key(CreateReleaseSubsteps.substepTitles[CreateReleaseSubstep.frameworkMirror]!)),
          testInputsCorrect[CreateReleaseSubstep.frameworkMirror]!);
      await tester.enterText(find.byKey(Key(CreateReleaseSubsteps.substepTitles[CreateReleaseSubstep.engineMirror]!)),
          testInputsCorrect[CreateReleaseSubstep.engineMirror]!);
      await tester.enterText(
          find.byKey(Key(CreateReleaseSubsteps.substepTitles[CreateReleaseSubstep.engineCherrypicks]!)),
          testInputsCorrect[CreateReleaseSubstep.engineCherrypicks]!);
      await tester.enterText(
          find.byKey(Key(CreateReleaseSubsteps.substepTitles[CreateReleaseSubstep.frameworkCherrypicks]!)),
          testInputsCorrect[CreateReleaseSubstep.frameworkCherrypicks]!);
      await tester.enterText(find.byKey(Key(CreateReleaseSubsteps.substepTitles[CreateReleaseSubstep.dartRevision]!)),
          testInputsCorrect[CreateReleaseSubstep.dartRevision]!);

      /// Tests the Increment dropdown menu.
      await tester.tap(find.byKey(Key(CreateReleaseSubsteps.substepTitles[CreateReleaseSubstep.increment]!)));
      await tester.pumpAndSettle(); // finish the menu animation
      expect(createReleaseSubstepsState.releaseData[CreateReleaseSubstep.increment], equals(null));
      await tester.tap(find.text(testInputsCorrect[CreateReleaseSubstep.increment]!).last);
      await tester.pumpAndSettle(); // finish the menu animation

      expect(createReleaseSubstepsState.releaseData, testInputsCorrect);
    });

    testWidgets('Continue button should be enabled when all the parameters are entered correctly',
        (WidgetTester tester) async {
      await tester.pumpWidget(ChangeNotifierProvider(
        create: (context) => StatusState(conductor: FakeConductor()),
        child: MaterialApp(
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
      ));

      final StatefulElement createReleaseSubsteps = tester.element(find.byType(CreateReleaseSubsteps));
      final CreateReleaseSubstepsState createReleaseSubstepsState =
          createReleaseSubsteps.state as CreateReleaseSubstepsState;
      final Finder continueButton = find.byKey(const Key('createReleaseContinue'));
      // default isEachInputValid state values, optional fields are valid from the start
      expect(
        createReleaseSubstepsState.isEachInputValid,
        equals(<CreateReleaseSubstep, bool>{
          CreateReleaseSubstep.candidateBranch: false,
          CreateReleaseSubstep.releaseChannel: false,
          CreateReleaseSubstep.frameworkMirror: false,
          CreateReleaseSubstep.engineMirror: false,
          CreateReleaseSubstep.engineCherrypicks: true,
          CreateReleaseSubstep.frameworkCherrypicks: true,
          CreateReleaseSubstep.dartRevision: true,
          CreateReleaseSubstep.increment: false,
        }),
      );

      expect(tester.widget<ElevatedButton>(continueButton).enabled, false);

      await fillAllParameters(tester, testInputsCorrect);
      // continue button is enabled, and all the parameters are validated
      expect(tester.widget<ElevatedButton>(continueButton).enabled, true);
      expect(
        createReleaseSubstepsState.isEachInputValid.containsValue(false),
        false,
      );
    });
  });

  group('CLI connection', () {
    testWidgets('Is able to display a conductor exception in the UI', (WidgetTester tester) async {
      const String exceptionMsg = 'There is a conductor Exception';
      final FakeStartContext startContext = FakeStartContext(
        runOverride: () async => throw ConductorException(exceptionMsg),
      );

      await tester.pumpWidget(ChangeNotifierProvider(
        create: (context) => StatusState(conductor: FakeConductor(fakeStartContextProvided: startContext)),
        child: MaterialApp(
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
      ));

      final Finder continueButton = find.byKey(const Key('createReleaseContinue'));
      await fillAllParameters(tester, testInputsCorrect);
      expect(continueButton, findsOneWidget);
      await tester.drag(continueButton, const Offset(-250, 0));
      await tester.pump();
      await tester.tap(continueButton);
      await tester.pumpAndSettle();
      expect(find.textContaining(exceptionMsg), findsOneWidget);
      expect(find.textContaining('Stack Trace'), findsOneWidget);
    });

    testWidgets('Is able to display a general exception in the UI', (WidgetTester tester) async {
      const String exceptionMsg = 'There is a general Exception';
      final FakeStartContext startContext = FakeStartContext(
        runOverride: () async => throw Exception(exceptionMsg),
      );

      await tester.pumpWidget(ChangeNotifierProvider(
        create: (context) => StatusState(conductor: FakeConductor(fakeStartContextProvided: startContext)),
        child: MaterialApp(
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
      ));

      final Finder continueButton = find.byKey(const Key('createReleaseContinue'));
      await fillAllParameters(tester, testInputsCorrect);
      expect(continueButton, findsOneWidget);
      await tester.drag(continueButton, const Offset(-250, 0));
      await tester.pump();
      await tester.tap(continueButton);
      await tester.pumpAndSettle();
      expect(find.textContaining(exceptionMsg), findsOneWidget);
      expect(find.textContaining('Stack Trace'), findsOneWidget);
    });

    testWidgets('Proceeds to the next step if there is no exception', (WidgetTester tester) async {
      bool contextRunCalled = false;
      bool nextStepReached = false;
      final FakeStartContext startContext = FakeStartContext(
        runOverride: () async => contextRunCalled = true,
      );

      await tester.pumpWidget(ChangeNotifierProvider(
        create: (context) => StatusState(conductor: FakeConductor(fakeStartContextProvided: startContext)),
        child: MaterialApp(
          home: Material(
            child: ListView(
              children: <Widget>[
                CreateReleaseSubsteps(
                  nextStep: () => nextStepReached = true,
                ),
              ],
            ),
          ),
        ),
      ));

      final Finder continueButton = find.byKey(const Key('createReleaseContinue'));
      await fillAllParameters(tester, testInputsCorrect);
      expect(continueButton, findsOneWidget);
      await tester.drag(continueButton, const Offset(-250, 0));
      await tester.pump();
      await tester.tap(continueButton);
      await tester.pumpAndSettle();
      expect(contextRunCalled, true);
      expect(nextStepReached, true);
    });

    testWidgets('Is able to display the loading UI, and hides it after the release is done',
        (WidgetTester tester) async {
      final FakeStartContext startContext = FakeStartContext();

      // This completer signifies the completion of `startContext.run()` function
      final Completer<void> completer = Completer<void>();

      startContext.addCommand(FakeCommand(
        command: const <String>[
          'git',
          'clone',
          '--origin',
          'upstream',
          '--',
          EngineRepository.defaultUpstream,
          '${kCheckoutsParentDirectory}flutter_conductor_checkouts/engine'
        ],
        completer: completer,
      ));

      await tester.pumpWidget(ChangeNotifierProvider(
        create: (context) => StatusState(conductor: FakeConductor(fakeStartContextProvided: startContext)),
        child: MaterialApp(
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
      ));

      final Finder continueButton = find.byKey(const Key('createReleaseContinue'));
      await fillAllParameters(tester, testInputsCorrect);
      expect(continueButton, findsOneWidget);
      await tester.drag(continueButton, const Offset(-250, 0));
      await tester.pump();
      await tester.tap(continueButton);
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(tester.widget<ElevatedButton>(continueButton).enabled, false);

      completer.complete();
      await tester.pumpAndSettle();
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(tester.widget<ElevatedButton>(continueButton).enabled, true);
    });

    testWidgets('Disable all inputs and dropdowns when loading', (WidgetTester tester) async {
      final FakeStartContext startContext = FakeStartContext();

      // This completer signifies the completion of `startContext.run()` function
      final Completer<void> completer = Completer<void>();

      startContext.addCommand(FakeCommand(
        command: const <String>[
          'git',
          'clone',
          '--origin',
          'upstream',
          '--',
          EngineRepository.defaultUpstream,
          '${kCheckoutsParentDirectory}flutter_conductor_checkouts/engine'
        ],
        completer: completer,
      ));

      await tester.pumpWidget(ChangeNotifierProvider(
        create: (context) => StatusState(conductor: FakeConductor(fakeStartContextProvided: startContext)),
        child: MaterialApp(
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
      ));

      final Finder continueButton = find.byKey(const Key('createReleaseContinue'));
      await fillAllParameters(tester, testInputsCorrect);
      await tester.drag(continueButton, const Offset(-250, 0));
      await tester.pump();
      await tester.tap(continueButton);
      await tester.pump();

      // Every input and dropdown is disabled.
      for (final CreateReleaseSubstep substep in CreateReleaseSubstep.values) {
        if (CreateReleaseSubsteps.dropdownElements.contains(substep)) {
          expect(
              tester.widget<DropdownButton>(find.byKey(Key(CreateReleaseSubsteps.substepTitles[substep]!))).onChanged,
              equals(null));
        } else {
          expect(tester.widget<TextFormField>(find.byKey(Key(CreateReleaseSubsteps.substepTitles[substep]!))).enabled,
              equals(false));
        }
      }

      completer.complete();
      await tester.pumpAndSettle();
    });
  });
}

/// Fills every input and dropdown with correct test data.
Future<void> fillAllParameters(WidgetTester tester, Map<CreateReleaseSubstep, String> testInputsCorrect) async {
  await tester.enterText(find.byKey(Key(CreateReleaseSubsteps.substepTitles[CreateReleaseSubstep.candidateBranch]!)),
      testInputsCorrect[CreateReleaseSubstep.candidateBranch]!);

  await tester.tap(find.byKey(Key(CreateReleaseSubsteps.substepTitles[CreateReleaseSubstep.releaseChannel]!)));
  await tester.pumpAndSettle();
  await tester.tap(find.text(testInputsCorrect[CreateReleaseSubstep.releaseChannel]!).last);

  await tester.enterText(find.byKey(Key(CreateReleaseSubsteps.substepTitles[CreateReleaseSubstep.frameworkMirror]!)),
      testInputsCorrect[CreateReleaseSubstep.frameworkMirror]!);
  await tester.enterText(find.byKey(Key(CreateReleaseSubsteps.substepTitles[CreateReleaseSubstep.engineMirror]!)),
      testInputsCorrect[CreateReleaseSubstep.engineMirror]!);
  await tester.enterText(find.byKey(Key(CreateReleaseSubsteps.substepTitles[CreateReleaseSubstep.engineCherrypicks]!)),
      testInputsCorrect[CreateReleaseSubstep.engineCherrypicks]!);
  await tester.enterText(
      find.byKey(Key(CreateReleaseSubsteps.substepTitles[CreateReleaseSubstep.frameworkCherrypicks]!)),
      testInputsCorrect[CreateReleaseSubstep.frameworkCherrypicks]!);
  await tester.enterText(find.byKey(Key(CreateReleaseSubsteps.substepTitles[CreateReleaseSubstep.dartRevision]!)),
      testInputsCorrect[CreateReleaseSubstep.dartRevision]!);

  await tester.tap(find.byKey(Key(CreateReleaseSubsteps.substepTitles[CreateReleaseSubstep.increment]!)));
  await tester.pumpAndSettle();
  await tester.tap(find.text(testInputsCorrect[CreateReleaseSubstep.increment]!).last);
  await tester.pumpAndSettle();
}
