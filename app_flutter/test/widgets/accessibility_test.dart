// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app_flutter/widgets/commit_author_avatar.dart';
import 'package:cocoon_service/protos.dart' show Commit;

void main() {
  group('Author avatars meet guidelines for theme brightness', () {
    List<String> generateInitials() {
      final List<String> names = <String>[];

      for (int i = 65; i <= 90; i++) {
        names.add(String.fromCharCode(i));
      }
      for (int i = 0; i <= 9; i++) {
        names.add(i.toString());
      }
      return names;
    }

    const List<String> longNames = <String>[
      'Michael',
      'Thomas',
      'Peter',
      'Volkert'
    ];

    Widget buildAuthors({@required List<String> names, ThemeData theme}) {
      final List<Widget> avatars = names
          .map((String name) => CommitAuthorAvatar(
                commit: Commit()..author = name,
              ))
          .toList();

      return MaterialApp(
        theme: theme ?? ThemeData.light(),
        home: Scaffold(
          body: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Wrap(children: avatars),
            ],
          ),
        ),
      );
    }

    testWidgets('dark theme', (WidgetTester tester) async {
      await tester.pumpWidget(buildAuthors(
        theme: ThemeData.dark(),
        names: generateInitials(),
      ));
      await expectLater(tester, meetsGuideline(textContrastGuideline));
    });

    testWidgets('light theme', (WidgetTester tester) async {
      await tester.pumpWidget(buildAuthors(
        names: generateInitials(),
      ));
      await expectLater(tester, meetsGuideline(textContrastGuideline));
    });

    testWidgets('long names, dark theme', (WidgetTester tester) async {
      await tester.pumpWidget(buildAuthors(
        theme: ThemeData.dark(),
        names: longNames,
      ));
      await expectLater(tester, meetsGuideline(textContrastGuideline));
    });

    testWidgets('long names, light theme', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildAuthors(names: longNames),
      );
      await expectLater(tester, meetsGuideline(textContrastGuideline));
    });
  });
}
