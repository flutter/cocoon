// Copyright 2026 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_common/guard_status.dart';
import 'package:cocoon_common/rpc_model.dart';
import 'package:cocoon_common/task_status.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app_icons/flutter_app_icons_platform_interface.dart';
import 'package:flutter_dashboard/service/cocoon.dart';
import 'package:flutter_dashboard/state/build.dart';
import 'package:flutter_dashboard/state/presubmit.dart';
import 'package:flutter_dashboard/views/presubmit_view.dart';
import 'package:flutter_dashboard/widgets/filter_dialog.dart';
import 'package:flutter_dashboard/widgets/state_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import '../utils/fake_flutter_app_icons.dart';
import '../utils/mocks.dart';

void main() {
  late MockCocoonService mockCocoonService;
  late MockFirebaseAuthService mockAuthService;
  late BuildState buildState;
  late PresubmitState presubmitState;

  setUp(() {
    mockCocoonService = MockCocoonService();
    mockAuthService = MockFirebaseAuthService();

    FlutterAppIconsPlatform.instance = FakeFlutterAppIcons();

    when(mockAuthService.user).thenReturn(null);
    when(mockAuthService.isAuthenticated).thenReturn(false);
    when(mockAuthService.idToken).thenAnswer((_) async => 'fakeToken');

    when(
      mockCocoonService.fetchFlutterBranches(),
    ).thenAnswer((_) async => const CocoonResponse.data([]));
    when(
      mockCocoonService.fetchRepos(),
    ).thenAnswer((_) async => const CocoonResponse.data([]));
    when(
      mockCocoonService.fetchCommitStatuses(
        branch: anyNamed('branch'),
        repo: anyNamed('repo'),
      ),
    ).thenAnswer((_) async => const CocoonResponse.data([]));
    when(
      mockCocoonService.fetchTreeBuildStatus(
        branch: anyNamed('branch'),
        repo: anyNamed('repo'),
      ),
    ).thenAnswer(
      (_) async => CocoonResponse.data(
        BuildStatusResponse(buildStatus: BuildStatus.success, failingTasks: []),
      ),
    );
    when(
      mockCocoonService.fetchSuppressedTests(repo: anyNamed('repo')),
    ).thenAnswer((_) async => const CocoonResponse.data([]));

    when(
      mockCocoonService.fetchPresubmitGuardSummaries(
        repo: anyNamed('repo'),
        pr: anyNamed('pr'),
      ),
    ).thenAnswer(
      (_) async => const CocoonResponse.data([
        PresubmitGuardSummary(
          commitSha: 'abc',
          creationTime: 123,
          guardStatus: GuardStatus.succeeded,
        ),
      ]),
    );

    when(
      mockCocoonService.fetchPresubmitCheckDetails(
        checkRunId: anyNamed('checkRunId'),
        buildName: anyNamed('buildName'),
        repo: anyNamed('repo'),
        owner: anyNamed('owner'),
      ),
    ).thenAnswer((_) async => const CocoonResponse.data([]));

    buildState = BuildState(
      cocoonService: mockCocoonService,
      authService: mockAuthService,
    );

    presubmitState = PresubmitState(
      cocoonService: mockCocoonService,
      authService: mockAuthService,
    );
  });

  Widget createPreSubmitView(Map<String, String> queryParameters) {
    presubmitState.syncUpdate(
      repo: queryParameters['repo'],
      pr: queryParameters['pr'],
      sha: queryParameters['sha'],
    );
    return Material(
      child: StateProvider(
        buildState: buildState,
        presubmitState: presubmitState,
        signInService: mockAuthService,
        child: MaterialApp(
          home: PreSubmitView(
            queryParameters: queryParameters,
            syncNavigation: false,
          ),
        ),
      ),
    );
  }

  testWidgets('PreSubmitView shows filter button and opens dialog', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(2000, 1080);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const guardResponse = PresubmitGuardResponse(
      prNum: 123,
      author: 'dash',
      guardStatus: GuardStatus.succeeded,
      checkRunId: 456,
      stages: [
        PresubmitGuardStage(
          name: 'stage1',
          createdAt: 0,
          builds: {'linux test': TaskStatus.succeeded},
        ),
      ],
    );

    when(
      mockCocoonService.fetchPresubmitGuard(repo: 'flutter', sha: 'abc'),
    ).thenAnswer((_) async => const CocoonResponse.data(guardResponse));

    await tester.runAsync(() async {
      await tester.pumpWidget(
        createPreSubmitView({'repo': 'flutter', 'sha': 'abc'}),
      );
      for (var i = 0; i < 50; i++) {
        await tester.pump();
        await Future<void>.delayed(const Duration(milliseconds: 50));
        if (find.byIcon(Icons.filter_alt_outlined).evaluate().isNotEmpty) break;
      }
    });
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.filter_alt_outlined), findsOneWidget);

    await tester.tap(find.byIcon(Icons.filter_alt_outlined));
    await tester.pumpAndSettle();

    expect(find.byType(FilterDialog), findsOneWidget);
  });

  testWidgets('Applying filters in dialog updates PreSubmitView sidebar', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(2000, 1080);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const guardResponse = PresubmitGuardResponse(
      prNum: 123,
      author: 'dash',
      guardStatus: GuardStatus.succeeded,
      checkRunId: 456,
      stages: [
        PresubmitGuardStage(
          name: 'stage1',
          createdAt: 0,
          builds: {
            'linux test': TaskStatus.succeeded,
            'mac test': TaskStatus.failed,
          },
        ),
      ],
    );

    when(
      mockCocoonService.fetchPresubmitGuard(repo: 'flutter', sha: 'abc'),
    ).thenAnswer((_) async => const CocoonResponse.data(guardResponse));

    await tester.runAsync(() async {
      await tester.pumpWidget(
        createPreSubmitView({'repo': 'flutter', 'sha': 'abc'}),
      );
      for (var i = 0; i < 50; i++) {
        await tester.pump();
        await Future<void>.delayed(const Duration(milliseconds: 50));
        if (find.text('linux test').evaluate().isNotEmpty) break;
      }
    });
    await tester.pumpAndSettle();

    expect(find.text('linux test'), findsOneWidget);
    expect(find.text('mac test'), findsOneWidget);

    // Open filter dialog
    await tester.tap(find.byIcon(Icons.filter_alt_outlined));
    await tester.pumpAndSettle();

    // Filter by platform 'mac' (unselect linux)
    await tester.tap(find.text('linux'));
    await tester.pump();

    // Close dialog
    await tester.tap(find.textContaining('Show 1 jobs'));
    await tester.pumpAndSettle();

    expect(find.text('linux test'), findsNothing);
    expect(find.text('mac test'), findsOneWidget);
    expect(find.byIcon(Icons.filter_alt), findsOneWidget);
  });
}
