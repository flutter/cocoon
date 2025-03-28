// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:fixnum/fixnum.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dashboard/logic/task_grid_filter.dart';
import 'package:flutter_dashboard/model/commit.pb.dart';
import 'package:flutter_dashboard/model/task.pb.dart';
import 'package:flutter_dashboard/src/rpc_model.dart';
import 'package:flutter_dashboard/state/build.dart';
import 'package:flutter_dashboard/widgets/error_brook_watcher.dart';
import 'package:flutter_dashboard/widgets/luci_task_attempt_summary.dart';
import 'package:flutter_dashboard/widgets/now.dart';
import 'package:flutter_dashboard/widgets/progress_button.dart';
import 'package:flutter_dashboard/widgets/state_provider.dart';
import 'package:flutter_dashboard/widgets/task_box.dart';
import 'package:flutter_dashboard/widgets/task_grid.dart';
import 'package:flutter_dashboard/widgets/task_overlay.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import '../utils/fake_build.dart';
import '../utils/golden.dart';
import '../utils/task_icons.dart';

class TestGrid extends StatelessWidget {
  const TestGrid({
    required this.buildState,
    required this.task,
    this.filter,
    super.key,
  });

  final BuildState buildState;
  final Task task;
  final TaskGridFilter? filter;

  @override
  Widget build(BuildContext context) {
    return Material(
      child: TaskGrid(
        filter: filter,
        buildState: buildState,
        commitStatuses: <CommitStatus>[
          CommitStatus(
            commit:
                (Commit()
                  ..author = 'Fats Domino'
                  ..sha = '24e8c0a2'
                  ..branch = 'master'),

            tasks: [task],
          ),
        ],
      ),
    );
  }
}

const double _cellSize = 36;

void main() {
  final nowTime = DateTime.utc(2020, 9, 1, 12, 30);
  final createTime = nowTime.subtract(const Duration(minutes: 52));
  final startTime = nowTime.subtract(const Duration(minutes: 50));
  final finishTime = nowTime.subtract(const Duration(minutes: 10));

  Int64 int64FromDateTime(DateTime time) => Int64(time.millisecondsSinceEpoch);

  late FakeBuildState buildState;

  setUp(() {
    buildState = FakeBuildState();
    when(buildState.authService.isAuthenticated).thenReturn(true);
  });

  testWidgets('TaskOverlay shows on click', (WidgetTester tester) async {
    await precacheTaskIcons(tester);

    final expectedTask =
        Task()
          ..attempts = 3
          ..builderName = 'Tasky McTaskFace'
          ..isFlaky =
              false // As opposed to the next test.
          ..status = TaskBox.statusFailed
          ..createTimestamp = int64FromDateTime(createTime)
          ..startTimestamp = int64FromDateTime(startTime)
          ..endTimestamp = int64FromDateTime(finishTime);

    final expectedTaskInfoString =
        'Attempts: 3\n'
        'Queued for 2 minutes\n'
        'Ran for 40 minutes';

    await tester.pumpWidget(
      Now.fixed(
        dateTime: nowTime,
        child: TaskBox(
          cellSize: _cellSize,
          child: MaterialApp(
            theme: ThemeData(useMaterial3: false),
            home: Scaffold(
              body: TestGrid(buildState: buildState, task: expectedTask),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text(expectedTask.builderName), findsNothing);
    expect(find.text(expectedTaskInfoString), findsNothing);

    await expectGoldenMatches(
      find.byType(MaterialApp),
      'task_overlay_test.normal_overlay_closed.png',
    );

    await tester.tapAt(const Offset(_cellSize * 1.5, _cellSize * 1.5));
    await tester.pump();

    expect(find.text(expectedTask.builderName), findsOneWidget);
    expect(find.text(expectedTaskInfoString), findsOneWidget);

    await expectGoldenMatches(
      find.byType(MaterialApp),
      'task_overlay_test.normal_overlay_open.png',
    );

    // Since the overlay positions itself below the middle of the widget,
    // it is safe to click the widget to close it again.
    await tester.tapAt(const Offset(_cellSize * 1.5, _cellSize * 1.5));
    await tester.pump();

    expect(find.text(expectedTask.builderName), findsNothing);
    expect(find.text(expectedTaskInfoString), findsNothing);

    await expectGoldenMatches(
      find.byType(MaterialApp),
      'task_overlay_test.normal_overlay_closed.png',
    );
  });

  testWidgets('TaskOverlay shows when flaky is true', (
    WidgetTester tester,
  ) async {
    await precacheTaskIcons(tester);
    final flakyTask =
        Task()
          ..attempts = 3
          ..builderName = 'Tasky McTaskFace'
          ..isFlaky =
              true // This is the point of this test.
          ..status = TaskBox.statusFailed
          ..createTimestamp = int64FromDateTime(createTime)
          ..startTimestamp = int64FromDateTime(startTime)
          ..endTimestamp = int64FromDateTime(finishTime);

    final flakyTaskInfoString =
        'Attempts: 3\n'
        'Queued for 2 minutes\n'
        'Ran for 40 minutes\n'
        'Flaky: true';

    await tester.pumpWidget(
      Now.fixed(
        dateTime: nowTime,
        child: TaskBox(
          cellSize: _cellSize,
          child: MaterialApp(
            theme: ThemeData(useMaterial3: false),
            home: Scaffold(
              body: TestGrid(
                buildState: buildState,
                task: flakyTask,
                // Otherwise the task is not rendered at all.
                filter: TaskGridFilter()..showBringup = true,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text(flakyTask.builderName), findsNothing);
    expect(find.text(flakyTaskInfoString), findsNothing);

    await expectGoldenMatches(
      find.byType(MaterialApp),
      'task_overlay_test.flaky_overlay_closed.png',
    );

    await tester.tapAt(const Offset(_cellSize * 1.5, _cellSize * 1.5));
    await tester.pump();

    expect(find.text(flakyTask.builderName), findsOneWidget);
    expect(find.text(flakyTaskInfoString), findsOneWidget);

    await expectGoldenMatches(
      find.byType(MaterialApp),
      'task_overlay_test.flaky_overlay_open.png',
    );
  });

  testWidgets('TaskOverlay computes durations correctly for completed task', (
    WidgetTester tester,
  ) async {
    /// Create a queue time of 2 minutes, run time of 8 minutes
    final createTime = nowTime.subtract(const Duration(minutes: 11));
    final startTime = nowTime.subtract(const Duration(minutes: 9));
    final finishTime = nowTime.subtract(const Duration(minutes: 1));

    final timeTask =
        Task()
          ..attempts = 1
          ..builderName = 'Tasky McTaskFace'
          ..isFlaky = false
          ..status = TaskBox.statusSucceeded
          ..createTimestamp = int64FromDateTime(createTime)
          ..startTimestamp = int64FromDateTime(startTime)
          ..endTimestamp = int64FromDateTime(finishTime);

    final timeTaskInfoString =
        'Attempts: 1\n'
        'Queued for 2 minutes\n'
        'Ran for 8 minutes';

    await tester.pumpWidget(
      Now.fixed(
        dateTime: nowTime,
        child: TaskBox(
          cellSize: _cellSize,
          child: MaterialApp(
            home: Scaffold(
              body: TestGrid(buildState: buildState, task: timeTask),
            ),
          ),
        ),
      ),
    );

    expect(find.text(timeTaskInfoString), findsNothing);

    // open the overlay to show the task summary
    await tester.tapAt(const Offset(_cellSize * 1.5, _cellSize * 1.5));
    await tester.pump();

    expect(find.text(timeTaskInfoString), findsOneWidget);
  });

  testWidgets('TaskOverlay computes durations correctly for running task', (
    WidgetTester tester,
  ) async {
    /// Create a queue time of 2 minutes, running time of 9 minutes
    final createTime = nowTime.subtract(const Duration(minutes: 11));
    final startTime = nowTime.subtract(const Duration(minutes: 9));

    final timeTask =
        Task()
          ..attempts = 1
          ..builderName = 'Tasky McTaskFace'
          ..status = TaskBox.statusInProgress
          ..isFlaky = false
          ..createTimestamp = int64FromDateTime(createTime)
          ..startTimestamp = int64FromDateTime(startTime);

    final timeTaskInfoString =
        'Attempts: 1\n'
        'Queuing for 11 minutes\n';

    await tester.pumpWidget(
      Now.fixed(
        dateTime: nowTime,
        child: TaskBox(
          cellSize: _cellSize,
          child: MaterialApp(
            home: Scaffold(
              body: TestGrid(buildState: buildState, task: timeTask),
            ),
          ),
        ),
      ),
    );

    expect(find.text(timeTaskInfoString), findsNothing);

    // open the overlay to show the task summary
    await tester.tapAt(const Offset(_cellSize * 1.5, _cellSize * 1.5));
    await tester.pump();

    expect(find.text(timeTaskInfoString), findsOneWidget);
  });

  testWidgets('TaskOverlay computes durations correctly for waiting task', (
    WidgetTester tester,
  ) async {
    /// Create a queue time of 2 minutes
    final createTime = nowTime.subtract(const Duration(minutes: 2));

    final timeTask =
        Task()
          ..attempts = 1
          ..builderName = 'Tasky McTaskFace'
          ..status = TaskBox.statusNew
          ..isFlaky = false
          ..createTimestamp = int64FromDateTime(createTime);

    final timeTaskInfoString =
        'Attempts: 1\n'
        'Waiting for backfill for 2 minutes\n';

    await tester.pumpWidget(
      Now.fixed(
        dateTime: nowTime,
        child: TaskBox(
          cellSize: _cellSize,
          child: MaterialApp(
            home: Scaffold(
              body: TestGrid(buildState: buildState, task: timeTask),
            ),
          ),
        ),
      ),
    );

    expect(find.text(timeTaskInfoString), findsNothing);

    // open the overlay to show the task summary
    await tester.tapAt(const Offset(_cellSize * 1.5, _cellSize * 1.5));
    await tester.pump();

    expect(find.text(timeTaskInfoString), findsOneWidget);
  });

  testWidgets('TaskOverlay computes durations correctly for queuing task', (
    WidgetTester tester,
  ) async {
    /// Create a queue time of 2 minutes
    final createTime = nowTime.subtract(const Duration(minutes: 11));

    final timeTask =
        Task()
          ..attempts = 1
          ..builderName = 'Tasky McTaskFace'
          ..status = TaskBox.statusInProgress
          ..isFlaky = false
          ..createTimestamp = int64FromDateTime(createTime);

    final timeTaskInfoString =
        'Attempts: 1\n'
        'Queuing for 11 minutes\n';

    await tester.pumpWidget(
      Now.fixed(
        dateTime: nowTime,
        child: TaskBox(
          cellSize: _cellSize,
          child: MaterialApp(
            home: Scaffold(
              body: TestGrid(buildState: buildState, task: timeTask),
            ),
          ),
        ),
      ),
    );

    expect(find.text(timeTaskInfoString), findsNothing);

    // open the overlay to show the task summary
    await tester.tapAt(const Offset(_cellSize * 1.5, _cellSize * 1.5));
    await tester.pump();

    expect(find.text(timeTaskInfoString), findsOneWidget);
  });

  testWidgets('TaskOverlay shows the right message for nondevicelab tasks', (
    WidgetTester tester,
  ) async {
    await precacheTaskIcons(tester);
    await tester.pumpWidget(
      Now.fixed(
        dateTime: nowTime,
        child: TaskBox(
          cellSize: _cellSize,
          child: MaterialApp(
            theme: ThemeData(useMaterial3: false),
            home: Scaffold(
              body: TestGrid(
                buildState: buildState,
                task: Task()..status = TaskBox.statusSucceeded,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    await expectGoldenMatches(
      find.byType(MaterialApp),
      'task_overlay_test.nondevicelab_closed.png',
    );

    await tester.tapAt(const Offset(_cellSize * 1.5, _cellSize * 1.5));
    await tester.pump();

    await expectGoldenMatches(
      find.byType(MaterialApp),
      'task_overlay_test.nondevicelab_open.png',
    );
  });

  testWidgets('TaskOverlay shows TaskAttemptSummary for Luci tasks', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      Now.fixed(
        dateTime: nowTime,
        child: TaskBox(
          cellSize: _cellSize,
          child: MaterialApp(
            home: Scaffold(
              body: TestGrid(
                buildState: buildState,
                task:
                    Task()
                      ..status = TaskBox.statusSucceeded
                      ..buildNumberList = '123',
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.byType(LuciTaskAttemptSummary), findsNothing);

    await tester.tapAt(const Offset(_cellSize * 1.5, _cellSize * 1.5));
    await tester.pump();

    expect(find.byType(LuciTaskAttemptSummary), findsOneWidget);
  });

  testWidgets('TaskOverlay shows TaskAttemptSummary for dart-internal tasks', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      Now.fixed(
        dateTime: nowTime,
        child: TaskBox(
          cellSize: _cellSize,
          child: MaterialApp(
            home: Scaffold(
              body: TestGrid(
                buildState: buildState,
                task:
                    Task()
                      ..builderName = 'Linux flutter_release_builder'
                      ..status = TaskBox.statusSucceeded
                      ..buildNumberList = '123',
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.byType(LuciTaskAttemptSummary), findsNothing);

    await tester.tapAt(const Offset(_cellSize * 1.5, _cellSize * 1.5));
    await tester.pump();

    expect(find.byType(LuciTaskAttemptSummary), findsOneWidget);
  });

  testWidgets('TaskOverlay: RERUN button disabled when user !isAuthenticated', (
    WidgetTester tester,
  ) async {
    final expectedTask =
        Task()
          ..attempts = 3
          ..builderName = 'Tasky McTaskFace'
          ..status = TaskBox.statusSucceeded
          ..isFlaky = false;

    final buildState = FakeBuildState(rerunTaskResult: true);
    when(buildState.authService.isAuthenticated).thenReturn(false);

    await tester.pumpWidget(
      Now.fixed(
        dateTime: nowTime,
        child: TaskBox(
          cellSize: _cellSize,
          child: MaterialApp(
            home: Scaffold(
              body: TestGrid(buildState: buildState, task: expectedTask),
            ),
          ),
        ),
      ),
    );

    // Open the overlay
    await tester.tapAt(const Offset(_cellSize * 1.5, _cellSize * 1.5));
    await tester.pump();

    final rerun =
        tester
            .element(find.text('RERUN'))
            .findAncestorWidgetOfExactType<ProgressButton>();

    expect(rerun, isNotNull, reason: 'The rerun button should exist.');
    expect(
      rerun!.onPressed,
      isNull,
      reason: 'The rerun button should be disabled.',
    );
  });

  testWidgets('TaskOverlay: successful rerun shows success snackbar message', (
    WidgetTester tester,
  ) async {
    final expectedTask =
        Task()
          ..attempts = 3
          ..builderName = 'Tasky McTaskFace'
          ..status = TaskBox.statusSucceeded
          ..isFlaky = false;

    final buildState = FakeBuildState(rerunTaskResult: true);
    when(buildState.authService.isAuthenticated).thenReturn(true);

    await tester.pumpWidget(
      Now.fixed(
        dateTime: nowTime,
        child: TaskBox(
          cellSize: _cellSize,
          child: MaterialApp(
            home: Scaffold(
              body: TestGrid(buildState: buildState, task: expectedTask),
            ),
          ),
        ),
      ),
    );

    // Open the overlay
    await tester.tapAt(const Offset(_cellSize * 1.5, _cellSize * 1.5));
    await tester.pump();

    expect(find.text(TaskOverlayContents.rerunErrorMessage), findsNothing);
    expect(find.text(TaskOverlayContents.rerunSuccessMessage), findsNothing);

    // Click the rerun task button
    await tester.tap(find.text('RERUN'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 750)); // open animation

    expect(find.text(TaskOverlayContents.rerunErrorMessage), findsNothing);
    expect(find.text(TaskOverlayContents.rerunSuccessMessage), findsOneWidget);

    // Snackbar message should go away after its duration
    await tester.pump(TaskOverlayContents.rerunSnackBarDuration);
    await tester.pump(const Duration(milliseconds: 1500)); // close animation

    expect(find.text(TaskOverlayContents.rerunErrorMessage), findsNothing);
    expect(find.text(TaskOverlayContents.rerunSuccessMessage), findsNothing);
  });

  testWidgets('failed rerun shows errorBrook snackbar message', (
    WidgetTester tester,
  ) async {
    final expectedTask =
        Task()
          ..attempts = 3
          ..builderName = 'Tasky McTaskFace'
          ..isFlaky = false
          ..status = TaskBox.statusNew;

    final buildState = FakeBuildState(rerunTaskResult: false);
    when(buildState.authService.isAuthenticated).thenReturn(true);

    await tester.pumpWidget(
      Now.fixed(
        dateTime: nowTime,
        child: TaskBox(
          cellSize: _cellSize,
          child: MaterialApp(
            home: ValueProvider<BuildState>(
              value: buildState,
              child: Scaffold(
                body: ErrorBrookWatcher(
                  errors: buildState.errors,
                  child: TestGrid(buildState: buildState, task: expectedTask),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tapAt(const Offset(_cellSize * 1.5, _cellSize * 1.5));
    // await tester.tap(find.byType(LatticeCell));
    // await tester.tap(find.byType(TaskOverlayContents));
    await tester.pump();

    // Click the rerun task button
    await tester.tap(find.text('RERUN'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 750)); // open animation

    expect(find.text(TaskOverlayContents.rerunErrorMessage), findsOneWidget);
    expect(find.text(TaskOverlayContents.rerunSuccessMessage), findsNothing);

    // Snackbar message should go away after its duration
    await tester.pump(
      ErrorBrookWatcher.errorSnackbarDuration,
    ); // wait the duration
    await tester.pump(); // schedule animation
    await tester.pump(const Duration(milliseconds: 1500)); // close animation

    expect(find.text(TaskOverlayContents.rerunErrorMessage), findsNothing);
    expect(find.text(TaskOverlayContents.rerunSuccessMessage), findsNothing);
  });

  test('TaskOverlayEntryPositionDelegate.positionDependentBox', () async {
    const normalSize = Size(800, 600);
    const childSize = Size(300, 180);

    // Window is too small, center.
    expect(
      TaskOverlayEntryPositionDelegate.positionDependentBox(
        size: const Size(250, 150),
        childSize: childSize,
        cellSize: _cellSize,
        target: const Offset(50.0, 50.0),
      ),
      const Offset(-25.0, 10.0),
    );

    // Normal positioning, below and to right.
    expect(
      TaskOverlayEntryPositionDelegate.positionDependentBox(
        size: normalSize,
        childSize: childSize,
        cellSize: _cellSize,
        target: const Offset(50.0, 50.0),
      ),
      const Offset(50.0, 82.4),
    );
    // Doesn't fit in right, below and to left.
    expect(
      TaskOverlayEntryPositionDelegate.positionDependentBox(
        size: normalSize,
        childSize: childSize,
        cellSize: _cellSize,
        target: const Offset(590.0, 50.0),
      ),
      const Offset(490.0, 82.4),
    );
    // Doesn't fit below, above and to right.
    expect(
      TaskOverlayEntryPositionDelegate.positionDependentBox(
        size: normalSize,
        childSize: childSize,
        cellSize: _cellSize,
        target: const Offset(50.0, 500.0),
      ),
      const Offset(50.0, 320.0),
    );
    // Above and to left.
    expect(
      TaskOverlayEntryPositionDelegate.positionDependentBox(
        size: normalSize,
        childSize: childSize,
        cellSize: _cellSize,
        target: const Offset(590.0, 500.0),
      ),
      const Offset(490.0, 320.0),
    );
  });
}
