// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:mockito/mockito.dart';
import 'package:process/process.dart';
import 'package:test/test.dart';

import 'package:device_doctor/src/host_utils.dart';

void main() {
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

  group('killAllRunningProcessesOnWindows', () {
    MockProcessManager processManager;
    String output;
    String pid;

    setUp(() {
      processManager = MockProcessManager();
      when(processManager.runSync(<String>['powershell', 'Get-CimInstance', 'Win32_Process']))
          .thenAnswer((_) => ProcessResult(1, 0, output, 'def'));
    });

    test('when there are unkilled processes', () async {
      when(processManager.runSync(<String>['taskkill', '/pid', pid, '/f']))
          .thenAnswer((_) => ProcessResult(1, 0, 'test', 'test'));
      pid = '123';
      output = '$pid abc';
      final bool result = await killAllRunningProcessesOnWindows('abc', processManager: processManager);
      expect(result, equals(false));
    });

    test('when all processes are killed', () async {
      pid = '123';
      output = '$pid abc';
      when(processManager.runSync(<String>['taskkill', '/pid', pid, '/f'])).thenAnswer((_) {
        pid = '';
        output = '';
        return ProcessResult(1, 0, 'test', 'test');
      });
      final bool result = await killAllRunningProcessesOnWindows('abc', processManager: processManager);
      expect(result, equals(true));
    });
  });
}

class MockProcessManager extends Mock implements ProcessManager {}
