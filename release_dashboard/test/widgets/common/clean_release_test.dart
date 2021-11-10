// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:conductor_ui/widgets/clean_release.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../src/services/fake_conductor.dart';

void main() {
  group('Clean release UI tests', () {
    testWidgets('AlertDialog Appears', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: CleanRelease(conductor: FakeConductor()),
        ),
      ));

      expect(find.byType(CleanRelease), findsOneWidget);
      expect(find.byType(AlertDialog), findsNothing);
      await tester.tap(find.byType(CleanRelease));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);
    });

    testWidgets('SnackBar Appears', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: CleanRelease(conductor: FakeConductor()),
        ),
      ));

      await tester.tap(find.byType(CleanRelease));
      await tester.pumpAndSettle();
      expect(find.byType(SnackBar), findsNothing);
      await tester.tap(find.text('Yes'));
      await tester.pumpAndSettle();
      expect(find.byType(SnackBar), findsOneWidget);
    });
  });
}
