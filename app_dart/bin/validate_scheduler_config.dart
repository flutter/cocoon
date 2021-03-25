// Copyright 2021 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:yaml/yaml.dart';

import 'package:cocoon_service/cocoon_service.dart';

void main(List<String> args) {
  final String configPath = args.first;
  final File configFile = File(configPath);
  if (!configFile.existsSync()) {
    print('validate_scheduler_config.dart configPath');
    exit(1);
  }

  final YamlMap configYaml = loadYaml(configFile.readAsStringSync()) as YamlMap;
  print(loadSchedulerConfig(configYaml));
}
