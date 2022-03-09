// Copyright 2021 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cocoon_service/ci_yaml.dart';
import 'package:cocoon_service/cocoon_service.dart';
import 'package:cocoon_service/protos.dart' as pb;
import 'package:cocoon_service/src/model/appengine/commit.dart';
import 'package:github/github.dart';
import 'package:http/http.dart' as http;
import 'package:yaml/yaml.dart';

import '../test/src/datastore/fake_config.dart';
import '../test/src/service/fake_scheduler.dart';
import '../test/src/utilities/entity_generators.dart';

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
  final http.Client client = http.Client();
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

Future<String> getRemoteConfigContent(String repo, String ref) async {
  final String configContent = await githubFileContent(
    RepositorySlug('flutter', repo),
    '.ci.yaml',
    ref: ref,
  );
  return configContent;
}

String getLocalConfigContent(String path) {
  final File configFile = File(path);
  return configFile.readAsStringSync();
}

Future<void> main(List<String> args) async {
  if (args.length != 1 && args.length != 3) {
    print('generate_jspb.dart \$local_ci_yaml');
    print('generate_jspb.dart \$repo \$sha \$branch');
    exit(1);
  }
  String configContent;
  if (args.length == 3) {
    configContent = await getRemoteConfigContent(args[0], args[1]);
  } else {
    configContent = getLocalConfigContent(args[0]);
  }

  pb.SchedulerConfig schedulerConfig;
  if (args.length == 3) {
    final FakeScheduler scheduler = FakeScheduler(config: FakeConfig());
    Commit currentCommit = generateCommit(1, repo: args[0], sha: args[1], branch: args[2]);

    // FOR REVIEW:
    // requiring branch information from user as well to check whether current branch is a release branch.
    if (args[2] == Config.defaultBranch(RepositorySlug('flutter', args[0]))) {
      // FOR REVIEW:
      // supply 0 in generateCommit, to singal that we use a deafult branch instead of sha
      Commit totCommit =
          generateTotCommit(0, repo: args[1], branch: Config.defaultBranch(RepositorySlug('flutter', args[0])));
      // There's an assumption that we're only generating builder configs from commits that
      // have already landed with validation. Otherwise, this will fail.
      CiYaml totConfig = await scheduler.getRealCiYaml(totCommit);
      CiYaml currentConfig = await scheduler.getRealCiYaml(currentCommit, totCiYaml: totConfig);
      schedulerConfig = currentConfig.config;
    } else {
      CiYaml currentConfig = await scheduler.getRealCiYaml(currentCommit);
      schedulerConfig = currentConfig.config;
    }
  } else {
    // FOR REVIEW:
    // when validating local file and sha is not available, we do it the old school way by generating a CiYaml directly
    final YamlMap configYaml = loadYaml(configContent) as YamlMap;
    CiYaml currentYaml = generateCiYamlFromYamlMap(configYaml);
    schedulerConfig = CiYaml.fromYaml(currentYaml).config;
  }

  print(jsonEncode(schedulerConfig.toProto3Json()));
}
