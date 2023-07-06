// Copyright 2021 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:core';
import 'dart:io';

import 'package:cocoon_service/cocoon_service.dart';
import 'package:cocoon_service/src/model/ci_yaml/ci_yaml.dart';
import 'package:cocoon_service/src/model/proto/internal/scheduler.pbserver.dart' as pb;
import 'package:github/github.dart';
import 'package:http/http.dart' as http;
import 'package:process/process.dart';
import 'package:test/test.dart';
import 'package:yaml/yaml.dart';

import 'common.dart';

/// List of repositories that have supported .ci.yaml config files.
final List<SupportedConfig> configs = <SupportedConfig>[
  SupportedConfig(RepositorySlug('flutter', 'cocoon'), 'main'),
  SupportedConfig(RepositorySlug('flutter', 'engine'), 'main'),
  SupportedConfig(RepositorySlug('flutter', 'flutter')),
  SupportedConfig(RepositorySlug('flutter', 'packages'), 'main'),
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
      final pb.SchedulerConfig currentSchedulerConfig = pb.SchedulerConfig()..mergeFromProto3Json(configYaml);
      try {
        CiYaml(
          slug: config.slug,
          branch: Config.defaultBranch(config.slug),
          config: currentSchedulerConfig,
        );
      } on FormatException catch (e) {
        fail(e.message);
      }
    });

    test(
      'validate enabled branches of $config',
      () async {
        final String configContent = await githubFileContent(
          config.slug,
          kCiYamlPath,
          httpClientProvider: () => http.Client(),
          ref: config.branch,
        );
        final YamlMap configYaml = loadYaml(configContent) as YamlMap;
        final pb.SchedulerConfig schedulerConfig = pb.SchedulerConfig()..mergeFromProto3Json(configYaml);

        final List<String> githubBranches = getBranchesForRepository(config.slug);

        final Map<String, bool> validEnabledBranches = <String, bool>{};
        // Add config wide enabled branches
        for (String enabledBranch in schedulerConfig.enabledBranches) {
          validEnabledBranches[enabledBranch] = false;
        }
        // Add all target specific enabled branches
        for (pb.Target target in schedulerConfig.targets) {
          for (String enabledBranch in target.enabledBranches) {
            validEnabledBranches[enabledBranch] = false;
          }
        }

        // N^2 scan to verify all enabled branch patterns match an exist branch on the repo.
        for (String enabledBranch in validEnabledBranches.keys) {
          for (String githubBranch in githubBranches) {
            if (CiYaml.enabledBranchesMatchesCurrentBranch(<String>[enabledBranch], githubBranch)) {
              validEnabledBranches[enabledBranch] = true;
            }
          }
        }

        if (config.slug.name == 'engine') {
          print(githubBranches);
          print(validEnabledBranches);
        }

        // Verify the enabled branches
        for (String enabledBranch in validEnabledBranches.keys) {
          expect(
            validEnabledBranches[enabledBranch],
            isTrue,
            reason: '$enabledBranch does not match to a branch in ${config.slug.fullName}',
          );
        }
      },
      skip: config.slug.name == 'flutter',
    );
  }
}

/// Gets all branches for [slug].
///
/// Internally, uses the git on path to get the branches from the remote for [slug].
List<String> getBranchesForRepository(RepositorySlug slug) {
  const ProcessManager processManager = LocalProcessManager();
  final ProcessResult result =
      processManager.runSync(<String>['git', 'ls-remote', '--head', 'https://github.com/${slug.fullName}']);
  final List<String> lines = (result.stdout as String).split('\n');

  final List<String> githubBranches = <String>[];
  for (String line in lines) {
    if (line.isEmpty) {
      continue;
    }
    // Lines follow the format of `$sha\t$ref`
    final String ref = line.split('\t')[1];
    final String branch = ref.replaceAll('refs/heads/', '');
    githubBranches.add(branch);
  }

  return githubBranches;
}
