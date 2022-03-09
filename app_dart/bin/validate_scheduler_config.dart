// Copyright 2021 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:cocoon_service/src/foundation/utils.dart' hide githubFileContent;
import 'package:cocoon_service/src/model/appengine/commit.dart';
import 'package:cocoon_service/src/model/ci_yaml/ci_yaml.dart';
import 'package:cocoon_service/src/service/config.dart';
import 'package:cocoon_service/src/service/scheduler.dart';
import 'package:github/github.dart';
import 'package:yaml/yaml.dart';

import '../test/src/datastore/fake_config.dart';
import '../test/src/service/fake_scheduler.dart';

void main(List<String> args) async {
  if (args.length != 3) {
    print('validate_scheduler_config.dart configPath \$repo \$branch');
    exit(1);
  }
  final String configPath = args.first;
  final File configFile = File(configPath);
  if (!configFile.existsSync()) {
    print('validate_scheduler_config.dart configPath \$repo \$branch');
    print('please provide a valid file path as configPath');
    exit(1);
  }

  final YamlMap configYaml = loadYaml(configFile.readAsStringSync()) as YamlMap;
  CiYaml currentConfig = generateCiYamlFromYamlMap(configYaml);

  if (args[2] == Config.defaultBranch(RepositorySlug('flutter', args[1]))) {
    final FakeScheduler scheduler = FakeScheduler(
      config: FakeConfig(),
      ciYaml: exampleConfig,
    );

    Commit totCommit = generateTotCommit(0, repo: args[1]);
    CiYaml totConfig = await scheduler.getRealCiYaml(totCommit);
    // FOR REVIEW:
    // totCommit now goes through the process of getCiYaml, which adds overhead
    // because tot config does not need to be validated

    print(CiYaml.fromYaml(currentConfig, totConfig: totConfig));
  } else {
    print(CiYaml.fromYaml(currentConfig));
  }
}
