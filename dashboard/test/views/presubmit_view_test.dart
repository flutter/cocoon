// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

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
          headSha: 'decaf_3_real_sha',
          creationTime: 123456789,
          guardStatus: GuardStatus.succeeded,
        ),
        PresubmitGuardSummary(
          headSha: 'face5_2_mock_sha',
          creationTime: 123456789,
          guardStatus: GuardStatus.failed,
        ),
        PresubmitGuardSummary(
          headSha: 'cafe5_1_mock_sha',
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

    when(
      mockCocoonService.rerunFailedJob(
        idToken: anyNamed('idToken'),
        repo: anyNamed('repo'),
        pr: anyNamed('pr'),
        jobName: anyNamed('jobName'),
      ),
    ).thenAnswer((_) async => const CocoonResponse<void>.data(null));

    when(
      mockCocoonService.rerunAllFailedJobs(
        idToken: anyNamed('idToken'),
        repo: anyNamed('repo'),
        pr: anyNamed('pr'),
      ),
    ).thenAnswer((_) async => const CocoonResponse<void>.data(null));

    when(
      mockCocoonService.fetchPresubmitJobDetails(
        checkRunId: anyNamed('checkRunId'),
        jobName: anyNamed('jobName'),
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
      mockCocoonService.fetchPresubmitJobDetails(
        checkRunId: anyNamed('checkRunId'),
        jobName: argThat(contains('mac_host_engine'), named: 'jobName'),
      ),
    ).thenAnswer(
      (_) async => CocoonResponse.data([
        PresubmitJobResponse(
          attemptNumber: 1,
          jobName: 'Mac mac_host_engine 1',
          creationTime: 0,
          status: TaskStatus.succeeded,
          summary: 'All tests passed (452/452)',
        ),
        PresubmitJobResponse(
          attemptNumber: 2,
          jobName: 'Mac mac_host_engine 1',
          creationTime: 0,
          status: TaskStatus.failed,
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
    'PreSubmitView displays default job details when summary is empty',
    (WidgetTester tester) async {
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
        mockCocoonService.fetchPresubmitJobDetails(
          checkRunId: anyNamed('checkRunId'),
          jobName: argThat(contains('mac_host_engine'), named: 'jobName'),
        ),
      ).thenAnswer(
        (_) async => CocoonResponse.data([
          PresubmitJobResponse(
            attemptNumber: 1,
            jobName: 'Mac mac_host_engine 1',
            creationTime: 0,
            status: TaskStatus.failed,
            summary: '', // Empty summary
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
          if (find
              .textContaining('Mac mac_host_engine 1 failed.')
              .evaluate()
              .isNotEmpty) {
            break;
          }
        }
      });
      await tester.pumpAndSettle();

      expect(
        find.textContaining('Mac mac_host_engine 1 failed.'),
        findsOneWidget,
      );
      expect(
        find.textContaining(
          'Click "View more details on LUCI UI" button below for more details.',
        ),
        findsOneWidget,
      );
    },
  );

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
      mockCocoonService.fetchPresubmitJobDetails(
        checkRunId: 456,
        jobName: 'Mac mac_host_engine',
      ),
    ).thenAnswer(
      (_) async => CocoonResponse.data([
        PresubmitJobResponse(
          attemptNumber: 1,
          jobName: 'Mac mac_host_engine',
          creationTime: 0,
          status: TaskStatus.succeeded,
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

    await tester.tap(find.textContaining('mac_host_engine').first);
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

  group('Re-run functionality', () {
    testWidgets('Re-run buttons are disabled when unauthenticated', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(2000, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      const guardResponse = PresubmitGuardResponse(
        prNum: 123,
        author: 'dash',
        guardStatus: GuardStatus.failed,
        checkRunId: 456,
        stages: [
          PresubmitGuardStage(
            name: 'Engine',
            createdAt: 0,
            builds: {'linux_bot': TaskStatus.failed},
          ),
        ],
      );

      when(
        mockCocoonService.fetchPresubmitGuard(
          repo: 'flutter',
          sha: 'decaf_3_real_sha',
        ),
      ).thenAnswer((_) async => const CocoonResponse.data(guardResponse));

      await tester.runAsync(() async {
        await tester.pumpWidget(
          createPreSubmitView({
            'repo': 'flutter',
            'pr': '123',
            'sha': 'decaf_3_real_sha',
          }),
        );
        for (var i = 0; i < 20; i++) {
          await tester.pump();
          await Future<void>.delayed(const Duration(milliseconds: 50));
          if (find.textContaining('linux_bot').evaluate().isNotEmpty) break;
        }
      });
      await tester.pumpAndSettle();

      final rerunAllButton = find.widgetWithText(TextButton, 'Re-run failed');
      final rerunButton = find.widgetWithText(TextButton, 'Re-run');

      expect(rerunAllButton, findsOneWidget);
      expect(rerunButton, findsOneWidget);

      // Verify buttons are disabled (onPressed is null)
      expect(tester.widget<TextButton>(rerunAllButton).onPressed, isNull);
      expect(tester.widget<TextButton>(rerunButton).onPressed, isNull);
    });

    testWidgets('Re-run buttons are enabled when authenticated', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(2000, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      when(mockAuthService.isAuthenticated).thenReturn(true);

      const guardResponse = PresubmitGuardResponse(
        prNum: 123,
        author: 'dash',
        guardStatus: GuardStatus.failed,
        checkRunId: 456,
        stages: [
          PresubmitGuardStage(
            name: 'Engine',
            createdAt: 0,
            builds: {'linux_bot': TaskStatus.failed},
          ),
        ],
      );

      when(
        mockCocoonService.fetchPresubmitGuard(
          repo: 'flutter',
          sha: 'decaf_3_real_sha',
        ),
      ).thenAnswer((_) async => const CocoonResponse.data(guardResponse));

      await tester.runAsync(() async {
        await tester.pumpWidget(
          createPreSubmitView({
            'repo': 'flutter',
            'pr': '123',
            'sha': 'decaf_3_real_sha',
          }),
        );
        for (var i = 0; i < 20; i++) {
          await tester.pump();
          await Future<void>.delayed(const Duration(milliseconds: 50));
          if (find.textContaining('linux_bot').evaluate().isNotEmpty) break;
        }
      });
      await tester.pumpAndSettle();

      final rerunAllButton = find.widgetWithText(TextButton, 'Re-run failed');
      final rerunButton = find.widgetWithText(TextButton, 'Re-run');

      expect(tester.widget<TextButton>(rerunAllButton).onPressed, isNotNull);
      expect(tester.widget<TextButton>(rerunButton).onPressed, isNotNull);
    });

    testWidgets('Re-run buttons are disabled while re-running', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(2000, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      when(mockAuthService.isAuthenticated).thenReturn(true);

      const guardResponse = PresubmitGuardResponse(
        prNum: 123,
        author: 'dash',
        guardStatus: GuardStatus.failed,
        checkRunId: 456,
        stages: [
          PresubmitGuardStage(
            name: 'Engine',
            createdAt: 0,
            builds: {'linux_bot': TaskStatus.failed},
          ),
        ],
      );

      final rerunCompleter = Completer<CocoonResponse<void>>();
      when(
        mockCocoonService.rerunAllFailedJobs(
          idToken: anyNamed('idToken'),
          repo: anyNamed('repo'),
          pr: anyNamed('pr'),
        ),
      ).thenAnswer((_) => rerunCompleter.future);

      when(
        mockCocoonService.fetchPresubmitGuard(
          repo: 'flutter',
          sha: 'decaf_3_real_sha',
        ),
      ).thenAnswer((_) async => const CocoonResponse.data(guardResponse));

      await tester.runAsync(() async {
        await tester.pumpWidget(
          createPreSubmitView({
            'repo': 'flutter',
            'pr': '123',
            'sha': 'decaf_3_real_sha',
          }),
        );
        for (var i = 0; i < 20; i++) {
          await tester.pump();
          await Future<void>.delayed(const Duration(milliseconds: 50));
          if (find.textContaining('linux_bot').evaluate().isNotEmpty) break;
        }
      });
      await tester.pumpAndSettle();

      final rerunAllButton = find.widgetWithText(TextButton, 'Re-run failed');
      final rerunButton = find.widgetWithText(TextButton, 'Re-run');

      // Start re-running
      final rerunFuture = presubmitState.rerunAllFailedJobs();
      await tester.pump();
      expect(tester.widget<TextButton>(rerunAllButton).onPressed, isNull);
      expect(tester.widget<TextButton>(rerunButton).onPressed, isNull);

      // Finish re-running
      rerunCompleter.complete(const CocoonResponse<void>.data(null));
      await rerunFuture;
      await tester.pump(
        const Duration(seconds: 2),
      ); // Pump time for the refresh timer

      expect(tester.widget<TextButton>(rerunAllButton).onPressed, isNotNull);
      expect(tester.widget<TextButton>(rerunButton).onPressed, isNotNull);
    });
  });

  group('PreSubmitView Sorting', () {
    testWidgets('checks are sorted by status priority and then name', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(2000, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      const guardResponse = PresubmitGuardResponse(
        prNum: 123,
        author: 'dash',
        guardStatus: GuardStatus.failed,
        checkRunId: 456,
        stages: [
          PresubmitGuardStage(
            name: 'Engine',
            createdAt: 0,
            builds: {
              'succeeded_z': TaskStatus.succeeded,
              'failed_b': TaskStatus.failed,
              'infra_c': TaskStatus.infraFailure,
              'in_progress_d': TaskStatus.inProgress,
              'new_e': TaskStatus.waitingForBackfill,
              'cancelled_f': TaskStatus.cancelled,
              'skipped_g': TaskStatus.skipped,
              'failed_a': TaskStatus.failed,
              'succeeded_u': TaskStatus.succeeded,
            },
          ),
        ],
      );

      when(
        mockCocoonService.fetchPresubmitGuard(
          repo: 'flutter',
          sha: 'decaf_3_real_sha',
        ),
      ).thenAnswer((_) async => const CocoonResponse.data(guardResponse));

      await tester.runAsync(() async {
        await tester.pumpWidget(
          createPreSubmitView({
            'repo': 'flutter',
            'pr': '123',
            'sha': 'decaf_3_real_sha',
          }),
        );
        for (var i = 0; i < 20; i++) {
          await tester.pump();
          await Future<void>.delayed(const Duration(milliseconds: 50));
          if (find.textContaining('succeeded_z').evaluate().isNotEmpty) break;
        }
      });
      await tester.pump(); // Render the results

      // The expected order should be:
      // 1. failed_a (Failed)
      // 2. failed_b (Failed)
      // 3. infra_c (Infra Failure)
      // 4. in_progress_d (In Progress)
      // 5. new_e (New)
      // 6. cancelled_f (Cancelled)
      // 7. skipped_g (Skipped)
      // 8. succeeded_u (Succeeded)
      // 9. succeeded_z (Succeeded)

      final names = tester
          .widgetList<Text>(
            find.descendant(
              of: find.byType(PreSubmitView),
              matching: find.byWidgetPredicate(
                (widget) =>
                    widget is Text &&
                    (widget.style?.fontSize == 14 ||
                        widget.style?.fontSize == 11),
              ),
            ),
          )
          .map((t) => t.data!)
          .where((name) => name != 'ENGINE')
          .take(9)
          .toList();

      expect(names, [
        'failed_a',
        'failed_b',
        'infra_c',
        'in_progress_d',
        'new_e',
        'cancelled_f',
        'skipped_g',
        'succeeded_u',
        'succeeded_z',
      ]);
    });
  });
}
