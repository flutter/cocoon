// Copyright (c) 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:test/test.dart' as test;

import 'package:cocoon_service/protos.dart' show CommitStatus, Stage, Task;

import 'package:app_flutter/service/cocoon.dart';
import 'package:app_flutter/service/fake_cocoon.dart';
import 'package:app_flutter/state/flutter_build.dart';
import 'package:app_flutter/commit_box.dart';
import 'package:app_flutter/status_grid.dart';
import 'package:app_flutter/task_box.dart';
import 'package:app_flutter/task_matrix.dart' show TaskMatrix;

void main() {
  group('StatusGrid', () {
    List<CommitStatus> statuses;

    TaskMatrix taskMatrix;

    setUpAll(() async {
      final FakeCocoonService service = FakeCocoonService();
      final CocoonResponse<List<CommitStatus>> response =
          await service.fetchCommitStatuses();
      statuses = response.data;
      taskMatrix = TaskMatrix(statuses: statuses);
    });

    testWidgets('shows loading indicator when statuses is empty',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Column(
            children: <Widget>[
              ChangeNotifierProvider<FlutterBuildState>(
                builder: (_) => FlutterBuildState(),
                child: const StatusGridContainer(),
              ),
            ],
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byType(GridView), findsNothing);
    });

    testWidgets('commits show in the same column', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Column(
            children: <Widget>[
              StatusGrid(
                buildState: FlutterBuildState(),
                statuses: statuses,
                taskMatrix: taskMatrix,
              ),
            ],
          ),
        ),
      );

      final List<Element> commits = find.byType(CommitBox).evaluate().toList();

      final double xPosition = commits.first.size.topLeft(Offset.zero).dx;

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
            children: <Widget>[
              StatusGrid(
                buildState: FlutterBuildState(),
                statuses: statuses,
                taskMatrix: taskMatrix,
              ),
            ],
          ),
        ),
      );

      final TaskBox firstTask = find.byType(TaskBox).evaluate().first.widget;
      expect(firstTask.task, taskMatrix.task(0, 0));
    });

    testWidgets('skipped tasks do not break the grid',
        (WidgetTester tester) async {
      /// Matrix Diagram:
      /// ✓☐☐
      /// ☐✓☐
      /// ☐☐✓
      final List<CommitStatus> statuses = <CommitStatus>[
        CommitStatus()
          ..stages.add(Stage()
            ..name = 'A'
            ..tasks.addAll(<Task>[
              Task()
                ..name = '1'
                ..status = TaskBox.statusSucceeded
            ])),
        CommitStatus()
          ..stages.add(Stage()
            ..name = 'A'
            ..tasks.addAll(<Task>[
              Task()
                ..name = '2'
                ..status = TaskBox.statusSucceeded
            ])),
        CommitStatus()
          ..stages.add(Stage()
            ..name = 'A'
            ..tasks.addAll(<Task>[
              Task()
                ..name = '3'
                ..status = TaskBox.statusSucceeded
            ]))
      ];
      final TaskMatrix taskMatrix = TaskMatrix(statuses: statuses);

      await tester.pumpWidget(
        MaterialApp(
          home: Column(
            children: <Widget>[
              StatusGrid(
                buildState: FlutterBuildState(),
                statuses: statuses,
                taskMatrix: taskMatrix,
              ),
            ],
          ),
        ),
      );
      expect(tester.takeException(),
          const test.TypeMatcher<NetworkImageLoadException>());

      expect(find.byType(TaskBox), findsNWidgets(3));

      final TaskBox firstTask = find.byType(TaskBox).evaluate().first.widget;
      expect(firstTask.task, statuses[0].stages[0].tasks[0]);

      final TaskBox secondTask =
          find.byType(TaskBox).evaluate().skip(1).first.widget;
      expect(secondTask.task, statuses[1].stages[0].tasks[0]);

      final TaskBox lastTask = find.byType(TaskBox).evaluate().last.widget;
      expect(lastTask.task, statuses[2].stages[0].tasks[0]);
    });
  });
}
