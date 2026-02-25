// Copyright 2019 The Flutter Authors. All rights reserved.
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
import 'package:flutter_dashboard/widgets/sha_selector.dart';
import 'package:flutter_dashboard/widgets/state_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';

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
          commitSha: 'decaf_3_real_sha',
          creationTime: 123456789,
          guardStatus: GuardStatus.succeeded,
        ),
        PresubmitGuardSummary(
          commitSha: 'face5_2_mock_sha',
          creationTime: 123456789,
          guardStatus: GuardStatus.failed,
        ),
        PresubmitGuardSummary(
          commitSha: 'cafe5_1_mock_sha',
          creationTime: 123456789,
          guardStatus: GuardStatus.inProgress,
        ),
      ]),
    );

    when(
      mockCocoonService.fetchPresubmitGuard(
        repo: anyNamed('repo'),
        sha: anyNamed('sha'),
      ),
    ).thenAnswer(
      (_) async => const CocoonResponse.error('Not found', statusCode: 404),
    );

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

  testWidgets(
    'PreSubmitView displays correct title and status with repo and sha',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(2000, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      const guardResponse = PresubmitGuardResponse(
        prNum: 123,
        author: 'dash',
        guardStatus: GuardStatus.succeeded,
        checkRunId: 456,
        stages: [],
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
          if (find.textContaining('by dash').evaluate().isNotEmpty) break;
        }
      });
      await tester.pumpAndSettle();

      expect(find.textContaining('PR #123 by dash (abc)'), findsOneWidget);
      expect(find.textContaining('Succeeded'), findsOneWidget);
    },
  );

  testWidgets('PreSubmitView displays mocked data and switches tabs', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(2000, 1080);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const mockSha = 'decaf_3_real_sha';
    const guardResponse = PresubmitGuardResponse(
      prNum: 123,
      author: 'dash',
      guardStatus: GuardStatus.failed,
      checkRunId: 456,
      stages: [
        PresubmitGuardStage(
          name: 'Engine',
          createdAt: 0,
          builds: {'Mac mac_host_engine 1': TaskStatus.failed},
        ),
      ],
    );

    when(
      mockCocoonService.fetchPresubmitGuard(
        repo: anyNamed('repo'),
        sha: mockSha,
      ),
    ).thenAnswer((_) async => const CocoonResponse.data(guardResponse));

    when(
      mockCocoonService.fetchPresubmitCheckDetails(
        checkRunId: anyNamed('checkRunId'),
        buildName: argThat(contains('mac_host_engine'), named: 'buildName'),
      ),
    ).thenAnswer(
      (_) async => CocoonResponse.data([
        PresubmitCheckResponse(
          attemptNumber: 1,
          buildName: 'Mac mac_host_engine 1',
          creationTime: 0,
          status: 'Succeeded',
          summary: 'All tests passed (452/452)',
        ),
        PresubmitCheckResponse(
          attemptNumber: 2,
          buildName: 'Mac mac_host_engine 1',
          creationTime: 0,
          status: 'Failed',
          summary: 'Test failed: Unit Tests',
        ),
      ]),
    );

    await tester.runAsync(() async {
      await tester.pumpWidget(
        createPreSubmitView({'repo': 'flutter', 'pr': '123'}),
      );
      for (var i = 0; i < 50; i++) {
        await tester.pump();
        await Future<void>.delayed(const Duration(milliseconds: 50));
        if (find.textContaining('by dash').evaluate().isNotEmpty) break;
      }
    });
    await tester.pumpAndSettle();

    expect(find.textContaining('PR #123'), findsOneWidget);

    await tester.tap(find.textContaining('mac_host_engine').first);
    await tester.runAsync(() async {
      for (var i = 0; i < 50; i++) {
        await tester.pump();
        await Future<void>.delayed(const Duration(milliseconds: 50));
        if (find.textContaining('All tests passed').evaluate().isNotEmpty) {
          break;
        }
      }
    });
    await tester.pumpAndSettle();

    expect(find.textContaining('All tests passed'), findsOneWidget);
    expect(find.textContaining('Status: Succeeded'), findsOneWidget);

    await tester.tap(find.text('#2'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Test failed: Unit Tests'), findsOneWidget);
    expect(find.textContaining('Status: Failed'), findsOneWidget);
  });

  testWidgets(
    'PreSubmitView automatically selects latest SHA and updates sidebar when opened with PR only',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(2000, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      const latestSha = 'decaf_3_real_sha';
      const guardResponse = PresubmitGuardResponse(
        prNum: 123,
        author: 'dash',
        guardStatus: GuardStatus.failed,
        checkRunId: 456,
        stages: [
          PresubmitGuardStage(
            name: 'Engine',
            createdAt: 0,
            builds: {'Mac mac_host_engine 1': TaskStatus.failed},
          ),
        ],
      );

      when(
        mockCocoonService.fetchPresubmitGuard(
          repo: anyNamed('repo'),
          sha: latestSha,
        ),
      ).thenAnswer((_) async => const CocoonResponse.data(guardResponse));

      await tester.runAsync(() async {
        await tester.pumpWidget(
          createPreSubmitView({'repo': 'flutter', 'pr': '123'}),
        );
        // Wait for summaries, then latest SHA selection, then guard status fetch
        for (var i = 0; i < 50; i++) {
          await tester.pump();
          await Future<void>.delayed(const Duration(milliseconds: 50));
          final state = Provider.of<PresubmitState>(
            tester.element(find.byType(PreSubmitView)),
            listen: false,
          );
          if (state.guardResponse != null) break;
        }
      });
      await tester.pumpAndSettle();

      final state = Provider.of<PresubmitState>(
        tester.element(find.byType(PreSubmitView)),
        listen: false,
      );
      expect(state.sha, latestSha);
      expect(find.textContaining('by dash'), findsOneWidget);
      expect(find.textContaining('mac_host_engine'), findsOneWidget);
    },
  );

  testWidgets('PreSubmitView SHA dropdown switches mock SHAs', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(2000, 1080);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.runAsync(() async {
      await tester.pumpWidget(
        createPreSubmitView({'repo': 'flutter', 'pr': '123'}),
      );
      for (var i = 0; i < 20; i++) {
        await tester.pump();
        await Future<void>.delayed(const Duration(milliseconds: 50));
        if (find.byType(ShaSelector).evaluate().isNotEmpty) break;
      }
    });
    await tester.pumpAndSettle();

    expect(find.byType(ShaSelector), findsOneWidget);

    await tester.tap(find.byType(ShaSelector));
    await tester.pumpAndSettle();

    await tester.tap(
      find.byWidgetPredicate(
        (widget) =>
            widget is DropdownMenuItem<String> &&
            widget.value == 'face5_2_mock_sha',
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(ShaSelector), findsOneWidget);
    expect(find.textContaining('face5_2'), findsOneWidget);
    expect(find.text('Re-run failed'), findsNothing);
    expect(find.text('Re-run'), findsNothing);
  });

  testWidgets('PreSubmitView functional sha route fetches check details', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(2000, 1080);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const guardResponse = PresubmitGuardResponse(
      prNum: 123,
      checkRunId: 456,
      author: 'dash',
      stages: [
        PresubmitGuardStage(
          name: 'Engine',
          createdAt: 0,
          builds: {'Mac mac_host_engine': TaskStatus.succeeded},
        ),
      ],
      guardStatus: GuardStatus.succeeded,
    );

    when(
      mockCocoonService.fetchPresubmitGuard(repo: 'flutter', sha: 'abc'),
    ).thenAnswer((_) async => const CocoonResponse.data(guardResponse));

    when(
      mockCocoonService.fetchPresubmitCheckDetails(
        checkRunId: 456,
        buildName: 'Mac mac_host_engine',
      ),
    ).thenAnswer(
      (_) async => CocoonResponse.data([
        PresubmitCheckResponse(
          attemptNumber: 1,
          buildName: 'Mac mac_host_engine',
          creationTime: 0,
          status: 'Succeeded',
          summary: 'Live log content',
        ),
      ]),
    );

    await tester.runAsync(() async {
      await tester.pumpWidget(
        createPreSubmitView({'repo': 'flutter', 'sha': 'abc'}),
      );
      for (var i = 0; i < 20; i++) {
        await tester.pump();
        await Future<void>.delayed(const Duration(milliseconds: 50));
        if (find.textContaining('by dash').evaluate().isNotEmpty) break;
      }
    });
    await tester.pumpAndSettle();

    await tester.tap(find.textContaining('mac_host_engine'));
    await tester.runAsync(() async {
      for (var i = 0; i < 20; i++) {
        await tester.pump();
        await Future<void>.delayed(const Duration(milliseconds: 50));
        if (find.textContaining('Live log content').evaluate().isNotEmpty) {
          break;
        }
      }
    });
    await tester.pumpAndSettle();

    expect(find.textContaining('Live log content'), findsOneWidget);
  });

  testWidgets('PreSubmitView meets accessibility guidelines', (
    WidgetTester tester,
  ) async {
    final handle = tester.ensureSemantics();
    tester.view.physicalSize = const Size(2000, 1080);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(createPreSubmitView({'repo': 'flutter'}));
    await tester.pumpAndSettle();

    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    handle.dispose();
  });

  group('PreSubmitView Header Text', () {
    testWidgets('displays loading text when navigated via PR', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(2000, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        createPreSubmitView({'repo': 'flutter', 'pr': '123'}),
      );
      expect(find.textContaining('PR #123'), findsOneWidget);
    });

    testWidgets(
      'displays empty header text when neither PR nor SHA is provided',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(2000, 1080);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(createPreSubmitView({'repo': 'flutter'}));
        expect(find.text(''), findsOneWidget);
      },
    );

    testWidgets('displays loading text when navigated via SHA', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(2000, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        createPreSubmitView({'repo': 'flutter', 'sha': 'abcdef123456'}),
      );
      expect(find.text('(abcdef1)'), findsOneWidget);
    });

    testWidgets('displays full header text when loaded', (
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
        stages: [],
      );

      when(
        mockCocoonService.fetchPresubmitGuard(
          repo: 'flutter',
          sha: 'abcdef123456',
        ),
      ).thenAnswer((_) async => const CocoonResponse.data(guardResponse));

      await tester.runAsync(() async {
        await tester.pumpWidget(
          createPreSubmitView({'repo': 'flutter', 'sha': 'abcdef123456'}),
        );
        for (var i = 0; i < 20; i++) {
          await tester.pump();
          await Future<void>.delayed(const Duration(milliseconds: 50));
          if (find.textContaining('by dash').evaluate().isNotEmpty) break;
        }
      });
      await tester.pumpAndSettle();

      expect(find.textContaining('PR #123 by dash (abcdef1)'), findsOneWidget);
    });
  });
}
