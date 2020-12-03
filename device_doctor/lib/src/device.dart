// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'android_device.dart';
import 'config.dart';
import 'ios_device.dart';

/// The root of the API for controlling devices.
DeviceDiscovery get devices => DeviceDiscovery();

/// Type of host that is configured to test.
enum HostType { vm, physical }

/// Operating system on the devices that this host is configured to test.
enum DeviceOperatingSystem { android, ios }

/// Discovers available devices and chooses one to work with.
abstract class DeviceDiscovery {
  factory DeviceDiscovery() {
    switch (config.deviceOperatingSystem) {
      case DeviceOperatingSystem.android:
        return AndroidDeviceDiscovery();
      case DeviceOperatingSystem.ios:
        return IosDeviceDiscovery();
      default:
        throw StateError('Unsupported device operating system: {config.deviceOperatingSystem}');
    }
  }

  /// Lists all available devices' IDs.
  Future<List<Device>> discoverDevices({int retriesDelayMs = 10000});

  /// Checks the health of the available devices.
  Future<Map<String, HealthCheckResult>> checkDevices();

  /// Recovers the device.
  Future<void> recoverDevice();
}

/// A proxy for one specific device.
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

/// Result of a health check for a specific parameter.
class HealthCheckResult {
  HealthCheckResult.success([this.details]) : succeeded = true;
  HealthCheckResult.failure(this.details) : succeeded = false;
  HealthCheckResult.error(dynamic error, dynamic stackTrace)
      : succeeded = false,
        details = 'ERROR: $error\n${stackTrace ?? ''}';

  final bool succeeded;
  final String details;

  @override
  String toString() {
    StringBuffer buf = StringBuffer(succeeded ? 'succeeded' : 'failed');
    if (details != null && details.trim().isNotEmpty) {
      buf.writeln();
      // Indent details by 4 spaces
      for (String line in details.trim().split('\n')) {
        buf.writeln('    $line');
      }
    }
    return '$buf';
  }
}
