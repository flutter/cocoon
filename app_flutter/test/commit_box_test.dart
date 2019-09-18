// Copyright (c) 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app_flutter/commit_box.dart';

void main() {
  group('CommitBox', () {
    const String message = 'message message';
    const String avatarUrl =
        'https://avatars2.githubusercontent.com/u/2148558?v=4';
    const String author = 'contributor';

    testWidgets('shows information correctly', (WidgetTester tester) async {
      await tester.pumpWidget(Directionality(
        child: CommitBox(
          message: message,
          avatarUrl: avatarUrl,
          author: author,
        ),
        textDirection: TextDirection.ltr,
      ));

      expect(find.byType(Image), findsOneWidget);

      // Image.Network throws a 400 exception in tests
      tester.takeException();
    });

    testWidgets('shows overlay on click', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: CommitBox(
          message: message,
          avatarUrl: avatarUrl,
          author: author,
        ),
      ));

      expect(find.text(message), findsNothing);
      expect(find.text(author), findsNothing);

      await tester.tap(find.byType(CommitBox));
      await tester.pump();

      expect(find.text(message), findsOneWidget);
      expect(find.text(author), findsOneWidget);

      // Image.Network throws a 400 exception in tests
      tester.takeException();
    });

    testWidgets('closes overlay on click out', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: CommitBox(
          message: message,
          avatarUrl: avatarUrl,
          author: author,
        ),
      ));

      // Open the overlay
      await tester.tap(find.byType(CommitBox));
      await tester.pump();

      // Since the overlay positions itself in the middle of the widget,
      // it is safe to click the widget to close it again
      await tester.tap(find.byType(CommitBox));
      await tester.pump();

      expect(find.text(message), findsNothing);

      // Image.Network throws a 400 exception in tests
      tester.takeException();
    });
  });
}
