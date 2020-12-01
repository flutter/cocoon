// Copyright 2016 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert' show utf8, JsonEncoder, LineSplitter;
import 'dart:io';

import 'package:meta/meta.dart';
import 'package:path/path.dart' as path;
import 'package:process/process.dart';
import 'package:yaml/yaml.dart';

import 'adb.dart';
import 'list_processes.dart';

/// Virtual current working directory, which affect functions, such as [exec].
String cwd = Directory.current.path;

Config _config;
Config get config => _config;

List<ProcessInfo> _runningProcesses = <ProcessInfo>[];
ProcessManager _processManager = LocalProcessManager();

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

class ProcessInfo {
  ProcessInfo(this.command, this.process);

  final DateTime startTime = DateTime.now();
  final String command;
  final Process process;

  @override
  String toString() {
    return '''
  command : $command
  started : $startTime
  pid     : ${process.pid}
'''
        .trim();
  }
}

/// Result of a health check for a specific parameter.
class HealthCheckResult {
  HealthCheckResult.success([this.details]) : succeeded = true;
  HealthCheckResult.failure(this.details) : succeeded = false;
  HealthCheckResult.error(dynamic error, dynamic stackTrace)
      : succeeded = false,
        details = 'ERROR: $error\n${stackTrace ?? ''}';

  final bool succeeded;
  final String details;

  @override
  String toString() {
    StringBuffer buf = StringBuffer(succeeded ? 'succeeded' : 'failed');
    if (details != null && details.trim().isNotEmpty) {
      buf.writeln();
      // Indent details by 4 spaces
      for (String line in details.trim().split('\n')) {
        buf.writeln('    $line');
      }
    }
    return '$buf';
  }
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

Future<Process> startProcess(String executable, List<String> arguments,
    {Map<String, String> env, bool silent: false}) async {
  String command = '$executable ${arguments?.join(" ") ?? ""}';
  if (!silent) logger.info('Executing: $command');
  Process proc =
      await _processManager.start(<String>[executable]..addAll(arguments), environment: env, workingDirectory: cwd);
  ProcessInfo procInfo = ProcessInfo(command, proc);
  _runningProcesses.add(procInfo);

  // ignore: unawaited_futures
  proc.exitCode.then((_) {
    _runningProcesses.remove(procInfo);
  });

  return proc;
}

Future<Null> forceQuitRunningProcesses() async {
  // Give normally quitting processes a chance to report their exit code.
  await Future<void>.delayed(const Duration(seconds: 1));

  // Whatever's left, kill it.
  for (ProcessInfo p in _runningProcesses) {
    logger.info('Force quitting process:\n$p');
    if (!p.process.kill()) {
      logger.warning('Failed to force quit process');
    }
  }
  _runningProcesses.clear();

  // Also kill sub-processes launched by top-level processes. We may not be
  // able to find all of them, but finding those whose CWD is the Flutter
  // repository are good candidates.
  List<int> pids = await listFlutterProcessIds(config.flutterDirectory);
  for (int pid in pids) {
    Process.killPid(pid, ProcessSignal.sigkill);
  }
}

/// Executes a command and returns its exit code.
Future<int> exec(String executable, List<String> arguments,
    {Map<String, String> env, bool canFail: false, bool silent: false}) async {
  Process proc = await startProcess(executable, arguments, env: env, silent: silent);

  final StreamSubscription<String> stdoutSubscription =
      proc.stdout.transform(utf8.decoder).transform(const LineSplitter()).listen(logger.info);
  final StreamSubscription<String> stderrSubscription =
      proc.stderr.transform(utf8.decoder).transform(const LineSplitter()).listen(logger.warning);

  // Wait for stdout and stderr to be fully processed because proc.exitCode
  // may complete first.
  await Future.wait<void>(<Future<void>>[
    stdoutSubscription.asFuture<void>(),
    stderrSubscription.asFuture<void>(),
  ]);
  // The streams as futures have already completed, so waiting for the
  // potentially async stream cancellation to complete likely has no benefit.
  unawaited(stdoutSubscription.cancel());
  unawaited(stderrSubscription.cancel());

  int exitCode = await proc.exitCode;
  if (exitCode != 0 && !canFail) {
    final List<String> command = [executable]..addAll(arguments);
    fail('Command "${command.join(' ')}" failed with exit code $exitCode.');
  }

  return exitCode;
}

/// Executes a command and returns its standard output as a String.
///
/// Standard error is redirected to the current process' standard error stream.
Future<String> eval(String executable, List<String> arguments,
    {Map<String, String> env, bool canFail: false, bool silent: false}) async {
  Process proc = await startProcess(executable, arguments, env: env, silent: silent);
  proc.stderr.listen((List<int> data) {
    stderr.add(data);
  });
  String output = await utf8.decodeStream(proc.stdout);
  int exitCode = await proc.exitCode;

  if (exitCode != 0 && !canFail) fail('Executable $executable failed with exit code $exitCode.');

  return output.trimRight();
}

Future<int> flutter(String command, {List<String> options: const <String>[], bool canFail: false}) {
  List<String> args = [command]..addAll(options);
  return exec(path.join(config.flutterDirectory.path, 'bin', 'flutter'), args, canFail: canFail);
}

String get dartBin => path.join(config.flutterDirectory.path, 'bin', 'cache', 'dart-sdk', 'bin', 'dart');

Future<int> dart(List<String> args) {
  args.insert(0, '--disable-dart-dev');
  return exec(dartBin, args);
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

class Config {
  Config({
    @required this.flutterDirectory,
    @required this.deviceOperatingSystem,
    @required this.hostType,
  });

  static void initialize(String deviceOS) {
    String home = Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'];
    if (home == null) throw "Unable to find \$HOME or \$USERPROFILE.";

    Directory flutterDirectory = dir(home, '.cocoon', 'flutter');
    mkdirs(flutterDirectory);

    DeviceOperatingSystem deviceOperatingSystem;
    switch (deviceOS) {
      case 'android':
        deviceOperatingSystem = DeviceOperatingSystem.android;
        break;
      case 'ios':
        deviceOperatingSystem = DeviceOperatingSystem.ios;
        break;
      case 'none':
        deviceOperatingSystem = DeviceOperatingSystem.none;
        break;
      default:
        throw BuildFailedError('Unrecognized device_os value: $deviceOS');
    }

    HostType hostType = HostType.physical;

    _config = Config(
      flutterDirectory: flutterDirectory,
      deviceOperatingSystem: deviceOperatingSystem,
      hostType: hostType,
    );
  }

  final Directory flutterDirectory;
  final DeviceOperatingSystem deviceOperatingSystem;
  final HostType hostType;

  String get adbPath {
    String androidHome = Platform.environment['ANDROID_HOME'];

    if (androidHome == null)
      throw 'ANDROID_HOME environment variable missing. This variable must '
          'point to the Android SDK directory containing platform-tools.';

    String adbPath = path.join(androidHome, 'platform-tools', 'adb');

    if (!_processManager.canRun(adbPath)) throw 'adb not found at: $adbPath';

    return path.absolute(adbPath);
  }

  @override
  String toString() => '''
flutterDirectory: $flutterDirectory
adbPath: ${deviceOperatingSystem == DeviceOperatingSystem.android ? adbPath : 'N/A'}
deviceOperatingSystem: $deviceOperatingSystem
hostType: $hostType
'''
      .trim();
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

bool canRun(String path) => _processManager.canRun(path);

final RegExp _whitespace = RegExp(r'\s+');

List<String> runningProcessesOnWindows(String processName) {
  final ProcessResult result = _processManager.runSync(<String>['powershell', 'Get-CimInstance', 'Win32_Process']);
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

Future<void> killAllRunningProcessesOnWindows(String processName) async {
  while (true) {
    final pids = runningProcessesOnWindows(processName);
    if (pids.isEmpty) {
      return;
    }
    for (String pid in pids) {
      _processManager.runSync(<String>['taskkill', '/pid', pid, '/f']);
    }
    // Killed processes don't release resources instantenously.
    await Future<void>.delayed(Duration(seconds: 1));
  }
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

/// Unlocks the login keychain on macOS.
///
/// Whic is required to
///   1. Enable Xcode to access the certificate for code signing.
///   2. Mitigate "Your session has expired" issue. See flutter/flutter#17860.
Future<Null> unlockKeyChain() async {
  if (Platform.isMacOS) {
    await exec(
        'security', <String>['unlock-keychain', '-p', Platform.environment['FLUTTER_USER_SECRET'], 'login.keychain'],
        canFail: false, silent: true);
  }
}

/// Overall health of the device.
class DeviceHealth {
  /// Check results keyed by parameter.
  final Map<String, HealthCheckResult> checks = <String, HealthCheckResult>{};

  /// Whether all [checks] succeeded.
  bool get ok => checks.isNotEmpty && checks.values.every((HealthCheckResult r) => r.succeeded);

  /// Sets a health check [result] for a given [parameter].
  void operator []=(String parameter, HealthCheckResult result) {
    if (checks.containsKey(parameter)) {
      logger.warning('duplicate health check ${parameter} submitted');
    }
    checks[parameter] = result;
  }

  void addAll(Map<String, HealthCheckResult> checks) {
    checks.forEach((String p, HealthCheckResult r) {
      this[p] = r;
    });
  }

  /// Human-readable printout of the agent's health status.
  @override
  String toString() {
    StringBuffer buf = new StringBuffer();
    checks.forEach((String parameter, HealthCheckResult result) {
      buf.writeln('$parameter: $result');
    });
    return buf.toString();
  }
}
