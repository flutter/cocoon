// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert' show LineSplitter, json;
import 'dart:io';

import 'package:meta/meta.dart';
import 'package:process/process.dart';

import 'device.dart';
import 'health.dart';
import 'mac.dart';
import 'utils.dart';

/// Identifiers for devices that should never be rebooted.
final Set<String> noRebootList = <String>{
  '822ef7958bba573829d85eef4df6cbdd86593730', // 32bit iPhone requires manual intervention on reboot.
};

/// IOS implementation of [DeviceDiscovery].
///
/// Discovers available ios devices and chooses one to work with.
class IosDeviceDiscovery implements DeviceDiscovery {
  factory IosDeviceDiscovery(String output) {
    return _instance ??= IosDeviceDiscovery._(output);
  }

  final String _outputFilePath;

  IosDeviceDiscovery._(this._outputFilePath);

  @visibleForTesting
  IosDeviceDiscovery.testing(this._outputFilePath);

  static IosDeviceDiscovery _instance;

  @override
  Future<List<Device>> discoverDevices({Duration retryDuration = const Duration(seconds: 10)}) async {
    return LineSplitter.split(await deviceListOutput()).map((String id) => IosDevice(deviceId: id)).toList();
  }

  Future<String> deviceListOutput() async {
    return eval('idevice_id', <String>['-l']);
  }

  @override
  Future<Map<String, List<HealthCheckResult>>> checkDevices({ProcessManager processManager}) async {
    processManager ??= LocalProcessManager();
    final Map<String, List<HealthCheckResult>> results = <String, List<HealthCheckResult>>{};
    for (Device device in await discoverDevices()) {
      final List<HealthCheckResult> checks = <HealthCheckResult>[];
      checks.add(HealthCheckResult.success(kDeviceAccessCheckKey));
      checks.add(await keychainUnlockCheck(processManager: processManager));
      checks.add(await certCheck(processManager: processManager));
      checks.add(await devicePairCheck(processManager: processManager));
      checks.add(await userAutoLoginCheck(processManager: processManager));
      results['ios-device-${device.deviceId}'] = checks;
    }
    final Map<String, Map<String, dynamic>> healthCheckMap = await healthcheck(results);
    await writeToFile(json.encode(healthCheckMap), _outputFilePath);
    return results;
  }

  /// Checks and returns the device properties.
  @override
  Future<Map<String, String>> deviceProperties({ProcessManager processManager}) async {
    return <String, String>{};
  }

  @override
  Future<void> recoverDevices() async {
    for (Device device in await discoverDevices()) {
      await device.recover();
    }
  }

  @visibleForTesting
  Future<HealthCheckResult> keychainUnlockCheck({ProcessManager processManager}) async {
    HealthCheckResult healthCheckResult;
    try {
      await eval(kUnlockLoginKeychain, <String>[], processManager: processManager);
      healthCheckResult = HealthCheckResult.success(kKeychainUnlockCheckKey);
    } on BuildFailedError catch (error) {
      healthCheckResult = HealthCheckResult.failure(kKeychainUnlockCheckKey, error.toString());
    }
    return healthCheckResult;
  }

  @visibleForTesting
  Future<HealthCheckResult> certCheck({ProcessManager processManager}) async {
    HealthCheckResult healthCheckResult;
    try {
      final String certCheckResult =
          await eval('security', <String>['find-identity', '-p', 'codesigning', '-v'], processManager: processManager);
      if (certCheckResult.contains('Apple Development: Flutter Devicelab') &&
          certCheckResult.contains('1 valid identities found')) {
        healthCheckResult = HealthCheckResult.success(kCertCheckKey);
      } else {
        healthCheckResult = HealthCheckResult.failure(kCertCheckKey, certCheckResult);
      }
    } on BuildFailedError catch (error) {
      healthCheckResult = HealthCheckResult.failure(kCertCheckKey, error.toString());
    }
    return healthCheckResult;
  }

  @visibleForTesting
  Future<HealthCheckResult> devicePairCheck({ProcessManager processManager}) async {
    HealthCheckResult healthCheckResult;
    try {
      final String devicePairCheckResult =
          await eval('idevicepair', <String>['validate'], processManager: processManager);
      if (devicePairCheckResult.contains('SUCCESS')) {
        healthCheckResult = HealthCheckResult.success(kDevicePairCheckKey);
      } else {
        healthCheckResult = HealthCheckResult.failure(kDevicePairCheckKey, devicePairCheckResult);
      }
    } on BuildFailedError catch (error) {
      healthCheckResult = HealthCheckResult.failure(kDevicePairCheckKey, error.toString());
    }
    return healthCheckResult;
  }
}

/// iOS device.
class IosDevice implements Device {
  const IosDevice({@required this.deviceId});

  @override
  final String deviceId;

  @override
  Future<void> recover() async {
    await uninstall_applications();
    await restart_device();
  }

  /// Restart iOS device.
  @visibleForTesting
  Future<bool> restart_device({ProcessManager processManager}) async {
    processManager ??= LocalProcessManager();
    try {
      if (noRebootList.contains(deviceId)) {
        return true;
      }
      await eval('idevicediagnostics', <String>['restart'], processManager: processManager);
    } on BuildFailedError catch (error) {
      logger.severe('device restart fails: $error');
      stderr.write('device restart fails: $error');
      return false;
    }
    return true;
  }

  /// Uninstall applications from a device.
  ///
  /// This is to prevent application installation failure caused by using different siging
  /// certificate from previous installed application.
  /// Issue: https://github.com/flutter/flutter/issues/76896
  @visibleForTesting
  Future<bool> uninstall_applications({ProcessManager processManager}) async {
    processManager ??= LocalProcessManager();
    String result;
    try {
      result = await eval('ideviceinstaller', <String>['-l'], processManager: processManager);
    } on BuildFailedError catch (error) {
      logger.severe('list applications fails: $error');
      stderr.write('list applications fails: $error');
      return false;
    }

    // Skip uninstalling process when no device is available or no application exists.
    if (result == 'No device found.' || result == 'CFBundleIdentifier, CFBundleVersion, CFBundleDisplayName') {
      return true;
    }
    final List<String> results = result.trim().split('\n');
    final List<String> bundleIdentifiers = results.sublist(1).map((e) => e.split(',')[0].trim()).toList();
    try {
      for (String bundleIdentifier in bundleIdentifiers) {
        await eval('ideviceinstaller', <String>['-U', bundleIdentifier], processManager: processManager);
      }
    } on BuildFailedError catch (error) {
      logger.severe('uninstall applications fails: $error');
      stderr.write('uninstall applications fails: $error');
      return false;
    }
    return true;
  }
}
