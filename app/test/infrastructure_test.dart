// Copyright (c) 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_web_test/flutter_web_test.dart';
import 'package:flutter_web/material.dart';

import 'package:cocoon/cocoon.dart';

void main() {
  group('GitHub status', () {
    testWidgets('Operational', (WidgetTester tester) async {
      final String gitHubStatusText = 'Status provided by GitHub'; // Status text is provided by GitHub, so there's no logic needed in the dashboard to handle different variants.
      final GithubStatus githubStatus = GithubStatus(status: gitHubStatusText, indicator: 'none');
      await _pumpGitHubStatusWidget(tester, githubStatus);

      final statusFinder = find.text(gitHubStatusText);
      expect(statusFinder, findsOneWidget);

      final iconFinder = find.byIcon(Icons.check);
      expect(iconFinder, findsOneWidget);
    });

    testWidgets('Minor', (WidgetTester tester) async {
      final GithubStatus githubStatus = const GithubStatus(status: 'Failure', indicator: 'minor');
      await _pumpGitHubStatusWidget(tester, githubStatus);
      final iconFinder = find.byIcon(Icons.warning);
      expect(iconFinder, findsOneWidget);
    });

    testWidgets('Major', (WidgetTester tester) async {
      final GithubStatus githubStatus = const GithubStatus(status: 'Failure', indicator: 'major');
      await _pumpGitHubStatusWidget(tester, githubStatus);
      final iconFinder = find.byIcon(Icons.error);
      expect(iconFinder, findsOneWidget);
    });

    testWidgets('Critical', (WidgetTester tester) async {
      final GithubStatus githubStatus = const GithubStatus(status: 'Failure', indicator: 'critical');
      await _pumpGitHubStatusWidget(tester, githubStatus);
      final iconFinder = find.byIcon(Icons.error);
      expect(iconFinder, findsOneWidget);
    });

    testWidgets('Bogus', (WidgetTester tester) async {
      final GithubStatus githubStatus = const GithubStatus(indicator: 'bogus unknown indicator');
      await _pumpGitHubStatusWidget(tester, githubStatus);
      final iconFinder = find.byIcon(Icons.help_outline);
      expect(iconFinder, findsOneWidget);
    });

    testWidgets('Unknown', (WidgetTester tester) async {
      final GithubStatus githubStatus = const GithubStatus();
      await _pumpGitHubStatusWidget(tester, githubStatus);

      final iconFinder = find.byIcon(Icons.help_outline);
      expect(iconFinder, findsOneWidget);

      final statusFinder = find.text('Unknown');
      expect(statusFinder, findsOneWidget);
    });
  });

  group('Build status', () {
    testWidgets('Succeeded', (WidgetTester tester) async {
      final BuildStatus buildStatus = const BuildStatus(anticipatedBuildStatus: 'Succeeded');
      await _pumpBuildStatusWidget(tester, buildStatus);

      final iconFinder = find.byIcon(Icons.check);
      expect(iconFinder, findsOneWidget);
    });

    testWidgets('Will fail', (WidgetTester tester) async {
      final BuildStatus buildStatus = const BuildStatus(anticipatedBuildStatus: 'Build Will Fail');
      await _pumpBuildStatusWidget(tester, buildStatus);

      final iconFinder = find.byIcon(Icons.error);
      expect(iconFinder, findsOneWidget);
    });

    testWidgets('Bogus', (WidgetTester tester) async {
      final BuildStatus buildStatus = const BuildStatus(anticipatedBuildStatus: 'Bogus unknown status');
      await _pumpBuildStatusWidget(tester, buildStatus);

      final iconFinder = find.byIcon(Icons.help_outline);
      expect(iconFinder, findsOneWidget);
    });

    testWidgets('Unknown', (WidgetTester tester) async {
      final BuildStatus buildStatus = const BuildStatus();
      await _pumpBuildStatusWidget(tester, buildStatus);

      final iconFinder = find.byIcon(Icons.help_outline);
      expect(iconFinder, findsOneWidget);
    });
  });

  group('Failing agents', () {
    testWidgets('None', (WidgetTester tester) async {
      final BuildStatus buildStatus = const BuildStatus();
      await _pumpFailingAgentsWidget(tester, buildStatus);

      final titleFinder = find.text('Failing Agents');
      expect(titleFinder, findsNothing);
    });

    testWidgets('One', (WidgetTester tester) async {
      final BuildStatus buildStatus = const BuildStatus(failingAgents: <String>['mac1']);
      await _pumpFailingAgentsWidget(tester, buildStatus);

      final titleFinder = find.text('Failing Agents');
      expect(titleFinder, findsOneWidget);

      final iconFinder = find.byIcon(Icons.desktop_windows);
      expect(iconFinder, findsOneWidget);

      final agentFinder = find.text('mac1');
      expect(agentFinder, findsOneWidget);
    });

    testWidgets('Two', (WidgetTester tester) async {
      final BuildStatus buildStatus = const BuildStatus(failingAgents: <String>['mac1', 'windows1']);
      await _pumpFailingAgentsWidget(tester, buildStatus);

      final titleFinder = find.text('Failing Agents');
      expect(titleFinder, findsOneWidget);

      final iconFinder = find.byIcon(Icons.desktop_windows);
      expect(iconFinder, findsNWidgets(2));

      final agentFinder1 = find.text('mac1');
      expect(agentFinder1, findsOneWidget);

      final agentFinder2 = find.text('windows1');
      expect(agentFinder2, findsOneWidget);
    });
  });
}

Future<void> _pumpGitHubStatusWidget(WidgetTester tester, GithubStatus status) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: ModelBinding<GithubStatus>(
          initialModel: status,
          child: const GitHubStatusWidget()
        )
      )
    )
  );
}

Future<void> _pumpBuildStatusWidget(WidgetTester tester, BuildStatus status) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: ModelBinding<BuildStatus>(
          initialModel: status,
          child: const BuildStatusWidget()
        )
      )
    )
  );
}

Future<void> _pumpFailingAgentsWidget(WidgetTester tester, BuildStatus status) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: ModelBinding<BuildStatus>(
          initialModel: status,
          child: const FailingAgentWidget()
        )
      )
    )
  );
}
