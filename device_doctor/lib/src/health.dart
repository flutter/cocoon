// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:platform/platform.dart' as platform;
import 'package:process/process.dart';

import 'utils.dart';

/// Closes system dialogs on iOS, e.g. the one about new system update.
///
/// The dialogs often cause test flakiness and performance regressions.
Future<HealthCheckResult> closeIosDialog(
    {ProcessManager pm = const LocalProcessManager(),
    String deviceId,
    platform.Platform pl = const platform.LocalPlatform()}) async {
  Directory dialogDir = dir(path.dirname(Platform.script.path), 'tool', 'infra-dialog');
  if (!await dialogDir.exists()) {
    dialogDir = dir(Directory.current.path, 'tool', 'infra-dialog');
    if (!await dialogDir.exists()) {
      fail('Unable to find infra-dialog at $dialogDir');
    }
  }

  // Runs the single XCUITest in infra-dialog.
  await inDirectory(dialogDir, () async {
    List<String> command =
        'xcrun xcodebuild -project infra-dialog.xcodeproj -scheme infra-dialog -destination id=$deviceId test'
            .split(' ');
    // By default the above command relies on automatic code signing, while on devicelab machines
    // it should utilize manual code signing as that is more stable. Below overwrites the code
    // signing config if one exists in the environment.
    if (pl.environment['FLUTTER_XCODE_CODE_SIGN_STYLE'] != null) {
      command.add("CODE_SIGN_STYLE=${pl.environment['FLUTTER_XCODE_CODE_SIGN_STYLE']}");
      command.add("DEVELOPMENT_TEAM=${pl.environment['FLUTTER_XCODE_DEVELOPMENT_TEAM']}");
      command.add("PROVISIONING_PROFILE_SPECIFIER=${pl.environment['FLUTTER_XCODE_PROVISIONING_PROFILE_SPECIFIER']}");
    }
    Process proc = await pm.start(command, workingDirectory: dialogDir.path);
    logger.info('Executing: $command');
    // Discards stdout and stderr as they are too large.
    await proc.stdout.drain<Object>();
    await proc.stderr.drain<Object>();
    int exitCode = await proc.exitCode;
    if (exitCode != 0) {
      fail('Command "xcrun xcodebuild -project infra-dialog..." failed with exit code $exitCode.');
    }
  });
  return HealthCheckResult.success('close iOS dialog');
}

/// Result of a health check for a specific parameter.
class HealthCheckResult {
  HealthCheckResult.success(this.name, [this.details]) : succeeded = true;
  HealthCheckResult.failure(this.name, this.details) : succeeded = false;
  HealthCheckResult.error(this.name, dynamic error, dynamic stackTrace)
      : succeeded = false,
        details = 'ERROR: $error\n${stackTrace ?? ''}';

  final String name;
  final bool succeeded;
  final String details;

  @override
  String toString() {
    StringBuffer buf = StringBuffer(name);
    buf.writeln(succeeded ? 'succeeded' : 'failed');
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

/// Check healthiness for discovered devices.
///
/// If any failed check, an explanation message will be sent to stdout and
/// an exception will be thrown.
Future<void> healthcheck(Map<String, List<HealthCheckResult>> deviceChecks) async {
  if (deviceChecks.isEmpty) {
    stderr.writeln('No healthy device is available');
    throw StateError('No healthy device is available');
  }
  for (String deviceID in deviceChecks.keys) {
    List<HealthCheckResult> checks = deviceChecks[deviceID];
    for (HealthCheckResult healthCheckResult in checks) {
      if (!healthCheckResult.succeeded) {
        stderr.writeln('${healthCheckResult.name} check failed with: ${healthCheckResult.details}');
        throw StateError('$deviceID: ${healthCheckResult.name} check failed with: ${healthCheckResult.details}');
      } else {
        stdout.writeln('${healthCheckResult.name} check succeeded');
      }
    }
  }
}
