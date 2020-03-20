// Copyright (c) 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:fixnum/fixnum.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:mockito/mockito.dart';

import 'package:cocoon_service/protos.dart' show Commit, Task;

import 'package:app_flutter/agent_dashboard_page.dart';
import 'package:app_flutter/state/flutter_build.dart';
import 'package:app_flutter/task_attempt_summary.dart';
import 'package:app_flutter/task_box.dart';
import 'package:app_flutter/task_helper.dart';

import 'utils/mocks.dart';
import 'utils/wrapper.dart';

void main() {
  group('TaskBox', () {
    final Task expectedTask = Task()
      ..attempts = 3
      ..stageName = 'devicelab'
      ..name = 'Tasky McTaskFace'
      ..reservedForAgentId = 'Agenty McAgentFace'
      ..reason = 'Because I said so'
      ..isFlaky = false;
    MockFlutterBuildState buildState;

    setUp(() {
      buildState = MockFlutterBuildState();
    });

    tearDown(() {
      clearInteractions(buildState);
    });

    // Table Driven Approach to ensure every message does show the corresponding color
    TaskBox.statusColor.forEach((String message, Color color) {
      testWidgets('is the color $color when given the message $message', (WidgetTester tester) async {
        expectTaskBoxColorWithMessage(tester, message, color);
      });
    });

    testWidgets('shows loading indicator for In Progress task', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: TaskBox(
            buildState: buildState,
            task: Task()..status = TaskBox.statusInProgress,
            commit: Commit(),
          ),
        ),
      );

      expect(find.byIcon(Icons.timelapse), findsOneWidget);
    });

    testWidgets('show orange when New but already attempted', (WidgetTester tester) async {
      final Task repeatTask = Task()
        ..status = 'New'
        ..attempts = 2;

      await tester.pumpWidget(
        MaterialApp(
          home: TaskBox(
            buildState: buildState,
            task: repeatTask,
            commit: Commit(),
            insertColorKeys: true,
          ),
        ),
      );

      final SizedBox taskBoxWidget = find.byKey(Key(Colors.orange.toString())).evaluate().first.widget as SizedBox;
      expect(taskBoxWidget, isNotNull);
    });

    testWidgets('show loading indicator for In Progress task that is not on first attempt',
        (WidgetTester tester) async {
      final Task repeatTask = Task()
        ..status = 'In Progress'
        ..attempts = 2;

      await tester.pumpWidget(
        MaterialApp(
          home: TaskBox(
            buildState: buildState,
            task: repeatTask,
            commit: Commit(),
            insertColorKeys: true,
          ),
        ),
      );

      final SizedBox taskBoxWidget = find.byKey(Key(Colors.orange.toString())).evaluate().first.widget as SizedBox;
      expect(taskBoxWidget, isNotNull);
      expect(find.byIcon(Icons.timelapse), findsOneWidget);
    });

    testWidgets('shows question mark for task marked flaky', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: TaskBox(
            buildState: buildState,
            task: Task()
              ..status = TaskBox.statusSucceeded
              ..isFlaky = true,
            commit: Commit(),
          ),
        ),
      );

      expect(find.byIcon(Icons.help), findsOneWidget);
    });

    testWidgets('shows question mark and loading indicator for task marked flaky that is in progress',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: TaskBox(
            buildState: buildState,
            task: Task()
              ..status = TaskBox.statusInProgress
              ..isFlaky = true,
            commit: Commit(),
          ),
        ),
      );

      expect(find.byIcon(Icons.timelapse), findsOneWidget);
      expect(find.byIcon(Icons.help), findsOneWidget);
    });

    testWidgets('show yellow when Succeeded but ran multiple times', (WidgetTester tester) async {
      final Task repeatTask = Task()
        ..status = 'Succeeded'
        ..attempts = 2;

      await tester.pumpWidget(
        MaterialApp(
          home: TaskBox(
            buildState: buildState,
            task: repeatTask,
            commit: Commit(),
            insertColorKeys: true,
          ),
        ),
      );

      final SizedBox taskBoxWidget = find.byKey(Key(Colors.yellow.toString())).evaluate().first.widget as SizedBox;
      expect(taskBoxWidget, isNotNull);
    });

    testWidgets('is the color black when given an unknown message', (WidgetTester tester) async {
      expectTaskBoxColorWithMessage(tester, '404', Colors.black);
    });

    testWidgets('shows overlay on click', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TaskBox(
              buildState: buildState,
              task: expectedTask,
              commit: Commit(),
            ),
          ),
        ),
      );

      final String expectedTaskInfoString = 'Attempts: ${expectedTask.attempts}\n'
          'Run time: 0 minutes\n'
          'Queue time: 0 seconds\n'
          'Flaky: ${expectedTask.isFlaky}';
      expect(find.text(expectedTask.name), findsNothing);
      expect(find.text(expectedTaskInfoString), findsNothing);
      expect(find.text(expectedTask.reservedForAgentId), findsNothing);

      // Ensure the task indicator isn't showing when overlay is not shown
      expect(find.byKey(const Key('task-overlay-key')), findsNothing);

      await tester.tap(find.byType(TaskBox));
      await tester.pump();

      expect(find.text(expectedTask.name), findsOneWidget);
      expect(find.text(expectedTaskInfoString), findsOneWidget);
      expect(find.text(expectedTask.reservedForAgentId), findsOneWidget);

      // Since the overlay is on screen, the indicator should be showing
      expect(find.byKey(const Key('task-overlay-key')), findsOneWidget);
    });

    testWidgets('overlay show flaky is true', (WidgetTester tester) async {
      final Task flakyTask = Task()
        ..attempts = 3
        ..stageName = 'devicelab'
        ..name = 'Tasky McTaskFace'
        ..reason = 'Because I said so'
        ..isFlaky = true;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TaskBox(
              buildState: buildState,
              task: flakyTask,
              commit: Commit(),
            ),
          ),
        ),
      );

      final String expectedTaskInfoString = 'Attempts: ${flakyTask.attempts}\n'
          'Run time: 0 minutes\n'
          'Queue time: 0 seconds\n'
          'Flaky: true';
      expect(find.text(expectedTaskInfoString), findsNothing);

      // Ensure the task indicator isn't showing when overlay is not shown
      expect(find.byKey(const Key('task-overlay-key')), findsNothing);

      await tester.tap(find.byType(TaskBox));
      await tester.pump();

      expect(find.text(expectedTaskInfoString), findsOneWidget);
    });

    testWidgets('durations are correct time', (WidgetTester tester) async {
      final Task timeTask = Task()
        ..attempts = 1
        ..stageName = 'devicelab'
        ..name = 'Tasky McTaskFace'
        ..reason = 'Because I said so'
        ..isFlaky = true
        ..createTimestamp = Int64.parseInt('0') // created at 0ms
        ..startTimestamp = Int64.parseInt('10000') // started after 10 seconds
        ..endTimestamp = Int64.parseInt('490000'); // ended after 8 minutes

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TaskBox(
              buildState: buildState,
              task: timeTask,
              commit: Commit(),
            ),
          ),
        ),
      );

      final String expectedTaskInfoString = 'Attempts: ${timeTask.attempts}\n'
          'Run time: 8 minutes\n'
          'Queue time: 10 seconds\n'
          'Flaky: true';
      expect(find.text(expectedTaskInfoString), findsNothing);

      // open the overlay to show the task summary
      await tester.tap(find.byType(TaskBox));
      await tester.pump();

      expect(find.text(expectedTaskInfoString), findsOneWidget);
    });

    testWidgets('devicelab agent button redirects to agent page', (WidgetTester tester) async {
      // TODO(ianh): remove the navigator observer since we don't seem to use it
      final MockNavigatorObserver navigatorObserver = MockNavigatorObserver();

      await tester.pumpWidget(
        FakeInserter(
          child: MaterialApp(
            home: Scaffold(
              body: TaskBox(
                buildState: buildState,
                task: expectedTask,
                commit: Commit(),
              ),
            ),
            navigatorObservers: <NavigatorObserver>[navigatorObserver],
            routes: <String, WidgetBuilder>{
              AgentDashboardPage.routeName: (BuildContext context) => const AgentDashboardPage(),
            },
          ),
        ),
      );

      // The AppBar title for the agent page
      expect(find.text('Infra Agents'), findsNothing);
      expect(find.text(expectedTask.reservedForAgentId), findsNothing);

      await tester.tap(find.byType(TaskBox));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      await tester.tap(find.text(expectedTask.reservedForAgentId));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Infra Agents'), findsOneWidget);
      // Check that the agent is filtered correctly, which tests if the route
      // argument was parsed correctly.
      expect(find.text(expectedTask.reservedForAgentId), findsOneWidget);
    });

    testWidgets('overlay message for nondevicelab tasks', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TaskBox(
              buildState: buildState,
              task: Task()
                ..stageName = 'cirrus'
                ..status = 'Succeeeded',
              commit: Commit(),
            ),
          ),
        ),
      );

      const String expectedTaskInfoString = 'Task was run outside of devicelab';
      expect(find.text(expectedTask.name), findsNothing);
      expect(find.text(expectedTaskInfoString), findsNothing);

      // Ensure the task indicator isn't showing when overlay is not shown
      expect(find.byKey(const Key('task-overlay-key')), findsNothing);

      await tester.tap(find.byType(TaskBox));
      await tester.pump();

      expect(find.text(expectedTaskInfoString), findsOneWidget);
    });

    testWidgets('closes overlay on click out', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TaskBox(
              buildState: buildState,
              task: expectedTask,
              commit: Commit(),
            ),
          ),
        ),
      );

      // Open the overlay
      await tester.tap(find.byType(TaskBox));
      await tester.pump();

      // Since the overlay positions itself in the middle of the widget,
      // it is safe to click the widget to close it again
      await tester.tap(find.byType(TaskBox));
      await tester.pump();

      expect(find.text(expectedTask.name), findsNothing);

      // The task indicator should not show after the overlay has been closed
      expect(find.byKey(const Key('task-overlay-key')), findsNothing);
    });

    testWidgets('overlay shows TaskAttemptSummary for devicelab tasks', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TaskBox(
              buildState: buildState,
              task: Task()
                ..stageName = 'devicelab'
                ..status = 'Succeeeded'
                ..attempts = 1,
              commit: Commit(),
            ),
          ),
        ),
      );

      expect(find.byType(TaskAttemptSummary), findsNothing);

      await tester.tap(find.byType(TaskBox));
      await tester.pump();

      expect(find.byType(TaskAttemptSummary), findsOneWidget);
    });

    testWidgets('overlay does not show TaskAttemptSummary for tasks outside of devicelab', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TaskBox(
              buildState: buildState,
              task: Task()
                ..stageName = 'cirrus'
                ..status = 'Succeeeded'
                ..attempts = 1,
              commit: Commit(),
            ),
          ),
        ),
      );

      expect(find.byType(TaskAttemptSummary), findsNothing);

      await tester.tap(find.byType(TaskBox));
      await tester.pump();

      expect(find.byType(TaskAttemptSummary), findsNothing);
    });

    testWidgets('successful rerun shows success snackbar message', (WidgetTester tester) async {
      when(buildState.rerunTask(any)).thenAnswer((_) => Future<bool>.value(true));
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TaskBox(
              buildState: buildState,
              task: expectedTask,
              commit: Commit(),
            ),
          ),
        ),
      );

      // Open the overlay
      await tester.tap(find.byType(TaskBox));
      await tester.pump();

      expect(find.text(TaskOverlayContents.rerunSuccessMessage), findsNothing);

      // Click the rerun task button
      await tester.tap(find.text('Rerun'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 750)); // 750ms open animation

      expect(find.text(TaskOverlayContents.rerunSuccessMessage), findsOneWidget);

      // Snackbar message should go away after its duration
      await tester.pumpAndSettle(TaskOverlayContents.rerunSnackbarDuration); // wait the duration
      await tester.pump(); // schedule animation
      await tester.pump(const Duration(milliseconds: 1500)); // close animation

      expect(find.text(TaskOverlayContents.rerunSuccessMessage), findsNothing);
    });

    testWidgets('failed rerun shows error snackbar message', (WidgetTester tester) async {
      when(buildState.rerunTask(any)).thenAnswer((_) => Future<bool>.value(false));
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TaskBox(
              buildState: buildState,
              task: expectedTask,
              commit: Commit(),
            ),
          ),
        ),
      );

      // Open the overlay
      await tester.tap(find.byType(TaskBox));
      await tester.pump();

      expect(find.text(TaskOverlayContents.rerunErrorMessage), findsNothing);
      expect(find.text(TaskOverlayContents.rerunSuccessMessage), findsNothing);

      // Click the rerun task button
      await tester.tap(find.text('Rerun'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 750)); // 750ms open animation

      expect(find.text(TaskOverlayContents.rerunSuccessMessage), findsNothing);
      expect(find.text(TaskOverlayContents.rerunErrorMessage), findsOneWidget);

      // Snackbar message should go away after its duration
      await tester.pumpAndSettle(TaskOverlayContents.rerunSnackbarDuration); // wait the duration
      await tester.pump(); // schedule animation
      await tester.pump(const Duration(milliseconds: 1500)); // close animation

      expect(find.text(TaskOverlayContents.rerunErrorMessage), findsNothing);
    });

    testWidgets('log button opens log url for public log', (WidgetTester tester) async {
      const MethodChannel channel = MethodChannel('plugins.flutter.io/url_launcher');
      final List<MethodCall> log = <MethodCall>[];
      channel.setMockMethodCallHandler((MethodCall methodCall) async {
        log.add(methodCall);
      });
      final Task publicTask = Task()..stageName = 'cirrus';
      final Commit commit = Commit()..sha = 'github123';
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TaskBox(
              buildState: buildState,
              task: publicTask,
              commit: commit,
            ),
          ),
        ),
      );

      // Open the overlay
      await tester.tap(find.byType(TaskBox));
      await tester.pump();

      // View log
      await tester.tap(find.text('Log'));
      await tester.pump();

      expect(
        log,
        <Matcher>[
          isMethodCall('launch', arguments: <String, Object>{
            'url': logUrl(publicTask, commit: commit),
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
      when(buildState.downloadLog(any, any)).thenAnswer((_) => Future<bool>.value(true));
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TaskBox(
              buildState: buildState,
              task: expectedTask,
              commit: Commit(),
            ),
          ),
        ),
      );

      // Open the overlay
      await tester.tap(find.byType(TaskBox));
      await tester.pump();

      verifyNever(buildState.downloadLog(any, any));

      // Click log button
      await tester.tap(find.text('Log'));
      await tester.pump();

      verify(buildState.downloadLog(any, any)).called(1);
    });

    testWidgets('failing to download devicelab log shows error snackbar', (WidgetTester tester) async {
      when(buildState.downloadLog(any, any)).thenAnswer((_) => Future<bool>.value(false));
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TaskBox(
              buildState: buildState,
              task: expectedTask,
              commit: Commit(),
            ),
          ),
        ),
      );

      // Open the overlay
      await tester.tap(find.byType(TaskBox));
      await tester.pump();

      // Click log button
      await tester.tap(find.text('Log'));
      await tester.pump();

      // expect error snackbar to be shown
      await tester.pump(const Duration(milliseconds: 750)); // 750ms open animation

      expect(find.text(TaskOverlayContents.downloadLogErrorMessage), findsOneWidget);

      // Snackbar message should go away after its duration
      await tester.pumpAndSettle(TaskOverlayContents.downloadLogSnackbarDuration); // wait the duration
      await tester.pump(); // schedule animation
      await tester.pump(const Duration(milliseconds: 1500)); // close animation

      expect(find.text(TaskOverlayContents.downloadLogErrorMessage), findsNothing);
    });
  });
}

Future<void> expectTaskBoxColorWithMessage(WidgetTester tester, String message, Color expectedColor) async {
  await tester.pumpWidget(
    MaterialApp(
      home: TaskBox(
        buildState: FlutterBuildState(
          authService: MockGoogleSignInService(),
          cocoonService: MockCocoonService(),
        ),
        task: Task()..status = message,
        commit: Commit(),
        insertColorKeys: true,
      ),
    ),
  );

  final SizedBox taskBoxWidget = find.byKey(Key(expectedColor.toString())).evaluate().first.widget as SizedBox;
  expect(taskBoxWidget, isNotNull);
}

/// Class for testing interactions on [NavigatorObserver].
class MockNavigatorObserver extends Mock implements NavigatorObserver {}
