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
      final List<String> names = <String>[
        'a',
        'b',
        'c',
        'd',
        'e',
        'f',
        'g',
        'h',
        'i',
        'j',
        'k',
        'l',
        'm',
        'n',
        'o',
        'p',
        'q',
        'r',
        's',
        't',
        'u',
        'v',
        'w',
        'x',
        'y',
        'z',
        '1',
        '2',
        '3',
        '4',
        '5',
        '6',
        '7',
        '8',
        '9',
        '0',
      ];
      final List<CommitAuthorAvatar> avatars = <CommitAuthorAvatar>[];

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
