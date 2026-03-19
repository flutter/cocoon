// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_common/guard_status.dart';
import 'package:cocoon_common/rpc_model.dart';
import 'package:cocoon_common/task_status.dart';
import 'package:flutter_dashboard/service/cocoon.dart';
import 'package:flutter_dashboard/state/presubmit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import '../utils/mocks.mocks.dart';

void main() {
  late PresubmitState presubmitState;
  late MockCocoonService mockCocoonService;
  late MockFirebaseAuthService mockAuthService;

  setUp(() {
    mockCocoonService = MockCocoonService();
    mockAuthService = MockFirebaseAuthService();
    when(mockAuthService.isAuthenticated).thenReturn(false);

    // Default stubs to avoid MissingStubError during auto-fetches
    when(
      mockCocoonService.fetchPresubmitGuardSummaries(
        pr: anyNamed('pr'),
        repo: anyNamed('repo'),
        owner: anyNamed('owner'),
      ),
    ).thenAnswer(
      (_) async => const CocoonResponse<List<PresubmitGuardSummary>>.data([]),
    );
    when(
      mockCocoonService.fetchPresubmitGuard(
        sha: anyNamed('sha'),
        repo: anyNamed('repo'),
        owner: anyNamed('owner'),
      ),
    ).thenAnswer(
      (_) async => const CocoonResponse<PresubmitGuardResponse>.data(null),
    );
    when(
      mockCocoonService.fetchPresubmitCheckDetails(
        checkRunId: anyNamed('checkRunId'),
        buildName: anyNamed('buildName'),
        repo: anyNamed('repo'),
        owner: anyNamed('owner'),
      ),
    ).thenAnswer(
      (_) async => const CocoonResponse<List<PresubmitCheckResponse>>.data([]),
    );

    presubmitState = PresubmitState(
      cocoonService: mockCocoonService,
      authService: mockAuthService,
    );
  });

  test('PresubmitState initializes with default filter values', () {
    expect(presubmitState.selectedStatuses, TaskStatus.values.toSet());
    expect(
      presubmitState.selectedPlatforms,
      isEmpty,
    ); // Initially empty until data is loaded
    expect(presubmitState.jobNameFilter, isNull);
  });

  test('updateFilters updates state and notifies listeners', () {
    var notified = false;
    presubmitState.addListener(() => notified = true);

    presubmitState.updateFilters(
      statuses: {TaskStatus.failed, TaskStatus.infraFailure},
      platforms: {'linux', 'mac'},
      jobNameFilter: 'test.*',
    );

    expect(presubmitState.selectedStatuses, {
      TaskStatus.failed,
      TaskStatus.infraFailure,
    });
    expect(presubmitState.selectedPlatforms, {'linux', 'mac'});
    expect(presubmitState.jobNameFilter, 'test.*');
    expect(notified, isTrue);
  });

  test('clearFilters resets state and notifies listeners', () {
    presubmitState.updateFilters(
      statuses: {TaskStatus.failed},
      platforms: {'linux'},
      jobNameFilter: 'test',
    );

    var notified = false;
    presubmitState.addListener(() => notified = true);

    presubmitState.clearFilters();

    expect(presubmitState.selectedStatuses, TaskStatus.values.toSet());
    expect(presubmitState.selectedPlatforms, isEmpty);
    expect(presubmitState.jobNameFilter, isNull);
    expect(notified, isTrue);
  });

  test('filteredGuardResponse applies status, platform, and regex filters', () {
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
            'linux test2': TaskStatus.failed,
            'mac test1': TaskStatus.succeeded,
            'windows test1': TaskStatus.inProgress,
          },
        ),
      ],
    );

    presubmitState.setGuardResponseForTest(response);

    // Filter by status
    presubmitState.updateFilters(statuses: {TaskStatus.failed});
    var filtered = presubmitState.filteredGuardResponse!;
    expect(filtered.stages[0].builds.length, 1);
    expect(filtered.stages[0].builds.keys.first, 'linux test2');

    // Filter by platform
    presubmitState.updateFilters(
      statuses: TaskStatus.values.toSet(),
      platforms: {'mac'},
    );
    filtered = presubmitState.filteredGuardResponse!;
    expect(filtered.stages[0].builds.length, 1);
    expect(filtered.stages[0].builds.keys.first, 'mac test1');

    // Filter by regex
    presubmitState.updateFilters(
      platforms: {'linux', 'mac', 'windows'},
      jobNameFilter: 'test2',
    );
    filtered = presubmitState.filteredGuardResponse!;
    expect(filtered.stages[0].builds.length, 1);
    expect(filtered.stages[0].builds.keys.first, 'linux test2');

    // All filters
    presubmitState.updateFilters(
      statuses: {TaskStatus.succeeded},
      platforms: {'linux'},
      jobNameFilter: 'test1',
    );
    filtered = presubmitState.filteredGuardResponse!;
    expect(filtered.stages[0].builds.length, 1);
    expect(filtered.stages[0].builds.keys.first, 'linux test1');
  });

  test('PR change resets filters', () {
    presubmitState.updateFilters(
      statuses: {TaskStatus.failed},
      jobNameFilter: 'abc',
    );

    presubmitState.update(pr: '456');

    expect(presubmitState.selectedStatuses, TaskStatus.values.toSet());
    expect(presubmitState.jobNameFilter, isNull);
  });

  test('ensureValidSelection auto-selects top-most job on filter change', () {
    const response = PresubmitGuardResponse(
      prNum: 123,
      author: 'dash',
      guardStatus: GuardStatus.failed,
      checkRunId: 456,
      stages: [
        PresubmitGuardStage(
          name: 'stage1',
          createdAt: 0,
          builds: {
            'linux test1': TaskStatus.succeeded,
            'linux test2': TaskStatus.failed,
          },
        ),
      ],
    );

    presubmitState.setGuardResponseForTest(response);

    // Initial selection should be 'linux test2' (failed has higher priority than succeeded)
    expect(presubmitState.selectedCheck, 'linux test2');

    // Filter out 'linux test2'
    presubmitState.updateFilters(statuses: {TaskStatus.succeeded});
    expect(presubmitState.selectedCheck, 'linux test1');

    // Filter out everything
    presubmitState.updateFilters(jobNameFilter: 'none');
    expect(presubmitState.selectedCheck, isNull);
  });
}
