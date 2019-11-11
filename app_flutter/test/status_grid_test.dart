// Copyright (c) 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:app_flutter/service/google_authentication.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
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

    /// Matrix Diagram:
    /// ✓☐☐
    /// ☐✓☐
    /// ☐☐✓
    /// To construct the matrix from this diagram, each [CommitStatus] must have a unique [Task]
    /// that does not share its name with any other [Task]. This will make that [CommitStatus] have
    /// its task on its own unique row and column.
    final List<CommitStatus> statusesWithSkips = <CommitStatus>[
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

    testWidgets('skipped tasks do not break the grid',
        (WidgetTester tester) async {
      final TaskMatrix taskMatrix = TaskMatrix(statuses: statusesWithSkips);

      await tester.pumpWidget(
        MaterialApp(
          home: Column(
            children: <Widget>[
              StatusGrid(
                buildState: FlutterBuildState(),
                statuses: statusesWithSkips,
                taskMatrix: taskMatrix,
                insertCellKeys: true,
              ),
            ],
          ),
        ),
      );
      expect(tester.takeException(),
          const test.TypeMatcher<NetworkImageLoadException>());

      expect(find.byType(TaskBox), findsNWidgets(3));

      // Row 1: ✓☐☐
      final TaskBox firstTask =
          find.byKey(const Key('cell-0-0')).evaluate().first.widget;
      expect(firstTask.task, statusesWithSkips[0].stages[0].tasks[0]);

      final SizedBox skippedTaskRow1Col2 =
          find.byKey(const Key('cell-0-1')).evaluate().first.widget;
      expect(skippedTaskRow1Col2, isNotNull);

      final SizedBox skippedTaskRow1Col3 =
          find.byKey(const Key('cell-0-2')).evaluate().first.widget;
      expect(skippedTaskRow1Col3, isNotNull);

      // Row 2: ☐✓☐
      final SizedBox skippedTaskRow2Col1 =
          find.byKey(const Key('cell-1-0')).evaluate().first.widget;
      expect(skippedTaskRow2Col1, isNotNull);

      final TaskBox secondTask =
          find.byKey(const Key('cell-1-1')).evaluate().first.widget;
      expect(secondTask.task, statusesWithSkips[1].stages[0].tasks[0]);

      final SizedBox skippedTaskRow2Col3 =
          find.byKey(const Key('cell-1-2')).evaluate().first.widget;
      expect(skippedTaskRow2Col3, isNotNull);

      // Row 3: ☐☐✓
      final SizedBox skippedTaskRow3Col1 =
          find.byKey(const Key('cell-2-0')).evaluate().first.widget;
      expect(skippedTaskRow3Col1, isNotNull);

      final SizedBox skippedTaskRow3Col2 =
          find.byKey(const Key('cell-2-1')).evaluate().first.widget;
      expect(skippedTaskRow3Col2, isNotNull);

      final TaskBox lastTask =
          find.byKey(const Key('cell-2-2')).evaluate().first.widget;
      expect(lastTask.task, statusesWithSkips[2].stages[0].tasks[0]);
    });

    testWidgets(
        'all cells in the grid have the same size even when grid has skipped tasks',
        (WidgetTester tester) async {
      final TaskMatrix taskMatrix = TaskMatrix(statuses: statusesWithSkips);

      await tester.pumpWidget(
        MaterialApp(
          home: Column(
            children: <Widget>[
              StatusGrid(
                buildState: FlutterBuildState(),
                statuses: statusesWithSkips,
                taskMatrix: taskMatrix,
                insertCellKeys: true,
              ),
            ],
          ),
        ),
      );

      // Compare all the cells to the first cell to check they all have
      // the same size
      final Element taskBox =
          find.byKey(const Key('cell-0-0')).evaluate().first;
      for (int rowIndex = 0; rowIndex < taskMatrix.rows; rowIndex++) {
        for (int colIndex = 0; colIndex < taskMatrix.columns; colIndex++) {
          final Element cell =
              find.byKey(Key('cell-$rowIndex-$colIndex')).evaluate().first;

          expect(taskBox.size, cell.size);
        }
      }
    });

    testWidgets('error snackbar shown for error fetching tree status',
        (WidgetTester tester) async {
      final FlutterBuildState buildState = TestFlutterBuildState(
          isTreeBuildingValue: CocoonResponse<bool>()..error = 'tree error',
          statusesValue: CocoonResponse<List<CommitStatus>>()
            ..data = <CommitStatus>[CommitStatus()]);

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Column(
            children: <Widget>[
              ChangeNotifierProvider<FlutterBuildState>.value(
                value: buildState,
                child: const StatusGridContainer(),
              ),
            ],
          ),
        ),
      ));
      await tester.pump(
          const Duration(milliseconds: 750)); // open animation for snackbar

      expect(
          find.text(StatusGridContainer.errorFetchCommitStatus), findsNothing);
      expect(
          find.text(StatusGridContainer.errorFetchTreeStatus), findsOneWidget);

      // Snackbar message should go away after its duration
      await tester.pumpAndSettle(
          StatusGridContainer.errorSnackbarDuration); // wait the duration
      await tester.pump(); // schedule animation
      await tester.pump(const Duration(milliseconds: 1500)); // close animation

      /// Update state to no longer have errors
      buildState.notifyListeners();

      // Wait another snackbar duration to prevent a race condition and ensure it clears
      await tester.pumpAndSettle(StatusGridContainer.errorSnackbarDuration);

      expect(
          find.text(StatusGridContainer.errorFetchCommitStatus), findsNothing);
      expect(find.text(StatusGridContainer.errorFetchTreeStatus), findsNothing);
    });

    testWidgets('error snackbar shown for error fetching commit statuses',
        (WidgetTester tester) async {
      final FlutterBuildState buildState = TestFlutterBuildState(
        isTreeBuildingValue: CocoonResponse<bool>()..data = true,
        statusesValue: CocoonResponse<List<CommitStatus>>()
          ..data = <CommitStatus>[CommitStatus()]
          ..error = 'statuses error',
      );

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Column(
            children: <Widget>[
              ChangeNotifierProvider<FlutterBuildState>.value(
                value: buildState,
                child: const StatusGridContainer(),
              ),
            ],
          ),
        ),
      ));

      await tester.pump(
          const Duration(milliseconds: 750)); // open animation for snackbar

      expect(find.text(StatusGridContainer.errorFetchTreeStatus), findsNothing);
      expect(find.text(StatusGridContainer.errorFetchCommitStatus),
          findsOneWidget);

      // Snackbar message should go away after its duration
      await tester.pumpAndSettle(
          StatusGridContainer.errorSnackbarDuration); // wait the duration
      await tester.pump(); // schedule animation
      await tester.pump(const Duration(milliseconds: 1500)); // close animation

      /// Update state to no longer have errors
      buildState.notifyListeners();

      // Wait another snackbar duration to prevent a race condition and ensure it clears
      await tester.pumpAndSettle(StatusGridContainer.errorSnackbarDuration);

      expect(
          find.text(StatusGridContainer.errorFetchCommitStatus), findsNothing);
      expect(find.text(StatusGridContainer.errorFetchTreeStatus), findsNothing);
    });
  });
}

/// A [ChangeNotifier] for testing the interactions with error handling.
class TestFlutterBuildState extends ChangeNotifier
    implements FlutterBuildState {
  TestFlutterBuildState(
      {@required this.isTreeBuildingValue, @required this.statusesValue});

  // Only return an error on the first call
  int hasErrorCallCount = 1;

  @override
  bool get hasError => hasErrorCallCount++ == 1;

  @override
  CocoonResponse<bool> get isTreeBuilding => isTreeBuildingValue;
  CocoonResponse<bool> isTreeBuildingValue;

  @override
  CocoonResponse<List<CommitStatus>> get statuses => statusesValue;
  CocoonResponse<List<CommitStatus>> statusesValue;

  @override
  Timer refreshTimer;

  @override
  GoogleSignInService get authService => null;

  @override
  Duration get refreshRate => null;

  @override
  Future<bool> rerunTask(Task task) => null;

  @override
  Future<void> signIn() => null;

  @override
  Future<void> startFetchingBuildStateUpdates() => null;
}
