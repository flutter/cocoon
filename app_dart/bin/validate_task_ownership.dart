// Copyright 2021 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:cocoon_service/src/request_handlers/flaky_handler_utils.dart';
import 'package:yaml/yaml.dart';

/// Validates task ownership.
///
/// It expects two parameters: the full path to the config file (`.ci.yaml`), and the full path
/// to the `TESTOWNERS` file.
///
/// This supports only framework repository now.
void main(List<String> args) {
  final String ciYamlPath = args[0];
  final String testOwnersPath = args[1];
  final File ciYamlFile = File(ciYamlPath);
  final File testOwnersFile = File(testOwnersPath);
  if (!ciYamlFile.existsSync() || !testOwnersFile.existsSync()) {
    print('validate_task_ownership.dart ciYamlPath testOwnersPath repo');
    exit(1);
  }
  final List<String> noOwnerBuilders = <String>[];
  final YamlMap ciYaml = loadYaml(ciYamlFile.readAsStringSync()) as YamlMap;
  final YamlList yamlList = ciYaml['targets'] as YamlList;
  final List<YamlMap> targets = yamlList.map<YamlMap>((dynamic target) => target as YamlMap).toList();
  for (final YamlMap target in targets) {
    final String builder = target['builder'] as String;
    final String owner = getTestOwner(builder, getTypeForBuilder(builder, ciYaml), testOwnersFile.readAsStringSync());
    print('$builder: $owner');
    if (owner == null) {
      noOwnerBuilders.add(builder);
    }
  }

  if (noOwnerBuilders.isNotEmpty) {
    print('# Test ownership check failed.');
    print('Builders missing owner: $noOwnerBuilders');
    print('Please define ownership in https://github.com/flutter/flutter/blob/master/TESTOWNERS');
    exit(1);
  }
}
