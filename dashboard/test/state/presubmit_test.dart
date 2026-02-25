// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_common/guard_status.dart';
import 'package:cocoon_common/rpc_model.dart';
import 'package:flutter_dashboard/service/cocoon.dart';
import 'package:flutter_dashboard/state/presubmit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import '../utils/mocks.dart';

void main() {
  late PresubmitState presubmitState;
  late MockCocoonService mockCocoonService;
  late MockFirebaseAuthService mockAuthService;

  setUp(() {
    mockCocoonService = MockCocoonService();
    mockAuthService = MockFirebaseAuthService();
    presubmitState = PresubmitState(
      cocoonService: mockCocoonService,
      authService: mockAuthService,
    );

    // Default stubs to avoid MissingStubError during auto-fetches
    when(
      mockCocoonService.fetchPresubmitGuardSummaries(
        repo: anyNamed('repo'),
        pr: anyNamed('pr'),
      ),
    ).thenAnswer(
      (_) async => const CocoonResponse<List<PresubmitGuardSummary>>.data([]),
    );
    when(
      mockCocoonService.fetchPresubmitGuard(
        repo: anyNamed('repo'),
        sha: anyNamed('sha'),
      ),
    ).thenAnswer(
      (_) async => const CocoonResponse<PresubmitGuardResponse>.data(null),
    );
    when(
      mockCocoonService.fetchCommitStatuses(
        repo: anyNamed('repo'),
        branch: anyNamed('branch'),
      ),
    ).thenAnswer(
      (_) async => const CocoonResponse<List<CommitStatus>>.data([]),
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
          commitSha: 'sha1',
          creationTime: 123,
          guardStatus: GuardStatus.succeeded,
        ),
      ];
      when(
        mockCocoonService.fetchPresubmitGuardSummaries(
          repo: 'flutter',
          pr: '123',
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
        mockCocoonService.fetchPresubmitGuard(repo: 'flutter', sha: 'sha1'),
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
    'PresubmitState update does not notify if values are the same and no fetch triggered',
    () {
      presubmitState.repo = 'flutter';
      presubmitState.pr = '123';
      presubmitState.sha = 'abc';
      // Use update to stabilize the state including lastFetched flags
      presubmitState.update(repo: 'flutter', pr: '123', sha: 'abc');

      var notified = false;
      presubmitState.addListener(() => notified = true);

      presubmitState.update(repo: 'flutter', pr: '123', sha: 'abc');

      expect(notified, isFalse);
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
          commitSha: 'sha1',
          creationTime: 123,
          guardStatus: GuardStatus.succeeded,
        ),
      ];
      when(
        mockCocoonService.fetchPresubmitGuardSummaries(
          repo: 'flutter',
          pr: '123',
        ),
      ).thenAnswer(
        (_) async =>
            const CocoonResponse<List<PresubmitGuardSummary>>.data(summaries),
      );

      presubmitState.pr = '123';
      presubmitState.sha = null;

      await presubmitState.fetchAvailableShas();

      expect(presubmitState.sha, 'sha1');
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

  test('PresubmitState refresh timer management', () {
    expect(presubmitState.refreshTimer, isNull);

    void listener() {}
    presubmitState.addListener(listener);
    expect(presubmitState.refreshTimer, isNotNull);

    presubmitState.removeListener(listener);
    expect(presubmitState.refreshTimer, isNull);
  });
}
