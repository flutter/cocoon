// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:args/args.dart';

import 'package:device_doctor/device_doctor.dart';

const String actionFlag = 'action';
const String deviceOSFlag = 'device-os';
const String helpFlag = 'help';
const List<String> supportedOptions = <String>['healthcheck', 'recovery', 'propertycheck'];
const List<String> supportedDeviceOS = <String>['ios', 'android'];

/// These values will be initialized in `_checkArgs` function,
/// and used in `main` function.
String _action;
String _deviceOS;

/// Manage `healthcheck`, `recovery`, and `properties` for devices.
///
/// For `healthcheck`, if no device is found or any health check fails an stderr will be logged,
/// and an exception will be thrown.
///
/// For `recovery`, it will do cleanup, reboot, etc. to try bringing device back to a working state.
///
/// For `properties`, it will return device properties/dimensions, like manufacture, base_buildid, etc.
///
/// Usage:
/// dart main.dart --action <healthcheck|recovery> --deviceOS <android|ios>
Future<void> main(List<String> args) async {
  final ArgParser parser = ArgParser();
  parser
    ..addOption('$actionFlag', help: 'Supported actions are healthcheck, recovery and properties.',
        callback: (String value) {
      if (!supportedOptions.contains(value)) {
        throw FormatException('\n-----\n'
            'Invalid value for option --action: $value.'
            'Supported actions are healthcheck and recovery.'
            '-----');
      }
    })
    ..addOption('$deviceOSFlag', help: 'Supported device OS: android and ios.', callback: (String value) {
      if (!supportedDeviceOS.contains(value)) {
        throw FormatException('\n-----\n'
            'Invalid value for option --device-os: $value.\n'
            'Supported device OS: android and ios.\n'
            '-----');
      }
    })
    ..addFlag('$helpFlag', help: 'Prints usage info.');

  final ArgResults argResults = parser.parse(args);
  _action = argResults[actionFlag];
  _deviceOS = argResults[deviceOSFlag];

  final DeviceDiscovery deviceDiscovery = DeviceDiscovery(_deviceOS);

  switch (_action) {
    case 'healthcheck':
      await deviceDiscovery.checkDevices();
      break;
    case 'recovery':
      await deviceDiscovery.recoverDevices();
      break;
    case 'properties':
      await deviceDiscovery.deviceProperties();
  }
}
