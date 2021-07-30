// Copyright 2021 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:cocoon_service/cocoon_service.dart';
import 'package:cocoon_service/protos.dart';
import 'package:yaml/yaml.dart';

const int kDefaultTimeout = 30;

void writeYaml(SchedulerConfig config) {
  // Header
  final List<String> configYaml = <String>[
    '# Describes the targets run in continuous integration environment.',
    '#',
    '# Flutter infra uses this file to generate a checklist of tasks to be performed',
    '# for every commit.',
    '#',
    '# More information at:',
    '#  * https://github.com/flutter/cocoon/blob/master/CI_YAML.md',
    'enabled_branches:',
  ];
  for (String branch in config.enabledBranches) {
    configYaml.add('  - $branch');
  }
  // Platform properties
  configYaml.add('');
  configYaml.add('platform_properties:');
  for (final String platform in config.platformProperties.keys) {
    configYaml.add('  $platform:');
    configYaml.add('    properties:');
    for (final MapEntry<String, String> entry in config.platformProperties[platform].properties.entries) {
      if (entry.value.startsWith('[')) {
        configYaml.add('      ${entry.key}: >-');
        configYaml.add('          ${entry.value}');
      } else {
        configYaml.add('      ${entry.key}: ${entry.value}');
      }
    }
  }
  // Targets
  configYaml.add('');
  configYaml.add('targets:');
  for (Target target in config.targets) {
    configYaml.add('  - name: ${target.name}');
    configYaml.add('    builder: ${target.builder}');
    if (target.enabledBranches.isNotEmpty) {
      configYaml.add('    enabled_branches:');
      for (String branch in target.enabledBranches) {
        configYaml.add('      - $branch');
      }
    }
    if (target.recipe.isNotEmpty) {
      configYaml.add('    recipe: ${target.recipe}');
    }
    if (target.bringup) {
      configYaml.add('    bringup: ${target.bringup}');
    }
    if (!target.presubmit) {
      configYaml.add('    presubmit: ${target.presubmit}');
    }
    if (!target.postsubmit) {
      configYaml.add('    postsubmit: ${target.postsubmit}');
    }
    if (target.timeout != kDefaultTimeout) {
      configYaml.add('    timeout: ${target.timeout}');
    }
    if (target.properties.isNotEmpty) {
      configYaml.add('    properties:');
      for (MapEntry<String, String> entry in target.properties.entries) {
        if (entry.key == 'tags') {
          final String tags = entry.value.trimRight().trimLeft();
          configYaml.add('      ${entry.key}: >');
          configYaml.add('        $tags');
        } else {
          if (entry.value.startsWith(RegExp(r'\d|true|false'))) {
            configYaml.add('      ${entry.key}: "${entry.value}"');
          } else {
            configYaml.add('      ${entry.key}: ${entry.value}');
          }
        }
      }
    }
    if (target.scheduler != SchedulerSystem.cocoon) {
      configYaml.add('    scheduler: ${target.scheduler}');
    }
    if (target.runIf.isNotEmpty) {
      configYaml.add('    runIf:');
      for (String regex in target.runIf) {
        configYaml.add('      - $regex');
      }
    }
    configYaml.add('');
  }
  print(configYaml.join('\n'));
}

Future<void> main(List<String> args) async {
  if (args.length != 1) {
    print('yaml_converter.dart \$path');
    exit(1);
  }
  final File ciYamlFile = File(args[0]);
  final YamlMap configYaml = loadYaml(ciYamlFile.readAsStringSync()) as YamlMap;
  final SchedulerConfig schedulerConfig = schedulerConfigFromYaml(configYaml);

  //////////////////////////////////////////////////////////////////////////////
  //////////////////////// Large Scale Change Logic ////////////////////////////
  //////////////////////////////////////////////////////////////////////////////
  
  // Example LSC where we sort the ci.yaml alphabetically.
  schedulerConfig.targets.sort((Target a, Target b) => a.name.compareTo(b.name));
  //////////////////////////////////////////////////////////////////////////////
  //////////////////////////////////////////////////////////////////////////////
  writeYaml(schedulerConfig);
}
