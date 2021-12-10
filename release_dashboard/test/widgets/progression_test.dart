// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:conductor_core/proto.dart' as pb;
import 'package:conductor_ui/state/status_state.dart';
import 'package:conductor_ui/widgets/cherrypicks_substeps.dart';
import 'package:conductor_ui/widgets/create_release_substeps.dart';
import 'package:conductor_ui/widgets/merge_pr_substeps.dart';
import 'package:conductor_ui/widgets/progression.dart';
import 'package:conductor_ui/widgets/publish_release_substeps.dart';
import 'package:conductor_ui/widgets/release_completed.dart';
import 'package:conductor_ui/widgets/verify_release_substep.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import '../fakes/services/fake_conductor.dart';
import '../src/test_state_generator.dart';

void main() {
  group('Main progression tests', () {
    late pb.ConductorState stateWithoutConflicts;

    setUp(() {
      stateWithoutConflicts = generateConductorState();
    });
    testWidgets('When the user clicks on a previously completed step, Stepper does not navigate back.',
        (WidgetTester tester) async {
      final FakeConductor fakeConductor = FakeConductor(testState: stateWithoutConflicts);

      await tester.pumpWidget(ChangeNotifierProvider(
        create: (context) => StatusState(conductor: fakeConductor),
        child: MaterialApp(
          home: Material(
            child: Column(
              children: <Widget>[
                MainProgression(conductor: fakeConductor),
              ],
            ),
          ),
        ),
      ));

      expect(tester.widget<Stepper>(find.byType(Stepper)).currentStep,
          equals(MainProgression.stepPosition[kCurrentPhase]));

      await tester.tap(find.text('Initialize a New Flutter Release'));
      await tester.pumpAndSettle();
      // Remains at the currentPhase after clicking on a previous phase.
      expect(tester.widget<Stepper>(find.byType(Stepper)).currentStep,
          equals(MainProgression.stepPosition[kCurrentPhase]));
    });

    testWidgets('Stepper only renders the widget of the current step', (WidgetTester tester) async {
      final FakeConductor fakeConductor = FakeConductor(testState: stateWithoutConflicts);

      await tester.pumpWidget(ChangeNotifierProvider(
        create: (context) => StatusState(conductor: fakeConductor),
        child: MaterialApp(
          home: Material(
            child: Column(
              children: <Widget>[
                MainProgression(conductor: fakeConductor),
              ],
            ),
          ),
        ),
      ));

      expect(find.byType(CherrypicksSubsteps), findsOneWidget);
      expect(find.byType(CreateReleaseSubsteps), findsNothing);
      expect(find.byType(MergePrSubsteps), findsNothing);
      expect(find.byType(PublishReleaseSubsteps), findsNothing);
      expect(find.byType(VerifyReleaseSubsteps), findsNothing);
      expect(find.byType(ReleaseCompleted), findsNothing);
    });

    testWidgets('Only previously completed steps or the current step are active', (WidgetTester tester) async {
      final FakeConductor fakeConductor = FakeConductor(testState: stateWithoutConflicts);

      await tester.pumpWidget(ChangeNotifierProvider(
        create: (context) => StatusState(conductor: fakeConductor),
        child: MaterialApp(
          home: Material(
            child: Column(
              children: <Widget>[
                MainProgression(conductor: fakeConductor),
              ],
            ),
          ),
        ),
      ));

      for (MapEntry step in MainProgression.stepPosition.entries) {
        if (step.value <= MainProgression.stepPosition[kCurrentPhase]) {
          expect(tester.widget<Stepper>(find.byType(Stepper)).steps[step.value].isActive, true);
        } else {
          expect(tester.widget<Stepper>(find.byType(Stepper)).steps[step.value].isActive, false);
        }
      }
    });

    testWidgets('Each step status changes according to the current step', (WidgetTester tester) async {
      final FakeConductor fakeConductor = FakeConductor(testState: stateWithoutConflicts);

      await tester.pumpWidget(ChangeNotifierProvider(
        create: (context) => StatusState(conductor: fakeConductor),
        child: MaterialApp(
          home: Material(
            child: Column(
              children: <Widget>[
                MainProgression(conductor: fakeConductor),
              ],
            ),
          ),
        ),
      ));

      for (MapEntry step in MainProgression.stepPosition.entries) {
        if (step.value == MainProgression.stepPosition[kCurrentPhase]) {
          expect(tester.widget<Stepper>(find.byType(Stepper)).steps[step.value].state, StepState.indexed);
        } else if (step.value < MainProgression.stepPosition[kCurrentPhase]) {
          expect(tester.widget<Stepper>(find.byType(Stepper)).steps[step.value].state, StepState.complete);
        } else {
          expect(tester.widget<Stepper>(find.byType(Stepper)).steps[step.value].state, StepState.disabled);
        }
      }
    });
  });

  group('Progression is able to resume from a previously completed step', () {
    late pb.ConductorState stateWithoutConflicts;

    setUp(() {
      stateWithoutConflicts = generateConductorState();
    });

    for (MapEntry step in MainProgression.stepPosition.entries) {
      if (step.key == ReleaseSteps.initializeRelease) {
        testWidgets('If there is no test state, start from creating a release step', (WidgetTester tester) async {
          final FakeConductor fakeConductor = FakeConductor();

          await tester.pumpWidget(ChangeNotifierProvider(
            create: (context) => StatusState(conductor: fakeConductor),
            child: MaterialApp(
              home: Material(
                child: Column(
                  children: <Widget>[
                    MainProgression(conductor: fakeConductor),
                  ],
                ),
              ),
            ),
          ));

          expect(tester.widget<Stepper>(find.byType(Stepper)).currentStep, equals(step.value));
        });
      } else {
        testWidgets('Widget is able to resume from step ${step.key}', (WidgetTester tester) async {
          // Set the current phase of state to aligh with this step.
          stateWithoutConflicts.currentPhase = step.key;
          final FakeConductor fakeConductor = FakeConductor(testState: stateWithoutConflicts);

          await tester.pumpWidget(ChangeNotifierProvider(
            create: (context) => StatusState(conductor: fakeConductor),
            child: MaterialApp(
              home: Material(
                child: Column(
                  children: <Widget>[
                    MainProgression(conductor: fakeConductor),
                  ],
                ),
              ),
            ),
          ));

          expect(tester.widget<Stepper>(find.byType(Stepper)).currentStep, equals(step.value));
        });
      }
    }
  });

  group('DialogPrompt appears correctly', () {
    late pb.ConductorState stateWithoutConflicts;

    setUp(() {
      stateWithoutConflicts = generateConductorState(currentPhase: pb.ReleasePhase.PUBLISH_VERSION);
    });

    testWidgets('Display a prompt if there is a message', (WidgetTester tester) async {
      const String initialPromptMessage = 'There is a prompt';
      final FakeConductor fakeConductor = FakeConductor(testState: stateWithoutConflicts);

      await tester.pumpWidget(ChangeNotifierProvider(
        create: (context) => StatusState(conductor: fakeConductor),
        child: MaterialApp(
          home: Material(
            child: Column(
              children: <Widget>[
                Builder(builder: (context) {
                  return MainProgression(
                    conductor: fakeConductor,
                    initialDialogPrompt: initialPromptMessage,
                  );
                }),
              ],
            ),
          ),
        ),
      ));

      await tester.tap(find.byKey(const Key('mergeFrameworkCherrypicksSubstepsContinue')));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text(initialPromptMessage), findsOneWidget);
    });
  });
}
