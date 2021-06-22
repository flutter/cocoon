// Copyright 2021 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io' as io;

import 'package:cocoon_service/cocoon_service.dart';
import 'package:test/test.dart';
import 'package:yaml/yaml.dart';

import './common.dart';

/// List of repositories that have valid .ci.yaml config files.
///
/// These will be prepended by 'https://raw.githubusercontent.com/'. Should be
/// of the form '<GITHUB_ORG>/<REPO_NAME>/<BRANCH>/<PATH_TO_FILE>'.
const List<String> configFiles = <String>[
  'flutter/cocoon/master/.ci.yaml',
  'flutter/engine/master/.ci.yaml',
  'flutter/flutter/master/.ci.yaml',
  'flutter/packages/master/.ci.yaml',
  'flutter/plugins/master/.ci.yaml',
];

Future<void> main() async {
  for (final String configFile in configFiles) {
    test('validate config file of $configFile', () async {
      final String configContent = await githubFileContent(
        configFile,
        httpClientProvider: () => io.HttpClient(),
        log: TestLogging.instance,
      );
      final YamlMap configYaml = loadYaml(configContent) as YamlMap;
      try {
        schedulerConfigFromYaml(configYaml);
      } on FormatException catch (e) {
        fail(e.message);
      }
    });
  }
}
