// Copyright (c) 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:app_flutter/state/flutter_build.dart';
import 'package:app_flutter/task_box.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cocoon_service/protos.dart' show CommitStatus;

import 'package:app_flutter/service/fake_cocoon.dart';
import 'package:app_flutter/commit_box.dart';
import 'package:app_flutter/status_grid.dart';
import 'package:provider/provider.dart';

void main() {
  group('StatusGrid', () {
    List<CommitStatus> expectedStatuses;

    FlutterBuildState buildState;

    setUp(() async {
      buildState = FlutterBuildState();
      buildState.startFetchingBuildStatusUpdates();

      final FakeCocoonService service = FakeCocoonService();
      expectedStatuses = await service.fetchCommitStatuses();
    });

    tearDown(() async {
      buildState.stopFetchingBuildStatusUpdate();
    });

    testWidgets('shows loading indicator when statuses is empty',
        (WidgetTester tester) async {
      await tester.pumpWidget(Column(
        children: [
          StatusGrid(),
        ],
      ));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byType(GridView), findsNothing);

      tester.takeException();
    });

    testWidgets('commits show in the same column', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Column(
            children: [
              ChangeNotifierProvider(
                builder: (_) => buildState,
                child: StatusGrid(),
              ),
            ],
          ),
        ),
      );

      List<Element> commits = find.byType(CommitBox).evaluate().toList();

      double xPosition = commits.first.size.topLeft(Offset.zero).dx;

      for (Element commit in commits) {
        // All the x positions should match the first instance if they're all in the same column
        expect(commit.size.topLeft(Offset.zero).dx, xPosition);
        tester.takeException();
      }
    });

    testWidgets('first task in grid is the first task given',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Column(
            children: [
              ChangeNotifierProvider(
                builder: (_) => buildState,
                child: StatusGrid(),
              ),
            ],
          ),
        ),
      );

      TaskBox firstTask = find.byType(TaskBox).evaluate().first.widget;
      expect(firstTask.task, expectedStatuses[0].stages[0].tasks[0]);

      tester.takeException();
    });

    testWidgets('last task in grid is the last task given',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Column(
            children: [
              ChangeNotifierProvider(
                builder: (_) => buildState,
                child: StatusGrid(),
              ),
            ],
          ),
        ),
      );

      TaskBox lastTask = find.byType(TaskBox).evaluate().last.widget;
      expect(lastTask.task, expectedStatuses.last.stages.last.tasks.last);

      tester.takeException();
    });
  });
}
