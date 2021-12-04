// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:conductor_core/proto.dart' as pb;
import 'package:conductor_ui/main.dart';
import 'package:conductor_ui/widgets/common/url_button.dart';
import 'package:conductor_ui/widgets/conductor_status.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/services/fake_conductor.dart';
import '../src/test_state_generator.dart';

void main() {
  group('conductor_status with statusState provider', () {
    late pb.ConductorState state;

    setUp(() {
      state = generateConductorState();
    });
    testWidgets('Conductor_status displays nothing found when there is no state file', (WidgetTester tester) async {
      await tester.pumpWidget(MyApp(
        FakeConductor(),
      ));

      expect(find.text('No persistent state file. Try starting a release.'), findsOneWidget);
      expect(find.text('Conductor version:'), findsNothing);
    });

    testWidgets('Conductor_status displays correct header elements', (WidgetTester tester) async {
      await tester.pumpWidget(MyApp(FakeConductor(testState: state)));

      expect(find.text('No persistent state file. Try starting a release.'), findsNothing);
      for (MapEntry headerElement in ConductorStatus.headerElements.entries) {
        expect(find.text('${headerElement.value}:'), findsOneWidget);
      }
      expect(find.text(kConductorVersion), findsOneWidget);
      expect(find.text(kReleaseChannel), findsOneWidget);
      expect(find.text(kReleaseVersion), findsOneWidget);
      expect(find.text('Release Started at:'), findsOneWidget);
      expect(find.text('Release Updated at:'), findsOneWidget);
      expect(find.text(kDartRevision), findsOneWidget);
      expect(find.text(kEngineCherrypick1), findsOneWidget);
      expect(find.text(kEngineCherrypick2), findsOneWidget);
      expect(find.text(kEngineCherrypick3), findsOneWidget);
      expect(find.text(kFrameworkCherrypick), findsOneWidget);
    });

    testWidgets('Conductor_status displays correct status with a null state file except a releaseChannel',
        (WidgetTester tester) async {
      final pb.ConductorState stateIncomplete = generateConductorState();
      stateIncomplete.engine.startingGitHead = '';
      stateIncomplete.engine.currentGitHead = '';
      stateIncomplete.engine.checkoutPath = '';
      stateIncomplete.framework.startingGitHead = '';
      stateIncomplete.framework.currentGitHead = '';
      stateIncomplete.framework.checkoutPath = '';

      await tester.pumpWidget(MyApp(FakeConductor(testState: stateIncomplete)));

      expect(find.text('No persistent state file. Try starting a release.'), findsNothing);
      for (MapEntry headerElement in ConductorStatus.headerElements.entries) {
        expect(find.text('${headerElement.value}:'), findsOneWidget);
      }
      expect(find.text(kReleaseChannel), findsNWidgets(1));
      expect(find.text('Unknown'), findsNWidgets(6));
    });

    testWidgets('Engine Repo Info section displays correctly in a dropdown fashion', (WidgetTester tester) async {
      await tester.pumpWidget(MyApp(FakeConductor(testState: state)));

      expect(find.text('No persistent state file. Try starting a release.'), findsNothing);
      for (final String repoElement in ConductorStatus.engineRepoElements.values) {
        expect(find.text('$repoElement:'), findsOneWidget);
      }

      expect(find.text(kEngineCandidateBranch), findsOneWidget);
      expect(find.text(kEngineStartingGitHead), findsOneWidget);
      expect(find.text(kEngineCurrentGitHead), findsOneWidget);
      expect(find.text(kEngineCheckoutPath), findsOneWidget);
      expect(find.text(kEngineLUCIDashboard), findsOneWidget);

      expect(tester.widget<ExpansionPanelList>(find.byType(ExpansionPanelList).first).children[0].isExpanded,
          equals(false));
      await tester.tap(find.byKey(const Key('engineRepoInfoDropdown')));
      await tester.pumpAndSettle();
      expect(tester.widget<ExpansionPanelList>(find.byType(ExpansionPanelList).first).children[0].isExpanded,
          equals(true));
    });

    testWidgets('Framework Repo Info section displays correctly in a dropdown fashion', (WidgetTester tester) async {
      await tester.pumpWidget(MyApp(FakeConductor(testState: state)));

      expect(find.text('No persistent state file. Try starting a release.'), findsNothing);
      for (final String repoElement in ConductorStatus.frameworkRepoElements.values) {
        expect(find.text('$repoElement:'), findsOneWidget);
      }

      expect(find.text(kFrameworkCandidateBranch), findsOneWidget);
      expect(find.text(kFrameworkStartingGitHead), findsOneWidget);
      expect(find.text(kFrameworkCurrentGitHead), findsOneWidget);
      expect(find.text(kFrameworkCheckoutPath), findsOneWidget);
      expect(find.text(kFrameworkLUCIDashboard), findsOneWidget);

      expect(tester.widget<ExpansionPanelList>(find.byType(ExpansionPanelList).at(1)).children[0].isExpanded,
          equals(false));
      await tester.tap(find.byKey(const Key('frameworkRepoInfoDropdown')));
      await tester.pumpAndSettle();
      expect(tester.widget<ExpansionPanelList>(find.byType(ExpansionPanelList).at(1)).children[0].isExpanded,
          equals(true));
    });

    testWidgets('Repo Info section displays UrlButton', (WidgetTester tester) async {
      await tester.pumpWidget(MyApp(FakeConductor(testState: state)));

      expect(find.byType(UrlButton), findsNWidgets(4));
    });
  });
}
