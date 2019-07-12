// Copyright (c) 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_web_test/flutter_web_test.dart';
import 'package:flutter_web/material.dart';

import 'package:cocoon/repository/details/infrastructure.dart';
import 'package:cocoon/repository/models/build_status.dart';
import 'package:cocoon/repository/models/github_status.dart';
import 'package:cocoon/repository/models/providers.dart';

void main() {
  group('GitHub status', () {
    testWidgets('Operational', (WidgetTester tester) async {
      const String gitHubStatusText = 'Status provided by GitHub'; // Status text is provided by GitHub, so there's no logic needed in the dashboard to handle different variants.
      const GithubStatus githubStatus = GithubStatus(status: gitHubStatusText, indicator: 'none');
      await _pumpGitHubStatusWidget(tester, githubStatus);

      final Finder statusFinder = find.text(gitHubStatusText);
      expect(statusFinder, findsOneWidget);

      final Finder iconFinder = find.byIcon(Icons.check);
      expect(iconFinder, findsOneWidget);
    });

    testWidgets('Minor', (WidgetTester tester) async {
      const GithubStatus githubStatus = GithubStatus(status: 'Failure', indicator: 'minor');
      await _pumpGitHubStatusWidget(tester, githubStatus);
      final Finder iconFinder = find.byIcon(Icons.warning);
      expect(iconFinder, findsOneWidget);
    });

    testWidgets('Major', (WidgetTester tester) async {
      const GithubStatus githubStatus = GithubStatus(status: 'Failure', indicator: 'major');
      await _pumpGitHubStatusWidget(tester, githubStatus);
      final Finder iconFinder = find.byIcon(Icons.error);
      expect(iconFinder, findsOneWidget);
    });

    testWidgets('Critical', (WidgetTester tester) async {
      const GithubStatus githubStatus = GithubStatus(status: 'Failure', indicator: 'critical');
      await _pumpGitHubStatusWidget(tester, githubStatus);
      final Finder iconFinder = find.byIcon(Icons.error);
      expect(iconFinder, findsOneWidget);
    });

    testWidgets('Bogus', (WidgetTester tester) async {
      const GithubStatus githubStatus = GithubStatus(indicator: 'bogus unknown indicator');
      await _pumpGitHubStatusWidget(tester, githubStatus);
      final Finder iconFinder = find.byIcon(Icons.help_outline);
      expect(iconFinder, findsOneWidget);
    });

    testWidgets('Unknown', (WidgetTester tester) async {
      const GithubStatus githubStatus = GithubStatus();
      await _pumpGitHubStatusWidget(tester, githubStatus);

      final Finder iconFinder = find.byIcon(Icons.help_outline);
      expect(iconFinder, findsOneWidget);

      final Finder statusFinder = find.text('Unknown');
      expect(statusFinder, findsOneWidget);
    });
  });

  group('Build status', () {
    testWidgets('Succeeded', (WidgetTester tester) async {
      const BuildStatus buildStatus = BuildStatus(anticipatedBuildStatus: 'Succeeded');
      await _pumpBuildStatusWidget(tester, buildStatus);

      final Finder iconFinder = find.byIcon(Icons.check);
      expect(iconFinder, findsOneWidget);
    });

    testWidgets('Will fail', (WidgetTester tester) async {
      const BuildStatus buildStatus = BuildStatus(anticipatedBuildStatus: 'Build Will Fail');
      await _pumpBuildStatusWidget(tester, buildStatus);

      final Finder iconFinder = find.byIcon(Icons.error);
      expect(iconFinder, findsOneWidget);
    });

    testWidgets('Bogus', (WidgetTester tester) async {
      const BuildStatus buildStatus = BuildStatus(anticipatedBuildStatus: 'Bogus unknown status');
      await _pumpBuildStatusWidget(tester, buildStatus);

      final Finder iconFinder = find.byIcon(Icons.help_outline);
      expect(iconFinder, findsOneWidget);
    });

    testWidgets('Unknown', (WidgetTester tester) async {
      const BuildStatus buildStatus = BuildStatus();
      await _pumpBuildStatusWidget(tester, buildStatus);

      final Finder iconFinder = find.byIcon(Icons.help_outline);
      expect(iconFinder, findsOneWidget);
    });
  });

  group('Failing agents', () {
    testWidgets('None', (WidgetTester tester) async {
      const BuildStatus buildStatus = BuildStatus();
      await _pumpFailingAgentsWidget(tester, buildStatus);

      final Finder titleFinder = find.text('Failing Agents');
      expect(titleFinder, findsNothing);
    });

    testWidgets('One', (WidgetTester tester) async {
      const BuildStatus buildStatus = BuildStatus(failingAgents: <String>['mac1']);
      await _pumpFailingAgentsWidget(tester, buildStatus);

      final Finder titleFinder = find.text('Failing Agents');
      expect(titleFinder, findsOneWidget);

      final Finder iconFinder = find.byIcon(Icons.desktop_windows);
      expect(iconFinder, findsOneWidget);

      final Finder agentFinder = find.text('mac1');
      expect(agentFinder, findsOneWidget);
    });

    testWidgets('Two', (WidgetTester tester) async {
      const BuildStatus buildStatus = BuildStatus(failingAgents: <String>['mac1', 'windows1']);
      await _pumpFailingAgentsWidget(tester, buildStatus);

      final Finder titleFinder = find.text('Failing Agents');
      expect(titleFinder, findsOneWidget);

      final Finder iconFinder = find.byIcon(Icons.desktop_windows);
      expect(iconFinder, findsNWidgets(2));

      final Finder agentFinder1 = find.text('mac1');
      expect(agentFinder1, findsOneWidget);

      final Finder agentFinder2 = find.text('windows1');
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
