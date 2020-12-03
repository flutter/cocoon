// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:meta/meta.dart';
import 'package:path/path.dart' as path;

import 'device.dart';
import 'utils.dart';

Config _config;
Config get config => _config;

class Config {
  Config({
    @required this.deviceOperatingSystem,
    @required this.hostType,
  });

  static void initialize(String deviceOS) {
    String home = Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'];
    if (home == null) throw "Unable to find \$HOME or \$USERPROFILE.";

    DeviceOperatingSystem deviceOperatingSystem;
    switch (deviceOS) {
      case 'android':
        deviceOperatingSystem = DeviceOperatingSystem.android;
        break;
      case 'ios':
        deviceOperatingSystem = DeviceOperatingSystem.ios;
        break;
      default:
        throw BuildFailedError('Unrecognized device_os value: $deviceOS');
    }

    HostType hostType = HostType.physical;

    _config = Config(
      deviceOperatingSystem: deviceOperatingSystem,
      hostType: hostType,
    );
  }

  final DeviceOperatingSystem deviceOperatingSystem;
  final HostType hostType;

  String get adbPath {
    String androidHome = Platform.environment['ANDROID_HOME'];

    if (androidHome == null)
      throw 'ANDROID_HOME environment variable missing. This variable must '
          'point to the Android SDK directory containing platform-tools.';

    String adbPath = path.join(androidHome, 'platform-tools', 'adb');

    if (!processManager.canRun(adbPath)) throw 'adb not found at: $adbPath';

    return path.absolute(adbPath);
  }

  @override
  String toString() => '''
adbPath: ${deviceOperatingSystem == DeviceOperatingSystem.android ? adbPath : 'N/A'}
deviceOperatingSystem: $deviceOperatingSystem
hostType: $hostType
'''
      .trim();
}
