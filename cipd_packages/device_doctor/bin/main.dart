// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:args/args.dart';

import 'package:device_doctor/device_doctor.dart';

const String actionFlag = 'action';
const String deviceOSFlag = 'device-os';
const String helpFlag = 'help';
const String outputFlag = 'output';
const List<String> supportedOptions = <String>[
  'healthcheck',
  'prepare',
  'recovery',
  'properties',
];
const List<String> supportedDeviceOS = <String>['ios', 'android'];
const String defaultOutputPath = '.output';

/// These values will be initialized in `_checkArgs` function,
/// and used in `main` function.
String? _action;
String? _deviceOS;
File? _output;

/// Manage `healthcheck`, `prepare, `recovery`, and `properties` for devices.
///
/// For `healthcheck`, if no device is found or any health check fails an stderr will be logged,
/// and an exception will be thrown.
///
/// For `recovery`, it will do cleanup, reboot, etc. to try bringing device back to a working state.
///
/// For `prepare`, it will prepare the device before running tasks, like kill running processes, etc.
///
/// For `properties`, it will return device properties/dimensions, like manufacture, base_buildid, etc.
///
/// Usage:
/// ```
/// dart main.dart --action <healthcheck|recovery> --deviceOS <android|ios>
/// ```
Future<void> main(List<String> args) async {
  final parser = ArgParser();
  parser
    ..addFlag(
      helpFlag,
      help: 'Prints usage info.',
      abbr: 'h',
      callback: (bool value) {
        if (value) {
          stdout.write('${parser.usage}\n');
          exit(1);
        }
      },
    )
    ..addOption(
      actionFlag,
      help: 'Supported actions.',
      allowed: supportedOptions,
      allowedHelp: {
        'healthcheck': 'Check device health status.',
        'recovery': 'Clean up and reboot device.',
        'properties': 'Return device properties/dimensions.',
      },
    )
    ..addOption(outputFlag, help: 'Path to the output file')
    ..addOption(
      deviceOSFlag,
      help: 'Supported device OS.',
      allowed: supportedDeviceOS,
      allowedHelp: {
        'android': 'Available for linux, mac, and windows.',
        'ios': 'Available for mac.',
      },
    );

  final argResults = parser.parse(args);
  _action = argResults[actionFlag] as String?;
  _deviceOS = argResults[deviceOSFlag] as String?;
  _output = File(argResults[outputFlag] ?? defaultOutputPath);

  final deviceDiscovery = DeviceDiscovery(_deviceOS, _output);

  switch (_action) {
    case 'healthcheck':
      await deviceDiscovery.checkDevices();
      break;
    case 'prepare':
      await deviceDiscovery.prepareDevices();
      break;
    case 'recovery':
      await deviceDiscovery.recoverDevices();
      break;
    case 'properties':
      await deviceDiscovery.deviceProperties();
  }
}
