// Copyright (c) 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cocoon_service/protos.dart' show Commit;

import 'package:app_flutter/widgets/commit_box.dart';

void main() {
  final Commit expectedCommit = Commit()
    ..author = 'AuthoryMcAuthor Face'
    ..authorAvatarUrl = 'https://avatars2.githubusercontent.com/u/2148558?v=4'
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
    await expectLater(find.byType(Overlay), matchesGoldenFile('commit_box_test.idle.png'));
  });

  testWidgets('CommitBox shows overlay on click', (WidgetTester tester) async {
    await tester.pumpWidget(basicApp);

    expect(find.text(shortSha), findsNothing);
    expect(find.text(expectedCommit.author), findsNothing);

    await tester.tap(find.byType(CommitBox));
    await tester.pump();

    expect(find.text(shortSha), findsOneWidget);
    expect(find.text(expectedCommit.author), findsOneWidget);

    await expectLater(find.byType(Overlay), matchesGoldenFile('commit_box_test.open.png'));
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

  testWidgets('tapping GitHub button in CommitBox redirects to GitHub', (WidgetTester tester) async {
    // The url_launcher calls get logged in this channel
    const MethodChannel channel = MethodChannel('plugins.flutter.io/url_launcher');
    final List<MethodCall> log = <MethodCall>[];
    channel.setMockMethodCallHandler((MethodCall methodCall) async {
      log.add(methodCall);
    });

    await tester.pumpWidget(basicApp);

    // Open the overlay
    await tester.tap(find.byType(CommitBox));
    await tester.pump();

    // Tap the redirect button
    await tester.tap(find.text('OPEN GITHUB'));
    await tester.pump();

    expect(
      log,
      <Matcher>[
        isMethodCall('launch', arguments: <String, Object>{
          'url': 'https://github.com/${expectedCommit.repository}/commit/${expectedCommit.sha}',
          'useSafariVC': true,
          'useWebView': false,
          'enableJavaScript': false,
          'enableDomStorage': false,
          'universalLinksOnly': false,
          'headers': <String, String>{}
        })
      ],
    );
  });
}
