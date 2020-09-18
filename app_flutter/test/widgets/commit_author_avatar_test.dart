// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:core';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/mockito.dart';

import 'package:cocoon_service/protos.dart' show Commit;

import 'package:app_flutter/widgets/commit_author_avatar.dart';

/// Example image data copied from Flutter SDK [Image.memory] tests.
/// https://github.com/flutter/flutter/blob/master/packages/flutter/test/painting/image_data.dart
const List<int> kTransparentImage = <int>[
  0x89,
  0x50,
  0x4E,
  0x47,
  0x0D,
  0x0A,
  0x1A,
  0x0A,
  0x00,
  0x00,
  0x00,
  0x0D,
  0x49,
  0x48,
  0x44,
  0x52,
  0x00,
  0x00,
  0x00,
  0x01,
  0x00,
  0x00,
  0x00,
  0x01,
  0x08,
  0x06,
  0x00,
  0x00,
  0x00,
  0x1F,
  0x15,
  0xC4,
  0x89,
  0x00,
  0x00,
  0x00,
  0x0A,
  0x49,
  0x44,
  0x41,
  0x54,
  0x78,
  0x9C,
  0x63,
  0x00,
  0x01,
  0x00,
  0x00,
  0x05,
  0x00,
  0x01,
  0x0D,
  0x0A,
  0x2D,
  0xB4,
  0x00,
  0x00,
  0x00,
  0x00,
  0x49,
  0x45,
  0x4E,
  0x44,
  0xAE,
];

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

  testWidgets('Show avatar when network request fails', (WidgetTester tester) async {
    final Commit commit = Commit()..author = 'Mike';
    final http.Client mockClient = MockHttpClient();
    when(mockClient.get(any)).thenAnswer((_) async => Future<http.Response>.value(http.Response('123', 404)));

    await tester.pumpWidget(
      MaterialApp(
        home: Column(
          children: <Widget>[
            CommitAuthorAvatar(
              commit: commit,
              client: mockClient,
            ),
          ],
        ),
      ),
    );
    // Ensure builder is finished.
    await tester.pumpAndSettle();

    expect(find.text('M'), findsNWidgets(1));
  });

  testWidgets('Show avatar when network request succeeds', (WidgetTester tester) async {
    final Commit commit = Commit()..author = 'Mike';
    final http.Client mockClient = MockHttpClient();
    when(mockClient.get(any)).thenAnswer(
        (_) async => Future<http.Response>.value(http.Response.bytes(Uint8List.fromList(kTransparentImage), 200)));

    await tester.pumpWidget(
      MaterialApp(
        home: Column(
          children: <Widget>[
            CommitAuthorAvatar(
              commit: commit,
              client: mockClient,
            ),
          ],
        ),
      ),
    );
    // Ensure builder is finished.
    await tester.pumpAndSettle();

    expect(find.text('M'), findsNWidgets(0));
    expect(find.byType(Image), findsNWidgets(1));
  });
}

class MockHttpClient extends Mock implements http.Client {}
