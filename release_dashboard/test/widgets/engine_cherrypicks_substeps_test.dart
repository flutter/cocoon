// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:conductor_core/conductor_core.dart';
import 'package:conductor_core/proto.dart' as pb;
import 'package:conductor_ui/models/repositories.dart';
import 'package:conductor_ui/state/status_state.dart';
import 'package:conductor_ui/widgets/cherrypicks_substeps.dart';
import 'package:conductor_ui/widgets/common/url_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import '../fakes/fake_next_context.dart';
import '../fakes/services/fake_conductor.dart';
import '../src/test_state_generator.dart';

void main() {
  const pb.ReleasePhase currentPhase = pb.ReleasePhase.APPLY_ENGINE_CHERRYPICKS;
  const pb.ReleasePhase nextPhase = pb.ReleasePhase.CODESIGN_ENGINE_BINARIES;

  group('Engine cherrypick substeps tests', () {
    late pb.ConductorState stateWithoutConflicts;

    setUp(() {
      stateWithoutConflicts = generateConductorState(currentPhase: currentPhase);
    });

    testWidgets('Continue button enables when all substeps are checked', (WidgetTester tester) async {
      await tester.pumpWidget(ChangeNotifierProvider(
        create: (context) => StatusState(conductor: FakeConductor(testState: stateWithoutConflicts)),
        child: MaterialApp(
          home: Material(
            child: ListView(
              children: const <Widget>[CherrypicksSubsteps(repository: Repositories.engine)],
            ),
          ),
        ),
      ));

      final Finder continueButton = find.byKey(const Key('applyEngineCherrypicksContinue'));
      expect((continueButton), findsOneWidget);
      expect(tester.widget<ElevatedButton>(continueButton).enabled, equals(false));
      for (final String substep in CherrypicksSubsteps.substepTitles.values) {
        await tester.tap(find.text(substep));
      }
      await tester.pumpAndSettle();
      expect(tester.widget<ElevatedButton>(continueButton).enabled, equals(true));
    });
  });

  group('Without cherrypick conflicts', () {
    late pb.ConductorState stateWithoutConflicts;

    setUp(() {
      stateWithoutConflicts = generateConductorState(currentPhase: currentPhase);
    });

    testWidgets("'Verify release number' substep displays correctly", (WidgetTester tester) async {
      await tester.pumpWidget(ChangeNotifierProvider(
        create: (context) => StatusState(conductor: FakeConductor(testState: stateWithoutConflicts)),
        child: MaterialApp(
          home: Material(
            child: Column(
              children: const <Widget>[CherrypicksSubsteps(repository: Repositories.engine)],
            ),
          ),
        ),
      ));

      expect(find.text(CherrypicksSubsteps.substepTitles[CherrypicksSubstep.verifyRelease]!), findsOneWidget);
      expect(find.textContaining(kReleaseVersion), findsOneWidget);
      expect(find.byType(UrlButton), findsOneWidget);
      expect(find.text(kWebsiteReleasesUrl), findsOneWidget);
    });

    testWidgets("'Apply cherrypicks' substep displays correctly", (WidgetTester tester) async {
      await tester.pumpWidget(ChangeNotifierProvider(
        create: (context) => StatusState(conductor: FakeConductor(testState: stateWithoutConflicts)),
        child: MaterialApp(
          home: Material(
            child: Column(
              children: const <Widget>[CherrypicksSubsteps(repository: Repositories.engine)],
            ),
          ),
        ),
      ));

      expect(find.text(CherrypicksSubsteps.substepTitles[CherrypicksSubstep.applyCherrypicks]!), findsOneWidget);
      expect(find.textContaining('No engine cherrypick conflicts'), findsOneWidget);
    });
  });

  group('With cherrypick conflicts', () {
    late pb.ConductorState stateWithConflicts;

    setUp(() {
      stateWithConflicts = generateConductorState(currentPhase: currentPhase, engineCherrypicksInConflict: true);
    });

    testWidgets("'Verify release number' substep displays correctly'", (WidgetTester tester) async {
      await tester.pumpWidget(ChangeNotifierProvider(
        create: (context) => StatusState(conductor: FakeConductor(testState: stateWithConflicts)),
        child: MaterialApp(
          home: Material(
            child: Column(
              children: const <Widget>[CherrypicksSubsteps(repository: Repositories.engine)],
            ),
          ),
        ),
      ));

      expect(find.text(CherrypicksSubsteps.substepTitles[CherrypicksSubstep.verifyRelease]!), findsOneWidget);
      expect(find.textContaining(kReleaseVersion), findsOneWidget);
      expect(find.text(kWebsiteReleasesUrl), findsOneWidget);
      expect(find.byType(UrlButton), findsNWidgets(2));
    });

    testWidgets("'Apply cherrypicks' substep displays correctly", (WidgetTester tester) async {
      FakeConductor fakeConductor = FakeConductor(testState: stateWithConflicts);
      await tester.pumpWidget(ChangeNotifierProvider(
        create: (context) => StatusState(conductor: fakeConductor),
        child: MaterialApp(
          home: Material(
            child: Column(
              children: const <Widget>[CherrypicksSubsteps(repository: Repositories.engine)],
            ),
          ),
        ),
      ));

      expect(find.text(CherrypicksSubsteps.substepTitles[CherrypicksSubstep.applyCherrypicks]!), findsOneWidget);
      expect(find.textContaining('Navigate to the engine checkout'), findsOneWidget);
      expect(find.textContaining('${fakeConductor.rootDirectory.path}/flutter_conductor_checkouts/engine'),
          findsOneWidget);
      expect(find.textContaining('apply the following engine cherrypicks'), findsOneWidget);
      expect(find.textContaining('git cherry-pick $kEngineCherrypick1'), findsOneWidget);
      expect(find.textContaining('git cherry-pick $kEngineCherrypick2'), findsOneWidget);

      expect(find.textContaining('See more information'), findsOneWidget);
      expect(find.text(kReleaseDocumentationUrl), findsOneWidget);
    });
  });

  group('NextContext tests', () {
    late pb.ConductorState stateWithoutConflicts;

    setUp(() {
      stateWithoutConflicts = generateConductorState(currentPhase: currentPhase);
    });
    testWidgets('Clicking on the continue button proceeds to the next phase of the release',
        (WidgetTester tester) async {
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
        create: (context) => StatusState(
          conductor: fakeConductor,
        ),
        child: MaterialApp(
          home: Material(
            child: ListView(
              children: const <Widget>[CherrypicksSubsteps(repository: Repositories.engine)],
            ),
          ),
        ),
      ));

      expect(fakeConductor.state?.currentPhase, equals(kCurrentPhase));
      await checkAllContinue(tester);
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
        create: (context) => StatusState(
          conductor: fakeConductor,
        ),
        child: MaterialApp(
          home: Material(
            child: ListView(
              children: const <Widget>[CherrypicksSubsteps(repository: Repositories.engine)],
            ),
          ),
        ),
      ));

      await checkAllContinue(tester);
      expect(fakeConductor.state?.currentPhase, equals(kCurrentPhase));
      expect(find.textContaining(exceptionMsg), findsOneWidget);
    });
  });
}

/// Check all substeps and press on the continue button.
Future<void> checkAllContinue(WidgetTester tester) async {
  for (final String substep in CherrypicksSubsteps.substepTitles.values) {
    await tester.tap(find.text(substep));
  }
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const Key('applyEngineCherrypicksContinue')));
  await tester.pumpAndSettle();
}
