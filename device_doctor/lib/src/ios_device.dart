// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert' show LineSplitter, json;

import 'package:meta/meta.dart';
import 'package:process/process.dart';

import 'device.dart';
import 'health.dart';
import 'utils.dart';

/// IOS implementation of [DeviceDiscovery].
///
/// Discovers available ios devices and chooses one to work with.
class IosDeviceDiscovery implements DeviceDiscovery {
  factory IosDeviceDiscovery() {
    return _instance ??= IosDeviceDiscovery._();
  }

  IosDeviceDiscovery._();

  @visibleForTesting
  IosDeviceDiscovery.testing();

  static IosDeviceDiscovery _instance;

  @override
  Future<List<Device>> discoverDevices({Duration retryDuration = const Duration(seconds: 10)}) async {
    return LineSplitter.split(await deviceListOutput()).map((String id) => IosDevice(deviceId: id)).toList();
  }

  Future<String> deviceListOutput() async {
    return eval('idevice_id', <String>['-l']);
  }

  @override
  Future<Map<String, List<HealthCheckResult>>> checkDevices() async {
    final Map<String, List<HealthCheckResult>> results = <String, List<HealthCheckResult>>{};
    for (Device device in await discoverDevices()) {
      final List<HealthCheckResult> checks = <HealthCheckResult>[];
      checks.add(HealthCheckResult.success('device_access'));
      results['ios-device-${device.deviceId}'] = checks;
    }
    final Map<String, Map<String, dynamic>> healthCheckMap = await healthcheck(results);
    await writeToFile(json.encode(healthCheckMap), kDeviceFailedHealthcheckFilename);
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
