// Copyright 2021 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:cocoon_service/cocoon_service.dart';
import 'package:collection/collection.dart';
import 'package:github/github.dart';

import '../proto/internal/scheduler.pb.dart' as pb;
import 'target.dart';

/// Key used for selecting which .ci.yaml to use
enum CiType {
  /// "Default" associated with this slug / ci.yaml
  ///
  /// Pre-fusion: engine, framework, etc
  /// Post-fusion: framework, etc
  ///
  /// NOTE: Required to be present
  any,

  /// Engine's .ci.yaml file located in the monorepo
  fusionEngine,
}

/// Wrapper around one or more [CiYamlSet] files contained in a single repository.
///
/// Single sourced repositories will have exactly one `.ci.yaml` file at the
/// root of the tree. This will have the type [CiType.any].
///
/// Merged repositories can have multiple `.ci.yaml` files located throughout
/// the tree. Today we only support the root type as [CiType.any] and the second
/// as [CiType.fusionEngine].
class CiYamlSet {
  CiYamlSet({
    required this.slug,
    required this.branch,
    required Map<CiType, pb.SchedulerConfig> yamls,
    CiYamlSet? totConfig,
    bool validate = false,
    this.isFusion = false,
  }) {
    for (final MapEntry(key: type, value: config) in yamls.entries) {
      configs[type] = CiYaml(
        slug: slug,
        branch: branch,
        config: config,
        type: type,
        validate: validate,
        isFusion: isFusion,
        totConfig: totConfig?.configs[type],
      );
    }
  }

  final bool isFusion;

  final configs = <CiType, CiYaml>{};

  /// Get's the [pb.SchedulerConfig] for the requested [type].
  ///
  /// The type is expected to exist and will fail otherwise.
  pb.SchedulerConfig configFor(CiType type) => configs[type]!.config;

  /// Get's the [CiYaml] for the requested [type].
  ///
  /// The type is expected to exist and will fail otherwise.
  CiYaml ciYamlFor(CiType type) => configs[type]!;

  /// The [RepositorySlug] that [config] is from.
  final RepositorySlug slug;

  /// The git branch currently being scheduled against.
  final String branch;

  /// Gets all [Target] that run on presubmit for this config.
  List<Target> presubmitTargets({CiType type = CiType.any}) => configs[type]!.presubmitTargets;

  /// Gets all [Target] that run on postsubmit for this config.
  List<Target> postsubmitTargets({CiType type = CiType.any}) => configs[type]!.postsubmitTargets;

  /// Gets the first [Target] matching [builderName] or null.
  Target? getFirstPostsubmitTarget(
    String builderName, {
    CiType type = CiType.any,
  }) =>
      configs[type]!.getFirstPostsubmitTarget(builderName);

  /// List of target names used to filter target from release candidate branches
  /// that were already removed from main.
  List<String>? totTargetNames({CiType type = CiType.any}) => configs[type]!.totTargetNames;

  /// List of postsubmit target names used to filter target from release candidate branches
  /// that were already removed from main.
  List<String>? totPostsubmitTargetNames({CiType type = CiType.any}) => configs[type]!.totPostsubmitTargetNames;

  /// Filters post submit targets to remove targets we do not want backfilled.
  List<Target> backfillTargets({CiType type = CiType.any}) => configs[type]!.backfillTargets;

  /// Filters targets that were removed from main. [slug] is the gihub
  /// slug for branch under test, [targets] is the list of targets from
  /// the branch under test and [totTargetNames] is the list of target
  /// names enabled on the default branch.
  List<Target> filterOutdatedTargets(
    slug,
    targets,
    totTargetNames, {
    CiType type = CiType.any,
  }) =>
      configs[type]!.filterOutdatedTargets(slug, targets, totTargetNames);

  /// Filters [targets] to those that should be started immediately.
  ///
  /// Targets with a dependency are triggered when there dependency pushes a notification that it has finished.
  /// This shouldn't be confused for targets that have the property named dependency, which is used by the
  /// flutter_deps recipe module on LUCI.
  List<Target> getInitialTargets(
    List<Target> targets, {
    CiType type = CiType.any,
  }) =>
      configs[type]!.getInitialTargets(targets);

  /// Get an unfiltered list of all [targets] that are found in the ci.yaml file.
  List<Target> targets({CiType type = CiType.any}) => configs[type]!.targets;
}

/// This is a wrapper class around S[pb.SchedulerConfig].
///
/// See //CI_YAML.md for high level documentation.
class CiYaml {
  /// Creates [CiYamlSet] from a [RepositorySlug], [branch], [pb.SchedulerConfig] and an optional [CiYamlSet] of tip of tree CiYaml.
  ///
  /// If [totConfig] is passed, the validation will verify no new targets have been added that may temporarily break the LUCI infrastructure (such as new prod or presubmit targets).
  CiYaml({
    required this.slug,
    required this.branch,
    required this.config,
    required this.type,
    CiYaml? totConfig,
    bool validate = false,
    this.isFusion = false,
  }) {
    if (validate) {
      _validate(config, branch, totSchedulerConfig: totConfig?.config);
    }
    // Do not filter bringup targets. They are required for backward compatibility
    // with release candidate branches.
    final Iterable<Target> totTargets = totConfig?._targets ?? <Target>[];
    final List<Target> totEnabledTargets = _filterEnabledTargets(totTargets);
    totTargetNames = totEnabledTargets.map((Target target) => target.value.name).toList();
    totPostsubmitTargetNames =
        totConfig?.postsubmitTargets.map((Target target) => target.value.name).toList() ?? <String>[];
  }

  final CiType type;

  final bool isFusion;

  /// List of target names used to filter target from release candidate branches
  /// that were already removed from main.
  List<String>? totTargetNames;

  /// List of postsubmit target names used to filter target from release candidate branches
  /// that were already removed from main.
  List<String>? totPostsubmitTargetNames;

  /// The underlying protobuf that contains the raw data from .ci.yaml.
  pb.SchedulerConfig config;

  /// The [RepositorySlug] that [config] is from.
  final RepositorySlug slug;

  /// The git branch currently being scheduled against.
  final String branch;

  /// Gets all [Target] that run on presubmit for this config.
  List<Target> get presubmitTargets {
    final Iterable<Target> presubmitTargets =
        _targets.where((Target target) => target.value.presubmit && !target.value.bringup);
    List<Target> enabledTargets = _filterEnabledTargets(presubmitTargets);

    if (enabledTargets.isEmpty) {
      throw Exception('$branch is not enabled for this .ci.yaml.\nAdd it to run tests against this PR.');
    }
    // Filter targets removed from main.
    if (totTargetNames!.isNotEmpty) {
      enabledTargets = filterOutdatedTargets(slug, enabledTargets, totTargetNames);
    }
    return enabledTargets;
  }

  /// Gets all [Target] that run on postsubmit for this config.
  List<Target> get postsubmitTargets {
    final Iterable<Target> postsubmitTargets = _targets.where((Target target) => target.value.postsubmit);

    List<Target> enabledTargets = _filterEnabledTargets(postsubmitTargets);
    // Filter targets removed from main.
    if (totPostsubmitTargetNames!.isNotEmpty) {
      enabledTargets = filterOutdatedTargets(slug, enabledTargets, totPostsubmitTargetNames);
    }
    // filter if release_build true if current branch is a release candidate branch, or a fusion tree.
    enabledTargets = _filterReleaseBuildTargets(enabledTargets);
    return enabledTargets;
  }

  /// Gets the first [Target] matching [builderName] or null.
  Target? getFirstPostsubmitTarget(String builderName) {
    return postsubmitTargets.singleWhereOrNull((Target target) => target.value.name == builderName);
  }

  /// Filters post submit targets to remove targets we do not want backfilled.
  List<Target> get backfillTargets {
    final List<Target> filteredTargets = <Target>[];
    for (Target target in postsubmitTargets) {
      final Map<String, Object> properties = target.getProperties();
      if (!properties.containsKey('backfill') || properties['backfill'] as bool) {
        filteredTargets.add(target);
      }
    }
    return filteredTargets;
  }

  /// Filters targets with release_build = true on release candidate branches and post submit in fusion trees.
  List<Target> _filterReleaseBuildTargets(List<Target> targets) {
    final List<Target> results = <Target>[];
    final bool releaseBranch = branch.contains(RegExp('^flutter-'));
    if (!releaseBranch && !isFusion) {
      return targets;
    }
    for (Target target in targets) {
      final Map<String, Object> properties = target.getProperties();
      if (!properties.containsKey('release_build') || !(properties['release_build'] as bool)) {
        if (!target.value.bringup) results.add(target);
      }
    }
    return results;
  }

  /// Filters targets that were removed from main. [slug] is the gihub
  /// slug for branch under test, [targets] is the list of targets from
  /// the branch under test and [totTargetNames] is the list of target
  /// names enabled on the default branch.
  List<Target> filterOutdatedTargets(slug, targets, totTargetNames) {
    final String defaultBranch = Config.defaultBranch(slug);
    return targets
        .where(
          (Target target) =>
              (target.value.enabledBranches.isNotEmpty && !target.value.enabledBranches.contains(defaultBranch)) ||
              totTargetNames!.contains(target.value.name),
        )
        .toList();
  }

  /// Filters [targets] to those that should be started immediately.
  ///
  /// Targets with a dependency are triggered when there dependency pushes a notification that it has finished.
  /// This shouldn't be confused for targets that have the property named dependency, which is used by the
  /// flutter_deps recipe module on LUCI.
  List<Target> getInitialTargets(List<Target> targets) {
    Iterable<Target> initialTargets = targets.where((Target target) => target.value.dependencies.isEmpty).toList();
    if (branch != Config.defaultBranch(slug)) {
      // Filter out bringup targets for release branches
      initialTargets = initialTargets.where((Target target) => !target.value.bringup);
    }

    return initialTargets.toList();
  }

  Iterable<Target> get _targets => config.targets.map(
        (pb.Target target) => Target(
          schedulerConfig: config,
          value: target,
          slug: slug,
        ),
      );

  /// Get an unfiltered list of all [targets] that are found in the ci.yaml file.
  List<Target> get targets => _targets.toList();

  /// Filter [targets] to only those that are expected to run for [branch].
  ///
  /// A [Target] is expected to run if:
  ///   1. [Target.enabledBranches] exists and matches [branch].
  ///   2. Otherwise, [config.enabledBranches] matches [branch].
  List<Target> _filterEnabledTargets(Iterable<Target> targets) {
    final List<Target> filteredTargets = <Target>[];

    final ghMqBranch = tryParseGitHubMergeQueueBranch(branch);
    final realBranch = ghMqBranch.parsed ? ghMqBranch.branch : branch;

    // 1. Add targets with local definition
    final Iterable<Target> overrideBranchTargets =
        targets.where((Target target) => target.value.enabledBranches.isNotEmpty);
    final Iterable<Target> enabledTargets = overrideBranchTargets
        .where((Target target) => enabledBranchesMatchesCurrentBranch(target.value.enabledBranches, realBranch));
    filteredTargets.addAll(enabledTargets);

    // 2. Add targets with global definition (this is the majority of targets)
    if (enabledBranchesMatchesCurrentBranch(config.enabledBranches, realBranch)) {
      final Iterable<Target> defaultBranchTargets =
          targets.where((Target target) => target.value.enabledBranches.isEmpty);
      filteredTargets.addAll(defaultBranchTargets);
    }

    return filteredTargets;
  }

  /// Whether any of the possible [RegExp] in [enabledBranches] match [branch].
  static bool enabledBranchesMatchesCurrentBranch(List<String> enabledBranches, String branch) {
    final List<String> regexes = <String>[];
    for (String enabledBranch in enabledBranches) {
      // Prefix with start of line and suffix with end of line
      regexes.add('^$enabledBranch\$');
    }
    final String rawRegexp = regexes.join('|');
    final RegExp regexp = RegExp(rawRegexp);

    return regexp.hasMatch(branch);
  }

  /// Validates [pb.SchedulerConfig] extracted from [CiYamlSet] files.
  ///
  /// A [pb.SchedulerConfig] file is considered good if:
  ///   1. It has at least one [pb.Target] in [pb.SchedulerConfig.targets]
  ///   2. It has at least one [branch] in [pb.SchedulerConfig.enabledBranches]
  ///   3. If a second [pb.SchedulerConfig] is passed in,
  ///   we compare the current list of [pb.Target] inside the current [pb.SchedulerConfig], i.e., [schedulerConfig],
  ///   with the list of [pb.Target] from tip of the tree [pb.SchedulerConfig], i.e., [totSchedulerConfig].
  ///   If a [pb.Target] is indentified as a new target compared to target list from tip of the tree, The new target
  ///   should have its field [pb.Target.bringup] set to true.
  ///   4. no cycle should exist in the dependency graph, as tracked by map [targetGraph]
  ///   5. [pb.Target] should not depend on self
  ///   6. [pb.Target] cannot have more than 1 dependency
  ///   7. [pb.Target] should depend on target that already exist in depedency graph, and already recorded in map [targetGraph]
  ///   8. [pb.Target] has an empty runIf or the runIf includes `.ci.yaml` and `DEPS if on the engine repo.
  void _validate(pb.SchedulerConfig schedulerConfig, String branch, {pb.SchedulerConfig? totSchedulerConfig}) {
    if (schedulerConfig.targets.isEmpty) {
      throw const FormatException('Scheduler config must have at least 1 target');
    }

    if (schedulerConfig.enabledBranches.isEmpty) {
      throw const FormatException('Scheduler config must have at least 1 enabled branch');
    }

    final Map<String, List<pb.Target>> targetGraph = <String, List<pb.Target>>{};
    final List<String> exceptions = <String>[];
    final Set<String> totTargets = <String>{};
    if (totSchedulerConfig != null) {
      for (pb.Target target in totSchedulerConfig.targets) {
        totTargets.add(target.name);
      }
    }
    // Construct [targetGraph]. With a one scan approach, cycles in the graph
    // cannot exist as it only works forward.
    for (final pb.Target target in schedulerConfig.targets) {
      if (targetGraph.containsKey(target.name)) {
        exceptions.add('ERROR: ${target.name} already exists in graph');
      } else {
        // a new build without "bringup: true"
        // link to wiki - https://github.com/flutter/flutter/blob/master/docs/infra/Reducing-Test-Flakiness.md#adding-a-new-devicelab-test
        if (totTargets.isNotEmpty && !totTargets.contains(target.name) && target.bringup != true) {
          exceptions.add(
            'ERROR: ${target.name} is a new builder added. it needs to be marked bringup: true\nIf ci.yaml wasn\'t changed, try `git fetch upstream && git merge upstream/master`',
          );
          continue;
        }
        targetGraph[target.name] = <pb.Target>[];
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

        // Verify runIf includes foundational files.
        if (target.runIf.isNotEmpty) {
          if (isFusion && type == CiType.fusionEngine) {
            // Look in different locations if fusion && engine ci.yaml
            if (!target.runIf.contains('engine/src/flutter/.ci.yaml')) {
              exceptions.add(
                'ERROR: ${target.name} is missing `engine/src/flutter/.ci.yaml` in runIf',
              );
            }
            if (!target.runIf.contains('DEPS')) {
              exceptions.add('ERROR: ${target.name} is missing `DEPS` in runIf');
            }
          } else {
            // not fusion or not engine in fusion.
            if (!target.runIf.contains('.ci.yaml')) {
              exceptions.add('ERROR: ${target.name} is missing `.ci.yaml` in runIf');
            }
            if (slug == Config.engineSlug && !target.runIf.contains('DEPS')) {
              exceptions.add('ERROR: ${target.name} is missing `DEPS` in runIf');
            }
          }
        }
      }

      /// Check the dependencies for the current target if it is viable and to
      /// be added to graph. Temporarily this is only being done on non-release
      /// branches.
      if (branch == Config.defaultBranch(slug)) {
        final String? dependencyJson = target.properties['dependencies'];
        if (dependencyJson != null) {
          DependencyValidator.hasVersion(dependencyJsonString: dependencyJson);
        }
      }
    }
    _checkExceptions(exceptions);
  }

  void _checkExceptions(List<String> exceptions) {
    if (exceptions.isNotEmpty) {
      final String fullException = exceptions.reduce((String exception, _) => '$exception\n');
      throw FormatException(fullException);
    }
  }
}

/// Class to verify the version of the dependencies in the ci.yaml config file
/// for each target we are going to execute.
class DependencyValidator {
  /// dependencyJsonString is guaranteed to be non empty as it must be found
  /// before this method is called.
  ///
  /// Checks a dependency string for a pinned version.
  /// If a version is found then it must not be empty or 'latest.'
  static void hasVersion({required String dependencyJsonString}) {
    final List<String> exceptions = <String>[];

    /// Decoded will contain a list of maps for the dependencies found.
    final List<dynamic> decoded = json.decode(dependencyJsonString) as List<dynamic>;

    for (Map<String, dynamic> depMap in decoded) {
      if (!depMap.containsKey('version')) {
        exceptions.add('ERROR: dependency ${depMap['dependency']} must have a version.');
      } else {
        final String version = depMap['version'] as String;
        if (version.isEmpty || version == 'latest') {
          exceptions
              .add('ERROR: dependency ${depMap['dependency']} must have a non empty, non "latest" version supplied.');
        }
      }
    }

    if (exceptions.isNotEmpty) {
      final String fullException = exceptions.reduce((String exception, _) => '$exception\n');
      throw FormatException(fullException);
    }
  }
}
