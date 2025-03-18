// Copyright 2021 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:core';

import 'package:cocoon_service/cocoon_service.dart';
import 'package:cocoon_service/src/model/ci_yaml/ci_yaml.dart';
import 'package:cocoon_service/src/model/proto/internal/scheduler.pbserver.dart'
    as pb;
import 'package:github/github.dart';
import 'package:http/http.dart' as http;
import 'package:process/process.dart';
import 'package:test/test.dart';
import 'package:yaml/yaml.dart';

import 'common.dart';

/// List of repositories that have supported .ci.yaml config files.
final List<SupportedConfig> configs = <SupportedConfig>[
  SupportedConfig(RepositorySlug('flutter', 'cocoon')),
  SupportedConfig(RepositorySlug('flutter', 'flutter')),
  SupportedConfig(RepositorySlug('flutter', 'packages')),
];

Future<void> main() async {
  for (final config in configs) {
    test('validate config file of $config', () async {
      final configContent = await githubFileContent(
        config.slug,
        kCiYamlPath,
        httpClientProvider: http.Client.new,
        ref: config.branch,
      );
      final configYaml = loadYaml(configContent) as YamlMap;
      final currentSchedulerConfig =
          pb.SchedulerConfig()..mergeFromProto3Json(configYaml);
      try {
        CiYaml(
          type: CiType.any,
          slug: config.slug,
          branch: Config.defaultBranch(config.slug),
          config: currentSchedulerConfig,
        );
      } on FormatException catch (e) {
        fail(e.message);
      }
    });

    test('validate enabled branches of $config', () async {
      final configContent = await githubFileContent(
        config.slug,
        kCiYamlPath,
        httpClientProvider: http.Client.new,
        ref: config.branch,
      );
      final configYaml = loadYaml(configContent) as YamlMap;
      final schedulerConfig =
          pb.SchedulerConfig()..mergeFromProto3Json(configYaml);
      // Validate using the existing CiYaml logic.
      CiYaml(
        type: CiType.any,
        slug: config.slug,
        branch: config.branch,
        config: schedulerConfig,
        validate: true,
      );

      final githubBranches = getBranchesForRepository(config.slug);

      final validEnabledBranches = <String, bool>{};
      // Add config wide enabled branches
      for (var enabledBranch in schedulerConfig.enabledBranches) {
        validEnabledBranches[enabledBranch] = false;
      }
      // Add all target specific enabled branches
      for (var target in schedulerConfig.targets) {
        for (var enabledBranch in target.enabledBranches) {
          validEnabledBranches[enabledBranch] = false;
        }
      }

      // N^2 scan to verify all enabled branch patterns match an exist branch on the repo.
      for (var enabledBranch in validEnabledBranches.keys) {
        for (var githubBranch in githubBranches) {
          if (CiYaml.enabledBranchesMatchesCurrentBranch(<String>[
            enabledBranch,
          ], githubBranch)) {
            validEnabledBranches[enabledBranch] = true;
          }
        }
      }

      // Verify the enabled branches
      for (var enabledBranch in validEnabledBranches.keys) {
        expect(
          validEnabledBranches[enabledBranch],
          isTrue,
          reason:
              '$enabledBranch does not match to a branch in ${config.slug.fullName}',
        );
      }
    });
  }
}

/// Gets all branches for [slug].
///
/// Internally, uses the git on path to get the branches from the remote for [slug].
List<String> getBranchesForRepository(RepositorySlug slug) {
  const ProcessManager processManager = LocalProcessManager();
  final result = processManager.runSync(<String>[
    'git',
    'ls-remote',
    '--head',
    'https://github.com/${slug.fullName}',
  ]);
  final lines = (result.stdout as String).split('\n');

  final githubBranches = <String>[];
  for (var line in lines) {
    if (line.isEmpty) {
      continue;
    }
    // Lines follow the format of `$sha\t$ref`
    final ref = line.split('\t')[1];
    final branch = ref.replaceAll('refs/heads/', '');
    githubBranches.add(branch);
  }

  return githubBranches;
}
