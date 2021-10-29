// Copyright 2021 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_service/cocoon_service.dart';
import 'package:github/github.dart';
import 'package:http/http.dart' as http;
import 'package:test/test.dart';
import 'package:yaml/yaml.dart';

import 'common.dart';

/// List of repositories that have supported .ci.yaml config files.
final List<SupportedConfig> configs = <SupportedConfig>[
  SupportedConfig(RepositorySlug('flutter', 'cocoon'), 'main'),
  SupportedConfig(RepositorySlug('flutter', 'engine')),
  SupportedConfig(RepositorySlug('flutter', 'flutter')),
  SupportedConfig(RepositorySlug('flutter', 'packages')),
  SupportedConfig(RepositorySlug('flutter', 'plugins')),
];

Future<void> main() async {
  for (final SupportedConfig config in configs) {
    test('validate config file of $config', () async {
      final String configContent = await githubFileContent(
        config.slug,
        kCiYamlPath,
        httpClientProvider: () => http.Client(),
        ref: config.branch,
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
