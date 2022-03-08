// Copyright 2021 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:cocoon_service/src/model/ci_yaml/ci_yaml.dart';
import 'package:cocoon_service/src/model/proto/internal/scheduler.pb.dart' as pb;
import 'package:cocoon_service/src/service/config.dart';
import 'package:github/github.dart';
import 'package:yaml/yaml.dart';

import 'generate_jspb.dart';

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

  pb.SchedulerConfig totSchedulerConfig = pb.SchedulerConfig();
  if (args[1] == Config.defaultBranch(RepositorySlug('flutter', 'repo'))) {
    String totConfigContent;
    totConfigContent = await githubFileContent(RepositorySlug('flutter', args[0]), '.ci.yaml', ref: args[1]);
    final YamlMap totConfigYaml = loadYaml(totConfigContent) as YamlMap;
    totSchedulerConfig.mergeFromProto3Json(totConfigYaml);

    CiYaml totConfig = CiYaml(config: totSchedulerConfig, slug: RepositorySlug('flutter', args[0]), branch: args[1]);
    print(CiYaml.fromYaml(configYaml, totConfig, ensureBringupTarget: true));
  } else {
    CiYaml totConfig = CiYaml(config: totSchedulerConfig, slug: RepositorySlug('flutter', args[0]), branch: args[1]);
    print(CiYaml.fromYaml(configYaml, totConfig));
  }
}
