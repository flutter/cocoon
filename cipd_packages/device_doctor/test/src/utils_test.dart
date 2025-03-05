// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:device_doctor/src/utils.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import 'utils.dart';

void main() {
  group('grep', () {
    String pattern;
    String from;

    test('with multiple matched lines', () async {
      pattern = 'abc';
      from = 'abc\n'
          'def\n'
          'abcd';
      expect(grep(pattern, from: from), equals(<String>['abc', 'abcd']));
    });
  });

  group('startProcess', () {
    late MockProcessManager processManager;
    List<List<int>> output;

    setUp(() {
      processManager = MockProcessManager();
    });

    test('validate process', () async {
      final sb = StringBuffer();
      sb.writeln('abc');
      output = <List<int>>[utf8.encode(sb.toString())];
      final Process process = FakeProcess(123, out: output);
      when(processManager.start(any,
              workingDirectory: anyNamed('workingDirectory')))
          .thenAnswer((_) => Future.value(process));

      final proc = await startProcess('abc', <String>['a', 'b', 'c'],
          processManager: processManager);
      expect(proc, process);
    });
  });

  group('eval', () {
    late MockProcessManager processManager;
    List<List<int>> output;
    Process process;

    setUp(() {
      processManager = MockProcessManager();
    });

    test('exit code 0', () async {
      final sb = StringBuffer();
      sb.writeln('abc');
      output = <List<int>>[utf8.encode(sb.toString())];
      process = FakeProcess(0, out: output);
      when(processManager.start(any,
              workingDirectory: anyNamed('workingDirectory')))
          .thenAnswer((_) => Future.value(process));
      final result = await eval('abc', <String>['a', 'b', 'c'],
          processManager: processManager);
      expect('$result\n', sb.toString());
    });

    test('exit code not 0', () async {
      final sb = StringBuffer();
      sb.writeln('List of devices attached');
      sb.writeln('ZY223JQNMR      device');
      output = <List<int>>[utf8.encode(sb.toString())];
      process = FakeProcess(1, out: output);
      expect(
        eval('abc', <String>['a', 'b', 'c'], processManager: processManager),
        throwsA(const TypeMatcher<BuildFailedException>()),
      );
    });
  });

  group('getMacBinaryPath', () {
    late MockProcessManager processManager;
    List<List<int>> output;

    setUp(() {
      processManager = MockProcessManager();
    });

    test('returns path when binary exists by default', () async {
      const path = '/abc/def/ideviceinstaller';
      output = <List<int>>[utf8.encode(path)];
      final Process process = FakeProcess(0, out: output);
      when(processManager.start(<String>['which', 'ideviceinstaller'],
              workingDirectory: anyNamed('workingDirectory')))
          .thenAnswer((_) => Future.value(process));

      final result = await getMacBinaryPath('ideviceinstaller',
          processManager: processManager);
      expect(result, path);
    });

    test('throws exception when binary does not exist in any location',
        () async {
      final Process processM1 = FakeProcess(1, out: <List<int>>[]);
      final Process processDefault = FakeProcess(1, out: <List<int>>[]);
      when(processManager.start(<String>['which', 'ideviceinstaller'],
              workingDirectory: anyNamed('workingDirectory')))
          .thenAnswer((_) => Future.value(processDefault));
      when(
        processManager.start(
          <String>['which', 'ideviceinstaller'],
          workingDirectory: anyNamed('workingDirectory'),
        ),
      ).thenAnswer((_) => Future.value(processM1));

      expect(
        getMacBinaryPath('ideviceinstaller', processManager: processManager),
        throwsA(const TypeMatcher<BuildFailedException>()),
      );
    });
  });
}
