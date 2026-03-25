// Copyright 2026 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_common/guard_status.dart';
import 'package:cocoon_common/rpc_model.dart';
import 'package:cocoon_common/task_status.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dashboard/service/cocoon.dart';
import 'package:flutter_dashboard/state/presubmit.dart';
import 'package:flutter_dashboard/widgets/filter_dialog.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';

import '../utils/mocks.mocks.dart';

void main() {
  late PresubmitState presubmitState;
  late MockCocoonService mockCocoonService;
  late MockFirebaseAuthService mockAuthService;

  setUp(() {
    mockCocoonService = MockCocoonService();
    mockAuthService = MockFirebaseAuthService();
    when(mockAuthService.isAuthenticated).thenReturn(false);

    presubmitState = PresubmitState(
      cocoonService: mockCocoonService,
      authService: mockAuthService,
    );

    when(
      mockCocoonService.fetchPresubmitJobDetails(
        checkRunId: anyNamed('checkRunId'),
        jobName: anyNamed('jobName'),
        repo: anyNamed('repo'),
        owner: anyNamed('owner'),
      ),
    ).thenAnswer(
      (_) async => const CocoonResponse<List<PresubmitJobResponse>>.data([]),
    );

    const response = PresubmitGuardResponse(
      prNum: 123,
      author: 'dash',
      guardStatus: GuardStatus.succeeded,
      checkRunId: 456,
      stages: [
        PresubmitGuardStage(
          name: 'stage1',
          createdAt: 0,
          builds: {
            'linux test1': TaskStatus.succeeded,
            'mac test1': TaskStatus.failed,
          },
        ),
      ],
    );
    presubmitState.setGuardResponseForTest(response);
  });

  Future<void> pumpDialog(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ChangeNotifierProvider<PresubmitState>.value(
          value: presubmitState,
          child: const FilterDialog(),
        ),
      ),
    );
  }

  testWidgets('FilterDialog shows all statuses and platforms', (
    WidgetTester tester,
  ) async {
    await pumpDialog(tester);

    expect(find.text('Filter jobs'), findsOneWidget);
    expect(find.text('Status'), findsOneWidget);
    expect(find.text('Platform'), findsOneWidget);

    // Verify statuses
    for (final status in TaskStatus.values) {
      expect(find.text(status.value), findsOneWidget);
    }

    // Verify platforms
    expect(find.text('linux'), findsOneWidget);
    expect(find.text('mac'), findsOneWidget);

    expect(find.text('Show 2 jobs'), findsOneWidget);
  });

  testWidgets('Toggling status updates filtered count', (
    WidgetTester tester,
  ) async {
    await pumpDialog(tester);

    expect(find.text('Show 2 jobs'), findsOneWidget);

    // Unselect Succeeded
    await tester.tap(find.text(TaskStatus.succeeded.value));
    await tester.pump();

    expect(find.text('Show 1 jobs'), findsOneWidget);

    // Select Succeeded back
    await tester.tap(find.text(TaskStatus.succeeded.value));
    await tester.pump();

    expect(find.text('Show 2 jobs'), findsOneWidget);
  });

  testWidgets('Toggling platform updates filtered count', (
    WidgetTester tester,
  ) async {
    await pumpDialog(tester);

    expect(find.text('Show 2 jobs'), findsOneWidget);

    // Unselect linux
    await tester.tap(find.text('linux'));
    await tester.pump();

    expect(find.text('Show 1 jobs'), findsOneWidget);
  });

  testWidgets('Regex filter updates filtered count', (
    WidgetTester tester,
  ) async {
    await pumpDialog(tester);

    expect(find.text('Show 2 jobs'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'test1');
    // Count should update immediately because of onChanged and setState
    await tester.pump();
    expect(find.text('Show 2 jobs'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'linux');
    await tester.pump();
    expect(find.text('Show 1 jobs'), findsOneWidget);
  });

  testWidgets('Regex filter updates filtered count immediately on typing', (
    WidgetTester tester,
  ) async {
    await pumpDialog(tester);

    expect(find.text('Show 2 jobs'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'linux');
    // Count should update immediately because of onChanged
    await tester.pump();
    expect(find.text('Show 1 jobs'), findsOneWidget);

    // Tap on 'Status' label to move focus - should still be 1 job
    await tester.tap(find.text('Status'), warnIfMissed: false);
    await tester.pump();

    expect(find.text('Show 1 jobs'), findsOneWidget);
  });

  testWidgets('Clear all filters resets everything', (
    WidgetTester tester,
  ) async {
    await pumpDialog(tester);

    await tester.tap(find.text('linux'));
    await tester.tap(find.text(TaskStatus.succeeded.value));
    await tester.pump();

    expect(
      find.text('Show 0 jobs'),
      findsNothing,
    ); // Should be 0 if unselected, but we have validation to keep at least one.
    // Actually our validation prevents unselecting the LAST one.
    // If we unselect linux, mac is still there. If we unselect succeeded, failed is still there.
    // 'mac test1' is failed. So it should show 1 job.
    expect(find.text('Show 1 jobs'), findsOneWidget);

    await tester.tap(find.text('Clear all filters'));
    await tester.pump();

    expect(find.text('Show 2 jobs'), findsOneWidget);
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      isEmpty,
    );
  });
}
