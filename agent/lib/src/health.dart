// Copyright 2017 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:meta/meta.dart';
import 'package:path/path.dart' as path;
import 'package:file/local.dart' as local;
import 'package:file/file.dart' as file;
import 'package:platform/platform.dart' as platform;
import 'package:process/process.dart';

import 'adb.dart';
import 'agent.dart';
import 'utils.dart';

final RegExp _kLinuxIpAddrExp = RegExp(r'inet +(\d+\.\d+\.\d+.\d+)/\d+');
final RegExp _kWindowsIpAddrExp = RegExp(r'IPv4 Address.*: +(\d+\.\d+\.\d+.\d+)\(Preferred\)');

Future<AgentHealth> performHealthChecks(Agent agent) async {
  AgentHealth results = AgentHealth();

  results['able-to-perform-health-check'] = await _captureErrors(() async {
    results['ssh-connectivity'] = await _captureErrors(_scrapeRemoteAccessInfo);

    Map<String, HealthCheckResult> deviceChecks = await devices.checkDevices();
    results.addAll(deviceChecks);

    bool hasHealthyDevices = deviceChecks.values.where((HealthCheckResult r) => r.succeeded).isNotEmpty;

    results['has-healthy-devices'] = hasHealthyDevices
        ? HealthCheckResult.success('Found ${deviceChecks.length} healthy devices')
        : HealthCheckResult.failure('No attached devices were found.');

    results['cocoon-connection'] = await _captureErrors(() async {
      String authStatus = await agent.getAuthenticationStatus();

      if (authStatus != 'OK') {
        results['cocoon-authentication'] =
            HealthCheckResult.failure('Failed to authenticate to Cocoon. Check config.yaml.');
      } else {
        results['cocoon-authentication'] = HealthCheckResult.success();
      }
    });
    results['remove-xcode-derived-data'] = await _captureErrors(removeXcodeDerivedData);
    results['remove-cached-data'] = await _captureErrors(removeCachedData);
    results['close-ios-dialog'] = await _captureErrors(closeIosDialog);
  });

  return results;
}

/// Catches all exceptions and turns them into [HealthCheckResult] error.
///
/// Null callback results are turned into [HealthCheckResult] success.
Future<HealthCheckResult> _captureErrors(Future<dynamic> healthCheckCallback()) async {
  Completer<HealthCheckResult> completer = Completer<HealthCheckResult>();

  // We intentionally ignore the future returned by the Chain because we're
  // reporting the results via the completer. Instead of reporting a Future
  // error, we report a successful Future carrying a HealthCheckResult error.
  // One way to think about this is that "we _successfully_ discovered health
  // check error, and will report it to the Cocoon back-end".
  // ignore: unawaited_futures
  try {
    dynamic result = await healthCheckCallback();
    completer.complete(result is HealthCheckResult ? result : HealthCheckResult.success());
  } catch (error, stackTrace) {
    completer.complete(HealthCheckResult.error(error, stackTrace));
  }
  return completer.future;
}

/// Returns the IP address for remote (SSH) access to this agent.
///
/// Uses `ipconfig getifaddr en0`.
///
/// Always returns [HealthCheckResult] success regardless of whether an IP
/// is available or not. Having remote access to an agent is not a prerequisite
/// for being able to perform Cocoon tasks. It's only there to make maintenance
/// convenient. The goal is only to report available IPs as part of the health
/// check.
Future<HealthCheckResult> _scrapeRemoteAccessInfo() async {
  String ip;
  if (Platform.isMacOS) {
    ip = (await eval('ipconfig', ['getifaddr', 'en0'], canFail: true)).trim();
  } else if (Platform.isLinux) {
    if (config.hostType == HostType.vm) {
      // Use hostname for VMs
      ip = (await eval('hostname', <String>[], canFail: true)).trim();
    } else {
      // Expect: 3: eno1    inet 123.45.67.89/26 brd ...
      final String out = (await eval('ip', ['-o', '-4', 'addr', 'show', 'eno1'], canFail: true)).trim();
      final Match match = _kLinuxIpAddrExp.firstMatch(out);
      ip = match?.group(1) ?? '';
    }
  } else if (Platform.isWindows) {
    final String out = (await eval('ipconfig', ['/all'], canFail: true)).trim();
    final Match match = _kWindowsIpAddrExp.firstMatch(out);
    ip = match?.group(1) ?? '';
  }

  return HealthCheckResult.success(
      ip.isEmpty ? 'Unable to determine IP address. Is wired ethernet connected?' : 'Last known IP address: $ip');
}

/// Completely removes Xcode DerivedData directory.
///
/// There're two purposes. First, it's a well known trick to fix Xcode when
/// Xcode behaves strangely for no obvious reason. Second, it avoids eating
/// all of the remaining disk space over time.
@visibleForTesting
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
@visibleForTesting
Future<HealthCheckResult> removeCachedData(
    {platform.Platform pf = const platform.LocalPlatform(), file.FileSystem fs = const local.LocalFileSystem()}) async {
  String home = pf.environment['HOME'];
  if (home == null) {
    return HealthCheckResult.failure('Missing \$HOME environment variable.');
  }
  List<String> cacheFolders = ['.graddle', '.dartServer'];
  for (String folder in cacheFolders) {
    String folderPath = path.join(home, folder);
    rrm(fs.directory(folderPath));
  }
  return HealthCheckResult.success();
}

/// Closes system dialogs on iOS, e.g. the one about new system update.
///
/// The dialogs often cause test flakiness and performance regressions.
@visibleForTesting
Future<HealthCheckResult> closeIosDialog(
    {ProcessManager pm = const LocalProcessManager(), DeviceDiscovery discovery, platform.Platform pl = const platform.LocalPlatform()}) async {
  if (discovery == null) {
    discovery = devices;
  }
  Directory dialogDir = dir(Directory.current.path, 'tool', 'infra-dialog');
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
          'xcrun xcodebuild -project infra-dialog.xcodeproj -scheme infra-dialog -destination id=${d.deviceId} test'.split(' ');
      // Overwrites code signing config when that exists.
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
