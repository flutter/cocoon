// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cocoon_service/protos.dart' show Commit;

import 'package:app_flutter/widgets/commit_author_avatar.dart';

void main() {
  testWidgets('Authors with same initial have differently coloured avatars', (WidgetTester tester) async {
    final Commit commit1 = Commit()..author = 'Mike';
    final Commit commit2 = Commit()..author = 'Michael';

    await tester.pumpWidget(
      MaterialApp(
        home: Column(
          children: <Widget>[
            CommitAuthorAvatar(
              commit: commit1,
            ),
            CommitAuthorAvatar(
              commit: commit2,
            ),
          ],
        ),
      ),
    );

    expect(find.text('M'), findsNWidgets(2));
    final List<CircleAvatar> avatars = tester.widgetList<CircleAvatar>(find.byType(CircleAvatar)).toList();
    expect(avatars, hasLength(2));
    expect(avatars.first.backgroundColor, isNot(avatars.last.backgroundColor));
  });
}
