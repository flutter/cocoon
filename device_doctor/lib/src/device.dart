// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'android_device.dart';
import 'health.dart';
import 'ios_device.dart';
import 'utils.dart';

/// Discovers available devices and chooses one to work with.
abstract class DeviceDiscovery {
  factory DeviceDiscovery(String deviceOs) {
    switch (deviceOs) {
      case 'ios':
        for (String property in supportedIosProperties) {
          if (!properties.keys.contains(property)) {
            throw FormatException('\n-----\n$property is not defined for $deviceOs device.\n-----');
          }
        }
        return IosDeviceDiscovery();
      case 'android':
        for (String property in supportedAndroidProperties) {
          if (!properties.keys.contains(property)) {
            throw FormatException('\n-----\n$property is not defined for $deviceOs device.\n-----');
          }
        }
        return AndroidDeviceDiscovery();
      default:
        throw StateError('Unsupported device operating system: $deviceOs');
    }
  }

  /// Lists all available devices' IDs.
  Future<List<Device>> discoverDevices({Duration retriesDelay = const Duration(seconds: 10)});

  /// Checks the health of the available devices.
  Future<Map<String, List<HealthCheckResult>>> checkDevices();

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

  /// Recovers the device back to a healthy state.
  Future<void> recover();
}
