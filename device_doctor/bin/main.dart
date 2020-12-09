// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:args/args.dart';

import 'package:device_doctor/src/device.dart';

const String actionFlag = 'action';
const String deviceOSFlag = 'device-os';
const String helpFlag = 'help';
const List<String> supportedOptions = <String>['healthcheck', 'recovery'];
const List<String> supportedDeviceOS = <String>['ios', 'android'];

/// These values will be initialized in `_checkArgs` function,
/// and used in `main` function.
String _deviceOS;

/// Manage healthcheck and recovery for devices.
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
  _deviceOS = argResults[deviceOSFlag];

  DeviceDiscovery(_deviceOS);

  // TODO(keyonghan): Implement healthcheck and recovery, https://github.com/flutter/flutter/issues/66193.
}
