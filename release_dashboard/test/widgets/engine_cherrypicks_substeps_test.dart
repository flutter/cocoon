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

import '../fakes/services/fake_conductor.dart';
import '../src/test_state_generator.dart';

void main() {
  group('Engine cherrypick substeps tests', () {
    testWidgets('Continue button appears when all substeps are checked', (WidgetTester tester) async {
      await tester.pumpWidget(ChangeNotifierProvider(
        create: (context) => StatusState(conductor: FakeConductor()),
        child: MaterialApp(
          home: Material(
            child: Column(
              children: <Widget>[
                Builder(builder: (context) {
                  return CherrypicksSubsteps(nextStep: () {}, repository: Repositories.engine);
                }),
              ],
            ),
          ),
        ),
      ));

      expect(find.byKey(const Key('applyEngineCherrypicksContinue')), findsNothing);
      for (final String substep in CherrypicksSubsteps.substepTitles.values) {
        await tester.tap(find.text(substep));
      }
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('applyEngineCherrypicksContinue')), findsOneWidget);
    });

    testWidgets('Clicking on the continue button proceeds to the next step', (WidgetTester tester) async {
      bool isNextStep = false;
      void nextStep() => isNextStep = true;

      await tester.pumpWidget(ChangeNotifierProvider(
        create: (context) => StatusState(conductor: FakeConductor()),
        child: MaterialApp(
          home: Material(
            child: Column(
              children: <Widget>[
                Builder(builder: (context) {
                  return CherrypicksSubsteps(nextStep: nextStep, repository: Repositories.engine);
                }),
              ],
            ),
          ),
        ),
      ));

      for (final String substep in CherrypicksSubsteps.substepTitles.values) {
        await tester.tap(find.text(substep));
      }
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('applyEngineCherrypicksContinue')));
      await tester.pumpAndSettle();
      expect(isNextStep, equals(true));
    });
  });

  group('Without cherrypick conflicts', () {
    late pb.ConductorState stateWithoutConflicts;

    setUp(() {
      stateWithoutConflicts = generateConductorState();
    });

    testWidgets("'Verify release number' substep displays correctly", (WidgetTester tester) async {
      await tester.pumpWidget(ChangeNotifierProvider(
        create: (context) => StatusState(conductor: FakeConductor(testState: stateWithoutConflicts)),
        child: MaterialApp(
          home: Material(
            child: Column(
              children: <Widget>[
                Builder(builder: (context) {
                  return CherrypicksSubsteps(nextStep: () {}, repository: Repositories.engine);
                }),
              ],
            ),
          ),
        ),
      ));

      expect(find.text(CherrypicksSubsteps.substepTitles[CherrypicksSubstep.verifyRelease]!), findsOneWidget);
      expect(find.textContaining(kReleaseVersion), findsOneWidget);
      expect(find.byType(UrlButton), findsOneWidget);
<<<<<<< HEAD
      expect(find.text(CherrypicksSubsteps.kReleaseSDKURL), findsOneWidget);
=======
      expect(find.text(kWebsiteReleasesUrl), findsOneWidget);
>>>>>>> ec01a34 (rebased from main)
    });

    testWidgets("'Apply cherrypicks' substep displays correctly", (WidgetTester tester) async {
      await tester.pumpWidget(ChangeNotifierProvider(
        create: (context) => StatusState(conductor: FakeConductor(testState: stateWithoutConflicts)),
        child: MaterialApp(
          home: Material(
            child: Column(
              children: <Widget>[
                Builder(builder: (context) {
                  return CherrypicksSubsteps(nextStep: () {}, repository: Repositories.engine);
                }),
              ],
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
      stateWithConflicts = generateConductorState(engineCherrypicksInConflict: true);
    });

    testWidgets("'Verify release number' substep displays correctly'", (WidgetTester tester) async {
      await tester.pumpWidget(ChangeNotifierProvider(
        create: (context) => StatusState(conductor: FakeConductor(testState: stateWithConflicts)),
        child: MaterialApp(
          home: Material(
            child: Column(
              children: <Widget>[
                Builder(builder: (context) {
                  return CherrypicksSubsteps(nextStep: () {}, repository: Repositories.engine);
                }),
              ],
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
              children: <Widget>[
                Builder(builder: (context) {
                  return CherrypicksSubsteps(nextStep: () {}, repository: Repositories.engine);
                }),
              ],
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
}
