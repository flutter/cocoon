// Copyright (c) 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as path;
import 'package:stack_trace/stack_trace.dart';
import 'package:yaml/yaml.dart';

/// Virtual current working directory, which affect functions, such as [exec].
String cwd = Directory.current.path;

Config _config;
Config get config => _config;

List<ProcessInfo> _runningProcesses = <ProcessInfo>[];

class ProcessInfo {
  ProcessInfo(this.command, this.process);

  final DateTime startTime = new DateTime.now();
  final String command;
  final Process process;

  @override
  String toString() {
    return
'''
  command : $command
  started : $startTime
  pid     : ${process.pid}
'''.trim();
  }
}

class BuildFailedError extends Error {
  BuildFailedError(this.message);

  final String message;

  @override
  String toString() => message;
}

void fail(String message) {
  throw new BuildFailedError(message);
}

void rm(FileSystemEntity entity) {
  if (entity.existsSync())
    entity.deleteSync();
}

/// Remove recursively.
void rrm(FileSystemEntity entity) {
  if (entity.existsSync())
    entity.deleteSync(recursive: true);
}

List<FileSystemEntity> ls(Directory directory) => directory.listSync();

Directory dir(String path) => new Directory(path);

File file(String path) => new File(path);

void copy(File sourceFile, Directory targetDirectory, { String name }) {
  File target = file(path.join(targetDirectory.path, name ?? path.basename(sourceFile.path)));
  target.writeAsBytesSync(sourceFile.readAsBytesSync());
}

FileSystemEntity move(FileSystemEntity whatToMove, { Directory to, String name }) {
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
  print('');
  print('••• $title •••');
}

Future<String> getDartVersion() async {
  // The Dart VM returns the version text to stderr.
  ProcessResult result = Process.runSync(dartBin, ['--version']);
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
  if (!dir('${config.flutterDirectory.path}/.git').existsSync()) {
    return null;
  }

  return inDirectory(config.flutterDirectory, () {
    return eval('git', ['rev-parse', 'HEAD']);
  });
}

Future<DateTime> getFlutterRepoCommitTimestamp(String commit) {
  // git show -s --format=%at 4b546df7f0b3858aaaa56c4079e5be1ba91fbb65
  return inDirectory(config.flutterDirectory, () async {
    String unixTimestamp = await eval('git', ['show', '-s', '--format=%at', commit]);
    int secondsSinceEpoch = int.parse(unixTimestamp);
    return new DateTime.fromMillisecondsSinceEpoch(secondsSinceEpoch * 1000);
  });
}

Future<Process> startProcess(String executable, List<String> arguments,
    {Map<String, String> env}) async {
  String command = '$executable ${arguments?.join(" ") ?? ""}';
  print('Executing: $command');
  Process proc = await Process.start(executable, arguments, environment: env, workingDirectory: cwd);
  ProcessInfo procInfo = new ProcessInfo(command, proc);
  _runningProcesses.add(procInfo);

  proc.exitCode.then((_) {
    _runningProcesses.remove(procInfo);
  });

  return proc;
}

Future<Null> forceQuitRunningProcesses() async {
  // Give normally quitting processes a chance to report their exit code.
  await new Future.delayed(const Duration(seconds: 1));

  // Whatever's left, kill it.
  for (ProcessInfo p in _runningProcesses) {
    print('Force quitting process:\n$p');
    if (!p.process.kill()) {
      print('Failed to force quit process');
    }
  }
  _runningProcesses.clear();
}

/// Executes a command and returns its exit code.
Future<int> exec(String executable, List<String> arguments,
    {Map<String, String> env, bool canFail: false}) async {
  Process proc = await startProcess(executable, arguments, env: env);

  proc.stdout
    .transform(UTF8.decoder)
    .transform(const LineSplitter())
    .listen(print);
  proc.stderr
    .transform(UTF8.decoder)
    .transform(const LineSplitter())
    .listen(stderr.writeln);

  int exitCode = await proc.exitCode;

  if (exitCode != 0 && !canFail)
    fail('Executable failed with exit code ${exitCode}.');

  return exitCode;
}

/// Executes a command and returns its standard output as a String.
///
/// Standard error is redirected to the current process' standard error stream.
Future<String> eval(String executable, List<String> arguments,
    {Map<String, String> env, bool canFail: false}) async {
  Process proc = await startProcess(executable, arguments, env: env);
  proc.stderr.listen((List<int> data) {
    stderr.add(data);
  });
  String output = await UTF8.decodeStream(proc.stdout);
  int exitCode = await proc.exitCode;

  if (exitCode != 0 && !canFail)
    fail('Executable failed with exit code ${exitCode}.');

  return output.trimRight();
}

Future<int> flutter(String command, {List<String> options: const<String>[], bool canFail: false}) {
  List<String> args = [command]
    ..addAll(options);
  return exec(path.join(config.flutterDirectory.path, 'bin', 'flutter'), args, canFail: canFail);
}

String get dartBin => path.join(config.flutterDirectory.path, 'bin/cache/dart-sdk/bin/dart');

Future<int> dart(List<String> args) => exec(dartBin, args);

Future<int> pub(String command) {
  return exec(
    path.join(config.flutterDirectory.path, 'bin/cache/dart-sdk/bin/pub'),
    [command]
  );
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

  if (!d.existsSync())
    throw 'Cannot cd into directory that does not exist: $directory';
}

class Config {
  Config({
    this.baseCocoonUrl,
    this.agentId,
    this.firebaseFlutterDashboardToken,
    this.authToken,
    this.flutterDirectory,
    this.runTaskFile
  });

  static void initialize(ArgResults args) {
    File agentConfigFile = file(args['config-file']);

    if (!agentConfigFile.existsSync()) {
      throw ('Agent config file not found: ${agentConfigFile.path}.');
    }

    File runTaskFile = file('${args['agent-checkout']}/bin/agent.dart');

    if (!runTaskFile.existsSync()) {
      throw ('run_task.dart file not found: ${runTaskFile.path}.');
    }

    Map<String, dynamic> agentConfig = loadYaml(agentConfigFile.readAsStringSync());
    String baseCocoonUrl = agentConfig['base_cocoon_url'] ?? 'https://flutter-dashboard.appspot.com';
    String agentId = requireConfigProperty(agentConfig, 'agent_id');
    String firebaseFlutterDashboardToken = requireConfigProperty(agentConfig, 'firebase_flutter_dashboard_token');
    String authToken = requireConfigProperty(agentConfig, 'auth_token');
    Directory flutterDirectory = dir('${Platform.environment['HOME']}/.cocoon/flutter');
    mkdirs(flutterDirectory);

    _config = new Config(
      baseCocoonUrl: baseCocoonUrl,
      agentId: agentId,
      firebaseFlutterDashboardToken: firebaseFlutterDashboardToken,
      authToken: authToken,
      flutterDirectory: flutterDirectory,
      runTaskFile: runTaskFile
    );
  }

  final String baseCocoonUrl;
  final String agentId;
  final String firebaseFlutterDashboardToken;
  final String authToken;
  final Directory flutterDirectory;
  final File runTaskFile;

  String get adbPath {
    String androidHome = Platform.environment['ANDROID_HOME'];

    if (androidHome == null)
      throw 'ANDROID_HOME environment variable missing. This variable must '
            'point to the Android SDK directory containing platform-tools.';

    File adbPath = file(path.join(androidHome, 'platform-tools/adb'));

    if (!adbPath.existsSync())
      throw 'adb not found at: $adbPath';

    return adbPath.absolute.path;
  }

  @override
  String toString() =>
'''
baseCocoonUrl: $baseCocoonUrl
agentId: $agentId
flutterDirectory: $flutterDirectory
runTaskFile: $runTaskFile
adbPath: $adbPath
'''.trim();
}

String requireEnvVar(String name) {
  String value = Platform.environment[name];

  if (value == null)
    fail('${name} environment variable is missing. Quitting.');

  return value;
}

dynamic/*=T*/ requireConfigProperty(Map<String, dynamic/*<T>*/> map, String propertyName) {
  if (!map.containsKey(propertyName))
    fail('Configuration property not found: $propertyName');

  return map[propertyName];
}

String jsonEncode(dynamic data) {
  return new JsonEncoder.withIndent('  ').convert(data) + '\n';
}

Future<bool> getFlutter(String revision) async {
  section('Get Flutter!');

  if (exists(dir('${config.flutterDirectory.path}/.git'))) {
    bool hasLocalChanges = await inDirectory(config.flutterDirectory, () async {
      String unstagedChanges = await eval('git', ['diff', '--numstat']);
      String stagedChanges = await eval('git', ['diff', '--numstat', '--cached']);
      return unstagedChanges.trim().isNotEmpty || stagedChanges.trim().isNotEmpty;
    });

    if (hasLocalChanges) {
      section('WARNING');
      print(
        'Pending changes detected in the local Flutter repo. Will skip syncing '
        'Flutter repo. The build will continue but it will marked as failed.'
      );
      return false;
    }
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
  return true;
}

void checkNotNull(Object o1, [Object o2 = 1, Object o3 = 1, Object o4 = 1,
    Object o5 = 1, Object o6 = 1, Object o7 = 1, Object o8 = 1, Object o9 = 1, Object o10 = 1]) {
  if (o1 == null)
    throw 'o1 is null';

  if (o2 == null)
    throw 'o2 is null';

  if (o3 == null)
    throw 'o3 is null';

  if (o4 == null)
    throw 'o4 is null';

  if (o5 == null)
    throw 'o5 is null';

  if (o6 == null)
    throw 'o6 is null';

  if (o7 == null)
    throw 'o7 is null';

  if (o8 == null)
    throw 'o8 is null';

  if (o9 == null)
    throw 'o9 is null';

  if (o10 == null)
    throw 'o10 is null';
}

/// Add benchmark values to a JSON results file.
///
/// If the file contains information about how long the benchmark took to run
/// (a `time` field), then return that info.
// TODO(yjbanov): move this data to __metadata__
num addBuildInfo(File jsonFile, {
  num expected,
  String sdk,
  String commit,
  DateTime timestamp
}) {
  Map<String, dynamic> json;

  if (jsonFile.existsSync())
    json = JSON.decode(jsonFile.readAsStringSync());
  else
    json = <String, dynamic>{};

  if (expected != null)
    json['expected'] = expected;
  if (sdk != null)
    json['sdk'] = sdk;
  if (commit != null)
    json['commit'] = commit;
  if (timestamp != null)
    json['timestamp'] = timestamp.millisecondsSinceEpoch;

  jsonFile.writeAsStringSync(jsonEncode(json));

  // Return the elapsed time of the benchmark (if any).
  return json['time'];
}

/// Splits [from] into lines and selects those that contain [pattern].
Iterable<String> grep(Pattern pattern, {@required String from}) {
  return from.split('\n').where((String line) {
    return line.contains(pattern);
  });
}

/// Captures asynchronous stack traces thrown by [callback].
///
/// This is a convenience wrapper around [Chain] optimized for use with
/// `async`/`await`.
///
/// Example:
///
///     try {
///       await captureAsyncStacks(() { /* async things */ });
///     } catch (error, chain) {
///
///     }
Future<Null> runAndCaptureAsyncStacks(Future<Null> callback()) {
  Completer<Null> completer = new Completer<Null>();
  Chain.capture(() async {
    await callback();
    completer.complete();
  }, onError: (error, Chain chain) async {
    completer.completeError(error, chain);
  });
  return completer.future;
}
