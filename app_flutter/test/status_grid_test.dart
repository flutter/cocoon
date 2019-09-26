// Copyright (c) 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cocoon_service/protos.dart' show CommitStatus;

import 'package:app_flutter/service/fake_cocoon.dart';
import 'package:app_flutter/status_grid.dart';

void main() {
  group('StatusGrid', () {
    List<CommitStatus> statuses;

    setUpAll(() async {
      final FakeCocoonService service = FakeCocoonService();
      statuses = await service.fetchCommitStatuses();
    });

    testWidgets('shows loading indicator when statuses is empty',
        (WidgetTester tester) async {
      await tester.pumpWidget(Column(
        children: [
          StatusGrid(
            statuses: <CommitStatus>[],
          ),
        ],
      ));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byType(GridView), findsNothing);

      tester.takeException();
    });

    testWidgets('has correct width', (WidgetTester tester) async {
      await tester.pumpWidget(Column(
        children: [
          StatusGrid(
            statuses: statuses,
          ),
        ],
      ));

      // expect(find.byType(GridView).evaluate()., 200);
    });

    testWidgets('has correct height', (WidgetTester tester) async {
            await tester.pumpWidget(Column(
        children: [
          StatusGrid(
            statuses: <CommitStatus>[],
          ),
        ],
      ));

      GridView grid = find.byType(GridView).evaluate().first.widget;

      // height should be 50.0 * statuses.length
    });

    testWidgets('commits only show in left most column',
        (WidgetTester tester) async {
      await tester.pumpWidget(Column(
        children: [
          StatusGrid(
            statuses: <CommitStatus>[],
          ),
        ],
      ));

      GridView grid = find.byType(GridView).evaluate().first.widget;
    });
  });
}
