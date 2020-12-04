// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:meta/meta.dart';

import 'device.dart';

/// Configures device operating system based on injected device OS.
///
/// This determines the [DeviceDiscovery].

class Config {
  Config({
    @required this.deviceOS,
  });

  final String deviceOS;
  DeviceOperatingSystem get deviceOperatingSystem => _initialize(deviceOS);

  static DeviceOperatingSystem _initialize(String deviceOS) {
    DeviceOperatingSystem deviceOperatingSystem;
    switch (deviceOS) {
      case 'ios':
        deviceOperatingSystem = DeviceOperatingSystem.ios;
        break;
    }
    return deviceOperatingSystem;
  }

  @override
  String toString() => '''
deviceOperatingSystem: $deviceOperatingSystem
'''
      .trim();
}
