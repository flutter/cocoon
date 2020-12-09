// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:args/args.dart';

import 'package:device_doctor/src/device.dart';
import 'package:device_doctor/src/ios_device.dart';

const String actionFlag = 'action';
const String deviceOSFlag = 'device-os';
const String helpFlag = 'help';
const List<String> supportedOptions = <String>['healthcheck', 'recovery'];
const List<String> supportedDeviceOS = <String>['ios', 'android'];

/// These values will be initialized in `_checkArgs` function,
/// and used in `main` function.
String _action;
String _deviceOS;

/// Manage `healthcheck` and `recovery` for devices.
/// 
/// For `healthcheck`, if no device is found or any health check fails an stderr will be logged,
/// and an exception will be thrown.
/// 
/// For `recovery`, device will do cleanup, reboot, and then dismiss any dialog for `ios` device.
///
/// Usage:
/// dart main.dart --action <healthcheck|recovery> --deviceOS <android|ios>
Future<void> main(List<String> args) async {
  final ArgParser parser = ArgParser();
  parser
    ..addOption('$actionFlag', help: 'Supported actions are healthcheck and recovery.', callback: (String value) {
      if (!supportedOptions.contains(value)) {
        throw FormatException('Invalid value for option --action: $value');
      }
    })
    ..addOption('$deviceOSFlag', help: 'Supported device OS: android and ios.', callback: (String value) {
      if (!supportedDeviceOS.contains(value)) {
        throw FormatException('Invalid value for option --device-os: $value');
      }
    })
    ..addFlag('$helpFlag', help: 'Prints usage info.');

  final ArgResults argResults = parser.parse(args);
  _action = argResults[actionFlag];
  _deviceOS = argResults[deviceOSFlag];

  final IosDeviceDiscovery deviceDiscovery = DeviceDiscovery(_deviceOS);

  switch (_action) {
    case 'healthcheck':
      await deviceDiscovery.checkDevices();
      break;
    case 'recovery':
      await deviceDiscovery.recoverDevices();
      break;
  }
}
