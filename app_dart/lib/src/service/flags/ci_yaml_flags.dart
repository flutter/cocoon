// Copyright 2025 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:json_annotation/json_annotation.dart';
import 'package:meta/meta.dart';

part 'ci_yaml_flags.g.dart';

/// Flags related to resolving `.ci.yaml`.
@JsonSerializable()
@immutable
final class CiYamlFlags {
  /// Default configuration for [CiYamlFlags] flags.
  static const defaultInstance = CiYamlFlags._(
    onlyUseTipOfTreeTargetsExistenceToFilterTargets: false,
  );

  /// Whether to _only_ use the existence of a target at tip-of-tree to filter
  /// out targets on other branches.
  ///
  /// By setting this flag to `true`, a tip-of-tree (default) branch's enabled
  /// branches cannot impact how a different branch's targets are enabled (or
  /// not), only the _existence_ of a tip-of-tree target is considered.
  ///
  /// ## Details
  ///
  /// As discovered in https://github.com/flutter/flutter/issues/169370, the
  /// default (or `master`/`main`) branch of a repository was required to have
  /// knowledge about all other possible branches, and if a new branch was
  /// created (but not defined in `enabledBranches: [ ...]`), the targets would
  /// automatically be filtered out.
  ///
  /// Consider the following tip-of-tree definition of a `.ci.yaml`:
  /// ```yaml
  /// # flutter/flutter/master
  /// # //engine/src/flutter/.ci.yaml
  /// enabled_branches:
  ///   - master
  ///   - flutter-\d+\.\d+-candidate\.\d+
  ///
  /// targets:
  ///   - name: Mac host_engine
  ///     properties:
  ///       release_build: "true"
  ///   - name: Mac host_engine_test
  /// ```
  ///
  /// And the same file, tweaked for execution in branch `ios-experimental`:
  /// ```yaml
  /// # flutter/flutter/ios-experimental
  /// # //engine/src/flutter/.ci.yaml
  /// enabled_branches:
  ///   - ios-experimental
  ///
  /// targets:
  ///   - name: Mac host_engine
  ///     properties:
  ///       release_build: "true"
  ///   - name: Mac host_engine_test
  /// ```
  ///
  /// If this flag is `false`, `Mac host_engine` does _not_ run on the
  /// `ios-experimental` branch's postsubmit, because it is configured to not
  /// run on `master`'s postsubmit (it is a `release_build`).
  ///
  /// This is confusing behavior, where experimental branches would need to
  /// modify the tip-of-tree `.ci.yaml` in order to allow targets to be executed
  /// on their branch, so this flag exists to change that behavior.
  @JsonKey()
  final bool onlyUseTipOfTreeTargetsExistenceToFilterTargets;

  const CiYamlFlags._({
    required this.onlyUseTipOfTreeTargetsExistenceToFilterTargets, //
  });

  /// Creates [CiYamlFlags] flags from the provided fields.
  ///
  /// Any omitted fields default to the values in [defaultInstance].
  factory CiYamlFlags({bool? onlyUseTipOfTreeTargetsExistenceToFilterTargets}) {
    return CiYamlFlags._(
      onlyUseTipOfTreeTargetsExistenceToFilterTargets:
          onlyUseTipOfTreeTargetsExistenceToFilterTargets ??
          defaultInstance.onlyUseTipOfTreeTargetsExistenceToFilterTargets,
    );
  }

  /// Creates [ContentAwareHashing] flags from a [json] object.
  ///
  /// Any omitted fields default to the values in [defaultInstance].
  factory CiYamlFlags.fromJson(Map<String, Object?>? json) {
    return _$CiYamlFlagsFromJson(json ?? {});
  }

  /// The inverse operation of [CiYamlFlags.fromJson].
  Map<String, Object?> toJson() => _$CiYamlFlagsToJson(this);
}
