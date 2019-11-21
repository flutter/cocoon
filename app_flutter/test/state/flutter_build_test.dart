// Copyright (c) 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import 'package:cocoon_service/protos.dart' show CommitStatus;

import 'package:app_flutter/service/cocoon.dart';
import 'package:app_flutter/service/fake_cocoon.dart';
import 'package:app_flutter/state/flutter_build.dart';

void main() {
  group('FlutterBuildState', () {
    FlutterBuildState buildState;
    MockCocoonService mockService;

    setUp(() {
      mockService = MockCocoonService();
      buildState = FlutterBuildState(cocoonServiceValue: mockService);

      when(mockService.fetchCommitStatuses()).thenAnswer((_) =>
          Future<CocoonResponse<List<CommitStatus>>>.value(
              CocoonResponse<List<CommitStatus>>()
                ..data = <CommitStatus>[CommitStatus()]));
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
  });
}

/// CocoonService for checking interactions.
class MockCocoonService extends Mock implements FakeCocoonService {}
