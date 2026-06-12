// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_common/rpc_model.dart';
import 'package:cocoon_common/guard_status.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dashboard/widgets/sha_selector.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final summaries = [
    const PresubmitGuardSummary(
      headSha: '1234567890abcdef',
      creationTime: 1718228490000, // Some timestamp
      guardStatus: GuardStatus.waitingForBackfill,
    ),
  ];

  testWidgets('ShaSelector background color matches Scaffold in dark mode', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: Scaffold(
          body: ShaSelector(
            availableShas: summaries,
            selectedSha: '1234567890abcdef',
            onShaSelected: (_) {},
          ),
        ),
      ),
    );

    final containerFinder = find.byType(Container);
    final container = tester.widget<Container>(containerFinder);
    final decoration = container.decoration as BoxDecoration;

    final theme = ThemeData.dark();
    expect(decoration.color, theme.scaffoldBackgroundColor);
  });

  testWidgets('ShaSelector background color matches AppBar in light mode', (
    WidgetTester tester,
  ) async {
    final theme = ThemeData(useMaterial3: false);
    final expectedColor = theme.appBarTheme.backgroundColor ?? theme.primaryColor;

    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: Scaffold(
          body: ShaSelector(
            availableShas: summaries,
            selectedSha: '1234567890abcdef',
            onShaSelected: (_) {},
          ),
        ),
      ),
    );

    final containerFinder = find.byType(Container);
    final container = tester.widget<Container>(containerFinder);
    final decoration = container.decoration as BoxDecoration;

    expect(decoration.color, expectedColor);
  });
}
