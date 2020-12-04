// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:args/args.dart';

import 'package:device_doctor/src/config.dart';
import 'package:device_doctor/src/device.dart';

const String actionFlag = 'action';
const String deviceOSFlag = 'device-os';
const String helpFlag = 'help';

/// These values will be initialized in `_checkArgs` function,
/// and used in `main` function.
String _action;
String _deviceOS;

/// Manage healthcheck and recovery for devices.
///
/// Usage:
/// dart main.dart --action <healthcheck|recovery> --deviceOS <android|ios>
Future<void> main(List<String> args) async {
  final ArgParser parser = ArgParser();
  parser
    ..addOption('$actionFlag', help: 'Supported actions are healthcheck and recovery.')
    ..addOption('$deviceOSFlag', help: 'Supported device OS: android and ios.')
    ..addFlag('$helpFlag', help: 'Prints usage info.');

  final ArgResults argResults = parser.parse(args);
  _action = argResults[actionFlag];
  _deviceOS = argResults[deviceOSFlag];

  if (!_checkArgs(parser, args)) {
    stdout.write('${parser.usage}');
    exit(1);
  }

  final Config config = Config(deviceOS: _deviceOS);
  DeviceDiscovery(config);

  // TODO(keyonghan): Implement healthcheck and recovery, https://github.com/flutter/flutter/issues/66193.
}

bool _checkArgs(ArgParser parser, List<String> args) {
  final ArgResults argResults = parser.parse(args);
  final bool printHelp = argResults[helpFlag];
  if (printHelp) {
    return false;
  }

  _action = argResults[actionFlag];
  _deviceOS = argResults[deviceOSFlag];
  if (_action == null) {
    stderr.write('ERROR: --$actionFlag must be defined\n');
    return false;
  }
  if (_deviceOS == null) {
    stderr.write('ERROR: --$deviceOSFlag must be defined\n');
    return false;
  }

  return true;
}
