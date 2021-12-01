// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:conductor_core/conductor_core.dart';
import 'package:conductor_core/proto.dart' as pb;
import 'package:conductor_ui/models/repositories.dart';
import 'package:conductor_ui/state/status_state.dart';
import 'package:conductor_ui/widgets/cherrypicks_substeps.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import '../fakes/services/fake_conductor.dart';
import '../src/test_state_generator.dart';

void main() {
  group('Framework cherrypick substeps tests', () {
    testWidgets('Continue button appears when all substeps are checked', (WidgetTester tester) async {
      await tester.pumpWidget(ChangeNotifierProvider(
        create: (context) => StatusState(conductor: FakeConductor()),
        child: MaterialApp(
          home: Material(
            child: Column(
              children: <Widget>[
                Builder(builder: (context) {
                  return CherrypicksSubsteps(nextStep: () {}, repository: Repositories.framework);
                }),
              ],
            ),
          ),
        ),
      ));

      expect(find.byKey(const Key('applyFrameworkCherrypicksContinue')), findsNothing);
      expect(find.text(CherrypicksSubsteps.substepTitles[CherrypicksSubstep.verifyRelease]!), findsNothing);
      expect(find.text(CherrypicksSubsteps.substepTitles[CherrypicksSubstep.applyCherrypicks]!), findsOneWidget);
      await tester.tap(find.text(CherrypicksSubsteps.substepTitles[CherrypicksSubstep.applyCherrypicks]!));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('applyFrameworkCherrypicksContinue')), findsOneWidget);
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
                  return CherrypicksSubsteps(nextStep: nextStep, repository: Repositories.framework);
                }),
              ],
            ),
          ),
        ),
      ));

      await tester.tap(find.text(CherrypicksSubsteps.substepTitles[CherrypicksSubstep.applyCherrypicks]!));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('applyFrameworkCherrypicksContinue')));
      await tester.pumpAndSettle();
      expect(isNextStep, equals(true));
    });
  });

  group('Without cherrypick conflicts', () {
    late pb.ConductorState stateWithoutConflicts;

    setUp(() {
      stateWithoutConflicts = generateConductorState();
    });

    testWidgets("'Apply cherrypicks' substep displays correctly", (WidgetTester tester) async {
      await tester.pumpWidget(ChangeNotifierProvider(
        create: (context) => StatusState(conductor: FakeConductor(testState: stateWithoutConflicts)),
        child: MaterialApp(
          home: Material(
            child: Column(
              children: <Widget>[
                Builder(builder: (context) {
                  return CherrypicksSubsteps(nextStep: () {}, repository: Repositories.framework);
                }),
              ],
            ),
          ),
        ),
      ));

      expect(find.text(CherrypicksSubsteps.substepTitles[CherrypicksSubstep.applyCherrypicks]!), findsOneWidget);
      expect(find.textContaining('No framework cherrypick conflicts'), findsOneWidget);
    });
  });

  group('With cherrypick conflicts', () {
    late pb.ConductorState stateWithConflicts;

    setUp(() {
      stateWithConflicts = generateConductorState(frameworkCherrypicksInConflict: true);
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
                  return CherrypicksSubsteps(nextStep: () {}, repository: Repositories.framework);
                }),
              ],
            ),
          ),
        ),
      ));

      expect(find.text(CherrypicksSubsteps.substepTitles[CherrypicksSubstep.applyCherrypicks]!), findsOneWidget);
      expect(find.textContaining('Navigate to the framework checkout'), findsOneWidget);
      expect(find.textContaining('${fakeConductor.rootDirectory.path}/flutter_conductor_checkouts/framework'),
          findsOneWidget);
      expect(find.textContaining('apply the following framework cherrypicks'), findsOneWidget);
      expect(find.textContaining('git cherry-pick $kFrameworkCherrypick'), findsOneWidget);

      expect(find.textContaining('See more information'), findsOneWidget);
      expect(find.text(kReleaseDocumentationUrl), findsOneWidget);
    });
  });
}
