// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:github/github.dart';
import 'package:meta/meta.dart';
import 'package:yaml/yaml.dart';

import '../request_handling/api_request_handler.dart';
import '../request_handling/authentication.dart';
import '../request_handling/body.dart';
import '../service/bigquery.dart';
import '../service/config.dart';
import '../service/github_service.dart';
import 'flaky_handler_utils.dart';

@immutable
class DeflakeFlakyTest extends ApiRequestHandler<Body> {
  const DeflakeFlakyTest(Config config, AuthenticationProvider authenticationProvider)
      : super(config: config, authenticationProvider: authenticationProvider);

  @override
  Future<Body> get() async {
    final RepositorySlug slug = config.flutterSlug;
    final GithubService gitHub = config.createGithubServiceWithToken(await config.githubOAuthToken);
    final BigqueryService bigquery = await config.createBigQueryService();
    final String ciContent = await gitHub.getFileContent(slug, kCiYamlPath);
    final List<String> potentialTargets = await _getPotentialTargets(gitHub, slug, content: ciContent);
    return Body.forJson(const <String, dynamic>{
      'Statuses': 'success',
    });
  }

  Future<List<String>> _getPotentialTargets(RepositorySlug slug, GithubService gitHub, {String content}) async {
    final YamlMap ci = loadYaml(content) as YamlMap;
    final YamlList targets = ci[kCiYamlTargetsKey] as YamlList;
    final List<YamlMap> flakyTargets = targets.where
    final List<String> lines = content.split('\n');
    while (lineNumber < lines.length && !lines[lineNumber].contains('builder:')) {
      if (lines[nextLine].contains('$kCiYamlTargetIsFlakyKey:')) {
        lines[nextLine] = lines[nextLine].replaceFirst('false', 'true # Flaky $issueUrl');
        return lines.join('\n');
      }
      nextLine += 1;
    }
  }

  String _marksBuildFlakyInContent(String content, String builder, String issueUrl) {
    final List<String> lines = content.split('\n');
    final int builderLineNumber = lines.indexWhere((String line) => line.contains('builder: $builder'));
    // Takes care the case if is kCiYamlTargetIsFlakyKey is already defined to false
    int nextLine = builderLineNumber + 1;
    while (nextLine < lines.length && !lines[nextLine].contains('builder:')) {
      if (lines[nextLine].contains('$kCiYamlTargetIsFlakyKey:')) {
        lines[nextLine] = lines[nextLine].replaceFirst('false', 'true # Flaky $issueUrl');
        return lines.join('\n');
      }
      nextLine += 1;
    }
    lines.insert(builderLineNumber + 1, '    $kCiYamlTargetIsFlakyKey: true # Flaky $issueUrl');
    return lines.join('\n');
  }
}
