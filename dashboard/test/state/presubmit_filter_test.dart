// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_common/task_status.dart';
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
}
