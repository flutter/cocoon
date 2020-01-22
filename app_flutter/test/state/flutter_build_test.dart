// Copyright (c) 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:mockito/mockito.dart';

import 'package:cocoon_service/protos.dart'
    show Commit, CommitStatus, Key, RootKey;

import 'package:app_flutter/service/cocoon.dart';
import 'package:app_flutter/service/fake_cocoon.dart';
import 'package:app_flutter/service/google_authentication.dart';
import 'package:app_flutter/state/flutter_build.dart';

void main() {
  group('FlutterBuildState', () {
    FlutterBuildState buildState;
    MockCocoonService mockService;

    CommitStatus setupCommitStatus;

    setUp(() {
      mockService = MockCocoonService();
      buildState = FlutterBuildState(cocoonServiceValue: mockService);

      setupCommitStatus = _createCommitStatusWithKey('setup');

      when(mockService.fetchCommitStatuses()).thenAnswer((_) =>
          Future<CocoonResponse<List<CommitStatus>>>.value(
              CocoonResponse<List<CommitStatus>>()
                ..data = <CommitStatus>[setupCommitStatus]));
      when(mockService.fetchTreeBuildStatus()).thenAnswer((_) =>
          Future<CocoonResponse<bool>>.value(
              CocoonResponse<bool>()..data = true));
    });

    testWidgets('timer should periodically fetch updates',
        (WidgetTester tester) async {
      buildState.startFetchingBuildStateUpdates();

      // startFetching immediately starts fetching results
      verify(mockService.fetchCommitStatuses()).called(1);

      // Periodic timers don't necessarily run at the same time in each interval.
      // We double the refreshRate to gurantee a call would have been made.
      await tester.pump(buildState.refreshRate * 2);
      verify(mockService.fetchCommitStatuses()).called(greaterThan(1));

      // Tear down fails to cancel the timer before the test is over
      buildState.dispose();
    });

    testWidgets('multiple start updates should not change the timer',
        (WidgetTester tester) async {
      buildState.startFetchingBuildStateUpdates();
      final Timer refreshTimer = buildState.refreshTimer;

      // This second run should not change the refresh timer
      buildState.startFetchingBuildStateUpdates();

      expect(refreshTimer, equals(buildState.refreshTimer));

      // Since startFetching sends out requests on start, we need to wait
      // for them to finish before disposing of the state.
      await tester.pumpAndSettle();

      // Tear down fails to cancel the timer before the test is over
      buildState.dispose();
    });

    testWidgets('statuses error should not delete previous statuses data',
        (WidgetTester tester) async {
      buildState.startFetchingBuildStateUpdates();

      // Periodic timers don't necessarily run at the same time in each interval.
      // We double the refreshRate to gurantee a call would have been made.
      await tester.pump(buildState.refreshRate * 2);
      final List<CommitStatus> originalData = buildState.statuses;

      when(mockService.fetchCommitStatuses()).thenAnswer((_) =>
          Future<CocoonResponse<List<CommitStatus>>>.value(
              CocoonResponse<List<CommitStatus>>()..error = 'error'));

      await tester.pump(buildState.refreshRate * 2);
      verify(mockService.fetchCommitStatuses()).called(greaterThan(1));

      expect(buildState.statuses, originalData);
      expect(buildState.errors.message,
          FlutterBuildState.errorMessageFetchingStatuses);

      // Tear down fails to cancel the timer before the test is over
      buildState.dispose();
    });

    testWidgets(
        'build status error should not delete previous build status data',
        (WidgetTester tester) async {
      buildState.startFetchingBuildStateUpdates();

      // Periodic timers don't necessarily run at the same time in each interval.
      // We double the refreshRate to gurantee a call would have been made.
      await tester.pump(buildState.refreshRate * 2);
      final bool originalData = buildState.isTreeBuilding;

      when(mockService.fetchTreeBuildStatus()).thenAnswer((_) =>
          Future<CocoonResponse<bool>>.value(
              CocoonResponse<bool>()..error = 'error'));

      await tester.pump(buildState.refreshRate * 2);
      verify(mockService.fetchTreeBuildStatus()).called(greaterThan(1));

      expect(buildState.isTreeBuilding, originalData);
      expect(buildState.errors.message,
          FlutterBuildState.errorMessageFetchingTreeStatus);

      // Tear down fails to cancel the timer before the test is over
      buildState.dispose();
    });

    testWidgets('fetch more commit statuses appends',
        (WidgetTester tester) async {
      buildState.startFetchingBuildStateUpdates();

      await untilCalled(mockService.fetchCommitStatuses());

      expect(buildState.statuses, <CommitStatus>[setupCommitStatus]);

      final CommitStatus statusA = _createCommitStatusWithKey('A');
      when(mockService.fetchCommitStatuses(
              lastCommitStatus:
                  captureThat(isNotNull, named: 'lastCommitStatus')))
          .thenAnswer((_) async => CocoonResponse<List<CommitStatus>>()
            ..data = <CommitStatus>[statusA]);

      await buildState.fetchMoreCommitStatuses();

      expect(buildState.statuses, <CommitStatus>[setupCommitStatus, statusA]);

      await tester.pump(buildState.refreshRate);

      expect(buildState.statuses, <CommitStatus>[setupCommitStatus, statusA]);

      buildState.dispose();
    });

    test('auth functions call auth service', () async {
      final MockGoogleSignInService mockSignInService =
          MockGoogleSignInService();
      buildState = FlutterBuildState(authServiceValue: mockSignInService);

      verifyNever(mockSignInService.signIn());
      verifyNever(mockSignInService.signOut());

      await buildState.signIn();
      verify(mockSignInService.signIn()).called(1);
      verifyNever(mockSignInService.signOut());

      await buildState.signOut();
      verify(mockSignInService.signOut()).called(1);
    });
  });

  testWidgets('sign in functions call notify listener',
      (WidgetTester tester) async {
    final MockGoogleSignInPlugin mockSignInPlugin = MockGoogleSignInPlugin();
    when(mockSignInPlugin.onCurrentUserChanged)
        .thenAnswer((_) => Stream<GoogleSignInAccount>.value(null));
    final GoogleSignInService signInService =
        GoogleSignInService(googleSignIn: mockSignInPlugin);
    final FlutterBuildState buildState =
        FlutterBuildState(authServiceValue: signInService);

    int callCount = 0;
    buildState.addListener(() => callCount++);

    // notify listener is called during construction of the state
    await tester.pump(const Duration(seconds: 5));
    expect(callCount, 1);

    await buildState.signIn();
    expect(callCount, 2);

    await buildState.signOut();
    expect(callCount, 3);
  });
}

CommitStatus _createCommitStatusWithKey(String keyValue) {
  return CommitStatus()
    ..commit = (Commit()
      ..author = keyValue
      ..key = (RootKey()..child = (Key()..name = keyValue)));
}

/// CocoonService for checking interactions.
class MockCocoonService extends Mock implements FakeCocoonService {}

class MockGoogleSignInPlugin extends Mock implements GoogleSignIn {}

/// Mock for testing interactions with [GoogleSignInService].
class MockGoogleSignInService extends Mock implements GoogleSignInService {}
