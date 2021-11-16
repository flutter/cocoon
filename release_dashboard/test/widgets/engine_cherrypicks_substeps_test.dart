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

void main() {
  const String conductorVersion = 'v1.0';
  const String releaseChannel = 'beta';
  const String releaseVersion = '1.2.0-3.4.pre';
  const String engineCandidateBranch = 'flutter-1.2-candidate.3';
  const String frameworkCandidateBranch = 'flutter-1.2-candidate.4';
  const String workingBranch = 'cherrypicks-$engineCandidateBranch';
  const String dartRevision = 'fe9708ab688dcda9923f584ba370a66fcbc3811f';
  const String engineCherrypick1 = 'a5a25cd702b062c24b2c67b8d30b5cb33e0ef6f0';
  const String engineCherrypick2 = '94d06a2e1d01a3b0c693b94d70c5e1df9d78d249';
  const String frameworkCherrypick = '768cd702b691584b2c67b8d30b5cb33e0ef6f0';
  const String engineStartingGitHead = '083049e6cae311910c6a6619a6681b7eba4035b4';
  const String engineCurrentGitHead = '23otn2o3itn2o3int2oi3tno23itno2i3tn';
  const String engineCheckoutPath = '/Users/engine';
  const String frameworkStartingGitHead = 'df6981e98rh49er8h149er8h19er8h1';
  const String frameworkCurrentGitHead = '239tnint023t09j2039tj0239tn';
  const String frameworkCheckoutPath = '/Users/framework';
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
      stateWithoutConflicts = pb.ConductorState(
        engine: pb.Repository(
          candidateBranch: engineCandidateBranch,
          cherrypicks: <pb.Cherrypick>[
            pb.Cherrypick(trunkRevision: engineCherrypick1),
            pb.Cherrypick(trunkRevision: engineCherrypick2),
          ],
          dartRevision: dartRevision,
          workingBranch: workingBranch,
          startingGitHead: engineStartingGitHead,
          currentGitHead: engineCurrentGitHead,
          checkoutPath: engineCheckoutPath,
        ),
        framework: pb.Repository(
          candidateBranch: frameworkCandidateBranch,
          cherrypicks: <pb.Cherrypick>[
            pb.Cherrypick(trunkRevision: frameworkCherrypick),
          ],
          workingBranch: workingBranch,
          startingGitHead: frameworkStartingGitHead,
          currentGitHead: frameworkCurrentGitHead,
          checkoutPath: frameworkCheckoutPath,
        ),
        conductorVersion: conductorVersion,
        releaseChannel: releaseChannel,
        releaseVersion: releaseVersion,
      );
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
      stateWithConflicts = pb.ConductorState(
        engine: pb.Repository(
          candidateBranch: engineCandidateBranch,
          cherrypicks: <pb.Cherrypick>[
            // initialize two engine cherrypick hashes with conflict
            pb.Cherrypick(trunkRevision: engineCherrypick1, state: pb.CherrypickState.PENDING_WITH_CONFLICT),
            pb.Cherrypick(trunkRevision: engineCherrypick2, state: pb.CherrypickState.PENDING_WITH_CONFLICT),
          ],
          dartRevision: dartRevision,
          workingBranch: workingBranch,
          startingGitHead: engineStartingGitHead,
          currentGitHead: engineCurrentGitHead,
          checkoutPath: engineCheckoutPath,
        ),
        framework: pb.Repository(
          candidateBranch: frameworkCandidateBranch,
          cherrypicks: <pb.Cherrypick>[
            pb.Cherrypick(trunkRevision: frameworkCherrypick),
          ],
          workingBranch: workingBranch,
          startingGitHead: frameworkStartingGitHead,
          currentGitHead: frameworkCurrentGitHead,
          checkoutPath: frameworkCheckoutPath,
        ),
        conductorVersion: conductorVersion,
        releaseChannel: releaseChannel,
        releaseVersion: releaseVersion,
      );
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
