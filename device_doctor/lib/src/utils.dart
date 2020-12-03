// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert' show JsonEncoder;
import 'dart:io';

import 'package:meta/meta.dart';
import 'package:path/path.dart' as path;
import 'package:process/process.dart';
import 'package:yaml/yaml.dart';

/// Virtual current working directory, which affect functions, such as [exec].
String cwd = Directory.current.path;

ProcessManager processManager = LocalProcessManager();

final Logger logger = PrintLogger(out: stdout, level: LogLevel.info);

class LogLevel {
  const LogLevel._(this._level, this.name);

  final int _level;
  final String name;

  static const LogLevel debug = const LogLevel._(0, 'DEBUG');
  static const LogLevel info = const LogLevel._(1, 'INFO');
  static const LogLevel warning = const LogLevel._(2, 'WARN');
  static const LogLevel error = const LogLevel._(3, 'ERROR');
}

abstract class Logger {
  void debug(Object message);
  void info(Object message);
  void warning(Object message);
  void error(Object message);
}

class PrintLogger implements Logger {
  PrintLogger({
    IOSink out,
    this.level = LogLevel.info,
  }) : out = out ?? stdout;

  final IOSink out;
  final LogLevel level;

  @override
  void debug(Object message) => _log(LogLevel.debug, message);

  @override
  void info(Object message) => _log(LogLevel.info, message);

  @override
  void warning(Object message) => _log(LogLevel.warning, message);

  @override
  void error(Object message) => _log(LogLevel.error, message);

  void _log(LogLevel level, Object message) {
    if (level._level >= this.level._level) out.writeln(toLogString('$message', level: level));
  }
}

String toLogString(String message, {LogLevel level}) {
  final StringBuffer buffer = StringBuffer();
  buffer.write(DateTime.now().toIso8601String());
  buffer.write(': ');
  if (level != null) {
    buffer.write(level.name);
    buffer.write(' ');
  }
  buffer.write(message);
  return buffer.toString();
}

class BuildFailedError extends Error {
  BuildFailedError(this.message);

  final String message;

  @override
  String toString() => message;
}

void fail(String message) {
  throw BuildFailedError(message);
}

void rm(FileSystemEntity entity) {
  if (entity.existsSync()) entity.deleteSync();
}

/// Remove recursively.
void rrm(FileSystemEntity entity) {
  if (entity.existsSync()) entity.deleteSync(recursive: true);
}

List<FileSystemEntity> ls(Directory directory) => directory.listSync();

/// Creates a directory from the given path, or multiple path parts by joining
/// them using OS-specific file path separator.
Directory dir(String thePath,
    [String part2, String part3, String part4, String part5, String part6, String part7, String part8]) {
  return Directory(path.join(thePath, part2, part3, part4, part5, part6, part7, part8));
}

/// Creates a file from the given path, or multiple path parts by joining
/// them using OS-specific file path separator.
File file(String thePath,
    [String part2, String part3, String part4, String part5, String part6, String part7, String part8]) {
  return File(path.join(thePath, part2, part3, part4, part5, part6, part7, part8));
}

void copy(File sourceFile, Directory targetDirectory, {String name}) {
  File target = file(path.join(targetDirectory.path, name ?? path.basename(sourceFile.path)));
  target.writeAsBytesSync(sourceFile.readAsBytesSync());
}

FileSystemEntity move(FileSystemEntity whatToMove, {Directory to, String name}) {
  return whatToMove.renameSync(path.join(to.path, name ?? path.basename(whatToMove.path)));
}

/// Equivalent of `mkdir directory`.
void mkdir(Directory directory) {
  directory.createSync();
}

/// Equivalent of `mkdir -p directory`.
void mkdirs(Directory directory) {
  directory.createSync(recursive: true);
}

bool exists(FileSystemEntity entity) => entity.existsSync();

void section(String title) {
  logger.info('');
  logger.info('••• $title •••');
}

Future<dynamic> inDirectory(dynamic directory, Future<dynamic> action()) async {
  String previousCwd = cwd;
  try {
    cd(directory);
    return await action();
  } finally {
    cd(previousCwd);
  }
}

void cd(dynamic directory) {
  Directory d;
  if (directory is String) {
    cwd = directory;
    d = dir(directory);
  } else if (directory is Directory) {
    cwd = directory.path;
    d = directory;
  } else {
    throw 'Unsupported type ${directory.runtimeType} of $directory';
  }

  if (!d.existsSync()) throw 'Cannot cd into directory that does not exist: $directory';
}

String requireEnvVar(String name) {
  String value = Platform.environment[name];

  if (value == null) fail('${name} environment variable is missing. Quitting.');

  return value;
}

T requireConfigProperty<T>(YamlMap map, String propertyName) {
  if (!map.containsKey(propertyName)) fail('Configuration property not found: $propertyName');

  return map[propertyName] as T;
}

String jsonEncode(dynamic data) {
  return JsonEncoder.withIndent('  ').convert(data) + '\n';
}

/// Splits [from] into lines and selects those that contain [pattern].
Iterable<String> grep(Pattern pattern, {@required String from}) {
  return from.split('\n').where((String line) {
    return line.contains(pattern);
  });
}

bool canRun(String path) => processManager.canRun(path);

final RegExp _whitespace = RegExp(r'\s+');

List<String> runningProcessesOnWindows(String processName) {
  final ProcessResult result = processManager.runSync(<String>['powershell', 'Get-CimInstance', 'Win32_Process']);
  List<String> pids = <String>[];
  if (result.exitCode == 0) {
    final String stdoutResult = result.stdout as String;
    for (String rawProcess in stdoutResult.split('\n')) {
      final String process = rawProcess.trim();
      if (!process.contains(processName)) {
        continue;
      }
      final List<String> parts = process.split(_whitespace);

      final String processPid = parts[0];
      final String currentRunningProcessPid = pid.toString();
      // Don't kill current process
      if (processPid == currentRunningProcessPid) {
        continue;
      }
      pids.add(processPid);
    }
  }
  return pids;
}

/// Indicates to the linter that the given future is intentionally not `await`-ed.
///
/// Has the same functionality as `unawaited` from `package:pedantic`.
///
/// In an async context, it is normally expected than all Futures are awaited,
/// and that is the basis of the lint unawaited_futures which is turned on for
/// the flutter_tools package. However, there are times where one or more
/// futures are intentionally not awaited. This function may be used to ignore a
/// particular future. It silences the unawaited_futures lint.
void unawaited(Future<void> future) {}
