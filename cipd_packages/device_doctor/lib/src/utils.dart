// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert' show utf8;
import 'dart:io';

import 'package:meta/meta.dart';
import 'package:path/path.dart' as path;
import 'package:process/process.dart';

const String kDeviceAccessCheckKey = 'device_access';
const String kAttachedDeviceHealthcheckKey = 'attached_device';
const String kAttachedDeviceHealthcheckValue = 'No device is available';
const String kAdbPowerServiceCheckKey = 'adb_power_service';
const String kDeveloperModeCheckKey = 'developer_mode';
const String kScreenOnCheckKey = 'screen_on';
const String kKillAdbServerCheckKey = 'kill_adb_server';
const String kKeychainUnlockCheckKey = 'keychain_unlock';
const String kDeviceProvisioningProfileCheckKey = 'device_provisioning_profile';
const String kUserAutoLoginCheckKey = 'swarming_user_auto_login';
const String kUnlockLoginKeychain = '/usr/local/bin/unlock_login_keychain.sh';
const String kCertCheckKey = 'codesigning_cert';
const String kDevicePairCheckKey = 'device_pair';
const String kScreenSaverCheckKey = 'screensaver';
const String kScreenRotationCheckKey = 'screen_rotation';
const String kBatteryLevelCheckKey = 'battery_level';
const String kBatteryTemperatureCheckKey = 'battery_temperature';
const List<String> kM1BrewBinPaths = ['/opt/homebrew/bin', '/usr/local/bin'];

void fail(String message) {
  throw BuildFailedError(message);
}

class BuildFailedError extends Error {
  BuildFailedError(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Creates a directory from the given path, or multiple path parts by joining
/// them using OS-specific file path separator.
Directory dir(
  String thePath, [
  String? part2,
  String? part3,
  String? part4,
  String? part5,
  String? part6,
  String? part7,
  String? part8,
]) {
  return Directory(path.join(thePath, part2, part3, part4, part5, part6, part7, part8));
}

Future<dynamic> inDirectory(dynamic directory, Future<dynamic> action()) async {
  final String previousCwd = path.current;
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
    d = dir(directory);
  } else if (directory is Directory) {
    d = directory;
  } else {
    throw 'Unsupported type ${directory.runtimeType} of $directory';
  }

  if (!d.existsSync()) throw 'Cannot cd into directory that does not exist: $directory';
}

/// Starts a process for an executable command, and returns the processes.
Future<Process> startProcess(
  String executable,
  List<String> arguments, {
  Map<String, String>? env,
  bool silent = false,
  ProcessManager? processManager = const LocalProcessManager(),
}) async {
  late Process proc;
  try {
    proc = await processManager!
        .start(<String>[executable]..addAll(arguments), environment: env, workingDirectory: path.current);
  } catch (error) {
    fail(error.toString());
  }
  return proc;
}

/// Executes a command and returns its standard output as a String.
///
/// Standard error is redirected to the current process' standard error stream.
Future<String> eval(
  String executable,
  List<String> arguments, {
  Map<String, String>? env,
  bool canFail = false,
  bool silent = false,
  ProcessManager? processManager = const LocalProcessManager(),
}) async {
  final Process proc =
      await startProcess(executable, arguments, env: env, silent: silent, processManager: processManager);
  proc.stderr.listen((List<int> data) {
    stderr.add(data);
  });
  final String output = await utf8.decodeStream(proc.stdout);
  final int exitCode = await proc.exitCode;

  if (exitCode != 0 && !canFail) fail('Executable $executable failed with exit code $exitCode.');

  return output.trimRight();
}

/// Splits [from] into lines and selects those that contain [pattern].
Iterable<String> grep(Pattern pattern, {@required String? from}) {
  return from!.split('\n').where((String line) {
    return line.contains(pattern);
  });
}

/// Write [results] to [filePath].
void writeToFile(String results, File file) {
  if (file.existsSync()) {
    try {
      file.deleteSync();
    } on FileSystemException catch (error) {
      print('Failed to delete ${file.path}: $error');
    }
  }
  file
    ..createSync()
    ..writeAsStringSync(results);
  return;
}

/// Return Mac binary path.
///
/// For M1 bots, binaries like `ideviceinstaller` are installed under `kM1BrewBinPath`,
/// where they are not visible in `$PATH` by default.
Future<String> getMacBinaryPath(
  String name, {
  ProcessManager processManager = const LocalProcessManager(),
}) async {
  final Map<String, String> env = Map.of(Platform.environment);
  String? path = env['PATH'] ?? '';
  final String additionalPaths = kM1BrewBinPaths.join(':');
  path = '$path:$additionalPaths';
  env['PATH'] = path;
  final String binaryPath =
      await eval('which', <String>[name], canFail: true, processManager: processManager, env: env);
  // Throws exception when the binary doesn't exist in either location.
  if (binaryPath.isEmpty) {
    fail('$name not found.');
  }
  return binaryPath;
}
