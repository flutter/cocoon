// Copyright 2021 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:cocoon_service/cocoon_service.dart';
import 'package:cocoon_service/protos.dart';
import 'package:yaml/yaml.dart';

const int kDefaultTimeout = 30;

void writeYaml(SchedulerConfig config) {
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
  configYaml.add('');
  configYaml.add('targets:');
  for (Target target in config.targets) {
    configYaml.add('  - name: ${target.name}');
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
        configYaml.add('      ${entry.key}: ${entry.value}');
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
  if (args.length != 2) {
    print('generate_jspb.dart \$repo \$sha');
    exit(1);
  }
  final String repo = args.first;
  final String sha = args[1];
  final Uri ciYamlUrl = Uri.https('raw.githubusercontent.com', 'flutter/$repo/$sha/.ci.yaml');
  final HttpClient client = HttpClient();
  final HttpClientRequest clientRequest = await client.getUrl(ciYamlUrl);
  final HttpClientResponse clientResponse = await clientRequest.close();
  if (clientResponse.statusCode != HttpStatus.ok) {
    throw HttpException('HTTP ${clientResponse.statusCode}: $ciYamlUrl');
  }
  final String configContent = await utf8.decoder.bind(clientResponse).join();
  client.close(force: true);
  final YamlMap configYaml = loadYaml(configContent) as YamlMap;
  // There's an assumption that we're only generating builder configs from commits that
  // have already landed with validation. Otherwise, this will fail.
  final SchedulerConfig schedulerConfig = schedulerConfigFromYaml(configYaml);
  writeYaml(schedulerConfig);
}
