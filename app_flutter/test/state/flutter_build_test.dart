// Copyright (c) 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:mockito/mockito.dart';

import 'package:cocoon_service/protos.dart' show Commit, CommitStatus, Key, RootKey;

import 'package:app_flutter/service/cocoon.dart';
import 'package:app_flutter/service/google_authentication.dart';
import 'package:app_flutter/state/flutter_build.dart';

import '../utils/mocks.dart';
import '../utils/output.dart';

void main() {
  const String _defaultBranch = 'master';

  group('FlutterBuildState', () {
    FlutterBuildState buildState;
    MockCocoonService mockCocoonService;
    String lastError;

    CommitStatus setupCommitStatus;

    setUp(() {
      mockCocoonService = MockCocoonService();
      buildState = FlutterBuildState(
        authService: MockGoogleSignInService(),
        cocoonService: mockCocoonService,
      )..errors.addListener((String message) => lastError = message);

      setupCommitStatus = _createCommitStatus('setup');

      when(mockCocoonService.fetchCommitStatuses(branch: anyNamed('branch'))).thenAnswer((_) =>
          Future<CocoonResponse<List<CommitStatus>>>.value(
              CocoonResponse<List<CommitStatus>>.data(<CommitStatus>[setupCommitStatus])));
      when(mockCocoonService.fetchTreeBuildStatus(branch: anyNamed('branch')))
          .thenAnswer((_) => Future<CocoonResponse<bool>>.value(const CocoonResponse<bool>.data(true)));
      when(mockCocoonService.fetchFlutterBranches()).thenAnswer((_) => Future<CocoonResponse<List<String>>>.value(
          const CocoonResponse<List<String>>.data(<String>[_defaultBranch])));
    });

    testWidgets('start calls fetch branches', (WidgetTester tester) async {
      buildState.startFetchingUpdates();

      // startFetching immediately starts fetching results
      verify(mockCocoonService.fetchFlutterBranches()).called(1);

      // Tear down fails to cancel the timer
      await tester.pump(buildState.refreshRate * 2);
      buildState.dispose();
    });

    testWidgets('timer should periodically fetch updates', (WidgetTester tester) async {
      buildState.startFetchingUpdates();

      // startFetching immediately starts fetching results
      verify(mockCocoonService.fetchCommitStatuses(branch: _defaultBranch)).called(1);

      // Periodic timers don't necessarily run at the same time in each interval.
      // We double the refreshRate to gurantee a call would have been made.
      await tester.pump(buildState.refreshRate * 2);
      verify(mockCocoonService.fetchCommitStatuses(branch: _defaultBranch)).called(greaterThan(1));

      // Tear down fails to cancel the timer before the test is over
      buildState.dispose();
    });

    testWidgets('multiple start updates should not change the timer', (WidgetTester tester) async {
      buildState.startFetchingUpdates();
      final Timer refreshTimer = buildState.refreshTimer;

      // This second run should not change the refresh timer
      buildState.startFetchingUpdates();

      expect(refreshTimer, equals(buildState.refreshTimer));

      // Since startFetching sends out requests on start, we need to wait
      // for them to finish before disposing of the state.
      await tester.pumpAndSettle();

      // Tear down fails to cancel the timer before the test is over
      buildState.dispose();
    });

    testWidgets('statuses error should not delete previous statuses data', (WidgetTester tester) async {
      buildState.startFetchingUpdates();

      // Periodic timers don't necessarily run at the same time in each interval.
      // We double the refreshRate to gurantee a call would have been made.
      await tester.pump(buildState.refreshRate * 2);
      final List<CommitStatus> originalData = buildState.statuses;

      when(mockCocoonService.fetchCommitStatuses(branch: _defaultBranch)).thenAnswer((_) =>
          Future<CocoonResponse<List<CommitStatus>>>.value(const CocoonResponse<List<CommitStatus>>.error('error')));

      await checkOutput(
        block: () async {
          await tester.pump(buildState.refreshRate);
        },
        output: <String>[
          'An error occured fetching build statuses from Cocoon: error',
        ],
      );
      verify(mockCocoonService.fetchCommitStatuses(branch: _defaultBranch)).called(greaterThan(1));

      expect(buildState.statuses, originalData);
      expect(lastError, startsWith(FlutterBuildState.errorMessageFetchingStatuses));

      // Tear down fails to cancel the timer before the test is over
      buildState.dispose();
    });

    testWidgets('build status error should not delete previous build status data', (WidgetTester tester) async {
      buildState.startFetchingUpdates();

      // Periodic timers don't necessarily run at the same time in each interval.
      // We double the refreshRate to gurantee a call would have been made.
      await tester.pump(buildState.refreshRate);
      final bool originalData = buildState.isTreeBuilding;

      when(mockCocoonService.fetchTreeBuildStatus(branch: _defaultBranch))
          .thenAnswer((_) => Future<CocoonResponse<bool>>.value(const CocoonResponse<bool>.error('error')));

      await checkOutput(
        block: () async {
          await tester.pump(buildState.refreshRate);
        },
        output: <String>[
          'An error occured fetching tree status from Cocoon: error',
        ],
      );
      verify(mockCocoonService.fetchTreeBuildStatus(branch: _defaultBranch)).called(greaterThan(1));

      expect(buildState.isTreeBuilding, originalData);
      expect(lastError, startsWith(FlutterBuildState.errorMessageFetchingTreeStatus));

      // Tear down fails to cancel the timer before the test is over
      buildState.dispose();
    });

    testWidgets('fetch more commit statuses appends', (WidgetTester tester) async {
      buildState.startFetchingUpdates();

      await untilCalled(mockCocoonService.fetchCommitStatuses(branch: anyNamed('branch')));

      expect(buildState.statuses, <CommitStatus>[setupCommitStatus]);

      final CommitStatus statusA = _createCommitStatus('A');
      when(mockCocoonService.fetchCommitStatuses(
              lastCommitStatus: captureThat(isNotNull, named: 'lastCommitStatus'), branch: anyNamed('branch')))
          .thenAnswer((_) async => CocoonResponse<List<CommitStatus>>.data(<CommitStatus>[statusA]));

      await buildState.fetchMoreCommitStatuses();

      expect(buildState.statuses, <CommitStatus>[setupCommitStatus, statusA]);

      await tester.pump(buildState.refreshRate);

      expect(buildState.statuses, <CommitStatus>[setupCommitStatus, statusA]);
      expect(buildState.moreStatusesExist, true);

      buildState.dispose();
    });

    testWidgets('fetchMoreCommitStatuses returns empty stops fetching more', (WidgetTester tester) async {
      buildState.startFetchingUpdates();

      await untilCalled(mockCocoonService.fetchCommitStatuses(branch: anyNamed('branch')));

      expect(buildState.statuses, <CommitStatus>[setupCommitStatus]);

      when(mockCocoonService.fetchCommitStatuses(
              lastCommitStatus: captureThat(isNotNull, named: 'lastCommitStatus'), branch: anyNamed('branch')))
          .thenAnswer((_) async => const CocoonResponse<List<CommitStatus>>.data(<CommitStatus>[]));

      await buildState.fetchMoreCommitStatuses();

      expect(buildState.statuses, <CommitStatus>[setupCommitStatus]);
      expect(buildState.moreStatusesExist, false);

      buildState.dispose();
    });

    testWidgets('update branch resets build state data', (WidgetTester tester) async {
      // Only return statuses when on master branch
      when(mockCocoonService.fetchCommitStatuses(branch: 'master')).thenAnswer((_) =>
          Future<CocoonResponse<List<CommitStatus>>>.value(
              CocoonResponse<List<CommitStatus>>.data(<CommitStatus>[setupCommitStatus])));
      // Mark tree green on master, red on dev
      when(mockCocoonService.fetchTreeBuildStatus(branch: 'master'))
          .thenAnswer((_) => Future<CocoonResponse<bool>>.value(const CocoonResponse<bool>.data(true)));
      when(mockCocoonService.fetchTreeBuildStatus(branch: 'dev'))
          .thenAnswer((_) => Future<CocoonResponse<bool>>.value(const CocoonResponse<bool>.data(false)));
      buildState.startFetchingUpdates();

      await untilCalled(mockCocoonService.fetchCommitStatuses(branch: 'master'));
      expect(buildState.statuses, isNotEmpty);
      expect(buildState.isTreeBuilding, isNotNull);

      // With mockito, the fetch requests for data will finish immediately
      await buildState.updateCurrentBranch('dev');

      expect(buildState.statuses, isEmpty);
      expect(buildState.isTreeBuilding, false);
      expect(buildState.moreStatusesExist, true);

      buildState.dispose();
    });
  });

  testWidgets('sign in functions call notify listener', (WidgetTester tester) async {
    final MockGoogleSignInPlugin mockSignInPlugin = MockGoogleSignInPlugin();
    when(mockSignInPlugin.onCurrentUserChanged).thenAnswer((_) => Stream<GoogleSignInAccount>.value(null));
    final GoogleSignInService signInService = GoogleSignInService(googleSignIn: mockSignInPlugin);

    final FlutterBuildState buildState = FlutterBuildState(
      cocoonService: MockCocoonService(),
      authService: signInService, // TODO(ianh): Settle on one of these two for the whole codebase.
    );

    int callCount = 0;
    buildState.addListener(() => callCount += 1);

    await tester.pump(const Duration(seconds: 5));
    expect(callCount, 1);

    await signInService.signIn();
    expect(callCount, 2);

    await signInService.signOut();
    expect(callCount, 3);
  });
}

CommitStatus _createCommitStatus(
  String keyValue, {
  String branch = 'master',
}) {
  return CommitStatus()
    ..branch = branch
    ..commit = (Commit()
      // Author is set so we don't have to dig through all the nested fields
      // while debugging
      ..author = keyValue
      ..key = (RootKey()..child = (Key()..name = keyValue)));
}
