// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app_flutter/widgets/commit_author_avatar.dart';
import 'package:cocoon_service/protos.dart' show Commit;

void main() {
  group('Author avatars meet guidelines for theme brightness', () {
    Widget buildAuthors() {
      final List<String> names = <String>[];
      final List<CommitAuthorAvatar> avatars = <CommitAuthorAvatar>[];

      for (int i = 65; i <= 90; i++) {
        names.add(String.fromCharCode(i));
      }
      for (int i = 0; i <= 9; i++) {
        names.add(i.toString());
      }

      for (final String name in names) {
        avatars.add(CommitAuthorAvatar(commit: Commit()..author = name));
      }

      return Scaffold(
        body: Column(mainAxisAlignment: MainAxisAlignment.center, children: <Widget>[
          Wrap(children: avatars),
        ]),
      );
    }

    testWidgets('dark theme', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(theme: ThemeData.dark(), home: buildAuthors()));
      await expectLater(tester, meetsGuideline(textContrastGuideline));
    });

    testWidgets('light theme', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(home: buildAuthors()));
      await expectLater(tester, meetsGuideline(textContrastGuideline));
    });
  });
}
