// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:conductor_core/proto.dart' as pb;
import 'package:conductor_ui/main.dart';
import 'package:conductor_ui/widgets/common/url_button.dart';
import 'package:conductor_ui/widgets/conductor_status.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../src/services/fake_conductor.dart';
import '../src/test_state_generator.dart';

void main() {
  group('conductor_status, also tests StatusState', () {
    late pb.ConductorState state;

    setUp(() {
      state = getTestState();
    });
    testWidgets('Conductor_status displays nothing found when there is no state file', (WidgetTester tester) async {
      await tester.pumpWidget(MyApp(
        FakeConductor(),
      ));

      expect(find.text('No persistent state file. Try starting a release.'), findsOneWidget);
      expect(find.text('Conductor version:'), findsNothing);
    });

    testWidgets('Conductor_status displays correct status with a state file', (WidgetTester tester) async {
      await tester.pumpWidget(MyApp(FakeConductor(testState: state)));

      expect(find.text('No persistent state file. Try starting a release.'), findsNothing);
      for (final String headerElement in ConductorStatus.headerElements) {
        expect(find.text('$headerElement:'), findsOneWidget);
      }
      expect(find.text(conductorVersion), findsOneWidget);
      expect(find.text(releaseChannel), findsOneWidget);
      expect(find.text(releaseVersion), findsOneWidget);
      expect(find.text('Release Started at:'), findsOneWidget);
      expect(find.text('Release Updated at:'), findsOneWidget);
      expect(find.text(dartRevision), findsOneWidget);
      expect(find.text(engineCherrypick1), findsOneWidget);
      expect(find.text(engineCherrypick2), findsOneWidget);
      expect(find.text(engineCherrypick3), findsOneWidget);
      expect(find.text(frameworkCherrypick), findsOneWidget);
    });

    testWidgets('Conductor_status displays correct status with a null state file except a releaseChannel',
        (WidgetTester tester) async {
      final pb.ConductorState stateIncomplete = pb.ConductorState(
        releaseChannel: releaseChannel,
      );

      await tester.pumpWidget(MyApp(FakeConductor(testState: stateIncomplete)));

      expect(find.text('No persistent state file. Try starting a release.'), findsNothing);
      for (final String headerElement in ConductorStatus.headerElements) {
        expect(find.text('$headerElement:'), findsOneWidget);
      }
      expect(find.text(releaseChannel), findsNWidgets(2));
      expect(find.text('Unknown'), findsNWidgets(11));
    });

    testWidgets('Repo Info section displays corresponding info in a dropdown fashion', (WidgetTester tester) async {
      await tester.pumpWidget(MyApp(FakeConductor(testState: state)));

      expect(find.text('No persistent state file. Try starting a release.'), findsNothing);
      for (final String repoElement in ConductorStatus.engineRepoElements.values) {
        expect(find.text('$repoElement:'), findsOneWidget);
      }
      for (final String repoElement in ConductorStatus.frameworkRepoElements.values) {
        expect(find.text('$repoElement:'), findsOneWidget);
      }
      expect(find.text(engineCandidateBranch), findsOneWidget);
      expect(find.text(engineStartingGitHead), findsOneWidget);
      expect(find.text(engineCurrentGitHead), findsOneWidget);
      expect(find.text(engineCheckoutPath), findsOneWidget);
      expect(find.text(engineLUCIDashboard), findsOneWidget);

      expect(find.text(frameworkCandidateBranch), findsOneWidget);
      expect(find.text(frameworkStartingGitHead), findsOneWidget);
      expect(find.text(frameworkCurrentGitHead), findsOneWidget);
      expect(find.text(frameworkCheckoutPath), findsOneWidget);
      expect(find.text(frameworkLUCIDashboard), findsOneWidget);

      expect(tester.widget<ExpansionPanelList>(find.byType(ExpansionPanelList).first).children[0].isExpanded,
          equals(false));
      await tester.tap(find.byKey(const Key('engineRepoInfoDropdown')));
      await tester.pumpAndSettle();
      expect(tester.widget<ExpansionPanelList>(find.byType(ExpansionPanelList).first).children[0].isExpanded,
          equals(true));
    });

    testWidgets('Repo Info section displays UrlButton', (WidgetTester tester) async {
      await tester.pumpWidget(MyApp(FakeConductor(testState: state)));

      expect(find.byType(UrlButton), findsNWidgets(4));
    });
  });
}
