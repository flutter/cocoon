// Copyright (c) 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:mockito/mockito.dart';

import 'package:cocoon_service/protos.dart' show Task;

import 'package:app_flutter/service/google_authentication.dart';
import 'package:app_flutter/state/flutter_build.dart';
import 'package:app_flutter/task_box.dart';
import 'package:app_flutter/task_helper.dart';

void main() {
  group('TaskBox', () {
    final Task expectedTask = Task()
      ..attempts = 3
      ..stageName = 'devicelab'
      ..name = 'Tasky McTaskFace'
      ..reason = 'Because I said so';
    FlutterBuildState buildState;

    setUpAll(() {
      buildState = MockFlutterBuildState();
    });

    // Table Driven Approach to ensure every message does show the corresponding color
    TaskBox.statusColor.forEach((String message, Color color) {
      testWidgets('is the color $color when given the message $message',
          (WidgetTester tester) async {
        expectTaskBoxColorWithMessage(tester, message, color);
      });
    });

    testWidgets('shows loading indicator for In Progress task',
        (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
          home: TaskBox(
              buildState: buildState,
              task: Task()..status = TaskBox.statusInProgress)));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('show orange when New but already attempted',
        (WidgetTester tester) async {
      final Task repeatTask = Task()
        ..status = 'New'
        ..attempts = 2;

      await tester.pumpWidget(
          MaterialApp(home: TaskBox(buildState: buildState, task: repeatTask)));

      final Container taskBoxWidget =
          find.byType(Container).evaluate().first.widget;
      final BoxDecoration decoration = taskBoxWidget.decoration;
      expect(decoration.color, Colors.orange);
    });

    testWidgets(
        'show loading indicator for In Progress task that is not on first attempt',
        (WidgetTester tester) async {
      final Task repeatTask = Task()
        ..status = 'In Progress'
        ..attempts = 2;

      await tester.pumpWidget(
          MaterialApp(home: TaskBox(buildState: buildState, task: repeatTask)));

      final Container taskBoxWidget =
          find.byType(Container).evaluate().first.widget;
      final BoxDecoration decoration = taskBoxWidget.decoration;
      expect(decoration.color, Colors.orange);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows question mark for task marked flaky',
        (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
          home: TaskBox(
              buildState: buildState,
              task: Task()
                ..status = TaskBox.statusSucceeded
                ..isFlaky = true)));

      expect(find.byIcon(Icons.help), findsOneWidget);
    });

    testWidgets(
        'shows question mark and loading indicator for task marked flaky that is in progress',
        (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
          home: TaskBox(
              buildState: buildState,
              task: Task()
                ..status = TaskBox.statusInProgress
                ..isFlaky = true)));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byIcon(Icons.help), findsOneWidget);
    });

    testWidgets('show yellow when Succeeded but ran multiple times',
        (WidgetTester tester) async {
      final Task repeatTask = Task()
        ..status = 'Succeeded'
        ..attempts = 2;

      await tester.pumpWidget(
          MaterialApp(home: TaskBox(buildState: buildState, task: repeatTask)));

      final Container taskBoxWidget =
          find.byType(Container).evaluate().first.widget;
      final BoxDecoration decoration = taskBoxWidget.decoration;
      expect(decoration.color, Colors.yellow);
    });

    testWidgets('is the color black when given an unknown message',
        (WidgetTester tester) async {
      expectTaskBoxColorWithMessage(tester, '404', Colors.black);
    });

    testWidgets('shows overlay on click', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TaskBox(
              buildState: buildState,
              task: expectedTask,
            ),
          ),
        ),
      );

      final String expectedTaskInfoString =
          'Attempts: ${expectedTask.attempts}\nDuration: 0 seconds\nAgent: ${expectedTask.reservedForAgentId}';
      expect(find.text(expectedTask.name), findsNothing);
      expect(find.text(expectedTaskInfoString), findsNothing);

      // Ensure the task indicator isn't showing when overlay is not shown
      expect(find.byKey(const Key('task-overlay-key')), findsNothing);

      await tester.tap(find.byType(TaskBox));
      await tester.pump();

      expect(find.text(expectedTask.name), findsOneWidget);
      expect(find.text(expectedTaskInfoString), findsOneWidget);

      // Since the overlay is on screen, the indicator should be showing
      expect(find.byKey(const Key('task-overlay-key')), findsOneWidget);
    });

    testWidgets('closes overlay on click out', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TaskBox(
              buildState: buildState,
              task: expectedTask,
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

    testWidgets('successful rerun shows success snackbar message',
        (WidgetTester tester) async {
      when(buildState.rerunTask(any))
          .thenAnswer((_) => Future<bool>.value(true));
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TaskBox(
              buildState: buildState,
              task: expectedTask,
            ),
          ),
        ),
      );

      // Open the overlay
      await tester.tap(find.byType(TaskBox));
      await tester.pump();

      expect(find.text(TaskOverlayContents.rerunSuccessMessage), findsNothing);

      // Click the rerun task button
      await tester.tap(find.text('Rerun task'));
      await tester.pump();
      await tester
          .pump(const Duration(milliseconds: 750)); // 750ms open animation

      expect(
          find.text(TaskOverlayContents.rerunSuccessMessage), findsOneWidget);

      // Snackbar message should go away after its duration
      await tester.pumpAndSettle(
          TaskOverlayContents.rerunSnackbarDuration); // wait the duration
      await tester.pump(); // schedule animation
      await tester.pump(const Duration(milliseconds: 1500)); // close animation

      expect(find.text(TaskOverlayContents.rerunSuccessMessage), findsNothing);
    });

    testWidgets('failed rerun shows error snackbar message',
        (WidgetTester tester) async {
      when(buildState.rerunTask(any))
          .thenAnswer((_) => Future<bool>.value(false));
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TaskBox(
              buildState: buildState,
              task: expectedTask,
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
      await tester.tap(find.text('Rerun task'));
      await tester.pump();
      await tester
          .pump(const Duration(milliseconds: 750)); // 750ms open animation

      expect(find.text(TaskOverlayContents.rerunSuccessMessage), findsNothing);
      expect(find.text(TaskOverlayContents.rerunErrorMessage), findsOneWidget);

      // Snackbar message should go away after its duration
      await tester.pumpAndSettle(
          TaskOverlayContents.rerunSnackbarDuration); // wait the duration
      await tester.pump(); // schedule animation
      await tester.pump(const Duration(milliseconds: 1500)); // close animation

      expect(find.text(TaskOverlayContents.rerunErrorMessage), findsNothing);
    });

    testWidgets('view log button opens log url for public log',
        (WidgetTester tester) async {
      const MethodChannel channel =
          MethodChannel('plugins.flutter.io/url_launcher');
      final List<MethodCall> log = <MethodCall>[];
      channel.setMockMethodCallHandler((MethodCall methodCall) async {
        log.add(methodCall);
      });
      final Task publicTask = Task()..stageName = 'cirrus';
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TaskBox(
              buildState: buildState,
              task: publicTask,
            ),
          ),
        ),
      );

      // Open the overlay
      await tester.tap(find.byType(TaskBox));
      await tester.pump();

      // View log
      await tester.tap(find.text('View log'));
      await tester.pump();

      expect(
        log,
        <Matcher>[
          isMethodCall('launch', arguments: <String, Object>{
            'url': logUrl(publicTask),
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

    testWidgets('view log button opens log url for devicelab log',
        (WidgetTester tester) async {
      const MethodChannel channel =
          MethodChannel('plugins.flutter.io/url_launcher');
      final List<MethodCall> log = <MethodCall>[];
      channel.setMockMethodCallHandler((MethodCall methodCall) async {
        log.add(methodCall);
      });

      final GoogleSignInService mockAuth = MockGoogleSignInService();
      when(mockAuth.accessToken).thenReturn('abc123');
      when(buildState.authService).thenReturn(mockAuth);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TaskBox(
              buildState: buildState,
              task: expectedTask,
            ),
          ),
        ),
      );

      // Open the overlay
      await tester.tap(find.byType(TaskBox));
      await tester.pump();

      // View log
      await tester.tap(find.text('View log'));
      await tester.pump();

      expect(
        log,
        <Matcher>[
          isMethodCall('launch', arguments: <String, Object>{
            'url': logUrl(expectedTask),
            'useSafariVC': true,
            'useWebView': false,
            'enableJavaScript': false,
            'enableDomStorage': false,
            'universalLinksOnly': false,
            'headers': <String, String>{
              'X-Flutter-AccessToken': 'abc123',
            }
          })
        ],
      );
    });
  });
}

Future<void> expectTaskBoxColorWithMessage(
    WidgetTester tester, String message, Color expectedColor) async {
  await tester.pumpWidget(
    MaterialApp(
      home: TaskBox(
        buildState: FlutterBuildState(),
        task: Task()..status = message,
      ),
    ),
  );

  final Container taskBoxWidget =
      find.byType(Container).evaluate().first.widget;
  final BoxDecoration decoration = taskBoxWidget.decoration;
  expect(decoration.color, expectedColor);
}

class MockFlutterBuildState extends Mock implements FlutterBuildState {}

class MockGoogleSignInService extends Mock implements GoogleSignInService {}
