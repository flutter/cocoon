// Copyright 2021 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore: import_of_legacy_library_into_null_safe
import 'package:yaml/yaml.dart';

// ignore: import_of_legacy_library_into_null_safe
import 'models/scheduler.pb.dart';

/// Load [yamlConfig] to [SchedulerConfig] and validate the dependency graph.
SchedulerConfig schedulerConfigFromYaml(YamlMap yamlConfig) {
  final SchedulerConfig config = SchedulerConfig();
  config.mergeFromProto3Json(yamlConfig);
  _validateSchedulerConfig(config);

  return config;
}

void _validateSchedulerConfig(SchedulerConfig schedulerConfig) {
  if (schedulerConfig.targets.isEmpty) {
    throw const FormatException('Scheduler config must have at least 1 target');
  }

  if (schedulerConfig.enabledBranches.isEmpty) {
    throw const FormatException('Scheduler config must have at least 1 enabled branch');
  }

  final Map<String, List<Target>> targetGraph = <String, List<Target>>{};
  final List<String> exceptions = <String>[];
  // Construct [targetGraph]. With a one scan approach, cycles in the graph
  // cannot exist as it only works forward.
  for (final Target target in schedulerConfig.targets) {
    if (targetGraph.containsKey(target.name)) {
      exceptions.add('ERROR: ${target.name} already exists in graph');
    } else {
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
            targetGraph[target.dependencies.first].add(target);
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