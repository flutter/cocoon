// Copyright 2021 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert' show jsonDecode;
import 'dart:io' as io;

import 'package:args/args.dart';
import 'package:cocoon_service/protos.dart';
import 'package:cocoon_service/src/service/luci.dart';

Future<void> main(List<String> args) async {
  final ArgParser parser = ArgParser()
    ..addOption(
      'try-builders',
      abbr: 't',
      help: "Path to a repo's `try_builders.json` config file.",
    )
    ..addOption(
      'prod-builders',
      abbr: 'p',
      help: "Path to a repo's `prod_builders.json` config file.",
    );
  final ArgResults results = parser.parse(args);
  final String tryBuildersPath = results['try-builders'] as String;
  final String prodBuildersPath = results['prod-builders'] as String;

  run(
    tryBuildersPath: tryBuildersPath,
    prodBuildersPath: prodBuildersPath,
  );
}

void run({
  String tryBuildersPath,
  String prodBuildersPath,
}) {
  final SchedulerConfig configTry = parseJson(
    tryBuildersPath,
    presubmit: true,
  );
  final SchedulerConfig configProd = parseJson(
    prodBuildersPath,
    postsubmit: true,
  );

  final SchedulerConfig mergedConfig = mergeConfigs(configTry, configProd);
  writeYaml(mergedConfig);
}

SchedulerConfig parseJson(String path, {bool presubmit = false, bool postsubmit = false}) {
  if (path == null) {
    return SchedulerConfig.getDefault();
  }

  final String buildersString = io.File(path).readAsStringSync();
  final Map<String, dynamic> jsonMap = jsonDecode(buildersString) as Map<String, dynamic>;
  final List<dynamic> builderList = jsonMap['builders'] as List<dynamic>;
  final Iterable<LuciBuilder> builders = builderList
      .map((dynamic builder) => LuciBuilder.fromJson(builder as Map<String, dynamic>))
      .where((LuciBuilder element) => element.enabled ?? true);
  final Iterable<Target> targets = builders.map((LuciBuilder builder) => Target(
        name: builder.taskName ?? builder.name,
        scheduler: SchedulerSystem.luci,
        presubmit: presubmit,
        postsubmit: postsubmit,
        builder: builder.name,
        runIf: builder.runIf,
        bringup: builder.flaky,
      ));

  return SchedulerConfig(enabledBranches: <String>['master'], targets: targets);
}

void writeYaml(SchedulerConfig config) {
  final List<String> configYaml = <String>['enabled_branches:'];
  for (String branch in config.enabledBranches) {
    configYaml.add('  - $branch');
  }
  configYaml.add('');
  configYaml.add('targets:');
  for (Target target in config.targets) {
    configYaml.add('  - ${target.name}');
    configYaml.add('    builder: ${target.builder}');
    if (target.bringup) {
      configYaml.add('    bringup: ${target.bringup}');
    }
    if (target.presubmit) {
      configYaml.add('    presubmit: ${target.presubmit}');
    }
    if (target.postsubmit) {
      configYaml.add('    postsubmit: ${target.postsubmit}');
    }
    if (target.scheduler != SchedulerSystem.cocoon) {
      configYaml.add('    scheduler: ${target.scheduler}');
    }
    if (target.runIf.isNotEmpty) {
      configYaml.add('    runIf:');
      for (String regex in target.runIf) {
        configYaml.add('      - $regex');
      }
    }
    configYaml.add('');
  }
  print(configYaml.join('\n'));
}

/// The [GeneratedMessage] merge functionality does not take into account
/// unique targets, so this implements it.
SchedulerConfig mergeConfigs(SchedulerConfig a, SchedulerConfig b) {
  final Map<String, Target> targets = <String, Target>{};
  final Set<String> enabledBranches = Set<String>.from(a.enabledBranches)..addAll(b.enabledBranches);
  for (Target target in a.targets) {
    targets[target.name] = target;
  }

  for (Target target in b.targets) {
    if (targets.containsKey(target.name)) {
      final Target mergeTarget = targets[target.name];
      if (target.builder != mergeTarget.builder) {
        print(target);
        print(mergeTarget);
        throw Exception('Builders do not match on ${target.name}');
      }
      mergeTarget.bringup = mergeTarget.bringup || target.bringup;
      mergeTarget.presubmit = mergeTarget.presubmit || target.presubmit;
      mergeTarget.postsubmit = mergeTarget.postsubmit || target.postsubmit;
      targets[target.name] = mergeTarget;
    } else {
      targets[target.name] = target;
    }
  }

  return SchedulerConfig(enabledBranches: enabledBranches, targets: targets.values);
}
