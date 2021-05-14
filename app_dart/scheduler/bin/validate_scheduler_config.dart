// Copyright 2021 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:cocoon_scheduler/scheduler.dart';
// ignore: import_of_legacy_library_into_null_safe
import 'package:yaml/yaml.dart';

void main(List<String> args) {
  final String configPath = args.first;
  final File configFile = File(configPath);
  if (!configFile.existsSync()) {
    print('validate_scheduler_config.dart configPath');
    exit(1);
  }

  final YamlMap configYaml = loadYaml(configFile.readAsStringSync()) as YamlMap;
  print(schedulerConfigFromYaml(configYaml));
}
