// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'android_device.dart';
import 'health.dart';
import 'ios_device.dart';

/// Discovers available devices and chooses one to work with.
abstract class DeviceDiscovery {
  factory DeviceDiscovery(String deviceOs) {
    switch (deviceOs) {
      case 'ios':
        return IosDeviceDiscovery();
      case 'android':
        return AndroidDeviceDiscovery();
      default:
        throw StateError('Unsupported device operating system: $deviceOs');
    }
  }

  /// Lists all available devices' IDs.
  Future<List<Device>> discoverDevices({Duration retryDuration = const Duration(seconds: 10)});

  /// Checks the health of the available devices.
  Future<Map<String, List<HealthCheckResult>>> checkDevices();

  /// Checks and returns the device properties, like manufacturer, base_buildid, etc.
  ///
  /// Currently it supports only android devices, but can extend to iOS devices.
  Future<Map<String, List<String>>> checkDeviceProperties();

  /// Recovers the device.
  Future<void> recoverDevices();
}

/// A proxy for one specific phone device.
abstract class Device {
  /// A unique device identifier.
  String get deviceId;

  /// Recovers the device back to a healthy state.
  Future<void> recover();
}
