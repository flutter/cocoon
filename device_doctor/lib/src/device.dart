// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'config.dart';
import 'ios_device.dart';
import 'utils.dart';

/// Operating system on the devices that this host is configured to test.
enum DeviceOperatingSystem { android, ios }

/// Discovers available devices and chooses one to work with.
abstract class DeviceDiscovery {
  factory DeviceDiscovery(Config config) {
    switch (config.deviceOperatingSystem) {
      case DeviceOperatingSystem.ios:
        return IosDeviceDiscovery();
      default:
        throw StateError('Unsupported device operating system: ${config.deviceOperatingSystem}');
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

  /// Wake up the device if it is not awake.
  Future<void> wakeUp();

  /// Send the device to sleep mode.
  Future<void> sendToSleep();

  /// Emulates pressing the power button, toggling the device's on/off state.
  Future<void> togglePower();

  /// Turns off TalkBack on Android devices, does nothing on iOS devices.
  Future<void> disableAccessibility();

  /// Unlocks the device.
  ///
  /// Assumes the device doesn't have a secure unlock pattern.
  Future<void> unlock();

  /// Recovers the device back to a healthy state.
  Future<void> recover();
}
