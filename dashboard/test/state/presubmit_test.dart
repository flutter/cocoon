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
  });
}
