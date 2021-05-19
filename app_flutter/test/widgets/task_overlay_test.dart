// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:app_flutter/logic/qualified_task.dart';
import 'package:app_flutter/state/build.dart';
import 'package:app_flutter/widgets/luci_task_attempt_summary.dart';
import 'package:app_flutter/widgets/now.dart';
import 'package:app_flutter/widgets/task_box.dart';
import 'package:app_flutter/widgets/task_grid.dart';
import 'package:app_flutter/widgets/task_overlay.dart';
import 'package:cocoon_service/protos.dart' show CommitStatus, Commit, Stage, Task;
import 'package:fixnum/fixnum.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../utils/fake_build.dart';
import '../utils/golden.dart';
import '../utils/task_icons.dart';

class TestGrid extends StatelessWidget {
  const TestGrid({
    this.buildState,
    this.task,
  });

  final BuildState buildState;
  final Task task;

  @override
  Widget build(BuildContext context) {
    return Material(
      child: TaskGrid(
        buildState: buildState ?? FakeBuildState(),
        commitStatuses: <CommitStatus>[
          CommitStatus()
            ..commit = (Commit()
              ..author = 'Fats Domino'
              ..sha = '24e8c0a2')
            ..stages.add(Stage()
              ..name = StageName.luci
              ..tasks.addAll(<Task>[task])),
        ],
      ),
    );
  }
}

void main() {
  final DateTime nowTime = DateTime.utc(2020, 9, 1, 12, 30);
  final DateTime createTime = nowTime.subtract(const Duration(minutes: 52));
  final DateTime startTime = nowTime.subtract(const Duration(minutes: 50));
  final DateTime finishTime = nowTime.subtract(const Duration(minutes: 10));

  Int64 _int64FromDateTime(DateTime time) => Int64(time.millisecondsSinceEpoch);

  testWidgets('TaskOverlay shows on click', (WidgetTester tester) async {
    await precacheTaskIcons(tester);

    final Task expectedTask = Task()
      ..attempts = 3
      ..stageName = 'luci'
      ..name = 'Tasky McTaskFace'
      ..reservedForAgentId = 'Agenty McAgentFace'
      ..isFlaky = false // As opposed to the next test.
      ..status = TaskBox.statusFailed
      ..createTimestamp = _int64FromDateTime(createTime)
      ..startTimestamp = _int64FromDateTime(startTime)
      ..endTimestamp = _int64FromDateTime(finishTime);

    final String expectedTaskInfoString = 'Attempts: ${expectedTask.attempts}\n'
        'Run time: 40 minutes\n'
        'Queue time: 120 seconds';

    await tester.pumpWidget(
      Now.fixed(
        dateTime: nowTime,
        child: MaterialApp(
          home: Scaffold(
            body: TestGrid(
              task: expectedTask,
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text(expectedTask.name), findsNothing);
    expect(find.text(expectedTaskInfoString), findsNothing);
    expect(find.text(expectedTask.reservedForAgentId), findsNothing);

    await expectGoldenMatches(find.byType(MaterialApp), 'task_overlay_test.normal_overlay_closed.png');

    await tester.tapAt(const Offset(TaskBox.cellSize * 1.5, TaskBox.cellSize * 1.5));
    await tester.pump();

    expect(find.text(expectedTask.name), findsOneWidget);
    expect(find.text(expectedTaskInfoString), findsOneWidget);

    await expectGoldenMatches(find.byType(MaterialApp), 'task_overlay_test.normal_overlay_open.png');

    // Since the overlay positions itself below the middle of the widget,
    // it is safe to click the widget to close it again.
    await tester.tapAt(const Offset(TaskBox.cellSize * 1.5, TaskBox.cellSize * 1.5));
    await tester.pump();

    expect(find.text(expectedTask.name), findsNothing);
    expect(find.text(expectedTaskInfoString), findsNothing);
    expect(find.text(expectedTask.reservedForAgentId), findsNothing);

    await expectGoldenMatches(find.byType(MaterialApp), 'task_overlay_test.normal_overlay_closed.png');
  });

  testWidgets('TaskOverlay shows when flaky is true', (WidgetTester tester) async {
    await precacheTaskIcons(tester);
    final Task flakyTask = Task()
      ..attempts = 3
      ..stageName = StageName.luci
      ..name = 'Tasky McTaskFace'
      ..isFlaky = true // This is the point of this test.
      ..status = TaskBox.statusFailed
      ..createTimestamp = _int64FromDateTime(createTime)
      ..startTimestamp = _int64FromDateTime(startTime)
      ..endTimestamp = _int64FromDateTime(finishTime);

    final String flakyTaskInfoString = 'Attempts: ${flakyTask.attempts}\n'
        'Run time: 40 minutes\n'
        'Queue time: 120 seconds\n'
        'Flaky: true';

    await tester.pumpWidget(
      Now.fixed(
        dateTime: nowTime,
        child: MaterialApp(
          home: Scaffold(
            body: TestGrid(
              task: flakyTask,
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text(flakyTask.name), findsNothing);
    expect(find.text(flakyTaskInfoString), findsNothing);
    expect(find.text(flakyTask.reservedForAgentId), findsNothing);

    await expectGoldenMatches(find.byType(MaterialApp), 'task_overlay_test.flaky_overlay_closed.png');

    await tester.tapAt(const Offset(TaskBox.cellSize * 1.5, TaskBox.cellSize * 1.5));
    await tester.pump();

    expect(find.text(flakyTask.name), findsOneWidget);
    expect(find.text(flakyTaskInfoString), findsOneWidget);

    await expectGoldenMatches(find.byType(MaterialApp), 'task_overlay_test.flaky_overlay_open.png');
  });

  testWidgets('TaskOverlay computes durations correctly for completed task', (WidgetTester tester) async {
    /// Create a queue time of 10 seconds, run time of 8 minutes
    final DateTime createTime = nowTime.subtract(const Duration(minutes: 9, seconds: 10));
    final DateTime startTime = nowTime.subtract(const Duration(minutes: 9));
    final DateTime finishTime = nowTime.subtract(const Duration(minutes: 1));

    final Task timeTask = Task()
      ..attempts = 1
      ..stageName = StageName.luci
      ..name = 'Tasky McTaskFace'
      ..isFlaky = false
      ..createTimestamp = _int64FromDateTime(createTime)
      ..startTimestamp = _int64FromDateTime(startTime)
      ..endTimestamp = _int64FromDateTime(finishTime);

    final String timeTaskInfoString = 'Attempts: ${timeTask.attempts}\n'
        'Run time: 8 minutes\n'
        'Queue time: 10 seconds';

    await tester.pumpWidget(
      Now.fixed(
        dateTime: nowTime,
        child: MaterialApp(
          home: Scaffold(
            body: TestGrid(
              task: timeTask,
            ),
          ),
        ),
      ),
    );

    expect(find.text(timeTaskInfoString), findsNothing);

    // open the overlay to show the task summary
    await tester.tapAt(const Offset(TaskBox.cellSize * 1.5, TaskBox.cellSize * 1.5));
    await tester.pump();

    expect(find.text(timeTaskInfoString), findsOneWidget);
  });

  testWidgets('TaskOverlay computes durations correctly for running task', (WidgetTester tester) async {
    /// Create a queue time of 10 seconds, running time of 9 minutes
    final DateTime createTime = nowTime.subtract(const Duration(minutes: 9, seconds: 10));
    final DateTime startTime = nowTime.subtract(const Duration(minutes: 9));

    final Task timeTask = Task()
      ..attempts = 1
      ..stageName = StageName.luci
      ..name = 'Tasky McTaskFace'
      ..status = TaskBox.statusInProgress
      ..isFlaky = false
      ..createTimestamp = _int64FromDateTime(createTime)
      ..startTimestamp = _int64FromDateTime(startTime);

    final String timeTaskInfoString = 'Attempts: ${timeTask.attempts}\n'
        'Running for 9 minutes\n'
        'Queue time: 10 seconds';

    await tester.pumpWidget(
      Now.fixed(
        dateTime: nowTime,
        child: MaterialApp(
          home: Scaffold(
            body: TestGrid(
              task: timeTask,
            ),
          ),
        ),
      ),
    );

    expect(find.text(timeTaskInfoString), findsNothing);

    // open the overlay to show the task summary
    await tester.tapAt(const Offset(TaskBox.cellSize * 1.5, TaskBox.cellSize * 1.5));
    await tester.pump();

    expect(find.text(timeTaskInfoString), findsOneWidget);
  });

  testWidgets('TaskOverlay computes durations correctly for queueing task', (WidgetTester tester) async {
    /// Create a queue time of 10 seconds, running time of 9 minutes
    final DateTime createTime = nowTime.subtract(const Duration(seconds: 10));

    final Task timeTask = Task()
      ..attempts = 1
      ..stageName = StageName.luci
      ..name = 'Tasky McTaskFace'
      ..status = TaskBox.statusNew
      ..isFlaky = false
      ..createTimestamp = _int64FromDateTime(createTime);

    final String timeTaskInfoString = 'Attempts: ${timeTask.attempts}\n'
        'Queueing for 10 seconds';

    await tester.pumpWidget(
      Now.fixed(
        dateTime: nowTime,
        child: MaterialApp(
          home: Scaffold(
            body: TestGrid(
              task: timeTask,
            ),
          ),
        ),
      ),
    );

    expect(find.text(timeTaskInfoString), findsNothing);

    // open the overlay to show the task summary
    await tester.tapAt(const Offset(TaskBox.cellSize * 1.5, TaskBox.cellSize * 1.5));
    await tester.pump();

    expect(find.text(timeTaskInfoString), findsOneWidget);
  });

  testWidgets('TaskOverlay shows the right message for nondevicelab tasks', (WidgetTester tester) async {
    await precacheTaskIcons(tester);
    await tester.pumpWidget(
      Now.fixed(
        dateTime: nowTime,
        child: MaterialApp(
          home: Scaffold(
            body: TestGrid(
              task: Task()
                ..stageName = 'cirrus'
                ..status = TaskBox.statusSucceeded,
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    await expectGoldenMatches(find.byType(MaterialApp), 'task_overlay_test.nondevicelab_closed.png');

    await tester.tapAt(const Offset(TaskBox.cellSize * 1.5, TaskBox.cellSize * 1.5));
    await tester.pump();

    await expectGoldenMatches(find.byType(MaterialApp), 'task_overlay_test.nondevicelab_open.png');
  });

  testWidgets('TaskOverlay shows TaskAttemptSummary for Luci tasks', (WidgetTester tester) async {
    await tester.pumpWidget(
      Now.fixed(
        dateTime: nowTime,
        child: MaterialApp(
          home: Scaffold(
            body: TestGrid(
              task: Task()
                ..stageName = 'chromebot'
                ..status = TaskBox.statusSucceeded
                ..buildNumberList = '123',
            ),
          ),
        ),
      ),
    );

    expect(find.byType(LuciTaskAttemptSummary), findsNothing);

    await tester.tapAt(const Offset(TaskBox.cellSize * 1.5, TaskBox.cellSize * 1.5));
    await tester.pump();

    expect(find.byType(LuciTaskAttemptSummary), findsOneWidget);
  });

  testWidgets('TaskOverlay: successful rerun shows success snackbar message', (WidgetTester tester) async {
    final Task expectedTask = Task()
      ..attempts = 3
      ..stageName = StageName.luci
      ..name = 'Tasky McTaskFace'
      ..reservedForAgentId = 'Agenty McAgentFace'
      ..isFlaky = false;

    await tester.pumpWidget(
      Now.fixed(
        dateTime: nowTime,
        child: MaterialApp(
          home: Scaffold(
            body: TestGrid(
              buildState: FakeBuildState(rerunTaskResult: true),
              task: expectedTask,
            ),
          ),
        ),
      ),
    );

    // Open the overlay
    await tester.tapAt(const Offset(TaskBox.cellSize * 1.5, TaskBox.cellSize * 1.5));
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

  testWidgets('failed rerun shows error snackbar message', (WidgetTester tester) async {
    final Task expectedTask = Task()
      ..attempts = 3
      ..stageName = StageName.luci
      ..name = 'Tasky McTaskFace'
      ..reservedForAgentId = 'Agenty McAgentFace'
      ..isFlaky = false
      ..status = TaskBox.statusNew;

    await tester.pumpWidget(
      Now.fixed(
        dateTime: nowTime,
        child: MaterialApp(
          home: Scaffold(
            body: TestGrid(
              buildState: FakeBuildState(rerunTaskResult: false),
              task: expectedTask,
            ),
          ),
        ),
      ),
    );

    // Open the overlay
    await tester.tapAt(const Offset(TaskBox.cellSize * 1.5, TaskBox.cellSize * 1.5));
    await tester.pump();

    expect(find.text(TaskOverlayContents.rerunErrorMessage), findsNothing);
    expect(find.text(TaskOverlayContents.rerunSuccessMessage), findsNothing);

    // Click the rerun task button
    await tester.tap(find.text('RERUN'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 750)); // open animation

    expect(find.text(TaskOverlayContents.rerunErrorMessage), findsOneWidget);
    expect(find.text(TaskOverlayContents.rerunSuccessMessage), findsNothing);

    // Snackbar message should go away after its duration
    await tester.pump(TaskOverlayContents.rerunSnackBarDuration);
    await tester.pump(const Duration(milliseconds: 1500)); // close animation

    expect(find.text(TaskOverlayContents.rerunErrorMessage), findsNothing);
    expect(find.text(TaskOverlayContents.rerunSuccessMessage), findsNothing);
  });

  testWidgets('log button opens log url for public log', (WidgetTester tester) async {
    const MethodChannel channel = MethodChannel('plugins.flutter.io/url_launcher');
    final List<MethodCall> log = <MethodCall>[];
    channel.setMockMethodCallHandler((MethodCall methodCall) async {
      log.add(methodCall);
    });
    final Task publicTask = Task()..stageName = 'cirrus';
    await tester.pumpWidget(
      Now.fixed(
        dateTime: nowTime,
        child: MaterialApp(
          home: Scaffold(
            body: TestGrid(
              task: publicTask,
            ),
          ),
        ),
      ),
    );

    // Open the overlay
    await tester.tapAt(const Offset(TaskBox.cellSize * 1.5, TaskBox.cellSize * 1.5));
    await tester.pump();

    // View log
    await tester.tap(find.text('VIEW LOGS'));
    await tester.pump();

    expect(
      log,
      <Matcher>[
        isMethodCall('launch', arguments: <String, Object>{
          'url': 'https://cirrus-ci.com/build/flutter/flutter/24e8c0a2?branch=',
          'useSafariVC': true,
          'useWebView': false,
          'enableJavaScript': false,
          'enableDomStorage': false,
          'universalLinksOnly': false,
          'headers': <String, String>{}
        })
      ],
    );
  });

  test('TaskOverlayEntryPositionDelegate.positionDependentBox', () async {
    const Size normalSize = Size(800, 600);
    const Size childSize = Size(300, 180);

    // Window is too small, center.
    expect(
      TaskOverlayEntryPositionDelegate.positionDependentBox(
        size: const Size(250, 150),
        childSize: childSize,
        target: const Offset(50.0, 50.0),
      ),
      const Offset(-25.0, 10.0),
    );

    // Normal positioning, below and to right.
    expect(
      TaskOverlayEntryPositionDelegate.positionDependentBox(
        size: normalSize,
        childSize: childSize,
        target: const Offset(50.0, 50.0),
      ),
      const Offset(50.0, 82.4),
    );
    // Doesn't fit in right, below and to left.
    expect(
      TaskOverlayEntryPositionDelegate.positionDependentBox(
        size: normalSize,
        childSize: childSize,
        target: const Offset(590.0, 50.0),
      ),
      const Offset(490.0, 82.4),
    );
    // Doesn't fit below, above and to right.
    expect(
      TaskOverlayEntryPositionDelegate.positionDependentBox(
        size: normalSize,
        childSize: childSize,
        target: const Offset(50.0, 500.0),
      ),
      const Offset(50.0, 320.0),
    );
    // Above and to left.
    expect(
      TaskOverlayEntryPositionDelegate.positionDependentBox(
        size: normalSize,
        childSize: childSize,
        target: const Offset(590.0, 500.0),
      ),
      const Offset(490.0, 320.0),
    );
  });
}
