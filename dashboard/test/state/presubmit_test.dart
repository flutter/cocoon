// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_dashboard/state/presubmit.dart';
import 'package:flutter_test/flutter_test.dart';

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
  });
}
