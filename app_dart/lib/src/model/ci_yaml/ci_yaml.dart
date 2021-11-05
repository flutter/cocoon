// Copyright 2021 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:github/github.dart';

import '../proto/internal/scheduler.pb.dart' as pb;
import 'target.dart';

/// This is a wrapper class around S[pb.SchedulerConfig].
///
/// See //CI_YAML.md for high level documentation.
class CiYaml {
  CiYaml({
    required this.config,
    required this.slug,
    required this.branch,
  });

  /// The underlying protobuf that contains the raw data from .ci.yaml.
  final pb.SchedulerConfig config;

  /// The [RepositorySlug] that [config] is from.
  final RepositorySlug slug;

  /// The git branch currently being scheduled against.
  final String branch;

  /// Gets all [Target] that run on presubmit for this config.
  List<Target> get presubmitTargets {
    if (!config.enabledBranches.contains(branch)) {
      throw Exception('$branch is not enabled for this .ci.yaml.\nAdd it to run tests against this PR.');
    }
    final Iterable<Target> presubmitTargets =
        _targets.where((Target target) => target.value.presubmit && !target.value.bringup);

    return _filterEnabledTargets(presubmitTargets);
  }

  /// Gets all [Target] that run on postsubmit for this config.
  List<Target> get postsubmitTargets {
    final Iterable<Target> postsubmitTargets = _targets.where((Target target) => target.value.postsubmit);

    return _filterEnabledTargets(postsubmitTargets);
  }

  /// Filters [targets] to those that should be started immediately.
  ///
  /// Targets with a dependency are triggered when there dependency pushes a notification that it has finished.
  /// This shouldn't be confused for targets that have the property named dependency, which is used by the
  /// flutter_deps recipe module on LUCI.
  List<Target> getInitialTargets(List<Target> targets) {
    return targets.where((Target target) => target.value.dependencies.isEmpty).toList();
  }

  Iterable<Target> get _targets => config.targets.map((pb.Target target) => Target(
        schedulerConfig: config,
        value: target,
        slug: slug,
      ));

  /// Filter [targets] to only those that are expected to run for [branch].
  ///
  /// A [Target] is expected to run if:
  ///   1. [Target.enabledBranches] exists and contains [branch].
  ///   2. Otherwise, [config.enabledBranches] contains [branch].
  List<Target> _filterEnabledTargets(Iterable<Target> targets) {
    final List<Target> filteredTargets = <Target>[];

    // 1. Add targets with local definition
    final Iterable<Target> overrideBranchTargets =
        targets.where((Target target) => target.value.enabledBranches.isNotEmpty);
    final Iterable<Target> enabledTargets =
        overrideBranchTargets.where((Target target) => target.value.enabledBranches.contains(branch));
    filteredTargets.addAll(enabledTargets);

    // 2. Add targets with global definition (this is the majority of targets)
    if (config.enabledBranches.contains(branch)) {
      final Iterable<Target> defaultBranchTargets =
          targets.where((Target target) => target.value.enabledBranches.isEmpty);
      filteredTargets.addAll(defaultBranchTargets);
    }

    return filteredTargets;
  }
}
