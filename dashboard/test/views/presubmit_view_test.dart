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
import 'package:flutter_dashboard/views/presubmit_view.dart';
import 'package:flutter_dashboard/widgets/state_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import '../utils/fake_flutter_app_icons.dart';
import '../utils/mocks.dart';

void main() {
  late MockCocoonService mockCocoonService;
  late MockFirebaseAuthService mockAuthService;
  late BuildState buildState;

  setUp(() {
    mockCocoonService = MockCocoonService();
    mockAuthService = MockFirebaseAuthService();

    FlutterAppIconsPlatform.instance = FakeFlutterAppIcons();

    when(mockAuthService.user).thenReturn(null);
    when(mockAuthService.isAuthenticated).thenReturn(false);

    when(mockCocoonService.fetchFlutterBranches()).thenAnswer(
      (_) async => const CocoonResponse.data([]),
    );
    when(mockCocoonService.fetchRepos()).thenAnswer(
      (_) async => const CocoonResponse.data([]),
    );
    when(mockCocoonService.fetchCommitStatuses(
      branch: anyNamed('branch'),
      repo: anyNamed('repo'),
    )).thenAnswer(
      (_) async => const CocoonResponse.data([]),
    );
    when(mockCocoonService.fetchTreeBuildStatus(
      branch: anyNamed('branch'),
      repo: anyNamed('repo'),
    )).thenAnswer(
      (_) async => CocoonResponse.data(BuildStatusResponse(
        buildStatus: BuildStatus.success,
        failingTasks: [],
      )),
    );
    when(mockCocoonService.fetchSuppressedTests(
      repo: anyNamed('repo'),
    )).thenAnswer(
      (_) async => const CocoonResponse.data([]),
    );
    
    when(mockCocoonService.fetchPresubmitGuard(
      repo: anyNamed('repo'),
      sha: anyNamed('sha'),
    )).thenAnswer(
      (_) async => const CocoonResponse.error('Not found', statusCode: 404),
    );

    buildState = BuildState(
      cocoonService: mockCocoonService,
      authService: mockAuthService,
    );
  });

  Widget createPreSubmitView(Map<String, String> queryParameters) {
    return Material(
      child: StateProvider(
        buildState: buildState,
        signInService: mockAuthService,
        child: MaterialApp(
          home: PreSubmitView(queryParameters: queryParameters),
        ),
      ),
    );
  }

  testWidgets('PreSubmitView displays correct title and status with repo and sha', (WidgetTester tester) async {
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

    when(mockCocoonService.fetchPresubmitGuard(repo: 'flutter', sha: 'abc')).thenAnswer(
      (_) async => const CocoonResponse.data(guardResponse),
    );

    await tester.pumpWidget(createPreSubmitView({'repo': 'flutter', 'sha': 'abc'}));
    await tester.pump();
    await tester.pump();

    expect(find.text('PR #123: [dash]'), findsOneWidget);
    expect(find.text('Succeeded'), findsOneWidget);
    expect(find.text('ENGINE'), findsOneWidget);
    expect(find.text('Mac mac_host_engine'), findsOneWidget);
  });

  testWidgets('PreSubmitView displays mocked data and switches tabs', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(2000, 1080);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(createPreSubmitView({'repo': 'flutter', 'pr': '1234'}));
    await tester.pump();

    expect(find.text('PR #1234: [dash]'), findsOneWidget);
    
    // Select a check
    await tester.tap(find.text('Mac mac_host_engine'));
    await tester.pump();

    // Verify log for attempt #1
    expect(find.textContaining('All tests passed (452/452)'), findsOneWidget);
    expect(find.text('Status: Succeeded'), findsOneWidget);

    // Switch to attempt #2
    await tester.tap(find.text('#2'));
    await tester.pump();

    expect(find.textContaining('Test failed: Unit Tests'), findsOneWidget);
    expect(find.text('Status: Failed'), findsOneWidget);
  });

  testWidgets('PreSubmitView SHA dropdown switches mock SHAs', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(2000, 1080);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(createPreSubmitView({'repo': 'flutter', 'pr': '1234'}));
    await tester.pump();

    // Find dropdown in AppBar actions and select mock_sha_2
    expect(find.text('mock_sha_'), findsOneWidget);
    await tester.tap(find.text('mock_sha_'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    
    // Select the second one from the dropdown menu
    await tester.tap(find.text('mock_sha_').at(1));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('mock_sha_'), findsOneWidget);
    expect(find.text('Re-run failed'), findsOneWidget);
  });

  testWidgets('PreSubmitView functional sha route fetches check details', (WidgetTester tester) async {
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

    when(mockCocoonService.fetchPresubmitGuard(repo: 'flutter', sha: 'abc')).thenAnswer(
      (_) async => const CocoonResponse.data(guardResponse),
    );

    when(mockCocoonService.fetchPresubmitCheckDetails(checkRunId: 456, buildName: 'Mac mac_host_engine')).thenAnswer(
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

    await tester.pumpWidget(createPreSubmitView({'repo': 'flutter', 'sha': 'abc'}));
    await tester.pump();
    await tester.pump();

    await tester.tap(find.text('Mac mac_host_engine'));
    await tester.pump();
    await tester.pump();

    expect(find.text('Live log content'), findsOneWidget);
  });

  testWidgets('PreSubmitView meets accessibility guidelines', (WidgetTester tester) async {
    final SemanticsHandle handle = tester.ensureSemantics();
    tester.view.physicalSize = const Size(2000, 1080);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(createPreSubmitView({'repo': 'flutter', 'pr': '1234'}));
    await tester.pump();

    // Verify text contrast
    await expectLater(tester, meetsGuideline(textContrastGuideline));

    handle.dispose();
  });
}
