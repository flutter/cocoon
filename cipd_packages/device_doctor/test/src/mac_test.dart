// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:device_doctor/src/mac.dart';
import 'package:device_doctor/src/utils.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import 'utils.dart';

void main() {
  group('Mac - health checks', () {
    late MockProcessManager processManager;
    late Process process;
    List<List<int>> output;

    setUp(() {
      processManager = MockProcessManager();
    });

    test('Swarming user auto login check - success', () async {
      when(processManager.start(any,
              workingDirectory: anyNamed('workingDirectory')))
          .thenAnswer((_) => Future.value(process));
      output = <List<int>>[utf8.encode('swarming')];
      process = FakeProcess(0, out: output);
      final healthCheckResult =
          await userAutoLoginCheck(processManager: processManager);
      expect(healthCheckResult.succeeded, true);
    });

    test('Swarming user auto login check - exception', () async {
      when(processManager.start(any,
              workingDirectory: anyNamed('workingDirectory')))
          .thenAnswer((_) => Future.value(process));
      process = FakeProcess(1);
      final healthCheckResult =
          await userAutoLoginCheck(processManager: processManager);
      expect(healthCheckResult.succeeded, false);
      expect(healthCheckResult.name, kUserAutoLoginCheckKey);
      expect(healthCheckResult.details,
          'Executable defaults failed with exit code 1.');
    });

    test('Swarming user auto login check - failure', () async {
      when(processManager.start(any,
              workingDirectory: anyNamed('workingDirectory')))
          .thenAnswer((_) => Future.value(process));
      output = <List<int>>[utf8.encode('test')];
      process = FakeProcess(0, out: output);
      final healthCheckResult =
          await userAutoLoginCheck(processManager: processManager);
      expect(healthCheckResult.succeeded, false);
      expect(healthCheckResult.name, kUserAutoLoginCheckKey);
      expect(healthCheckResult.details,
          'swarming user is not setup for auto login');
    });
  });
}
