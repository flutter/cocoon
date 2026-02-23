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
  group('PresubmitState', () {
    late MockCocoonService mockCocoonService;

    setUp(() {
      mockCocoonService = MockCocoonService();
    });

    test('initializes with default values', () {
      final presubmitState = PresubmitState(
        authService: MockFirebaseAuthService(),
        cocoonService: mockCocoonService,
      );
      expect(presubmitState.repo, 'flutter');
      expect(presubmitState.pr, isNull);
      expect(presubmitState.sha, isNull);
    });

    test('update method updates properties and notifies listeners', () {
      final presubmitState = PresubmitState(
        authService: MockFirebaseAuthService(),
        cocoonService: mockCocoonService,
      );
      bool notified = false;
      presubmitState.addListener(() => notified = true);

      presubmitState.update(repo: 'cocoon', pr: '123', sha: 'abc');

      expect(presubmitState.repo, 'cocoon');
      expect(presubmitState.pr, '123');
      expect(presubmitState.sha, 'abc');
      expect(notified, isTrue);
    });

    test('fetchAvailableShas updates availableSummaries and notifies listeners', () async {
      final presubmitState = PresubmitState(
        authService: MockFirebaseAuthService(),
        cocoonService: mockCocoonService,
      );
      presubmitState.repo = 'flutter';
      presubmitState.pr = '123';

      final mockSummaries = [
        PresubmitGuardSummary(
          commitSha: 'sha1',
          creationTime: 123,
          guardStatus: GuardStatus.succeeded,
        ),
      ];

      when(mockCocoonService.fetchPresubmitGuardSummaries(
        repo: 'flutter',
        pr: '123',
      )).thenAnswer((_) async => CocoonResponse<List<PresubmitGuardSummary>>.data(mockSummaries));

      bool notified = false;
      presubmitState.addListener(() => notified = true);

      await presubmitState.fetchAvailableShas();

      expect(presubmitState.availableSummaries, mockSummaries);
      expect(presubmitState.isLoading, isFalse);
      expect(notified, isTrue);
    });

    test('fetchGuardStatus updates guardResponse and notifies listeners', () async {
      final presubmitState = PresubmitState(
        authService: MockFirebaseAuthService(),
        cocoonService: mockCocoonService,
      );
      presubmitState.repo = 'flutter';
      presubmitState.sha = 'sha1';

      final mockResponse = PresubmitGuardResponse(
        prNum: 123,
        author: 'author1',
        guardStatus: GuardStatus.succeeded,
        checkRunId: 456,
        stages: [],
      );

      when(mockCocoonService.fetchPresubmitGuard(
        repo: 'flutter',
        sha: 'sha1',
      )).thenAnswer((_) async => CocoonResponse<PresubmitGuardResponse>.data(mockResponse));

      bool notified = false;
      presubmitState.addListener(() => notified = true);

      await presubmitState.fetchGuardStatus();

      expect(presubmitState.guardResponse, mockResponse);
      expect(presubmitState.isLoading, isFalse);
      expect(notified, isTrue);
    });

    test('update does not notify if values are the same', () {
      final presubmitState = PresubmitState(
        authService: MockFirebaseAuthService(),
        cocoonService: mockCocoonService,
        repo: 'flutter',
        pr: '123',
        sha: 'abc',
      );
      bool notified = false;
      presubmitState.addListener(() => notified = true);

      presubmitState.update(repo: 'flutter', pr: '123', sha: 'abc');

      expect(notified, isFalse);
    });

    test('fetchAvailableShas returns early if pr is null', () async {
      final presubmitState = PresubmitState(
        authService: MockFirebaseAuthService(),
        cocoonService: mockCocoonService,
      );
      presubmitState.pr = null;

      await presubmitState.fetchAvailableShas();

      expect(presubmitState.isLoading, isFalse);
      verifyNever(mockCocoonService.fetchPresubmitGuardSummaries(
        repo: anyNamed('repo'),
        pr: anyNamed('pr'),
      ));
    });

    test('fetchAvailableShas defaults sha to latest if sha is null', () async {
      final presubmitState = PresubmitState(
        authService: MockFirebaseAuthService(),
        cocoonService: mockCocoonService,
      );
      presubmitState.repo = 'flutter';
      presubmitState.pr = '123';
      presubmitState.sha = null;

      final mockSummaries = [
        PresubmitGuardSummary(
          commitSha: 'sha1',
          creationTime: 123,
          guardStatus: GuardStatus.succeeded,
        ),
      ];

      when(mockCocoonService.fetchPresubmitGuardSummaries(
        repo: 'flutter',
        pr: '123',
      )).thenAnswer((_) async => CocoonResponse<List<PresubmitGuardSummary>>.data(mockSummaries));

      await presubmitState.fetchAvailableShas();

      expect(presubmitState.sha, 'sha1');
    });

    test('fetchGuardStatus returns early if sha is null', () async {
      final presubmitState = PresubmitState(
        authService: MockFirebaseAuthService(),
        cocoonService: mockCocoonService,
      );
      presubmitState.sha = null;

      await presubmitState.fetchGuardStatus();

      expect(presubmitState.isLoading, isFalse);
      verifyNever(mockCocoonService.fetchPresubmitGuard(
        repo: anyNamed('repo'),
        sha: anyNamed('sha'),
      ));
    });
  });
}
