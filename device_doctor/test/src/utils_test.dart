// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import 'package:device_doctor/src/utils.dart';

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
    MockProcessManager processManager;
    List<List<int>> output;

    setUp(() {
      processManager = MockProcessManager();
    });

    test('validate process', () async {
      StringBuffer sb = new StringBuffer();
      sb.writeln('abc');
      output = <List<int>>[utf8.encode(sb.toString())];
      Process process = FakeProcess(123, out: output);
      when(processManager.start(any, workingDirectory: anyNamed('workingDirectory')))
          .thenAnswer((_) => Future.value(process));

      Process proc = await startProcess('abc', <String>['a', 'b', 'c'], processManager: processManager);
      expect(proc, process);
    });
  });

  group('eval', () {
    MockProcessManager processManager;
    List<List<int>> output;
    Process process;

    setUp(() {
      processManager = MockProcessManager();
      when(processManager.start(any, workingDirectory: anyNamed('workingDirectory')))
          .thenAnswer((_) => Future.value(process));
    });

    test('exit code 0', () async {
      StringBuffer sb = new StringBuffer();
      sb.writeln('abc');
      output = <List<int>>[utf8.encode(sb.toString())];
      process = FakeProcess(0, out: output);
      final String result = await eval('abc', <String>['a', 'b', 'c'], processManager: processManager);
      expect('$result\n', sb.toString());
    });

    test('exit code not 0', () async {
      StringBuffer sb = new StringBuffer();
      sb.writeln('List of devices attached');
      sb.writeln('ZY223JQNMR      device');
      output = <List<int>>[utf8.encode(sb.toString())];
      process = FakeProcess(1, out: output);
      expect(
        eval('abc', <String>['a', 'b', 'c'], processManager: processManager),
        throwsA(TypeMatcher<BuildFailedError>()),
      );
    });
  });
}
