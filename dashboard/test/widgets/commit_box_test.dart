// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dashboard/model/commit.pb.dart';
import 'package:flutter_dashboard/widgets/commit_box.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

import '../utils/fake_url_launcher.dart';
import '../utils/golden.dart';

void main() {
  final Commit expectedCommit = Commit()
    ..author = 'AuthoryMcAuthor Face'
    ..authorAvatarUrl = 'https://avatars2.githubusercontent.com/u/2148558?v=4'
    ..message = 'commit message\n\nreview comments'
    ..repository = 'flutter/cocoon'
    ..sha = 'ShaShankRedemption';
  final String shortSha = expectedCommit.sha.substring(0, 7);
  final Widget basicApp = MaterialApp(
    home: Material(
      child: Center(
        child: SizedBox(
          height: 100.0,
          width: 100.0,
          child: CommitBox(
            commit: expectedCommit,
          ),
        ),
      ),
    ),
  );

  testWidgets('CommitBox shows information correctly', (WidgetTester tester) async {
    await tester.pumpWidget(basicApp);
    await expectGoldenMatches(find.byType(Overlay), 'commit_box_test.idle.png');
  });

  testWidgets('CommitBox shows overlay on click', (WidgetTester tester) async {
    await tester.pumpWidget(basicApp);

    expect(find.text(shortSha), findsNothing);
    expect(find.text(expectedCommit.author), findsNothing);

    await tester.tap(find.byType(CommitBox));
    await tester.pump();

    expect(find.text(shortSha), findsOneWidget);
    expect(find.text(expectedCommit.author), findsOneWidget);

    await expectGoldenMatches(find.byType(Overlay), 'commit_box_test.open.png');
  });

  testWidgets('CommitBox overlay shows first line of commit message', (WidgetTester tester) async {
    await tester.pumpWidget(basicApp);
    await tester.tap(find.byType(CommitBox));
    await tester.pump();

    expect(find.text(expectedCommit.message), findsNothing);
    expect(find.text('commit message'), findsOneWidget);
  });

  testWidgets('CommitBox closes overlay on click out', (WidgetTester tester) async {
    await tester.pumpWidget(basicApp);

    // Open the overlay
    await tester.tap(find.byType(CommitBox));
    await tester.pump();
    expect(find.text(shortSha), findsOneWidget);

    // Since the overlay positions itself a little below the center of the widget,
    // it is safe to click the center of the widget to close it again.
    await tester.tap(find.byType(CommitBox));
    await tester.pump();

    expect(find.text(shortSha), findsNothing);
  });

  testWidgets('tapping sha in CommitBox redirects to GitHub', (WidgetTester tester) async {
    final FakeUrlLauncher urlLauncher = FakeUrlLauncher();
    UrlLauncherPlatform.instance = urlLauncher;

    await tester.pumpWidget(basicApp);

    // Open the overlay
    await tester.tap(find.byType(CommitBox));
    await tester.pump();

    // Tap the redirect button
    await tester.tap(find.byType(Hyperlink));
    await tester.pump();

    expect(urlLauncher.launches, isNotEmpty);
    expect(urlLauncher.launches.single, 'https://github.com/${expectedCommit.repository}/commit/${expectedCommit.sha}');
  });

  testWidgets('clicking copy icon in CommitBox adds sha to clipboard', (WidgetTester tester) async {
    final List<MethodCall> log = <MethodCall>[];
    SystemChannels.platform.setMockMethodCallHandler((MethodCall methodCall) async {
      log.add(methodCall);
    });

    await tester.pumpWidget(basicApp);

    // Open the overlay
    await tester.tap(find.byType(CommitBox));
    await tester.pump();

    // Tap the copy button
    await tester.tap(find.byIcon(Icons.copy));
    await tester.pump();

    expect((log.last.arguments as Object) as Map<String, dynamic>, <String, String>{
      'text': expectedCommit.sha,
    });
  });
}
