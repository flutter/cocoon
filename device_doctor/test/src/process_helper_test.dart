// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:mockito/mockito.dart';
import 'package:process/process.dart';
import 'package:test/test.dart';

import 'package:device_doctor/src/process_helper.dart';

void main() {
  group('grep', () {
    String pattern;
    String from;

    test('deviceDiscovery no retries', () async {
      pattern = 'abc';
      from = 'abc\n'
          'def\n'
          'abcd';
      expect(grep(pattern, from: from), equals(<String>['abc', 'abcd']));
    });
  });

  group('runningProcessesOnWindows', () {
    MockProcessManager processManager;
    String output;

    setUp(() {
      processManager = MockProcessManager();
      when(processManager.runSync(<String>['powershell', 'Get-CimInstance', 'Win32_Process']))
          .thenAnswer((_) => ProcessResult(1, 0, output, 'def'));
    });

    test('when there is a single matched process', () async {
      output = '123 abc';
      List<String> processes = runningProcessesOnWindows('abc', processManager: processManager);
      expect(processes, equals(<String>['123']));
    });

    test('when there are more than one matched process', () async {
      output = '123 abc\n 456 abc\n 789 def';
      List<String> processes = runningProcessesOnWindows('abc', processManager: processManager);
      expect(processes, equals(<String>['123', '456']));
    });

    test('when there is no matched process', () async {
      output = '123 def';
      List<String> processes = runningProcessesOnWindows('abc', processManager: processManager);
      expect(processes, equals(<String>[]));
    });
  });
}

class MockProcessManager extends Mock implements ProcessManager {}
