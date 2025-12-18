// Copyright 2025 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_common/rpc_model.dart';
import 'package:cocoon_common/task_status.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dashboard/logic/qualified_task.dart';
import 'package:flutter_dashboard/widgets/test_details_popover.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import '../utils/fake_build.dart';
import '../utils/generate_task_for_tests.dart';
import '../utils/mocks.dart';

void main() {
  group('TestDetailsPopover', () {
    late FakeBuildState buildState;
    late QualifiedTask task;
    late MockFirebaseAuthService authService;

    setUp(() {
      authService = MockFirebaseAuthService();
      when(authService.isAuthenticated).thenReturn(true);

      buildState = FakeBuildState(authService: authService);
      task = QualifiedTask.fromTask(
        generateTaskForTest(
          builderName: 'linux_android',
          status: TaskStatus.succeeded,
        ),
      );
    });

    testWidgets('shows task name', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TestDetailsPopover(
              qualifiedTask: task,
              buildState: buildState,
              showSnackBarCallback: (_) {},
              closeCallback: () {},
            ),
          ),
        ),
      );

      expect(find.text('linux_android'), findsOneWidget);
      expect(find.text('Source Config'), findsOneWidget);
    });

    testWidgets('shows Unblock Tree button when not suppressed', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TestDetailsPopover(
              qualifiedTask: task,
              buildState: buildState,
              showSnackBarCallback: (_) {},
              closeCallback: () {},
            ),
          ),
        ),
      );

      expect(find.text('Unblock Tree'), findsOneWidget);
      expect(find.text('Include Test in Tree'), findsNothing);
    });

    final suppressedTest = SuppressedTest(
      name: 'linux_android',
      repository: 'flutter/flutter',
      issueLink: 'url',
      createTimestamp: 123,
    );

    testWidgets('shows Include Test in Tree button when suppressed', (
      WidgetTester tester,
    ) async {
      buildState.suppressedTests = [suppressedTest];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TestDetailsPopover(
              qualifiedTask: task,
              buildState: buildState,
              showSnackBarCallback: (_) {},
              closeCallback: () {},
            ),
          ),
        ),
      );

      expect(find.text('Include Test in Tree'), findsOneWidget);
      expect(find.text('Unblock Tree'), findsNothing);
    });

    testWidgets('Include Test button unsuppresses test', (
      WidgetTester tester,
    ) async {
      buildState.suppressedTests = [suppressedTest];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TestDetailsPopover(
              qualifiedTask: task,
              buildState: buildState,
              showSnackBarCallback: (_) {},
              closeCallback: () {},
            ),
          ),
        ),
      );

      await tester.tap(find.text('Include Test in Tree'));
      await tester.pump();

      expect(buildState.updateTestSuppressionCalls, isNotEmpty);
      expect(
        buildState.updateTestSuppressionCalls.single.testName,
        'linux_android',
      );
      expect(buildState.updateTestSuppressionCalls.single.suppress, false);
    });

    testWidgets('Unblock Tree flow works with dialog', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TestDetailsPopover(
              qualifiedTask: task,
              buildState: buildState,
              showSnackBarCallback: (_) {},
              closeCallback: () {},
            ),
          ),
        ),
      );

      // Tap Unblock Tree
      await tester.tap(find.text('Unblock Tree'));
      await tester.pumpAndSettle();

      expect(find.text('Issue Link (Required)'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('Unblock Tree'),
        ),
        findsAtLeastNWidgets(1), // Title and maybe button
      );

      // Try to submit empty (clear default first)
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Issue Link (Required)'),
        '',
      );
      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.widgetWithText(ElevatedButton, 'Unblock Tree'),
        ),
      );
      await tester.pump();
      expect(find.text('Please enter an issue link'), findsOneWidget);

      // Enter invalid URL
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Issue Link (Required)'),
        'not a url',
      );
      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.widgetWithText(ElevatedButton, 'Unblock Tree'),
        ),
      );
      await tester.pump();
      expect(find.text('Please enter a valid URL'), findsOneWidget);

      // Enter valid match
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Issue Link (Required)'),
        'https://github.com/flutter/flutter/issues/1234',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Note (Optional)'),
        'Flaky test',
      );

      // Tap the Unblock Tree button inside the dialog
      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.widgetWithText(ElevatedButton, 'Unblock Tree'),
        ),
      );
      await tester.pumpAndSettle();

      expect(buildState.updateTestSuppressionCalls, isNotEmpty);
      final call = buildState.updateTestSuppressionCalls.single;
      expect(call.testName, 'linux_android');
      expect(call.suppress, true);
      expect(call.issueLink, 'https://github.com/flutter/flutter/issues/1234');
      expect(call.note, 'Flaky test');
    });
    testWidgets('shows error snackbar when update fails', (
      WidgetTester tester,
    ) async {
      buildState.updateTestSuppressionResult = false;
      buildState.suppressedTests = [suppressedTest];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TestDetailsPopover(
              qualifiedTask: task,
              buildState: buildState,
              showSnackBarCallback: (SnackBar snackBar) {
                ScaffoldMessenger.of(
                  tester.element(find.byType(Scaffold)),
                ).showSnackBar(snackBar);
              },
              closeCallback: () {},
            ),
          ),
        ),
      );

      // Tap Include Test
      await tester.tap(find.text('Include Test in Tree'));
      await tester.pump(); // Start async call
      await tester.pump(); // Resolve async call and show snackbar

      expect(find.text('Failed to update test suppression'), findsOneWidget);
    });
  });
}
