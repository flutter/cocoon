// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';
import 'dart:async';
import 'dart:convert' show LineSplitter;

import 'package:meta/meta.dart';

import 'device.dart';
import 'health.dart';
import 'process_helper.dart';

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
  Future<List<Device>> discoverDevices({Duration retriesDelayMs = const Duration(seconds: 10)}) async {
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
    await _healthcheck(results);
    return results;
  }

  @override
  Future<void> recoverDevices({Duration retriesDelayMs = const Duration(seconds: 10)}) async {
    for (Device device in await discoverDevices()) {
      await device.recover();
    }
  }

  /// Check healthiness for discovered devices.
  ///
  /// If any failed check, an explanation message will be sent to stdout and
  /// an exception will be thrown.
  Future<void> _healthcheck(Map<String, List<HealthCheckResult>> deviceChecks) async {
    if (deviceChecks.isEmpty) {
      stderr.writeln('No healthy iOS device is available');
      throw StateError('No healthy iOS device is available');
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
}

/// iOS device.
class IosDevice implements Device {
  const IosDevice({@required this.deviceId});

  @override
  final String deviceId;

  // The methods below are stubs for now. They will need to be expanded.
  // We currently do not have a way to lock/unlock iOS devices. So we assume the
  // devices are already unlocked. For now we'll just keep them at minimum
  // screen brightness so they don't drain battery too fast.

  @override
  Future<bool> isAwake() async => true;

  @override
  Future<bool> isAsleep() async => false;

  @override
  Future<void> unlock() async {}

  @override
  Future<void> recover() async {
    // Restarts the device first.
    await eval('idevicediagnostics', <String>['restart']);
    // Close pop up dialogs if any.
    await closeIosDialog(deviceId: deviceId);
  }
}
