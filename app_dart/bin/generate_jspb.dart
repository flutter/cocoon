// Copyright 2021 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:cocoon_service/cocoon_service.dart';
import 'package:cocoon_service/protos.dart';
import 'package:cocoon_service/src/foundation/providers.dart';
import 'package:cocoon_service/src/foundation/typedefs.dart';
import 'package:yaml/yaml.dart';

Future<String> getRemoteConfigContent(String repo, String ref) async {
  const HttpClientProvider httpClientProvider = Providers.freshHttpClient;
  final String configContent =
      await githubFileContent('flutter/$repo/$ref/.ci.yaml', httpClientProvider: httpClientProvider);
  return configContent;
}

String getLocalConfigContent(String path) {
  final File configFile = File(path);
  return configFile.readAsStringSync();
}

Future<void> main(List<String> args) async {
  if (args.length != 1 && args.length != 2) {
    print('generate_jspb.dart \$local_ci_yaml');
    print('generate_jspb.dart \$repo \$sha');
    exit(1);
  }
  String configContent;
  if (args.length == 2) {
    configContent = await getRemoteConfigContent(args[0], args[1]);
  } else {
    configContent = getLocalConfigContent(args[0]);
  }
  final YamlMap configYaml = loadYaml(configContent) as YamlMap;
  // There's an assumption that we're only generating builder configs from commits that
  // have already landed with validation. Otherwise, this will fail.
  final SchedulerConfig schedulerConfig = schedulerConfigFromYaml(configYaml);
  print(jsonEncode(schedulerConfig.toProto3Json()));
}
