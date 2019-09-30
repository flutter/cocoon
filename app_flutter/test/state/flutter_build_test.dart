// Copyright (c) 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import 'package:app_flutter/state/flutter_build.dart';
import '../service/mock_cocoon.dart';

void main() {
  group('FlutterBuildState', () {
    FlutterBuildState buildState;
    MockCocoonService mockService;

    setUp(() {
      mockService = MockCocoonService();
      buildState = FlutterBuildState(cocoonService: mockService);
    });

    tearDown(() {
      buildState.dispose();
    });

    testWidgets('timer should periodically fetch updates',
        (WidgetTester tester) async {
      verifyZeroInteractions(mockService);

      buildState.startFetchingBuildStateUpdates();

      // pump [refreshRate] so at least one fetch call is made
      await tester.pump(buildState.refreshRate);

      verify(mockService.fetchCommitStatuses()).called(greaterThan(0));
    });

    test('multiple start updates should not change the timer', () {
      buildState.startFetchingBuildStateUpdates();
      Timer refreshTimer = buildState.refreshTimer;

      // This second run should not change the refresh timer
      buildState.startFetchingBuildStateUpdates();

      expect(refreshTimer, equals(buildState.refreshTimer));
    });
  });
}
