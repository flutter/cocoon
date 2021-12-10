// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:conductor_core/conductor_core.dart';
import 'package:conductor_core/proto.dart' as pb;
import 'package:conductor_ui/state/status_state.dart';
import 'package:conductor_ui/widgets/common/checkbox_substep.dart';
import 'package:conductor_ui/widgets/common/url_button.dart';
import 'package:conductor_ui/widgets/verify_release_substep.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import '../fakes/fake_next_context.dart';
import '../fakes/services/fake_conductor.dart';
import '../src/test_state_generator.dart';

void main() {
  const pb.ReleasePhase currentPhase = pb.ReleasePhase.VERIFY_RELEASE;
  const pb.ReleasePhase nextPhase = pb.ReleasePhase.RELEASE_COMPLETED;
  group('Verify Release UI tests', () {
    late pb.ConductorState stateWithoutConflicts;

    setUp(() {
      stateWithoutConflicts = generateConductorState(currentPhase: currentPhase);
    });

    testWidgets('Render all elements correctly', (WidgetTester tester) async {
      await tester.pumpWidget(ChangeNotifierProvider(
        create: (context) => StatusState(conductor: FakeConductor(testState: stateWithoutConflicts)),
        child: MaterialApp(
          home: Material(
            child: Column(
              children: const <Widget>[VerifyReleaseSubsteps()],
            ),
          ),
        ),
      ));

      for (VerifyReleaseSubstep substep in VerifyReleaseSubstep.values) {
        expect(find.textContaining(VerifyReleaseSubsteps.substepTitles[substep]!), findsOneWidget);
        expect(find.textContaining(VerifyReleaseSubsteps.substepSubtitles[substep]!), findsOneWidget);
      }
      expect(find.byType(CheckboxAsSubstep), findsNWidgets(2));
      expect(find.byKey(const Key('verifyReleaseContinue')), findsOneWidget);
    });

    testWidgets('Renders the release channel', (WidgetTester tester) async {
      await tester.pumpWidget(ChangeNotifierProvider(
        create: (context) => StatusState(conductor: FakeConductor(testState: stateWithoutConflicts)),
        child: MaterialApp(
          home: Material(
            child: Column(
              children: const <Widget>[VerifyReleaseSubsteps()],
            ),
          ),
        ),
      ));

      expect(find.textContaining(kReleaseChannel), findsNWidgets(2));
    });

    testWidgets('Renders the Luci link', (WidgetTester tester) async {
      await tester.pumpWidget(ChangeNotifierProvider(
        create: (context) => StatusState(conductor: FakeConductor(testState: stateWithoutConflicts)),
        child: MaterialApp(
          home: Material(
            child: Column(
              children: const <Widget>[VerifyReleaseSubsteps()],
            ),
          ),
        ),
      ));

      final String postMonitorLuci = luciConsoleLink(
        kReleaseChannel,
        'packaging',
      );
      expect(find.byType(UrlButton), findsOneWidget);
      expect(find.text(postMonitorLuci), findsOneWidget);
    });

    testWidgets('Checking all substeps enables the continue button', (WidgetTester tester) async {
      await tester.pumpWidget(ChangeNotifierProvider(
        create: (context) => StatusState(conductor: FakeConductor(testState: stateWithoutConflicts)),
        child: MaterialApp(
          home: Material(
            child: Column(
              children: const <Widget>[VerifyReleaseSubsteps()],
            ),
          ),
        ),
      ));

      Finder continueButton = find.byKey(const Key('verifyReleaseContinue'));
      expect(continueButton, findsOneWidget);
      expect(tester.widget<ElevatedButton>(continueButton).enabled, equals(false));
      for (VerifyReleaseSubstep substep in VerifyReleaseSubstep.values) {
        await tester.tap(find.textContaining(VerifyReleaseSubsteps.substepTitles[substep]!));
      }
      await tester.pumpAndSettle();
      expect(tester.widget<ElevatedButton>(continueButton).enabled, equals(true));
    });
  });

  group('nextContext tests', () {
    late pb.ConductorState stateWithoutConflicts;

    setUp(() {
      stateWithoutConflicts = generateConductorState(currentPhase: currentPhase);
    });

    testWidgets('Clicking on the continue button proceeds to the next step', (WidgetTester tester) async {
      final pb.ConductorState nextPhaseState = generateConductorState(currentPhase: nextPhase);

      FakeConductor fakeConductor = FakeConductor(
        testState: stateWithoutConflicts,
      );
      // Initialize a [FakeNextContext] that changes the state of the conductor to be at the
      // next phase, and attach it to the conductor. That simulates the scenario when
      // 'fakeNextContext.run()` is called, proceeds to the next phase of the release.
      FakeNextContext fakeNextContext = FakeNextContext(
        runOverride: () async => fakeConductor.testState = nextPhaseState,
      );
      fakeConductor.fakeNextContextProvided = fakeNextContext;

      await tester.pumpWidget(ChangeNotifierProvider(
        create: (context) => StatusState(conductor: fakeConductor),
        child: MaterialApp(
          home: Material(
            child: Column(
              children: const <Widget>[VerifyReleaseSubsteps()],
            ),
          ),
        ),
      ));

      Finder continueButton = find.byKey(const Key('verifyReleaseContinue'));
      expect(fakeConductor.state?.currentPhase, equals(currentPhase));
      for (VerifyReleaseSubstep substep in VerifyReleaseSubstep.values) {
        await tester.tap(find.textContaining(VerifyReleaseSubsteps.substepTitles[substep]!));
      }
      await tester.pumpAndSettle();
      await tester.tap(continueButton);
      await tester.pumpAndSettle();
      expect(fakeConductor.state?.currentPhase, equals(nextPhase));
    });

    testWidgets('Catch an exception correctly', (WidgetTester tester) async {
      const String exceptionMsg = 'There is a general Exception';

      // Initialize a [FakeNextContext] that throws an error and attach it to the conductor.
      // That simulates the scenario when 'fakeNextContext.run()` is called, an error is thrown.
      final FakeConductor fakeConductor = FakeConductor(
        testState: stateWithoutConflicts,
        fakeNextContextProvided: FakeNextContext(
          runOverride: () async => throw Exception(exceptionMsg),
        ),
      );

      await tester.pumpWidget(ChangeNotifierProvider(
        create: (context) => StatusState(conductor: fakeConductor),
        child: MaterialApp(
          home: Material(
            child: ListView(
              children: const <Widget>[VerifyReleaseSubsteps()],
            ),
          ),
        ),
      ));

      Finder continueButton = find.byKey(const Key('verifyReleaseContinue'));
      for (VerifyReleaseSubstep substep in VerifyReleaseSubstep.values) {
        await tester.tap(find.textContaining(VerifyReleaseSubsteps.substepTitles[substep]!));
      }
      await tester.pumpAndSettle();
      await tester.tap(continueButton);
      await tester.pumpAndSettle();
      expect(fakeConductor.state?.currentPhase, equals(currentPhase));
      expect(find.textContaining(exceptionMsg), findsOneWidget);
    });
  });
}
