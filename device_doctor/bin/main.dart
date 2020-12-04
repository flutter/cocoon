// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:args/args.dart';

import 'package:device_doctor/src/config.dart';

const String actionFlag = 'action';
const String deviceOSFlag = 'deviceOS';
const String helpFlag = 'help';

String _action;
String _deviceOS;

/// Manage healthcheck and recovery for devices.
///
/// Usage:
/// dart main.dart --action <healthcheck|recovery> --deviceOS <android|ios>
Future<void> main(List<String> args) async {
  final ArgParser parser = ArgParser();
  parser
    ..addOption('$actionFlag')
    ..addOption('$deviceOSFlag')
    ..addFlag('$helpFlag');

  if (!_checkArgs(parser, args)) {
    stdout.write('\nRequired flags:\n'
        '--$actionFlag Supported actions are healthcheck, recover, and cleanup.\n'
        '--$deviceOSFlag Supported device OS: android or ios.\n');
    exit(1);
  }

  Config.initialize(_deviceOS);

  // Healthcheck and recovery will be implemented here. PR to be continued.
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
