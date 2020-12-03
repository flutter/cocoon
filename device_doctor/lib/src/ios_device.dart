// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert' show LineSplitter;

import 'package:meta/meta.dart';

import 'device.dart';
import 'process_helper.dart';

class IosDeviceDiscovery implements DeviceDiscovery {
  factory IosDeviceDiscovery() {
    return _instance ??= IosDeviceDiscovery._();
  }

  IosDeviceDiscovery._();

  static IosDeviceDiscovery _instance;

  @override
  Future<List<Device>> discoverDevices({int retriesDelayMs = 10000}) async {
    // Warm up device list. This is to ensure slow devices are discovered.
    // https://github.com/flutter/flutter/issues/64753
    // await eval('xcrun', <String>['xcdevice', 'list', '--timeout', '10']);
    final List<String> iosDeviceIds = LineSplitter.split(await eval('idevice_id', <String>['-l'])).toList();
    return iosDeviceIds.map((String id) => IosDevice(deviceId: id)).toList();
  }

  @override
  Future<Map<String, HealthCheckResult>> checkDevices() async {
    final Map<String, HealthCheckResult> results = <String, HealthCheckResult>{};
    for (Device device in await discoverDevices()) {
      results['ios-device-${device.deviceId}'] = HealthCheckResult.success();
    }
    return results;
  }

  @override
  Future<void> recoverDevice() async {
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

  // The methods below are stubs for now. They will need to be expanded.
  // We currently do not have a way to lock/unlock iOS devices. So we assume the
  // devices are already unlocked. For now we'll just keep them at minimum
  // screen brightness so they don't drain battery too fast.

  @override
  Future<bool> isAwake() async => true;

  @override
  Future<bool> isAsleep() async => false;

  @override
  Future<void> wakeUp() async {}

  @override
  Future<void> sendToSleep() async {}

  @override
  Future<void> togglePower() async {}

  @override
  Future<void> unlock() async {}

  @override
  Future<void> disableAccessibility() async {}

  @override
  Future<void> recover() async {
    await eval('idevicediagnostics', <String>['restart']);
  }
}
