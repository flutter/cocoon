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
  group('GitHub status widget', () {
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

  group('Build status widget', () {
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

  group('Failing agents widget', () {
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

  group('Post-commit test widget', () {
    testWidgets('None', (WidgetTester tester) async {
      const BuildStatus buildStatus = BuildStatus();
      await _pumpCommitResultsWidget(tester, buildStatus);

      final Finder titleFinder = find.byType(ListTile);
      expect(titleFinder, findsNothing);
    });

    testWidgets('Commit results', (WidgetTester tester) async {
      BuildStatus buildStatus = BuildStatus(commitTestResults: <CommitTestResult>[
        CommitTestResult(
          sha: '123456789',
          avatarImageURL: 'https://www.google.com',
          createDateTime: DateTime(2019, 1, 1, 13, 10),
          inProgressTestCount: 10,
          succeededTestCount: 20,
          failedFlakyTestCount: 30,
          failedTestCount: 40,
          failingTests: <String>['test1', 'test2', 'test3']
        ),
        CommitTestResult(
          sha: '5678',
          avatarImageURL: 'https://about.google',
          createDateTime: DateTime(2019, 1, 1, 5, 20),
          inProgressTestCount: 50,
          succeededTestCount: 60,
          failedFlakyTestCount: 70,
          failedTestCount: 0
        ),
        CommitTestResult(
          sha: '987654321',
          avatarImageURL: 'https://store.google.com',
          createDateTime: DateTime(2019, 1, 1, 11, 59),
          inProgressTestCount: 0,
          succeededTestCount: 80,
          failedFlakyTestCount: 90,
          failedTestCount: 0
        ),
      ]);

      await _pumpCommitResultsWidget(tester, buildStatus);

      final Finder listTileFinder = find.byWidgetPredicate((Widget widget) => widget is ListTile);
      expect(listTileFinder, findsNWidgets(3));

      ListTile firstResult = tester.widget<ListTile>(listTileFinder.first);
      expect((firstResult.title as Text).data, '[123456] 1:10 PM');

      // First commit
      final CircleAvatar firstLeading = firstResult.leading;
      expect((firstLeading.child as Icon).icon, Icons.error);

      final CircleAvatar firstTrailing = firstResult.trailing;
      final Image firstImage = firstTrailing.child;
      final NetworkImage firstNetworkImage = firstImage.image;
      expect(firstNetworkImage.url, 'https://www.google.com');

      // Second commit
      final ListTile secondResult = tester.widget<ListTile>(listTileFinder.at(1));
      expect((secondResult.title as Text).data, '[5678] 5:20 AM');

      final CircleAvatar secondTrailing = secondResult.trailing;
      final Image secondImage = secondTrailing.child;
      final NetworkImage secondNetworkImage = secondImage.image;
      expect(secondNetworkImage.url, 'https://about.google');

      // Third commit
      final ListTile thirdResult = tester.widget<ListTile>(listTileFinder.at(2));
      expect((thirdResult.title as Text).data, '[987654] 11:59 AM');

      final CircleAvatar thirdLeading = thirdResult.leading;
      expect((thirdLeading.child as Icon).icon, Icons.check);

      final CircleAvatar thirdTrailing = thirdResult.trailing;
      final Image thirdImage = thirdTrailing.child;
      final NetworkImage thirdNetworkImage = thirdImage.image;
      expect(thirdNetworkImage.url, 'https://store.google.com');
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

Future<void> _pumpCommitResultsWidget(WidgetTester tester, BuildStatus status) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: ModelBinding<BuildStatus>(
          initialModel: status,
          child: const CommitResultsWidget()
        )
      )
    )
  );
}