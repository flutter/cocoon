// Copyright 2021 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:cocoon_scheduler/scheduler.dart';
import 'package:yaml/yaml.dart';

Future<void> main(List<String> args) async {
  if (args.length != 2) {
    print('generate_builder_config.dart \$repo \$sha');
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
  const JsonEncoder encoder = JsonEncoder.withIndent('  ');
  final String prettyJson = encoder.convert(schedulerConfig.writeToJsonMap());
  print(prettyJson);
}
