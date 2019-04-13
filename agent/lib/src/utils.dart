// Copyright (c) 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert' show json, utf8, JsonEncoder, LineSplitter;
import 'dart:io';

import 'package:args/args.dart';
import 'package:meta/meta.dart';
import 'package:process/process.dart';
import 'package:path/path.dart' as path;
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
    if (level._level >= this.level._level)
      out.writeln(toLogString('$message', level: level));
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
    [String part2,
    String part3,
    String part4,
    String part5,
    String part6,
    String part7,
    String part8]) {
  return Directory(
      path.join(thePath, part2, part3, part4, part5, part6, part7, part8));
}

/// Creates a file from the given path, or multiple path parts by joining
/// them using OS-specific file path separator.
File file(String thePath,
    [String part2,
    String part3,
    String part4,
    String part5,
    String part6,
    String part7,
    String part8]) {
  return File(
      path.join(thePath, part2, part3, part4, part5, part6, part7, part8));
}

void copy(File sourceFile, Directory targetDirectory, {String name}) {
  File target = file(
      path.join(targetDirectory.path, name ?? path.basename(sourceFile.path)));
  target.writeAsBytesSync(sourceFile.readAsBytesSync());
}

FileSystemEntity move(FileSystemEntity whatToMove,
    {Directory to, String name}) {
  return whatToMove
      .renameSync(path.join(to.path, name ?? path.basename(whatToMove.path)));
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

Future<String> getDartVersion() async {
  // The Dart VM returns the version text to stderr.
  ProcessResult result = _processManager.runSync([dartBin, '--version']);
  String version = result.stderr.trim();

  // Convert:
  //   Dart VM version: 1.17.0-dev.2.0 (Tue May  3 12:14:52 2016) on "macos_x64"
  // to:
  //   1.17.0-dev.2.0
  if (version.indexOf('(') != -1)
    version = version.substring(0, version.indexOf('(')).trim();
  if (version.indexOf(':') != -1)
    version = version.substring(version.indexOf(':') + 1).trim();

  return version.replaceAll('"', "'");
}

Future<String> getCurrentFlutterRepoCommit() {
  if (!dir(config.flutterDirectory.path, '.git').existsSync()) {
    return null;
  }

  return inDirectory(config.flutterDirectory, () {
    return eval('git', ['rev-parse', 'HEAD']);
  });
}

Future<DateTime> getFlutterRepoCommitTimestamp(String commit) {
  // git show -s --format=%at 4b546df7f0b3858aaaa56c4079e5be1ba91fbb65
  return inDirectory(config.flutterDirectory, () async {
    String unixTimestamp =
        await eval('git', ['show', '-s', '--format=%at', commit]);
    int secondsSinceEpoch = int.parse(unixTimestamp);
    return DateTime.fromMillisecondsSinceEpoch(secondsSinceEpoch * 1000);
  });
}

/// When exists, this file indicates an installation is in progress or failed
/// to complete.
File get _installationLock =>
    file(config.flutterDirectory.parent.path, '.installation-lock');

/// Flutter repository revision that's currently installed.
///
/// Returns `null` if nothing is installed or installation failed to complete.
Future<String> _getCurrentInstallationRevision() async {
  if (exists(_installationLock)) {
    return null;
  }

  return getCurrentFlutterRepoCommit();
}

Future<Null> getFlutterAt(String revision) async {
  String currentRevision = await _getCurrentInstallationRevision();

  // This agent will likely run multiple tasks in the same checklist and
  // therefore the same revision. It would be too costly to have to reinstall
  // Flutter every time.
  if (currentRevision == revision) {
    logger.info('Reusing previously checked out Flutter revision: $revision');
    return;
  }

  await getFlutter(revision);
}

Future<Process> startProcess(String executable, List<String> arguments,
    {Map<String, String> env, bool silent: false}) async {
  String command = '$executable ${arguments?.join(" ") ?? ""}';
  if (!silent) logger.info('Executing: $command');
  Process proc = await _processManager.start([executable]..addAll(arguments),
      environment: env, workingDirectory: cwd);
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
  await Future.delayed(const Duration(seconds: 1));

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
    {Map<String, String> env, bool canFail: false}) async {
  Process proc = await startProcess(executable, arguments, env: env);

  proc.stdout
      .transform(utf8.decoder)
      .transform(const LineSplitter())
      .listen(logger.info);
  proc.stderr
      .transform(utf8.decoder)
      .transform(const LineSplitter())
      .listen(logger.warning);

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
  Process proc =
      await startProcess(executable, arguments, env: env, silent: silent);
  proc.stderr.listen((List<int> data) {
    stderr.add(data);
  });
  String output = await utf8.decodeStream(proc.stdout);
  int exitCode = await proc.exitCode;

  if (exitCode != 0 && !canFail)
    fail('Executable $executable failed with exit code $exitCode.');

  return output.trimRight();
}

Future<int> flutter(String command,
    {List<String> options: const <String>[], bool canFail: false}) {
  List<String> args = [command]..addAll(options);
  return exec(path.join(config.flutterDirectory.path, 'bin', 'flutter'), args,
      canFail: canFail);
}

String get dartBin => path.join(
    config.flutterDirectory.path, 'bin', 'cache', 'dart-sdk', 'bin', 'dart');

Future<int> dart(List<String> args) => exec(dartBin, args);

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

  if (!d.existsSync())
    throw 'Cannot cd into directory that does not exist: $directory';
}

class Config {
  Config({
    @required this.baseCocoonUrl,
    @required this.agentId,
    @required this.authToken,
    @required this.flutterDirectory,
    @required this.deviceOperatingSystem,
  });

  static void initialize(ArgResults args) {
    File agentConfigFile = file(args['config-file']);

    if (!agentConfigFile.existsSync()) {
      throw ('Agent config file not found: ${agentConfigFile.path}.');
    }

    YamlMap agentConfig = loadYaml(agentConfigFile.readAsStringSync());
    String baseCocoonUrl = agentConfig['base_cocoon_url'] ??
        'https://flutter-dashboard.appspot.com';
    String agentId = requireConfigProperty<String>(agentConfig, 'agent_id');
    String authToken = requireConfigProperty<String>(agentConfig, 'auth_token');
    String home =
        Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'];
    if (home == null) throw "Unable to find \$HOME or \$USERPROFILE.";

    Directory flutterDirectory = dir(home, '.cocoon', 'flutter');
    mkdirs(flutterDirectory);

    DeviceOperatingSystem deviceOperatingSystem;
    switch (agentConfig['device_os']) {
      case 'android':
        deviceOperatingSystem = DeviceOperatingSystem.android;
        break;
      case 'ios':
        deviceOperatingSystem = DeviceOperatingSystem.ios;
        break;
      default:
        throw BuildFailedError(
            'Unrecognized device_os value: ${agentConfig['device_os']}');
    }

    _config = Config(
      baseCocoonUrl: baseCocoonUrl,
      agentId: agentId,
      authToken: authToken,
      flutterDirectory: flutterDirectory,
      deviceOperatingSystem: deviceOperatingSystem,
    );
  }

  final String baseCocoonUrl;
  final String agentId;
  final String authToken;
  final Directory flutterDirectory;
  final DeviceOperatingSystem deviceOperatingSystem;

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
baseCocoonUrl: $baseCocoonUrl
agentId: $agentId
flutterDirectory: $flutterDirectory
adbPath: ${deviceOperatingSystem == DeviceOperatingSystem.android ? adbPath : 'N/A'}
deviceOperatingSystem: $deviceOperatingSystem
'''
      .trim();
}

String requireEnvVar(String name) {
  String value = Platform.environment[name];

  if (value == null) fail('${name} environment variable is missing. Quitting.');

  return value;
}

T requireConfigProperty<T>(YamlMap map, String propertyName) {
  if (!map.containsKey(propertyName))
    fail('Configuration property not found: $propertyName');

  return map[propertyName];
}

String jsonEncode(dynamic data) {
  return JsonEncoder.withIndent('  ').convert(data) + '\n';
}

Future<Null> getFlutter(String revision) async {
  section('Get Flutter!');

  _installationLock.createSync(recursive: true);

  if (exists(config.flutterDirectory)) {
    rrm(config.flutterDirectory);
  }

  await inDirectory(config.flutterDirectory.parent, () async {
    await exec('git', ['clone', 'https://github.com/flutter/flutter.git']);
  });

  await inDirectory(config.flutterDirectory, () async {
    await exec('git', ['checkout', revision]);
  });

  await flutter('config', options: ['--no-analytics']);

  section('flutter doctor');
  await flutter('doctor');

  section('flutter update-packages');
  await flutter('update-packages');

  rm(_installationLock);
}

void checkNotNull(Object o1,
    [Object o2 = 1,
    Object o3 = 1,
    Object o4 = 1,
    Object o5 = 1,
    Object o6 = 1,
    Object o7 = 1,
    Object o8 = 1,
    Object o9 = 1,
    Object o10 = 1]) {
  if (o1 == null) throw 'o1 is null';

  if (o2 == null) throw 'o2 is null';

  if (o3 == null) throw 'o3 is null';

  if (o4 == null) throw 'o4 is null';

  if (o5 == null) throw 'o5 is null';

  if (o6 == null) throw 'o6 is null';

  if (o7 == null) throw 'o7 is null';

  if (o8 == null) throw 'o8 is null';

  if (o9 == null) throw 'o9 is null';

  if (o10 == null) throw 'o10 is null';
}

/// Add benchmark values to a JSON results file.
///
/// If the file contains information about how long the benchmark took to run
/// (a `time` field), then return that info.
// TODO(yjbanov): move this data to __metadata__
num addBuildInfo(File jsonFile,
    {num expected, String sdk, String commit, DateTime timestamp}) {
  Map<String, dynamic> jsonData;

  if (jsonFile.existsSync())
    jsonData = json.decode(jsonFile.readAsStringSync());
  else
    jsonData = <String, dynamic>{};

  if (expected != null) jsonData['expected'] = expected;
  if (sdk != null) jsonData['sdk'] = sdk;
  if (commit != null) jsonData['commit'] = commit;
  if (timestamp != null)
    jsonData['timestamp'] = timestamp.millisecondsSinceEpoch;

  jsonFile.writeAsStringSync(jsonEncode(jsonData));

  // Return the elapsed time of the benchmark (if any).
  return jsonData['time'];
}

/// Splits [from] into lines and selects those that contain [pattern].
Iterable<String> grep(Pattern pattern, {@required String from}) {
  return from.split('\n').where((String line) {
    return line.contains(pattern);
  });
}

bool canRun(String path) => _processManager.canRun(path);
