// Copyright 2021 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:cocoon_service/protos.dart' as pb;
import 'package:cocoon_service/src/model/ci_yaml/ci_yaml.dart';
import 'package:cocoon_service/src/service/config.dart';
import 'package:yaml/yaml.dart';

void main(List<String> args) async {
  if (args.length != 1) {
    print('validate_scheduler_config.dart configPath');
    exit(1);
  }
  final String configPath = args.first;
  final File configFile = File(configPath);
  if (!configFile.existsSync()) {
    print('validate_scheduler_config.dart configPath');
    exit(1);
  }

  final YamlMap configYaml = loadYaml(configFile.readAsStringSync()) as YamlMap;
  final pb.SchedulerConfig unCheckedSchedulerConfig = pb.SchedulerConfig()..mergeFromProto3Json(configYaml);
  print(
    CiYamlInner(
      type: CiType.any,
      slug: Config.flutterSlug,
      branch: Config.defaultBranch(Config.flutterSlug),
      config: unCheckedSchedulerConfig,
    ).config,
  );
}
