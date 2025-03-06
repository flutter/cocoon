// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:logging/logging.dart';
import 'package:mockito/mockito.dart';
import 'package:platform/platform.dart';
import 'package:process/process.dart';

class MockPlatform extends Mock implements Platform {
  @override
  Map<String, String> environment = <String, String>{};
}

class MockProcessManager extends Mock implements ProcessManager {
  @override
  Future<Process> start(
    List<Object>? command, {
    String? workingDirectory,
    Map<String, String>? environment,
    bool includeParentEnvironment = true,
    bool runInShell = false,
    ProcessStartMode mode = ProcessStartMode.normal,
  }) {
    return super.noSuchMethod(
      Invocation.method(
        #start,
        [command],
        {#workingDirectory: workingDirectory},
      ),
      returnValue: Future<Process>.value(FakeProcess(0)),
    );
  }

  @override
  ProcessResult runSync(
    List<Object> command, {
    String? workingDirectory,
    Map<String, String>? environment,
    bool includeParentEnvironment = true,
    bool runInShell = false,
    covariant Encoding? stdoutEncoding = systemEncoding,
    covariant Encoding? stderrEncoding = systemEncoding,
  }) {
    return super.noSuchMethod(
      Invocation.method(#runSync, [command]),
      returnValue: ProcessResult(1, 0, 'abc', 'def'),
    );
  }

  @override
  Future<ProcessResult> run(
    List<Object> command, {
    String? workingDirectory,
    Map<String, String>? environment,
    bool includeParentEnvironment = true,
    bool runInShell = false,
    covariant Encoding? stdoutEncoding = systemEncoding,
    covariant Encoding? stderrEncoding = systemEncoding,
  }) {
    return super.noSuchMethod(
      Invocation.method(#run, [command]),
      returnValue: Future.value(ProcessResult(1, 0, 'abc', 'def')),
    );
  }
}

class FakeProcess extends Fake implements Process {
  FakeProcess(
    int exitCode, {
    List<List<int>>? err = const [
      <int>[1, 2, 3],
    ],
    List<List<int>>? out = const [
      <int>[1, 2, 3],
    ],
  }) : _exitCode = exitCode,
       _err = err,
       _out = out;

  final int _exitCode;
  final List<List<int>>? _err;
  final List<List<int>>? _out;

  @override
  Future<int> get exitCode => Future.value(_exitCode);

  @override
  Stream<List<int>> get stderr => Stream.fromIterable(_err ?? <List<int>>[]);

  @override
  Stream<List<int>> get stdout =>
      Stream.fromIterable(_out ?? <List<int>>[utf8.encode('test')]);
}

class TestLogger implements Logger {
  @override
  final String name = 'test-logger';
  @override
  String get fullName => name;
  @override
  void clearListeners() => throw UnimplementedError('Unimplemented!');
  @override
  bool isLoggable(Level value) => throw UnimplementedError('Unimplemented!');
  @override
  Level get level => throw UnimplementedError('Unimplemented!');
  @override
  set level(Level? value) => throw UnimplementedError('Unimplemented!');
  @override
  Stream<LogRecord> get onRecord => throw UnimplementedError('Unimplemented!');
  @override
  Stream<Level?> get onLevelChanged =>
      throw UnimplementedError('Unimplemented!');
  @override
  final Logger? parent = null;
  @override
  final Map<String, Logger> children = const <String, Logger>{};

  final Map<Level, List<String>> logs = <Level, List<String>>{};

  @override
  void log(
    Level logLevel,
    Object? message, [
    Object? error,
    StackTrace? stackTrace,
    Zone? zone,
  ]) {
    logs[logLevel] ??= <String>[];
    logs[logLevel]!.add(message.toString());
  }

  @override
  void finest(Object? message, [Object? error, StackTrace? stackTrace]) =>
      log(Level.FINEST, message, error, stackTrace);

  @override
  void finer(Object? message, [Object? error, StackTrace? stackTrace]) =>
      log(Level.FINER, message, error, stackTrace);

  @override
  void fine(Object? message, [Object? error, StackTrace? stackTrace]) =>
      log(Level.FINE, message, error, stackTrace);

  @override
  void config(Object? message, [Object? error, StackTrace? stackTrace]) =>
      log(Level.CONFIG, message, error, stackTrace);

  @override
  void info(Object? message, [Object? error, StackTrace? stackTrace]) =>
      log(Level.INFO, message, error, stackTrace);

  @override
  void warning(Object? message, [Object? error, StackTrace? stackTrace]) =>
      log(Level.WARNING, message, error, stackTrace);

  @override
  void severe(Object? message, [Object? error, StackTrace? stackTrace]) =>
      log(Level.SEVERE, message, error, stackTrace);

  @override
  void shout(Object? message, [Object? error, StackTrace? stackTrace]) =>
      log(Level.SHOUT, message, error, stackTrace);
}
