// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:fixnum/fixnum.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:mockito/mockito.dart';

import 'package:cocoon_service/protos.dart' show CommitStatus, Commit, Stage, Task;

import 'package:app_flutter/agent_dashboard_page.dart';
import 'package:app_flutter/state/build.dart';
import 'package:app_flutter/widgets/luci_task_attempt_summary.dart';
import 'package:app_flutter/widgets/task_grid.dart';
import 'package:app_flutter/widgets/task_attempt_summary.dart';
import 'package:app_flutter/widgets/task_box.dart';
import 'package:app_flutter/widgets/task_overlay.dart';

import '../utils/fake_build.dart';
import '../utils/mocks.dart';
import '../utils/task_icons.dart';
import '../utils/wrapper.dart';

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
              ..name = 'Stage'
              ..tasks.addAll(<Task>[task])),
        ],
      ),
    );
  }
}

void main() {
  testWidgets('TaskOverlay shows on click', (WidgetTester tester) async {
    await precacheTaskIcons(tester);

    final Task expectedTask = Task()
      ..attempts = 3
      ..stageName = 'devicelab'
      ..name = 'Tasky McTaskFace'
      ..reservedForAgentId = 'Agenty McAgentFace'
      ..reason = 'Because I said so'
      ..isFlaky = false // As opposed to the next test.
      ..status = 'Failed';

    final String expectedTaskInfoString = 'Attempts: ${expectedTask.attempts}\n'
        'Run time: 0 minutes\n'
        'Queue time: 0 seconds\n'
        'Flaky: ${expectedTask.isFlaky}';

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TestGrid(
            task: expectedTask,
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text(expectedTask.name), findsNothing);
    expect(find.text(expectedTaskInfoString), findsNothing);
    expect(find.text(expectedTask.reservedForAgentId), findsNothing);

    await expectLater(find.byType(MaterialApp), matchesGoldenFile('task_overlay_test.normal_overlay_closed.png'));

    await tester.tapAt(const Offset(TaskBox.cellSize * 1.5, TaskBox.cellSize * 1.5));
    await tester.pump();

    expect(find.text(expectedTask.name), findsOneWidget);
    expect(find.text(expectedTaskInfoString), findsOneWidget);
    expect(find.text('SHOW ${expectedTask.reservedForAgentId}'), findsOneWidget);

    await expectLater(find.byType(MaterialApp), matchesGoldenFile('task_overlay_test.normal_overlay_open.png'));

    // Since the overlay positions itself below the middle of the widget,
    // it is safe to click the widget to close it again.
    await tester.tapAt(const Offset(TaskBox.cellSize * 1.5, TaskBox.cellSize * 1.5));
    await tester.pump();

    expect(find.text(expectedTask.name), findsNothing);
    expect(find.text(expectedTaskInfoString), findsNothing);
    expect(find.text(expectedTask.reservedForAgentId), findsNothing);

    await expectLater(find.byType(MaterialApp), matchesGoldenFile('task_overlay_test.normal_overlay_closed.png'));
  });

  testWidgets('TaskOverlay shows when flaky is true', (WidgetTester tester) async {
    await precacheTaskIcons(tester);
    final Task flakyTask = Task()
      ..attempts = 3
      ..stageName = 'devicelab'
      ..name = 'Tasky McTaskFace'
      ..reason = 'Because I said so'
      ..isFlaky = true // This is the point of this test.
      ..status = 'Failed';

    final String flakyTaskInfoString = 'Attempts: ${flakyTask.attempts}\n'
        'Run time: 0 minutes\n'
        'Queue time: 0 seconds\n'
        'Flaky: true';

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TestGrid(
            task: flakyTask,
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text(flakyTask.name), findsNothing);
    expect(find.text(flakyTaskInfoString), findsNothing);
    expect(find.text(flakyTask.reservedForAgentId), findsNothing);

    await expectLater(find.byType(MaterialApp), matchesGoldenFile('task_overlay_test.flaky_overlay_closed.png'));

    await tester.tapAt(const Offset(TaskBox.cellSize * 1.5, TaskBox.cellSize * 1.5));
    await tester.pump();

    expect(find.text(flakyTask.name), findsOneWidget);
    expect(find.text(flakyTaskInfoString), findsOneWidget);
    expect(find.text('SHOW ${flakyTask.reservedForAgentId}'), findsOneWidget);

    await expectLater(find.byType(MaterialApp), matchesGoldenFile('task_overlay_test.flaky_overlay_open.png'));
  });

  testWidgets('TaskOverlay computes durations correctly', (WidgetTester tester) async {
    final Task timeTask = Task()
      ..attempts = 1
      ..stageName = 'devicelab'
      ..name = 'Tasky McTaskFace'
      ..reason = 'Because I said so'
      ..isFlaky = true
      ..createTimestamp = Int64.parseInt('0') // created at 0ms
      ..startTimestamp = Int64.parseInt('10000') // started after 10 seconds
      ..endTimestamp = Int64.parseInt('490000'); // ended after 8 minutes

    final String timeTaskInfoString = 'Attempts: ${timeTask.attempts}\n'
        'Run time: 8 minutes\n'
        'Queue time: 10 seconds\n'
        'Flaky: true';

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TestGrid(
            task: timeTask,
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

  testWidgets('TaskOverlay devicelab agent button redirects to agent page', (WidgetTester tester) async {
    final Task expectedTask = Task()
      ..attempts = 3
      ..stageName = 'devicelab'
      ..name = 'Tasky McTaskFace'
      ..reservedForAgentId = 'Agenty McAgentFace'
      ..reason = 'Because I said so'
      ..isFlaky = false
      ..status = 'Succeeded';

    await tester.pumpWidget(
      FakeInserter(
        child: MaterialApp(
          home: Scaffold(
            body: TestGrid(
              task: expectedTask,
            ),
          ),
          routes: <String, WidgetBuilder>{
            AgentDashboardPage.routeName: (BuildContext context) => const AgentDashboardPage(),
          },
        ),
      ),
    );

    // The AppBar title for the agent page
    expect(find.text('Infra Agents'), findsNothing);
    expect(find.text('SHOW ${expectedTask.reservedForAgentId}'), findsNothing);
    expect(find.text(expectedTask.reservedForAgentId), findsNothing);

    await tester.tapAt(const Offset(TaskBox.cellSize * 1.5, TaskBox.cellSize * 1.5));
    await tester.pump();

    expect(find.text('Infra Agents'), findsNothing);
    expect(find.text('SHOW ${expectedTask.reservedForAgentId}'), findsOneWidget);
    expect(find.text(expectedTask.reservedForAgentId), findsNothing);

    await tester.tap(find.text('SHOW ${expectedTask.reservedForAgentId}'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Infra Agents'), findsOneWidget);
    expect(find.text('SHOW ${expectedTask.reservedForAgentId}'), findsNothing);
    // We check that the agent is filtered correctly, which tests if
    // the route argument was parsed correctly, by looking for the
    // text field that contains the search pattern. (The actual agent
    // isn't listed because we don't set up the test data with any
    // agents.)
    expect(find.widgetWithText(TextField, expectedTask.reservedForAgentId), findsOneWidget);
  });

  testWidgets('TaskOverlay shows the right message for nondevicelab tasks', (WidgetTester tester) async {
    await precacheTaskIcons(tester);
    const String expectedTaskInfoString = 'Task was run outside of devicelab';
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TestGrid(
            task: Task()
              ..stageName = 'cirrus'
              ..status = 'Succeeded',
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text(expectedTaskInfoString), findsNothing);
    await expectLater(find.byType(MaterialApp), matchesGoldenFile('task_overlay_test.nondevicelab_closed.png'));

    await tester.tapAt(const Offset(TaskBox.cellSize * 1.5, TaskBox.cellSize * 1.5));
    await tester.pump();

    expect(find.text(expectedTaskInfoString), findsOneWidget);
    await expectLater(find.byType(MaterialApp), matchesGoldenFile('task_overlay_test.nondevicelab_open.png'));
  });

  testWidgets('TaskOverlay shows TaskAttemptSummary for devicelab tasks', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TestGrid(
            task: Task()
              ..stageName = 'devicelab'
              ..status = 'Succeeded'
              ..attempts = 1,
          ),
        ),
      ),
    );

    expect(find.byType(TaskAttemptSummary), findsNothing);

    await tester.tapAt(const Offset(TaskBox.cellSize * 1.5, TaskBox.cellSize * 1.5));
    await tester.pump();

    expect(find.byType(TaskAttemptSummary), findsOneWidget);
  });

  testWidgets('TaskOverlay shows TaskAttemptSummary for Luci tasks', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TestGrid(
            task: Task()
              ..stageName = 'chromebot'
              ..status = 'Succeeded'
              ..buildNumberList = '123',
          ),
        ),
      ),
    );

    expect(find.byType(LuciTaskAttemptSummary), findsNothing);

    await tester.tapAt(const Offset(TaskBox.cellSize * 1.5, TaskBox.cellSize * 1.5));
    await tester.pump();

    expect(find.byType(LuciTaskAttemptSummary), findsOneWidget);
  });

  testWidgets('TaskOverlay does not show TaskAttemptSummary for tasks outside of devicelab',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TestGrid(
            task: Task()
              ..stageName = 'cirrus'
              ..status = 'Succeeded'
              ..attempts = 1,
          ),
        ),
      ),
    );

    expect(find.byType(TaskAttemptSummary), findsNothing);

    await tester.tapAt(const Offset(TaskBox.cellSize * 1.5, TaskBox.cellSize * 1.5));
    await tester.pump();

    expect(find.byType(TaskAttemptSummary), findsNothing);
  });

  testWidgets('TaskOverlay: successful rerun shows success snackbar message', (WidgetTester tester) async {
    final Task expectedTask = Task()
      ..attempts = 3
      ..stageName = 'devicelab'
      ..name = 'Tasky McTaskFace'
      ..reservedForAgentId = 'Agenty McAgentFace'
      ..reason = 'Because I said so'
      ..isFlaky = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TestGrid(
            buildState: FakeBuildState(rerunTaskResult: true),
            task: expectedTask,
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
      ..stageName = 'devicelab'
      ..name = 'Tasky McTaskFace'
      ..reservedForAgentId = 'Agenty McAgentFace'
      ..reason = 'Because I said so'
      ..isFlaky = false
      ..status = 'New';

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TestGrid(
            buildState: FakeBuildState(rerunTaskResult: false),
            task: expectedTask,
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
      MaterialApp(
        home: Scaffold(
          body: TestGrid(
            task: publicTask,
          ),
        ),
      ),
    );

    // Open the overlay
    await tester.tapAt(const Offset(TaskBox.cellSize * 1.5, TaskBox.cellSize * 1.5));
    await tester.pump();

    // View log
    await tester.tap(find.text('DOWNLOAD ALL LOGS'));
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

  testWidgets('log button calls build state to download devicelab log', (WidgetTester tester) async {
    final Task expectedTask = Task()
      ..attempts = 3
      ..stageName = 'devicelab'
      ..name = 'Tasky McTaskFace'
      ..reservedForAgentId = 'Agenty McAgentFace'
      ..reason = 'Because I said so'
      ..isFlaky = false
      ..status = 'New';

    final MockBuildState buildState = MockBuildState();
    when(buildState.moreStatusesExist).thenReturn(true);
    when(buildState.downloadLog(any, any)).thenAnswer((_) async => true);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TestGrid(
            buildState: buildState,
            task: expectedTask,
          ),
        ),
      ),
    );

    // Open the overlay
    await tester.tapAt(const Offset(TaskBox.cellSize * 1.5, TaskBox.cellSize * 1.5));
    await tester.pump();

    verifyNever(buildState.downloadLog(any, any));

    // Click log button
    await tester.tap(find.text('DOWNLOAD ALL LOGS'));
    await tester.pump();

    verify(buildState.downloadLog(any, any)).called(1);
  });

  testWidgets('failing to download devicelab log shows error snackbar', (WidgetTester tester) async {
    final Task expectedTask = Task()
      ..attempts = 3
      ..stageName = 'devicelab'
      ..name = 'Tasky McTaskFace'
      ..reservedForAgentId = 'Agenty McAgentFace'
      ..reason = 'Because I said so'
      ..isFlaky = false;

    final MockBuildState buildState = MockBuildState();
    when(buildState.moreStatusesExist).thenReturn(true);
    when(buildState.downloadLog(any, any)).thenAnswer((_) async => false);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TestGrid(
            buildState: buildState,
            task: expectedTask,
          ),
        ),
      ),
    );

    // Open the overlay
    await tester.tapAt(const Offset(TaskBox.cellSize * 1.5, TaskBox.cellSize * 1.5));
    await tester.pump();

    // Click log button
    await tester.tap(find.text('DOWNLOAD ALL LOGS'));
    await tester.pump();

    // expect error snackbar to be shown
    await tester.pump(const Duration(milliseconds: 750)); // 750ms open animation

    expect(find.text(TaskOverlayContents.downloadLogErrorMessage), findsOneWidget);

    // Snackbar message should go away after its duration
    await tester.pumpAndSettle(TaskOverlayContents.downloadLogSnackBarDuration); // wait the duration
    await tester.pump(); // schedule animation
    await tester.pump(const Duration(milliseconds: 1500)); // close animation

    expect(find.text(TaskOverlayContents.downloadLogErrorMessage), findsNothing);
  });
}
