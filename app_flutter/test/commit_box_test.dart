// Copyright (c) 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_service/protos.dart' show Commit;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:test/test.dart' as test show TypeMatcher;

import 'package:app_flutter/commit_box.dart';

void main() {
  group('CommitBox', () {
    final Commit expectedCommit = Commit()
      ..author = 'AuthoryMcAuthor Face'
      ..authorAvatarUrl = 'https://avatars2.githubusercontent.com/u/2148558?v=4'
      ..repository = 'flutter/cocoon'
      ..sha = 'ShaShankRedemption';

    testWidgets('shows information correctly', (WidgetTester tester) async {
      await tester.pumpWidget(Directionality(
        child: CommitBox(
          commit: expectedCommit,
        ),
        textDirection: TextDirection.ltr,
      ));

      // Image.Network throws a 400 exception in tests
      expect(find.byType(Image), findsOneWidget);
      if (!kIsWeb) {
        expect(tester.takeException(),
            const test.TypeMatcher<NetworkImageLoadException>());
      }
    });

    testWidgets('shows overlay on click', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: CommitBox(
          commit: expectedCommit,
        ),
      ));

      final String shortSha = expectedCommit.sha.substring(0, 7);
      expect(find.text(shortSha), findsNothing);
      expect(find.text(expectedCommit.author), findsNothing);

      await tester.tap(find.byType(CommitBox));
      await tester.pump();

      expect(find.text(shortSha), findsOneWidget);
      expect(find.text(expectedCommit.author), findsOneWidget);
    });

    testWidgets('closes overlay on click out', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: CommitBox(
          commit: expectedCommit,
        ),
      ));

      // Open the overlay
      await tester.tap(find.byType(CommitBox));
      await tester.pump();

      // Since the overlay positions itself in the middle of the widget,
      // it is safe to click the widget to close it again
      await tester.tap(find.byType(CommitBox));
      await tester.pump();

      expect(find.text(expectedCommit.sha), findsNothing);
    });

    testWidgets('tapping GitHub button should redirect to GitHub',
        (WidgetTester tester) async {
      // The url_launcher calls get logged in this channel
      const MethodChannel channel =
          MethodChannel('plugins.flutter.io/url_launcher');
      final List<MethodCall> log = <MethodCall>[];
      channel.setMockMethodCallHandler((MethodCall methodCall) async {
        log.add(methodCall);
      });

      await tester.pumpWidget(MaterialApp(
        home: CommitBox(
          commit: expectedCommit,
        ),
      ));

      // Open the overlay
      await tester.tap(find.byType(CommitBox));
      await tester.pump();

      // Tap the redirect button
      await tester.tap(find.text('GitHub'));
      await tester.pump();

      expect(
        log,
        <Matcher>[
          isMethodCall('launch', arguments: <String, Object>{
            'url':
                'https://github.com/${expectedCommit.repository}/commit/${expectedCommit.sha}',
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
  });
}
