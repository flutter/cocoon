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

/// The minimum battery level to run a task with a scale of 100%.
const int _kBatteryMinLevel = 15;

/// Identifiers for devices that should never be rebooted.
final Set<String> noRebootList = <String>{
  '822ef7958bba573829d85eef4df6cbdd86593730', // 32bit iPhone requires manual intervention on reboot.
};

/// IOS implementation of [DeviceDiscovery].
///
/// Discovers available ios devices and chooses one to work with.
class IosDeviceDiscovery implements DeviceDiscovery {
  factory IosDeviceDiscovery(File? output) {
    return _instance ??= IosDeviceDiscovery._(output);
  }

  final File? _outputFilePath;

  IosDeviceDiscovery._(this._outputFilePath);

  @visibleForTesting
  IosDeviceDiscovery.testing(this._outputFilePath);

  static IosDeviceDiscovery? _instance;

  @override
  Future<List<Device>> discoverDevices({Duration retryDuration = const Duration(seconds: 10)}) async {
    final List<Device> discoveredDevices =
        LineSplitter.split(await deviceListOutput()).map((String id) => IosDevice(deviceId: id)).toList();
    stdout.write('ios devices discovered: ${discoveredDevices.map((e) => e.deviceId).toList()}');
    return discoveredDevices;
  }

  Future<String> deviceListOutput({
    ProcessManager processManager = const LocalProcessManager(),
  }) async {
    final String fullPathIdeviceId = await getMacBinaryPath('idevice_id', processManager: processManager);
    stdout.write('idevice_id path $fullPathIdeviceId');
    return eval(fullPathIdeviceId, <String>['-l'], processManager: processManager);
  }

  @override
  Future<Map<String, List<HealthCheckResult>>> checkDevices({ProcessManager? processManager}) async {
    processManager ??= LocalProcessManager();
    final Map<String, List<HealthCheckResult>> results = <String, List<HealthCheckResult>>{};
    for (Device device in await discoverDevices()) {
      final List<HealthCheckResult> checks = <HealthCheckResult>[];
      checks.add(HealthCheckResult.success(kDeviceAccessCheckKey));
      checks.add(await keychainUnlockCheck(processManager: processManager));
      checks.add(await certCheck(processManager: processManager));
      checks.add(await devicePairCheck(processManager: processManager));
      checks.add(await userAutoLoginCheck(processManager: processManager));
      checks.add(await deviceProvisioningProfileCheck(device.deviceId, processManager: processManager));
      checks.add(await batteryLevelCheck(processManager: processManager));
      results['ios-device-${device.deviceId}'] = checks;
    }
    final Map<String, Map<String, dynamic>> healthCheckMap = await healthcheck(results);
    writeToFile(json.encode(healthCheckMap), _outputFilePath!);
    return results;
  }

  /// Checks and returns the device properties.
  @override
  Future<Map<String, String>> deviceProperties({ProcessManager? processManager}) async {
    return <String, String>{};
  }

  @override
  Future<void> recoverDevices() async {
    for (Device device in await discoverDevices()) {
      await device.recover();
    }
  }

  @visibleForTesting
  Future<HealthCheckResult> deviceProvisioningProfileCheck(String? deviceId, {ProcessManager? processManager}) async {
    HealthCheckResult healthCheckResult;
    try {
      final String? homeDir = Platform.environment['HOME'];

      final String out = await eval(
        'ls',
        <String>['$homeDir/Library/MobileDevice/Provisioning\ Profiles'],
        processManager: processManager,
      );
      // Split filenames
      final profiles = LineSplitter.split(out).toList();

      // Check all provisioning profiles in the directory to
      // to see if any contain a valid profile
      bool validProfileFound = false;
      for (var file in profiles) {
        final String provisionFileContent = await eval(
          'security',
          <String>['cms', '-D', '-i', '$homeDir/Library/MobileDevice/Provisioning\ Profiles/$file'],
          processManager: processManager,
        );
        if (provisionFileContent.contains(deviceId!)) {
          validProfileFound = true;
          break;
        }
      }
      // If any file contained a valid profile, then set result accordingly
      if (validProfileFound) {
        healthCheckResult = HealthCheckResult.success(kDeviceProvisioningProfileCheckKey);
      } else {
        healthCheckResult = HealthCheckResult.failure(
          kDeviceProvisioningProfileCheckKey,
          'device does not exist in the provisioning profile',
        );
      }
    } on BuildFailedError catch (error) {
      healthCheckResult = HealthCheckResult.failure(kDeviceProvisioningProfileCheckKey, error.toString());
    }
    return healthCheckResult;
  }

  @visibleForTesting
  Future<HealthCheckResult> keychainUnlockCheck({ProcessManager? processManager}) async {
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
  Future<HealthCheckResult> batteryLevelCheck({ProcessManager? processManager}) async {
    HealthCheckResult healthCheckResult;
    try {
      final String batteryCheckResult = await eval(
        'ideviceinfo',
        <String>['-q', 'com.apple.mobile.battery', '-k', 'BatteryCurrentCapacity'],
        processManager: processManager,
      );
      final int level = int.parse(batteryCheckResult.isEmpty ? '0' : batteryCheckResult);
      if (level < _kBatteryMinLevel) {
        healthCheckResult =
            HealthCheckResult.failure(kBatteryLevelCheckKey, 'Battery level ($level) is below $_kBatteryMinLevel');
      } else {
        healthCheckResult = HealthCheckResult.success(kBatteryLevelCheckKey);
      }
    } on BuildFailedError catch (error) {
      healthCheckResult = HealthCheckResult.failure(kBatteryLevelCheckKey, error.toString());
    }
    return healthCheckResult;
  }

  @visibleForTesting
  Future<HealthCheckResult> certCheck({ProcessManager? processManager}) async {
    HealthCheckResult healthCheckResult;
    try {
      final String certCheckResult =
          await eval('security', <String>['find-identity', '-p', 'codesigning', '-v'], processManager: processManager);
      if (certCheckResult.contains('Apple Development: Flutter Devicelab') &&
          certCheckResult.contains('1 valid identities found') &&
          !certCheckResult.contains('CSSMERR_TP_CERT_REVOKED')) {
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
  Future<HealthCheckResult> devicePairCheck({ProcessManager? processManager}) async {
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

  @override
  Future<void> prepareDevices() async {
    for (Device device in await discoverDevices()) {
      await device.prepare();
    }
  }
}

/// iOS device.
class IosDevice implements Device {
  const IosDevice({@required this.deviceId});

  @override
  final String? deviceId;

  @override
  Future<void> recover() async {
    await uninstall_applications();
    await restart_device();
  }

  @override
  Future<void> prepare() async {
    return;
  }

  /// Restart iOS device.
  @visibleForTesting
  Future<bool> restart_device({ProcessManager? processManager}) async {
    processManager ??= LocalProcessManager();
    try {
      if (noRebootList.contains(deviceId)) {
        stdout.write('Device not marked for reboot.');
        return true;
      }
      final String fullPathIdevicediagnostics =
          await getMacBinaryPath('idevicediagnostics', processManager: processManager);
      await eval(fullPathIdevicediagnostics, <String>['restart'], processManager: processManager);
    } on BuildFailedError catch (error) {
      stderr.write('device restart fails: $error');
      return false;
    }
    stdout.write('Restart device complete.');
    return true;
  }

  /// Uninstall applications from a device.
  ///
  /// This is to prevent application installation failure caused by using different signing
  /// certificate from previous installed application.
  /// Issue: https://github.com/flutter/flutter/issues/76896
  @visibleForTesting
  Future<bool> uninstall_applications({ProcessManager? processManager}) async {
    processManager ??= LocalProcessManager();
    String result;
    final String fullPathIdeviceInstaller = await getMacBinaryPath('ideviceinstaller', processManager: processManager);
    try {
      result = await eval(fullPathIdeviceInstaller, <String>['-l'], processManager: processManager);
    } on BuildFailedError catch (error) {
      stderr.write('list applications fails: $error');
      return false;
    }

    // Skip uninstalling process when no device is available or no application exists.
    if (result == 'No device found.' || result == 'CFBundleIdentifier, CFBundleVersion, CFBundleDisplayName') {
      stdout.write('No device was found or no application to uninstall exists.');
      return true;
    }
    final List<String> results = result.trim().split('\n');
    final List<String> bundleIdentifiers = results.sublist(1).map((e) => e.split(',')[0].trim()).toList();
    try {
      for (String bundleIdentifier in bundleIdentifiers) {
        await eval(fullPathIdeviceInstaller, <String>['-U', bundleIdentifier], processManager: processManager);
      }
    } on BuildFailedError catch (error) {
      stderr.write('uninstall applications fails: $error');
      return false;
    }
    stdout.write('Uninstall complete.');
    return true;
  }
}
