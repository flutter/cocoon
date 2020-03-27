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
    MockCocoonService mockCocoonService;
    CommitStatus setupCommitStatus;

    setUp(() {
      mockCocoonService = MockCocoonService();
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
      final FlutterBuildState buildState = FlutterBuildState(
        authService: MockGoogleSignInService(),
        cocoonService: mockCocoonService,
      );
      void listener() {}
      buildState.addListener(listener);

      // startFetching immediately starts fetching results
      verify(mockCocoonService.fetchFlutterBranches()).called(1);

      buildState.dispose();
    });

    testWidgets('timer should periodically fetch updates', (WidgetTester tester) async {
      final FlutterBuildState buildState = FlutterBuildState(
        authService: MockGoogleSignInService(),
        cocoonService: mockCocoonService,
      );
      verifyNever(mockCocoonService.fetchCommitStatuses(branch: anyNamed('branch')));

      void listener() {}
      buildState.addListener(listener);

      // startFetching immediately starts fetching results
      verify(mockCocoonService.fetchCommitStatuses(branch: _defaultBranch)).called(1);

      verifyNever(mockCocoonService.fetchCommitStatuses(branch: anyNamed('branch')));
      await tester.pump(buildState.refreshRate * 2);
      verify(mockCocoonService.fetchCommitStatuses(branch: _defaultBranch)).called(2);

      buildState.dispose();
    });

    testWidgets('multiple start updates should not change the timer', (WidgetTester tester) async {
      final FlutterBuildState buildState = FlutterBuildState(
        authService: MockGoogleSignInService(),
        cocoonService: mockCocoonService,
      );
      void listener1() {}
      buildState.addListener(listener1);

      // Another listener shouldn't change the timer.
      final Timer refreshTimer = buildState.refreshTimer;
      void listener2() {}
      buildState.addListener(listener2);
      expect(buildState.refreshTimer, equals(refreshTimer));

      // Removing a listener shouldn't change the timer.
      buildState.removeListener(listener1);
      expect(buildState.refreshTimer, equals(refreshTimer));

      // Removing both listeners should cancel the timer.
      buildState.removeListener(listener2);
      expect(buildState.refreshTimer, isNull);

      // A new listener now should change the timer.
      buildState.addListener(listener1);
      expect(buildState.refreshTimer, isNot(isNull));
      expect(buildState.refreshTimer, isNot(equals(refreshTimer)));

      buildState.dispose();
    });

    testWidgets('statuses error should not delete previous statuses data', (WidgetTester tester) async {
      String lastError;
      final FlutterBuildState buildState = FlutterBuildState(
        authService: MockGoogleSignInService(),
        cocoonService: mockCocoonService,
      )..errors.addListener((String message) => lastError = message);
      verifyNever(mockCocoonService.fetchTreeBuildStatus(branch: anyNamed('branch')));
      verifyNever(mockCocoonService.fetchCommitStatuses(branch: anyNamed('branch')));
      void listener() {}
      buildState.addListener(listener);
      verify(mockCocoonService.fetchTreeBuildStatus(branch: _defaultBranch)).called(1);
      verify(mockCocoonService.fetchCommitStatuses(branch: _defaultBranch)).called(1);
      await tester.pump();
      final List<CommitStatus> originalData = buildState.statuses;
      verifyNever(mockCocoonService.fetchTreeBuildStatus(branch: anyNamed('branch')));
      verifyNever(mockCocoonService.fetchCommitStatuses(branch: anyNamed('branch')));
      verifyNever(mockCocoonService.fetchTreeBuildStatus(branch: _defaultBranch));
      verifyNever(mockCocoonService.fetchCommitStatuses(branch: _defaultBranch));

      when(mockCocoonService.fetchCommitStatuses(branch: _defaultBranch)).thenAnswer(
        (_) =>
            Future<CocoonResponse<List<CommitStatus>>>.value(const CocoonResponse<List<CommitStatus>>.error('error')),
      );
      await checkOutput(
        block: () async {
          await tester.pump(buildState.refreshRate);
        },
        output: <String>[
          'An error occured fetching build statuses from Cocoon: error',
        ],
      );
      verify(mockCocoonService.fetchTreeBuildStatus(branch: _defaultBranch)).called(1);
      verify(mockCocoonService.fetchCommitStatuses(branch: _defaultBranch)).called(1);

      expect(buildState.statuses, originalData);
      expect(lastError, startsWith(FlutterBuildState.errorMessageFetchingStatuses));

      buildState.dispose();
    });

    testWidgets('build status error should not delete previous build status data', (WidgetTester tester) async {
      String lastError;
      final FlutterBuildState buildState = FlutterBuildState(
        authService: MockGoogleSignInService(),
        cocoonService: mockCocoonService,
      )..errors.addListener((String message) => lastError = message);
      verifyNever(mockCocoonService.fetchTreeBuildStatus(branch: anyNamed('branch')));
      void listener() {}
      buildState.addListener(listener);

      await tester.pump();
      verify(mockCocoonService.fetchTreeBuildStatus(branch: _defaultBranch)).called(1);
      final bool originalData = buildState.isTreeBuilding;
      verifyNever(mockCocoonService.fetchTreeBuildStatus(branch: anyNamed('branch')));
      verifyNever(mockCocoonService.fetchTreeBuildStatus(branch: _defaultBranch));

      when(mockCocoonService.fetchTreeBuildStatus(branch: _defaultBranch)).thenAnswer(
        (_) => Future<CocoonResponse<bool>>.value(const CocoonResponse<bool>.error('error')),
      );
      await checkOutput(
        block: () async {
          await tester.pump(buildState.refreshRate);
        },
        output: <String>[
          'An error occured fetching tree status from Cocoon: error',
        ],
      );
      verify(mockCocoonService.fetchTreeBuildStatus(branch: _defaultBranch)).called(1);

      expect(buildState.isTreeBuilding, originalData);
      expect(lastError, startsWith(FlutterBuildState.errorMessageFetchingTreeStatus));

      buildState.dispose();
    });

    testWidgets('fetch more commit statuses appends', (WidgetTester tester) async {
      final FlutterBuildState buildState = FlutterBuildState(
        authService: MockGoogleSignInService(),
        cocoonService: mockCocoonService,
      );
      void listener() {}
      buildState.addListener(listener);

      await untilCalled(mockCocoonService.fetchCommitStatuses(branch: anyNamed('branch')));

      expect(buildState.statuses, <CommitStatus>[setupCommitStatus]);

      final CommitStatus statusA = _createCommitStatus('A');
      when(
        mockCocoonService.fetchCommitStatuses(
          lastCommitStatus: captureThat(isNotNull, named: 'lastCommitStatus'),
          branch: anyNamed('branch'),
        ),
      ).thenAnswer((_) async => CocoonResponse<List<CommitStatus>>.data(<CommitStatus>[statusA]));

      await buildState.fetchMoreCommitStatuses();

      expect(buildState.statuses, <CommitStatus>[setupCommitStatus, statusA]);

      await tester.pump(buildState.refreshRate);

      expect(buildState.statuses, <CommitStatus>[setupCommitStatus, statusA]);
      expect(buildState.moreStatusesExist, true);

      buildState.dispose();
    });

    testWidgets('fetchMoreCommitStatuses returns empty stops fetching more', (WidgetTester tester) async {
      final FlutterBuildState buildState = FlutterBuildState(
        authService: MockGoogleSignInService(),
        cocoonService: mockCocoonService,
      );
      void listener() {}
      buildState.addListener(listener);

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
      when(
        mockCocoonService.fetchCommitStatuses(branch: 'master'),
      ).thenAnswer(
        (_) => Future<CocoonResponse<List<CommitStatus>>>.value(
          CocoonResponse<List<CommitStatus>>.data(<CommitStatus>[setupCommitStatus]),
        ),
      );
      // Mark tree green on master, red on dev
      when(mockCocoonService.fetchTreeBuildStatus(branch: 'master'))
          .thenAnswer((_) => Future<CocoonResponse<bool>>.value(const CocoonResponse<bool>.data(true)));
      when(mockCocoonService.fetchTreeBuildStatus(branch: 'dev'))
          .thenAnswer((_) => Future<CocoonResponse<bool>>.value(const CocoonResponse<bool>.data(false)));
      final FlutterBuildState buildState = FlutterBuildState(
        authService: MockGoogleSignInService(),
        cocoonService: mockCocoonService,
      );
      void listener() {}
      buildState.addListener(listener);

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
    final MockCocoonService mockCocoonService = MockCocoonService();
    when(mockCocoonService.fetchFlutterBranches()).thenAnswer((_) => Completer<CocoonResponse<List<String>>>().future);
    when(mockCocoonService.fetchCommitStatuses(branch: anyNamed('branch')))
        .thenAnswer((_) => Completer<CocoonResponse<List<CommitStatus>>>().future);
    when(mockCocoonService.fetchTreeBuildStatus(branch: anyNamed('branch')))
        .thenAnswer((_) => Completer<CocoonResponse<bool>>().future);
    final GoogleSignInService signInService = GoogleSignInService(googleSignIn: mockSignInPlugin);
    final FlutterBuildState buildState = FlutterBuildState(
      cocoonService: mockCocoonService,
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

    buildState.dispose();
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
