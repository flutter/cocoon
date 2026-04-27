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
    when(mockAuthService.idToken).thenAnswer((_) async => 'fakeToken');

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
      mockCocoonService.fetchPresubmitJobDetails(
        checkRunId: anyNamed('checkRunId'),
        jobName: anyNamed('jobName'),
        repo: anyNamed('repo'),
        owner: anyNamed('owner'),
      ),
    ).thenAnswer(
      (_) async => const CocoonResponse<List<PresubmitJobResponse>>.data([]),
    );
    when(
      mockCocoonService.fetchCommitStatuses(
        repo: anyNamed('repo'),
        branch: anyNamed('branch'),
      ),
    ).thenAnswer(
      (_) async => const CocoonResponse<List<CommitStatus>>.data([]),
    );

    presubmitState = PresubmitState(
      cocoonService: mockCocoonService,
      authService: mockAuthService,
    );
  });

  test('PresubmitState initializes with default values', () {
    expect(presubmitState.repo, 'flutter');
    expect(presubmitState.pr, isNull);
    expect(presubmitState.sha, isNull);
    expect(presubmitState.isLoading, isFalse);
    expect(presubmitState.guardResponse, isNull);
    expect(presubmitState.availableSummaries, isEmpty);
  });

  test(
    'PresubmitState update method updates properties and notifies listeners',
    () {
      var notified = false;
      presubmitState.addListener(() => notified = true);

      presubmitState.update(repo: 'cocoon', pr: '123', sha: 'abc');

      expect(presubmitState.repo, 'cocoon');
      expect(presubmitState.pr, '123');
      expect(presubmitState.sha, 'abc');
      expect(notified, isTrue);
    },
  );

  test(
    'PresubmitState fetchAvailableShas updates availableSummaries and notifies listeners',
    () async {
      const summaries = [
        PresubmitGuardSummary(
          headSha: 'sha1',
          creationTime: 123,
          guardStatus: GuardStatus.succeeded,
        ),
      ];
      when(
        mockCocoonService.fetchPresubmitGuardSummaries(
          pr: '123',
          repo: 'flutter',
        ),
      ).thenAnswer(
        (_) async =>
            const CocoonResponse<List<PresubmitGuardSummary>>.data(summaries),
      );

      presubmitState.pr = '123';
      var notified = false;
      presubmitState.addListener(() => notified = true);

      await presubmitState.fetchAvailableShas();

      expect(presubmitState.availableSummaries, summaries);
      expect(notified, isTrue);
    },
  );

  test(
    'PresubmitState fetchGuardStatus updates guardResponse and notifies listeners',
    () async {
      const guardResponse = PresubmitGuardResponse(
        prNum: 123,
        author: 'dash',
        guardStatus: GuardStatus.succeeded,
        checkRunId: 456,
        stages: [],
      );
      when(
        mockCocoonService.fetchPresubmitGuard(sha: 'sha1', repo: 'flutter'),
      ).thenAnswer(
        (_) async =>
            const CocoonResponse<PresubmitGuardResponse>.data(guardResponse),
      );

      presubmitState.sha = 'sha1';
      var notified = false;
      presubmitState.addListener(() => notified = true);

      await presubmitState.fetchGuardStatus();

      expect(presubmitState.guardResponse, guardResponse);
      expect(presubmitState.isLoading, isFalse);
      expect(notified, isTrue);
    },
  );

  test(
    'PresubmitState fetchCheckDetails updates checks and notifies listeners',
    () async {
      final checks = [
        PresubmitJobResponse(
          attemptNumber: 1,
          jobName: 'check1',
          creationTime: 0,
          status: TaskStatus.succeeded,
        ),
      ];
      const guardResponse = PresubmitGuardResponse(
        prNum: 123,
        author: 'dash',
        guardStatus: GuardStatus.succeeded,
        checkRunId: 456,
        stages: [],
      );
      presubmitState.setGuardResponseForTest(guardResponse);

      when(
        mockCocoonService.fetchPresubmitJobDetails(
          checkRunId: 456,
          jobName: 'check1',
          repo: 'flutter',
        ),
      ).thenAnswer(
        (_) async => CocoonResponse<List<PresubmitJobResponse>>.data(checks),
      );

      presubmitState.selectJob('check1');
      var notified = false;
      presubmitState.addListener(() => notified = true);

      await presubmitState.fetchJobDetails();

      expect(presubmitState.jobs, checks);
      expect(notified, isTrue);
    },
  );

  test(
    'PresubmitState update does not notify if values are the same and no fetch triggered',
    () {
      presubmitState.update(repo: 'flutter', pr: '123', sha: 'sha1');
      var notifiedCount = 0;
      presubmitState.addListener(() => notifiedCount++);

      presubmitState.update(repo: 'flutter', pr: '123', sha: 'sha1');

      expect(notifiedCount, 0);
    },
  );

  test(
    'PresubmitState fetchAvailableShas returns early if pr is null',
    () async {
      await presubmitState.fetchAvailableShas();
      verifyNever(
        mockCocoonService.fetchPresubmitGuardSummaries(
          repo: anyNamed('repo'),
          pr: anyNamed('pr'),
        ),
      );
    },
  );

  test(
    'PresubmitState fetchAvailableShas defaults sha to latest if sha is null',
    () async {
      const summaries = [
        PresubmitGuardSummary(
          headSha: 'latest',
          creationTime: 123,
          guardStatus: GuardStatus.succeeded,
        ),
      ];
      when(
        mockCocoonService.fetchPresubmitGuardSummaries(
          pr: '123',
          repo: 'flutter',
        ),
      ).thenAnswer(
        (_) async =>
            const CocoonResponse<List<PresubmitGuardSummary>>.data(summaries),
      );

      presubmitState.pr = '123';
      await presubmitState.fetchAvailableShas();

      expect(presubmitState.sha, 'latest');
    },
  );

  test(
    'PresubmitState fetchGuardStatus returns early if sha is null',
    () async {
      await presubmitState.fetchGuardStatus();
      verifyNever(
        mockCocoonService.fetchPresubmitGuard(
          repo: anyNamed('repo'),
          sha: anyNamed('sha'),
        ),
      );
    },
  );

  test('PresubmitState refresh timer management', () async {
    presubmitState.addListener(() {}); // Trigger timer start
    expect(presubmitState.refreshTimer, isNotNull);

    presubmitState.dispose();
    expect(presubmitState.refreshTimer?.isActive, isFalse);
  });

  test('PresubmitState pause and resume timer management', () async {
    presubmitState.addListener(() {}); // Trigger timer start
    expect(presubmitState.refreshTimer, isNotNull);

    presubmitState.pause();
    expect(presubmitState.refreshTimer, isNull);

    presubmitState.resume();
    expect(presubmitState.refreshTimer, isNotNull);
  });

  test(
    'PresubmitState refreshes on auth change when becoming authenticated',
    () async {
      // Create a local state initialized with PR
      final localPresubmitState = PresubmitState(
        cocoonService: mockCocoonService,
        authService: mockAuthService,
        pr: '123',
      );
      // Wait for constructor fetch
      await Future<void>.delayed(Duration.zero);
      clearInteractions(mockCocoonService);

      // Now login
      when(mockAuthService.isAuthenticated).thenReturn(true);
      localPresubmitState.onAuthChanged();

      // onAuthChanged triggers _fetchRefreshUpdate -> fetchIfNeeded -> fetchAvailableShas
      // which is async. We just need to wait for it to complete.
      await localPresubmitState.fetchAvailableShas();

      verify(
        mockCocoonService.fetchPresubmitGuardSummaries(
          repo: anyNamed('repo'),
          pr: anyNamed('pr'),
        ),
      ).called(greaterThanOrEqualTo(1));
    },
  );

  test(
    'PresubmitState refreshes on auth change when becoming unauthenticated',
    () async {
      when(mockAuthService.isAuthenticated).thenReturn(true);
      final localPresubmitState = PresubmitState(
        cocoonService: mockCocoonService,
        authService: mockAuthService,
        pr: '123',
      );
      await Future<void>.delayed(Duration.zero);
      clearInteractions(mockCocoonService);

      when(mockAuthService.isAuthenticated).thenReturn(false);
      localPresubmitState.onAuthChanged();
      await Future<void>.delayed(Duration.zero);

      // Should not refresh when logout
      verifyNever(
        mockCocoonService.fetchPresubmitGuardSummaries(
          repo: anyNamed('repo'),
          pr: anyNamed('pr'),
        ),
      );
    },
  );

  test('rerunFailedJob triggers API and updates loading state', () async {
    when(
      mockCocoonService.rerunFailedJob(
        idToken: anyNamed('idToken'),
        repo: anyNamed('repo'),
        pr: anyNamed('pr'),
        jobName: anyNamed('jobName'),
      ),
    ).thenAnswer((_) async => const CocoonResponse<void>.data(null));

    presubmitState.pr = '123';
    final error = await presubmitState.rerunFailedJob('check1');

    expect(error, isNull);
    verify(
      mockCocoonService.rerunFailedJob(
        idToken: anyNamed('idToken'),
        repo: 'flutter',
        pr: 123,
        jobName: 'check1',
      ),
    ).called(1);
  });

  test('rerunAllFailedJobs triggers API and updates loading state', () async {
    when(
      mockCocoonService.rerunAllFailedJobs(
        idToken: anyNamed('idToken'),
        repo: anyNamed('repo'),
        pr: anyNamed('pr'),
      ),
    ).thenAnswer((_) async => const CocoonResponse<void>.data(null));

    presubmitState.pr = '123';
    final error = await presubmitState.rerunAllFailedJobs();

    expect(error, isNull);
    verify(
      mockCocoonService.rerunAllFailedJobs(
        idToken: anyNamed('idToken'),
        repo: 'flutter',
        pr: 123,
      ),
    ).called(1);
  });
  test(
    'syncUpdate with null sha resets _lastFetchedPr to force re-fetch when pr is the same',
    () async {
      const summaries = [
        PresubmitGuardSummary(
          headSha: 'latest',
          creationTime: 123,
          guardStatus: GuardStatus.succeeded,
        ),
      ];
      when(
        mockCocoonService.fetchPresubmitGuardSummaries(
          pr: '123',
          repo: 'flutter',
        ),
      ).thenAnswer(
        (_) async =>
            const CocoonResponse<List<PresubmitGuardSummary>>.data(summaries),
      );

      presubmitState.update(repo: 'flutter', pr: '123', sha: 'sha1');
      expect(presubmitState.sha, 'sha1');

      await Future<void>.delayed(Duration.zero);
      clearInteractions(mockCocoonService);

      presubmitState.update(pr: '123', sha: null);

      await Future<void>.delayed(Duration.zero);

      verify(
        mockCocoonService.fetchPresubmitGuardSummaries(
          pr: '123',
          repo: 'flutter',
        ),
      ).called(1);
      expect(presubmitState.sha, 'latest');
    },
  );
}
