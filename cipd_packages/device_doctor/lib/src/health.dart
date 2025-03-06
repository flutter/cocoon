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
Future<HealthCheckResult> closeIosDialog({
  ProcessManager pm = const LocalProcessManager(),
  String? deviceId,
  platform.Platform pl = const platform.LocalPlatform(),
  String infraDialog = 'infra-dialog',
}) async {
  var dialogDir = dir(path.dirname(Platform.script.path), 'tool', infraDialog);
  if (!await dialogDir.exists()) {
    dialogDir = dir(Directory.current.path, 'tool', infraDialog);
    if (!await dialogDir.exists()) {
      fail('Unable to find infra-dialog at $dialogDir');
    }
  }

  // Runs the single XCUITest in infra-dialog.
  await inDirectory(dialogDir, () async {
    final command =
        'xcrun xcodebuild -project infra-dialog.xcodeproj -scheme infra-dialog -destination -quiet id=$deviceId test'
            .split(' ');
    // By default the above command relies on automatic code signing, while on devicelab machines
    // it should utilize manual code signing as that is more stable. Below overwrites the code
    // signing config if one exists in the environment.
    if (pl.environment['FLUTTER_XCODE_CODE_SIGN_STYLE'] != null) {
      command.add(
          "CODE_SIGN_STYLE=${pl.environment['FLUTTER_XCODE_CODE_SIGN_STYLE']}");
      command.add(
          "DEVELOPMENT_TEAM=${pl.environment['FLUTTER_XCODE_DEVELOPMENT_TEAM']}");
      command.add(
          "PROVISIONING_PROFILE_SPECIFIER=${pl.environment['FLUTTER_XCODE_PROVISIONING_PROFILE_SPECIFIER']}");
    }
    final proc = await pm.start(command, workingDirectory: dialogDir.path);
    final exitCode = await proc.exitCode;
    if (exitCode != 0) {
      fail('Command "$command" failed with exit code $exitCode.');
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
  final String? details;

  @override
  String toString() {
    final buf = StringBuffer(name);
    buf.writeln(succeeded ? 'succeeded' : 'failed');
    if (details != null && details!.trim().isNotEmpty) {
      buf.writeln();
      // Indent details by 4 spaces
      for (var line in details!.trim().split('\n')) {
        buf.writeln('    $line');
      }
    }
    return '$buf';
  }
}

/// Check healthiness for discovered devices.
Future<Map<String, Map<String, dynamic>>> healthcheck(
    Map<String, List<HealthCheckResult>> deviceChecks) async {
  final healthcheckMap = <String, Map<String, dynamic>>{};
  if (deviceChecks.isEmpty) {
    healthcheckMap[kAttachedDeviceHealthcheckKey] = <String, dynamic>{
      'status': false,
      'details': kAttachedDeviceHealthcheckValue,
    };
  } else {
    healthcheckMap[kAttachedDeviceHealthcheckKey] = <String, dynamic>{
      'status': true,
      'details': null
    };
  }
  for (var deviceID in deviceChecks.keys) {
    final checks = deviceChecks[deviceID]!;
    for (var healthCheckResult in checks) {
      final healthCheckResultMap = <String, dynamic>{
        'status': healthCheckResult.succeeded,
        'details': healthCheckResult.details,
      };
      healthcheckMap[healthCheckResult.name] = healthCheckResultMap;
    }
  }
  return healthcheckMap;
}
