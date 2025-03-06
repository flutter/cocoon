// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:device_doctor/src/host_utils.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import 'utils.dart';

void main() {
  group('runningProcessesOnWindows', () {
    late MockProcessManager processManager;
    String output;

    setUp(() {
      processManager = MockProcessManager();
    });

    test('when there is a single matched process', () async {
      output = '123 abc';
      when(
        processManager.runSync(<String>[
          'powershell',
          'Get-CimInstance',
          'Win32_Process',
        ]),
      ).thenAnswer((_) => ProcessResult(1, 0, output, 'def'));
      final processes = runningProcessesOnWindows(
        'abc',
        processManager: processManager,
      );
      expect(processes, equals(<String>['123']));
    });

    test('when there are more than one matched process', () async {
      output = '123 abc\n 456 abc\n 789 def';
      when(
        processManager.runSync(<String>[
          'powershell',
          'Get-CimInstance',
          'Win32_Process',
        ]),
      ).thenAnswer((_) => ProcessResult(1, 0, output, 'def'));
      final processes = runningProcessesOnWindows(
        'abc',
        processManager: processManager,
      );
      expect(processes, equals(<String>['123', '456']));
    });

    test('when there is no matched process', () async {
      output = '123 def';
      when(
        processManager.runSync(<String>[
          'powershell',
          'Get-CimInstance',
          'Win32_Process',
        ]),
      ).thenAnswer((_) => ProcessResult(1, 0, output, 'def'));
      final processes = runningProcessesOnWindows(
        'abc',
        processManager: processManager,
      );
      expect(processes, equals(<String>[]));
    });
  });

  group('killAllRunningProcessesOnWindows', () {
    late MockProcessManager processManager;
    String output;
    String pid;

    setUp(() {
      processManager = MockProcessManager();
    });

    test('when there are unkilled processes', () async {
      pid = '123';
      output = '$pid abc';
      when(
        processManager.runSync(<String>[
          'powershell',
          'Get-CimInstance',
          'Win32_Process',
        ]),
      ).thenAnswer((_) => ProcessResult(1, 0, output, 'def'));
      when(
        processManager.runSync(<String>['taskkill', '/pid', pid, '/f']),
      ).thenAnswer((_) => ProcessResult(1, 0, 'test', 'test'));
      final result = await killAllRunningProcessesOnWindows(
        'abc',
        processManager: processManager,
      );
      expect(result, equals(false));
    });

    test('when all processes are killed', () async {
      pid = '123';
      output = '$pid abc';
      when(
        processManager.runSync(<String>[
          'powershell',
          'Get-CimInstance',
          'Win32_Process',
        ]),
      ).thenAnswer((_) => ProcessResult(1, 0, output, 'def'));
      when(
        processManager.runSync(<String>['taskkill', '/pid', pid, '/f']),
      ).thenAnswer((_) {
        pid = '';
        output = '';
        return ProcessResult(1, 0, 'test', 'test');
      });
      final result = await killAllRunningProcessesOnWindows(
        'abc',
        processManager: processManager,
      );
      expect(result, equals(true));
    });
  });
}
