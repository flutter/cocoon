// Copyright (c) 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_service/protos.dart' show Commit;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:test/test.dart' as test show TypeMatcher;

import 'package:app_flutter/commit_box.dart';

void main() {
  group('CommitBox', () {
    Commit expectedCommit = Commit()
      ..author = 'AuthoryMcAuthor Face'
      ..authorAvatarUrl = 'https://avatars2.githubusercontent.com/u/2148558?v=4'
      ..repository = 'flutter/cocoon'
      ..sha = 'sha shank redemption';

    testWidgets('shows information correctly', (WidgetTester tester) async {
      await tester.pumpWidget(Directionality(
        child: CommitBox(
          commit: expectedCommit,
        ),
        textDirection: TextDirection.ltr,
      ));

      expect(find.byType(Image), findsOneWidget);

      // Image.Network throws a 400 exception in tests
      expect(tester.takeException(),
          test.TypeMatcher<NetworkImageLoadException>());
    });

    testWidgets('shows overlay on click', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: CommitBox(
          commit: expectedCommit,
        ),
      ));

      expect(find.text(expectedCommit.sha), findsNothing);
      expect(find.text(expectedCommit.author), findsNothing);

      await tester.tap(find.byType(CommitBox));
      await tester.pump();

      expect(find.text(expectedCommit.sha), findsOneWidget);
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
  });
}
