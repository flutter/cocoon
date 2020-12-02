// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:args/args.dart';
import "package:path/path.dart" show dirname, join;
import 'package:yaml/yaml.dart';

import 'package:device_doctor/src/adb.dart';
import 'package:device_doctor/src/health.dart';
import 'package:device_doctor/src/utils.dart';

const String actionFlag = 'action';
const String configFileFlag = 'config-file';
const String helpFlag = 'help';

String _action;
String _deviceOS;

/// Manage healthcheck, cleanup and restart for devices configured in
/// config.yaml.
///
/// Usage:
/// dart main.dart --action <healthcheck|cleanup|restart>
Future<void> main(List<String> args) async {
  final ArgParser parser = ArgParser();
  parser
    ..addOption('$actionFlag')
    ..addOption('$configFileFlag', abbr: 'c', defaultsTo: 'config.yaml')
    ..addFlag('$helpFlag');

  if (!_checkArgs(parser, args)) {
    stdout.write('\nRequired flags:\n'
        '--$actionFlag Supported actions are healthcheck, restart, and cleanup.\n'
        'Optional flags:\n'
        '--$configFileFlag Device OS config file for hosts.\n');
    exit(1);
  }

  final ArgResults argResults = parser.parse(args);
  final File configFile = file(join(dirname(Platform.script.path), argResults[configFileFlag] as String));
  final YamlMap config = loadYaml(configFile.readAsStringSync()) as YamlMap;
  final String hostname = Platform.localHostname;

  _deviceOS = config[hostname] as String ?? '';

  Config.initialize(_deviceOS);

  switch (_action) {
    case 'healthcheck':
      final Map<String, HealthCheckResult> deviceChecks = await devices.checkDevices();
      final bool hasHealthyDevices = deviceChecks.values.where((HealthCheckResult r) => r.succeeded).isNotEmpty;
      if (!hasHealthyDevices) {
        throw StateError('No healthy $_deviceOS device is available for $hostname');
      }
      if (_deviceOS == 'ios') {
        await closeIosDialog();
      }
      break;
    case 'restart':
      await devices.restartDevice();
      break;
    case 'cleanup':
      await removeCachedData();
      if (_deviceOS == 'ios') {
        await removeXcodeDerivedData();
      }
      break;
    default:
      print('ERROR: Supported actions are healthcheck, restart, and cleanup.');
      break;
  }
}

bool _checkArgs(ArgParser parser, List<String> args) {
  final ArgResults argResults = parser.parse(args);
  final bool printHelp = argResults[helpFlag];
  if (printHelp) {
    return false;
  }

  _action = argResults[actionFlag];
  if (_action == null) {
    stderr.write('ERROR: --$actionFlag must be defined\n');
    return false;
  }

  return true;
}
