// Copyright 2021 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io' as io;

import 'package:test/test.dart';
import 'package:yaml/yaml.dart';

import 'package:cocoon_service/cocoon_service.dart';

import './common.dart';

/// List of repositories that have valid .ci.yaml config files.
///
/// These will be prepended by 'https://raw.githubusercontent.com/'. Should be
/// of the form '<GITHUB_ORG>/<REPO_NAME>/<BRANCH>/<PATH_TO_FILE>'.
const List<String> configFiles = <String>[
  'flutter/flutter/master/.ci.yaml',
];

Future<void> main() async {
  for (final String configFile in configFiles) {
    test('validate config file of $configFile', () async {
      final String configContent = await remoteFileContent(
        () => io.HttpClient(),
        TestLogging.instance,
        twoSecondLinearBackoff,
        configFile,
      );
      if (configContent == null) {
        fail('Failed to download file: https://raw.githubusercontent.com/$configFile');
      }

      final YamlMap configYaml = loadYaml(configContent) as YamlMap;
      try {
        loadSchedulerConfig(configYaml);
      } on FormatException catch (e) {
        fail(e.message);
      }
    });
  }
}
