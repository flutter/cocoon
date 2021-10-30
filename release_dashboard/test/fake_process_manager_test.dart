// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'fake_process_manager.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FakeProcessManager', () {
    test('does not throw when expected FakeCommand runs', () {
      final FakeProcessManager processManager = FakeProcessManager.list(
        <FakeCommand>[
          const FakeCommand(command: <String>['rm', '-rf', '/']),
        ],
      );

      processManager.runSync(
        <String>['rm', '-rf', '/'],
      );

      expect(processManager.hasRemainingExpectations, false);
    });

    test('throws when unexpected command is run', () {
      final FakeProcessManager processManager = FakeProcessManager.empty();

      TestFailure? failure;
      // Note expect(() => cb(), throwsA(TestFailure)) does not work
      try {
        processManager.runSync(<String>['rm', '-rf', '/']);
      } on TestFailure catch (e) {
        failure = e;
      }
      expect(failure != null, true);
    });
  });
}
