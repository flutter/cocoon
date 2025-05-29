// Copyright 2021 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:cocoon_common/is_release_branch.dart';
import 'package:collection/collection.dart';
import 'package:github/github.dart';

import '../../../cocoon_service.dart';
import '../../service/flags/ci_yaml_flags.dart';
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
final class CiYamlSet {
  CiYamlSet({
    required this.slug,
    required this.branch,
    required Map<CiType, pb.SchedulerConfig> yamls,
    CiYamlFlags flags = CiYamlFlags.defaultInstance,
    CiYamlSet? totConfig,
    bool validate = false,
  }) {
    for (final MapEntry(key: type, value: config) in yamls.entries) {
      configs[type] = CiYaml(
        slug: slug,
        branch: branch,
        config: config,
        type: type,
        validate: validate,
        totConfig: totConfig?.configs[type],
        flags: flags,
      );
    }
  }

  /// Whether [slug] is [Config.flutterSlug], the fusion `flutter/flutter` repo.
  ///
  /// If `true`, multiple `.ci.yaml` files are available. See [CiType].
  bool get isFusion => slug == Config.flutterSlug;

  final configs = <CiType, CiYaml>{};

  /// Get's the [pb.SchedulerConfig] for the requested [type].
  ///
  /// The type is expected to exist and will fail otherwise.
  pb.SchedulerConfig configFor(CiType type) => configs[type]!.config;

  /// Get's the [CiYaml] for the requested [type].
  ///
  /// The type is expected to exist and will fail otherwise.
  CiYaml ciYamlFor(CiType type) => configs[type]!;

  /// The [RepositorySlug] that the config is from.
  final RepositorySlug slug;

  /// The git branch currently being scheduled against.
  final String branch;

  /// Gets all [Target] that run on presubmit for this config.
  List<Target> presubmitTargets({CiType type = CiType.any}) =>
      configs[type]!.presubmitTargets;

  /// Gets all [Target] that run on postsubmit for this config.
  List<Target> postsubmitTargets({CiType type = CiType.any}) =>
      configs[type]!.postsubmitTargets;

  /// Gets the first [Target] matching [builderName] or null.
  Target? getFirstPostsubmitTarget(
    String builderName, {
    CiType type = CiType.any,
  }) => configs[type]!.getFirstPostsubmitTarget(builderName);

  /// List of target names used to filter target from release candidate branches
  /// that were already removed from main.
  List<String>? totTargetNames({CiType type = CiType.any}) =>
      configs[type]!._totTargetNames;

  /// List of postsubmit target names used to filter target from release candidate branches
  /// that were already removed from main.
  List<String>? totPostsubmitTargetNames({CiType type = CiType.any}) =>
      configs[type]!._totPostsubmitTargetNames;

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
    CiYamlFlags flags = CiYamlFlags.defaultInstance,
    CiYaml? totConfig,
    bool validate = false,
  }) : _flags = flags {
    if (validate) {
      _validate(config, branch, totSchedulerConfig: totConfig?.config);
    }
    // Do not filter bringup targets. They are required for backward compatibility
    // with release candidate branches.
    final totTargets = totConfig?._targets ?? const [];
    _totTargetNames = List.unmodifiable(totTargets.map((t) => t.name));
    if (_flags.onlyUseTipOfTreeTargetsExistenceToFilterTargets) {
      _totPostsubmitTargetNames = _totTargetNames;
    } else if (totConfig != null) {
      _totPostsubmitTargetNames = List.unmodifiable(
        totConfig.postsubmitTargets.map((t) => t.name),
      );
    } else {
      _totPostsubmitTargetNames = const [];
    }
  }

  /// Flags related to resolving `.ci.yaml`.
  final CiYamlFlags _flags;

  /// The type of `.ci.yaml` `this` represents.
  final CiType type;

  /// Whether [slug] is [Config.flutterSlug], the fusion `flutter/flutter` repo.
  ///
  /// If `true`, multiple `.ci.yaml` files are available. See [CiType].
  bool get isFusion => slug == Config.flutterSlug;

  /// Target names that exist at tip-of-tree.
  ///
  /// This list is unmodifiable.
  late final List<String> _totTargetNames;

  /// Target names that execute on postsubmit at tip-of-tree.
  ///
  /// This list is unmodifiable.
  late final List<String> _totPostsubmitTargetNames;

  /// The underlying protobuf that contains the raw data from .ci.yaml.
  pb.SchedulerConfig config;

  /// The [RepositorySlug] that [config] is from.
  final RepositorySlug slug;

  /// The git branch currently being scheduled against.
  final String branch;

  /// Gets all [Target] that run on presubmit for this config.
  List<Target> get presubmitTargets {
    final presubmitTargets = _targets.where(
      (Target target) => target.presubmit && !target.isBringup,
    );
    var enabledTargets = _filterEnabledTargets(presubmitTargets);

    if (enabledTargets.isEmpty) {
      throw BranchNotEnabledForThisCiYamlException(branch: branch);
    }
    // Filter targets removed from main.
    if (_totTargetNames.isNotEmpty) {
      enabledTargets = _filterOutdatedTargets(
        slug,
        enabledTargets,
        _totTargetNames,
      );
    }
    return enabledTargets;
  }

  /// Gets all [Target] that run on postsubmit for this config.
  List<Target> get postsubmitTargets {
    final postsubmitTargets = _targets.where(
      (Target target) => target.postsubmit,
    );

    var enabledTargets = _filterEnabledTargets(postsubmitTargets);
    // Filter targets removed from main.
    if (_totPostsubmitTargetNames.isNotEmpty) {
      enabledTargets = _filterOutdatedTargets(
        slug,
        enabledTargets,
        _totPostsubmitTargetNames,
      );
    }
    // filter if release_build true if current branch is a release candidate branch, or a fusion tree.
    enabledTargets = _selectTargetsForBranch(enabledTargets);
    return enabledTargets;
  }

  /// Gets the first [Target] matching [builderName] or null.
  Target? getFirstPostsubmitTarget(String builderName) {
    return postsubmitTargets.singleWhereOrNull(
      (Target target) => target.name == builderName,
    );
  }

  /// Pick targets out of the given [targets] list that should be run for the
  /// branch that's being tested.
  List<Target> _selectTargetsForBranch(List<Target> targets) {
    if (!isFusion) {
      // Non-flutter/flutter repos run all targets in post-submit.
      return targets;
    } else if (isReleaseCandidateBranch(branchName: branch)) {
      // For release branches:
      // bringup: true         --> Always omitted.
      // release_build: "true" --> Built by Linux flutter_release_builder.
      return [
        ...targets.where(
          (target) => !target.isReleaseBuild && !target.isBringup,
        ),
      ];
    } else if (branch.contains('experimental')) {
      // For experimental branches:
      // Run all targets in post-submit.
      // TODO(matanlurey): Codify this elsewhere once its proven.
      return targets;
    } else {
      // For flutter/flutter branches include "master".
      return [...targets.where((target) => !target.isReleaseBuild)];
    }
  }

  /// Filters targets that were removed from main. [slug] is the gihub
  /// slug for branch under test, [targets] is the list of targets from
  /// the branch under test and [totTargetNames] is the list of target
  /// names enabled on the default branch.
  List<Target> _filterOutdatedTargets(
    RepositorySlug slug,
    Iterable<Target> targets,
    Iterable<String> totTargetNames,
  ) {
    final defaultBranch = Config.defaultBranch(slug);
    return targets.where((target) {
      final forcedEnabledBranches = target.enabledBranches;
      if (_flags.targetEnabledBranchesOverridesTipOfTreeTargetExistence &&
          forcedEnabledBranches.isNotEmpty &&
          !forcedEnabledBranches.contains(defaultBranch)) {
        return true;
      }

      // Otherwise, the target must exist in Tip-of-Tree.
      return totTargetNames.contains(target.name);
    }).toList();
  }

  Iterable<Target> get _targets => config.targets.map(
    (pb.Target target) =>
        Target(schedulerConfig: config, value: target, slug: slug),
  );

  /// Get an unfiltered list of all [targets] that are found in the ci.yaml file.
  List<Target> get targets => _targets.toList();

  /// Filter [targets] to only those that are expected to run for [branch].
  ///
  /// A [Target] is expected to run if:
  ///   1. [Target.enabledBranches] exists and matches [branch].
  ///   2. Otherwise, [config.enabledBranches] matches [branch].
  List<Target> _filterEnabledTargets(Iterable<Target> targets) {
    final filteredTargets = <Target>[];

    final ghMqBranch = tryParseGitHubMergeQueueBranch(branch);
    final realBranch =
        ghMqBranch == notGitHubMergeQueueBranch ? branch : ghMqBranch.branch;

    // 1. Add targets with local definition
    final overrideBranchTargets = targets.where(
      (Target target) => target.enabledBranches.isNotEmpty,
    );
    final enabledTargets = overrideBranchTargets.where(
      (Target target) => enabledBranchesMatchesCurrentBranch(
        target.enabledBranches,
        realBranch,
      ),
    );
    filteredTargets.addAll(enabledTargets);

    // 2. Add targets with global definition (this is the majority of targets)
    if (enabledBranchesMatchesCurrentBranch(
      config.enabledBranches,
      realBranch,
    )) {
      final defaultBranchTargets = targets.where(
        (Target target) => target.enabledBranches.isEmpty,
      );
      filteredTargets.addAll(defaultBranchTargets);
    }

    return filteredTargets;
  }

  /// Whether any of the possible [RegExp] in [enabledBranches] match [branch].
  static bool enabledBranchesMatchesCurrentBranch(
    Iterable<String> enabledBranches,
    String branch,
  ) {
    final regexes = <String>[];
    for (var enabledBranch in enabledBranches) {
      // Prefix with start of line and suffix with end of line
      regexes.add('^$enabledBranch\$');
    }
    final rawRegexp = regexes.join('|');
    final regexp = RegExp(rawRegexp);

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
  void _validate(
    pb.SchedulerConfig schedulerConfig,
    String branch, {
    pb.SchedulerConfig? totSchedulerConfig,
  }) {
    if (schedulerConfig.targets.isEmpty) {
      throw const FormatException(
        'Scheduler config must have at least 1 target',
      );
    }

    if (schedulerConfig.enabledBranches.isEmpty) {
      throw const FormatException(
        'Scheduler config must have at least 1 enabled branch',
      );
    }

    final targetGraph = <String, List<pb.Target>>{};
    final exceptions = <String>[];
    final totTargets = <String>{};
    if (totSchedulerConfig != null) {
      for (var target in totSchedulerConfig.targets) {
        totTargets.add(target.name);
      }
    }
    // Construct [targetGraph]. With a one scan approach, cycles in the graph
    // cannot exist as it only works forward.
    for (final target in schedulerConfig.targets) {
      if (targetGraph.containsKey(target.name)) {
        exceptions.add('ERROR: ${target.name} already exists in graph');
      } else {
        // a new build without "bringup: true"
        // link to wiki - https://github.com/flutter/flutter/blob/master/docs/infra/Reducing-Test-Flakiness.md#adding-a-new-devicelab-test
        if (totTargets.isNotEmpty &&
            !totTargets.contains(target.name) &&
            target.bringup != true) {
          exceptions.add(
            'ERROR: ${target.name} is a new builder added. it needs to be marked bringup: true\nIf ci.yaml wasn\'t changed, try `git fetch upstream && git merge upstream/master`',
          );
          continue;
        }
        targetGraph[target.name] = <pb.Target>[];

        // To add or change validations that are specific to a repository, such as flutter/flutter,
        // see https://github.com/flutter/flutter/blob/master/dev/bots/test/ci_yaml_validation_test.dart.
      }

      /// Check the dependencies for the current target if it is viable and to
      /// be added to graph. Temporarily this is only being done on non-release
      /// branches.
      if (branch == Config.defaultBranch(slug)) {
        final dependencyJson = target.properties['dependencies'];
        if (dependencyJson != null) {
          DependencyValidator.hasVersion(dependencyJsonString: dependencyJson);
        }
      }
    }

    if (exceptions.isNotEmpty) {
      final fullException = exceptions.reduce(
        (String exception, _) => '$exception\n',
      );
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
    final exceptions = <String>[];

    /// Decoded will contain a list of maps for the dependencies found.
    final decoded = json.decode(dependencyJsonString) as List<dynamic>;

    for (final depMap in decoded.cast<Map<String, dynamic>>()) {
      if (!depMap.containsKey('version')) {
        exceptions.add(
          'ERROR: dependency ${depMap['dependency']} must have a version.',
        );
      } else {
        final version = depMap['version'] as String;
        if (version.isEmpty || version == 'latest') {
          exceptions.add(
            'ERROR: dependency ${depMap['dependency']} must have a non empty, non "latest" version supplied.',
          );
        }
      }
    }

    if (exceptions.isNotEmpty) {
      final fullException = exceptions.reduce(
        (String exception, _) => '$exception\n',
      );
      throw FormatException(fullException);
    }
  }
}

final class BranchNotEnabledForThisCiYamlException implements Exception {
  BranchNotEnabledForThisCiYamlException({required this.branch});

  final String branch;

  @override
  String toString() {
    return '$branch is not enabled for this .ci.yaml.\nAdd it to run tests against this PR.';
  }
}
