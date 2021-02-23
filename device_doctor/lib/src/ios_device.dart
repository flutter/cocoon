// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert' show LineSplitter, json;

import 'package:meta/meta.dart';
import 'package:process/process.dart';

import 'device.dart';
import 'health.dart';
import 'mac.dart';
import 'utils.dart';

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
      checks.add(HealthCheckResult.success('device_access'));
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
    // Restarts the device first.
    await eval('idevicediagnostics', <String>['restart']);
    // Close pop up dialogs if any.
    await closeIosDialog(deviceId: deviceId);
  }
}
