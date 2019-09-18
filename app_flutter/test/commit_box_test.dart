// Copyright (c) 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app_flutter/commit_box.dart';

void main() {
  group('CommitBox', () {
    testWidgets('shows information correctly', (WidgetTester tester) async {
      const String message = 'message message';
      const String avatarUrl =
          'https://avatars2.githubusercontent.com/u/2148558?v=4';

      await tester.pumpWidget(Directionality(
        child: CommitBox(
          message: message,
          avatarUrl: avatarUrl,
        ),
        textDirection: TextDirection.ltr,
      ));

      expect(find.byType(Image), findsOneWidget);

      // Image.Network throws a 400 exception in tests
      tester.takeException();
    });
  });
}
