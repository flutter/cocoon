// Copyright 2021 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cocoon_service/protos.dart' as pb;
import 'package:github/github.dart';
import 'package:http/http.dart' as http;
import 'package:meta/meta.dart';
import 'package:yaml/yaml.dart';

@visibleForTesting
http.Client Function()? debugHttpClientFactory;

Future<String> githubFileContent(
  RepositorySlug slug,
  String filePath, {
  String ref = 'master',
  Duration timeout = const Duration(seconds: 5),
}) async {
  final Uri githubUrl = Uri.https('raw.githubusercontent.com', '${slug.fullName}/$ref/$filePath');
  return getUrl(githubUrl);
}

FutureOr<String> getUrl(Uri url) async {
  final http.Client client = debugHttpClientFactory?.call() ?? http.Client();
  try {
    final http.Response response = await client.get(url);

    if (response.statusCode == HttpStatus.ok) {
      return response.body;
    } else {
      throw HttpException('HTTP ${response.statusCode}: $url');
    }
  } finally {
    client.close();
  }
}

Future<String> getRemoteConfigContent(String repo, String ref, String relativePath) async {
  final String configContent = await githubFileContent(
    RepositorySlug('flutter', repo),
    relativePath,
    ref: ref,
  );
  return configContent;
}

String getLocalConfigContent(String path) {
  final File configFile = File(path);
  return configFile.readAsStringSync();
}

Future<void> main(List<String> args) async {
  if (args.length != 1 && args.length != 2 && args.length != 3) {
    print('generate_jspb.dart \$local_ci_yaml');
    print('generate_jspb.dart \$repo \$sha');
    print('generate_jspb.dart \$repo \$sha \$relativePath');
    exit(1);
  }
  String configContent;
  if (args.length == 1) {
    configContent = getLocalConfigContent(args[0]);
  } else {
    final String relativePath = args.elementAtOrNull(2) ?? '.ci.yaml';
    configContent = await getRemoteConfigContent(args[0], args[1], relativePath);
  }

  final YamlMap configYaml = loadYaml(configContent) as YamlMap;
  final pb.SchedulerConfig schedulerConfig = pb.SchedulerConfig()..mergeFromProto3Json(configYaml);

  print(jsonEncode(schedulerConfig.toProto3Json()));
}
