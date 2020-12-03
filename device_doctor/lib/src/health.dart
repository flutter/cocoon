// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:file/local.dart' as local;
import 'package:file/file.dart' as file;
import 'package:path/path.dart' as path;
import 'package:platform/platform.dart' as platform;
import 'package:process/process.dart';

import 'device.dart';
import 'ios_device.dart';
import 'process_helper.dart';
import 'utils.dart';

/// Completely removes Xcode DerivedData directory.
///
/// There're two purposes. First, it's a well known trick to fix Xcode when
/// Xcode behaves strangely for no obvious reason. Second, it avoids eating
/// all of the remaining disk space over time.
Future<HealthCheckResult> removeXcodeDerivedData(
    {platform.Platform pf = const platform.LocalPlatform(), file.FileSystem fs = const local.LocalFileSystem()}) async {
  if (!pf.isMacOS) {
    return HealthCheckResult.success();
  }
  String home = pf.environment['HOME'];
  if (home == null) {
    return HealthCheckResult.failure('Missing \$HOME environment variable.');
  }
  String p = path.join(home, 'Library/Developer/Xcode/DerivedData');
  rrm(fs.directory(p));
  return HealthCheckResult.success();
}

/// Completely removes Cache directories.
///
/// This is needed for VMs with limited resources where the
/// cache directories grow very fast.
Future<HealthCheckResult> removeCachedData(
    {platform.Platform pf = const platform.LocalPlatform(), file.FileSystem fs = const local.LocalFileSystem()}) async {
  String home = pf.environment['HOME'];
  if (home == null) {
    return HealthCheckResult.failure('Missing \$HOME environment variable.');
  }
  List<String> cacheFolders = ['.gradle', '.dartServer'];
  for (String folder in cacheFolders) {
    String folderPath = path.join(home, folder);
    rrm(fs.directory(folderPath));
  }
  return HealthCheckResult.success();
}

/// Closes system dialogs on iOS, e.g. the one about new system update.
///
/// The dialogs often cause test flakiness and performance regressions.
Future<HealthCheckResult> closeIosDialog(
    {ProcessManager pm = const LocalProcessManager(),
    DeviceDiscovery discovery,
    platform.Platform pl = const platform.LocalPlatform()}) async {
  if (discovery == null) {
    discovery = devices;
  }
  print(Platform.script.path);
  print(Directory.current.path);
  Directory dialogDir = dir(path.dirname(Platform.script.path), 'tool', 'infra-dialog');
  if (!await dialogDir.exists()) {
    fail('Unable to find infra-dialog at $dialogDir');
  }

  for (Device d in await discovery.discoverDevices()) {
    if (!(d is IosDevice)) {
      continue;
    }
    await unlockKeyChain();
    // Runs the single XCUITest in infra-dialog.
    await inDirectory(dialogDir, () async {
      List<String> command =
          'xcrun xcodebuild -project infra-dialog.xcodeproj -scheme infra-dialog -destination id=${d.deviceId} test'
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
  }
  return HealthCheckResult.success();
}

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
