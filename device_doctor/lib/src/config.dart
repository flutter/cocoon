// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:meta/meta.dart';

import 'device.dart';

Config _config;
Config get config => _config;

/// Configures device operating system based on injected decice OS.
///
/// This determines the [DeviceDiscovery].
class Config {
  Config({
    @required this.deviceOperatingSystem,
  });

  static void initialize(String deviceOS) {
    DeviceOperatingSystem deviceOperatingSystem;
    switch (deviceOS) {
      case 'ios':
        deviceOperatingSystem = DeviceOperatingSystem.ios;
        break;
    }

    _config = Config(
      deviceOperatingSystem: deviceOperatingSystem,
    );
  }

  final DeviceOperatingSystem deviceOperatingSystem;

  @override
  String toString() => '''
deviceOperatingSystem: $deviceOperatingSystem
'''
      .trim();
}
