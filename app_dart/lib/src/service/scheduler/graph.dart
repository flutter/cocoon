// Copyright 2021 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:github/github.dart';
import 'package:meta/meta.dart';
import 'package:retry/retry.dart';
import 'package:yaml/yaml.dart';

import '../../foundation/providers.dart';
import '../../foundation/utils.dart';
import '../../model/proto/internal/scheduler.pb.dart';
import '../config.dart';

/// Load [yamlConfig] to [SchedulerConfig] and validate the dependency graph.
Future<SchedulerConfig> schedulerConfigFromYaml(YamlMap? yamlConfig,
    {RepositorySlug? slug, bool ensureBringupTargets = true}) async {
  final SchedulerConfig config = SchedulerConfig();
  config.mergeFromProto3Json(yamlConfig);

  // check for new builders and compare to tip of tree, if current branch is not a release branch
  if (ensureBringupTargets && slug != null && slug.name == Config.defaultBranch(slug)) {
    final String tipOfTreeConfigContent = await githubFileContent(
      slug,
      '.ci.yaml',
      ref: Config.defaultBranch(slug),
      httpClientProvider: Providers.freshHttpClient,
      retryOptions: const RetryOptions(maxAttempts: 3),
    );
    final YamlMap tipOfTreeConfigYaml = loadYaml(tipOfTreeConfigContent) as YamlMap;
    final SchedulerConfig totConfig = SchedulerConfig();
    totConfig.mergeFromProto3Json(tipOfTreeConfigYaml);
    validateSchedulerConfig(config, totConfig: totConfig);
  } else {
    validateSchedulerConfig(config);
  }

  return config;
}

@visibleForTesting
void validateSchedulerConfig(SchedulerConfig schedulerConfig, {SchedulerConfig? totConfig}) {
  if (schedulerConfig.targets.isEmpty) {
    throw const FormatException('Scheduler config must have at least 1 target');
  }

  if (schedulerConfig.enabledBranches.isEmpty) {
    throw const FormatException('Scheduler config must have at least 1 enabled branch');
  }

  final Map<String, List<Target>> targetGraph = <String, List<Target>>{};
  final List<String> exceptions = <String>[];
  final Set<String> totTargets = <String>{};
  if (totConfig != null) {
    for (Target target in totConfig.targets) {
      totTargets.add(target.name);
    }
  }
  // Construct [targetGraph]. With a one scan approach, cycles in the graph
  // cannot exist as it only works forward.
  for (final Target target in schedulerConfig.targets) {
    if (targetGraph.containsKey(target.name)) {
      exceptions.add('ERROR: ${target.name} already exists in graph');
    } else {
      // a new build without "bringup: true"
      // link to wiki - https://github.com/flutter/flutter/wiki/Reducing-Test-Flakiness#adding-a-new-devicelab-test
      if (totTargets.isNotEmpty && !totTargets.contains(target.name) && target.bringup != true) {
        exceptions.add('ERROR: ${target.name} is a new builder added. it needs to be marked bringup: true');
        continue;
      }
      targetGraph[target.name] = <Target>[];
      // Add edges
      if (target.dependencies.isNotEmpty) {
        if (target.dependencies.length != 1) {
          exceptions
              .add('ERROR: ${target.name} has multiple dependencies which is not supported. Use only one dependency');
        } else {
          if (target.dependencies.first == target.name) {
            exceptions.add('ERROR: ${target.name} cannot depend on itself');
          } else if (targetGraph.containsKey(target.dependencies.first)) {
            targetGraph[target.dependencies.first]!.add(target);
          } else {
            exceptions.add('ERROR: ${target.name} depends on ${target.dependencies.first} which does not exist');
          }
        }
      }
    }
  }
  _checkExceptions(exceptions);
}

void _checkExceptions(List<String> exceptions) {
  if (exceptions.isNotEmpty) {
    final String fullException = exceptions.reduce((String exception, _) => exception + '\n');
    throw FormatException(fullException);
  }
}
