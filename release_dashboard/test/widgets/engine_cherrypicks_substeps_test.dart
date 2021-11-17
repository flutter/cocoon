// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:conductor_core/proto.dart' as pb;
import 'package:conductor_ui/state/status_state.dart';
import 'package:conductor_ui/widgets/common/url_button.dart';
import 'package:conductor_ui/widgets/engine_cherrypicks_substeps.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import '../src/services/fake_conductor.dart';
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
                  return EngineCherrypicksSubsteps(nextStep: () {});
                }),
              ],
            ),
          ),
        ),
      ));

      expect(find.byKey(const Key('applyEngineCherrypicksContinue')), findsNothing);
      for (final String substep in EngineCherrypicksSubsteps.substepTitles.values) {
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
                  return EngineCherrypicksSubsteps(nextStep: nextStep);
                }),
              ],
            ),
          ),
        ),
      ));

      for (final String substep in EngineCherrypicksSubsteps.substepTitles.values) {
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
      stateWithoutConflicts = getTestState();
    });

    testWidgets("'Verify release number' substep displays correctly", (WidgetTester tester) async {
      await tester.pumpWidget(ChangeNotifierProvider(
        create: (context) => StatusState(conductor: FakeConductor(testState: stateWithoutConflicts)),
        child: MaterialApp(
          home: Material(
            child: Column(
              children: <Widget>[
                Builder(builder: (context) {
                  return EngineCherrypicksSubsteps(nextStep: () {});
                }),
              ],
            ),
          ),
        ),
      ));

      expect(
          find.text(EngineCherrypicksSubsteps.substepTitles[EngineCherrypicksSubstep.verifyRelease]!), findsOneWidget);
      expect(find.textContaining(releaseVersion), findsOneWidget);
      expect(find.byType(UrlButton), findsOneWidget);
      expect(find.text(EngineCherrypicksSubsteps.releaseSDKURL), findsOneWidget);
    });

    testWidgets("'Apply cherrypicks' substep displays correctly", (WidgetTester tester) async {
      await tester.pumpWidget(ChangeNotifierProvider(
        create: (context) => StatusState(conductor: FakeConductor(testState: stateWithoutConflicts)),
        child: MaterialApp(
          home: Material(
            child: Column(
              children: <Widget>[
                Builder(builder: (context) {
                  return EngineCherrypicksSubsteps(nextStep: () {});
                }),
              ],
            ),
          ),
        ),
      ));

      expect(find.text(EngineCherrypicksSubsteps.substepTitles[EngineCherrypicksSubstep.applyCherrypicks]!),
          findsOneWidget);
      expect(find.textContaining('No cherrypick conflicts'), findsOneWidget);
    });
  });

  group('With cherrypick conflicts', () {
    late pb.ConductorState stateWithConflicts;

    setUp(() {
      stateWithConflicts = getTestState(engineCherrypicksInConflict: true);
    });

    testWidgets("'Verify release number' substep displays correctly'", (WidgetTester tester) async {
      await tester.pumpWidget(ChangeNotifierProvider(
        create: (context) => StatusState(conductor: FakeConductor(testState: stateWithConflicts)),
        child: MaterialApp(
          home: Material(
            child: Column(
              children: <Widget>[
                Builder(builder: (context) {
                  return EngineCherrypicksSubsteps(nextStep: () {});
                }),
              ],
            ),
          ),
        ),
      ));

      expect(
          find.text(EngineCherrypicksSubsteps.substepTitles[EngineCherrypicksSubstep.verifyRelease]!), findsOneWidget);
      expect(find.textContaining(releaseVersion), findsOneWidget);
      expect(find.text(EngineCherrypicksSubsteps.releaseSDKURL), findsOneWidget);
      expect(find.byType(UrlButton), findsNWidgets(3));
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
                  return EngineCherrypicksSubsteps(nextStep: () {});
                }),
              ],
            ),
          ),
        ),
      ));

      expect(find.text(EngineCherrypicksSubsteps.substepTitles[EngineCherrypicksSubstep.applyCherrypicks]!),
          findsOneWidget);
      expect(find.textContaining('You must manually apply the following engine cherrypicks that are in conflict'),
          findsOneWidget);
      expect(find.textContaining(engineCherrypick1), findsOneWidget);
      expect(find.textContaining(engineCherrypick2), findsOneWidget);
      expect(find.textContaining('to the engine checkout at the following location and resolve any conflicts:'),
          findsOneWidget);
      expect(find.textContaining(fakeConductor.rootDirectory.path), findsOneWidget);
      expect(find.textContaining('See more information'), findsOneWidget);
      expect(find.text(EngineCherrypicksSubsteps.cherrypickHelpURL), findsOneWidget);
    });
  });
}
