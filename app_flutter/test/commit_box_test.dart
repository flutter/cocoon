// Copyright (c) 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app_flutter/commit_box.dart';

void main() {
  testWidgets('CommitBox shows the correct information',
      (WidgetTester tester) async {
    const String author = 'tester';
    const String message = 'message';
    const String hash = 'hashy hash';
    const String avatarUrl =
        'https://avatars2.githubusercontent.com/u/42042535?v=4';

    await tester.pumpWidget(MaterialApp(
        home: CommitBox(
            author: author,
            message: message,
            avatarUrl: avatarUrl,
            hash: hash)));

    expect(find.text(message), findsOneWidget);
  });
}
