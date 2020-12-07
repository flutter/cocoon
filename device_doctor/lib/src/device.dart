// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'health.dart';
import 'ios_device.dart';

/// Operating system on the devices that this host is configured to test.
enum DeviceOperatingSystem { android, ios }

/// Discovers available devices and chooses one to work with.
abstract class DeviceDiscovery {
  factory DeviceDiscovery(String deviceOs) {
    switch (deviceOs) {
      case 'ios':
        return IosDeviceDiscovery();
      default:
        throw StateError('Unsupported device operating system: $deviceOs');
    }
  }

  /// Lists all available devices' IDs.
  Future<List<Device>> discoverDevices({Duration retriesDelayMs = const Duration(seconds: 10)});

  /// Checks the health of the available devices.
  Future<Map<String, HealthCheckResult>> checkDevices();

  /// Recovers the device.
  Future<void> recoverDevices();
}

/// A proxy for one specific phone device.
abstract class Device {
  /// A unique device identifier.
  String get deviceId;

  /// Whether the device is awake.
  Future<bool> isAwake();

  /// Whether the device is asleep.
  Future<bool> isAsleep();

  /// Unlocks the device.
  ///
  /// Assumes the device doesn't have a secure unlock pattern.
  Future<void> unlock() async {}

  /// Recovers the device back to a healthy state.
  Future<void> recover();
}
