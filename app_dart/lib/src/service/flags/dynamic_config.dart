// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// @docImport '../config.dart';
/// @docImport 'dynamic_config_updater.dart';
library;

import 'dart:io' as io;

import 'package:json_annotation/json_annotation.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

import 'ci_yaml_flags.dart';
import 'consolidated_check_run_flow_flags.dart';
import 'content_aware_hashing_flags.dart';
import 'dynamic_config_updater.dart';

part 'dynamic_config.g.dart';

/// Flags for the service that can be updated dynamically with out a restart.
///
/// Normally, this object is from [Config.flags], and is updated in the
/// background automatically by [DynamicConfigUpdater], where the latest copy
/// of `//app_dart/config.yaml` is fetched periodically.
///
/// To get a one-time copy of the file, see also:
///
/// - [DynamicConfig.fromRemoteLatest]
/// - [DynamicConfig.fromLocalFileSystem]
@JsonSerializable(explicitToJson: true)
@immutable
final class DynamicConfig {
  /// Default configuration for flags.
  static const defaultInstance = DynamicConfig._(
    backfillerCommitLimit: 50,
    ciYaml: CiYamlFlags.defaultInstance,
    contentAwareHashing: ContentAwareHashing.defaultInstance,
    closeMqGuardAfterPresubmit: false,
    consolidatedCheckRunFlow: ConsolidatedCheckRunFlow.defaultInstance,
    dynamicTestSuppression: false,
  );

  /// Upper limit of commit rows to be backfilled in API call.
  ///
  /// This limits the number of commits to be checked to backfill. When bots
  /// are idle, we hope to scan as many commit rows as possible.
  @JsonKey()
  final int backfillerCommitLimit;

  /// Flags associated with content-aware hashing.
  @JsonKey()
  final ContentAwareHashing contentAwareHashing;

  /// Flags related to resolving `.ci.yaml`.
  @JsonKey()
  final CiYamlFlags ciYaml;

  /// Whether to close the MQ guard right after LUCI presubmit compleated
  /// instead of doing that as part of the `check_run` GitHub event handling.
  @JsonKey()
  final bool closeMqGuardAfterPresubmit;

  /// Flags related tp consolidated check-run flow configuration.
  @JsonKey()
  final ConsolidatedCheckRunFlow consolidatedCheckRunFlow;

  /// Whether to allow the tree status to be suppressed for specific failed tests.
  @JsonKey()
  final bool dynamicTestSuppression;

  const DynamicConfig._({
    required this.backfillerCommitLimit,
    required this.ciYaml,
    required this.contentAwareHashing,
    required this.closeMqGuardAfterPresubmit,
    required this.consolidatedCheckRunFlow,
    required this.dynamicTestSuppression,
  });

  /// Creates [DynamicConfig] flags from a [json] object.
  ///
  /// Any omitted fields default to the values in [defaultInstance].
  factory DynamicConfig({
    int? backfillerCommitLimit,
    CiYamlFlags? ciYaml,
    ContentAwareHashing? contentAwareHashing,
    bool? closeMqGuardAfterPresubmit,
    ConsolidatedCheckRunFlow? consolidatedCheckRunFlow,
    bool? dynamicTestSuppression,
  }) {
    return DynamicConfig._(
      backfillerCommitLimit:
          backfillerCommitLimit ?? defaultInstance.backfillerCommitLimit,
      ciYaml: ciYaml ?? defaultInstance.ciYaml,
      contentAwareHashing:
          contentAwareHashing ?? defaultInstance.contentAwareHashing,
      closeMqGuardAfterPresubmit:
          closeMqGuardAfterPresubmit ??
          defaultInstance.closeMqGuardAfterPresubmit,
      consolidatedCheckRunFlow:
          consolidatedCheckRunFlow ?? defaultInstance.consolidatedCheckRunFlow,
      dynamicTestSuppression:
          dynamicTestSuppression ?? defaultInstance.dynamicTestSuppression,
    );
  }

  /// Creates [DynamicConfig] flags from a [json] object.
  ///
  /// Any omitted fields default to the values in [defaultInstance].
  factory DynamicConfig.fromJson(Map<String, Object?>? json) {
    return _$DynamicConfigFromJson(json ?? {});
  }

  /// Creates [DynamicConfig] flags from a [yaml] object.
  factory DynamicConfig.fromYaml(YamlMap? yaml) {
    return DynamicConfig.fromJson(yaml?.asMap);
  }

  /// Returns the latest copy of [DynamicConfig] fetched from tip-of-tree.
  ///
  /// Equivalent to a single call to [DynamicConfigUpdater.fetchDynamicConfig].
  static Future<DynamicConfig> fromRemoteLatest() {
    return DynamicConfigUpdater().fetchDynamicConfig();
  }

  /// Returns the latest copy of [DynamicConfig] fetched from the repository.
  static Future<DynamicConfig> fromLocalFileSystem() async {
    final execPath = io.Platform.resolvedExecutable;

    // Walk backwards until the root of the Cocoon repository is found.
    var dir = io.File(execPath).parent;
    while (dir.path != dir.parent.path) {
      final gitDir = io.Directory(p.join(dir.path, '.git'));
      if (await gitDir.exists()) {
        break;
      }
      dir = dir.parent;
    }

    final configPath = io.File(p.join(dir.path, 'app_dart', 'config.yaml'));
    if (!await configPath.exists()) {
      throw StateError('Could not find config.yaml at ${configPath.path}');
    }

    final yaml = loadYaml(await configPath.readAsString()) as YamlMap;
    return DynamicConfig.fromYaml(yaml);
  }

  /// The inverse operation of [DynamicConfig.fromJson].
  Map<String, Object?> toJson() => _$DynamicConfigToJson(this);
}

extension _YamlMapToMap on YamlMap {
  Map<String, Object?> get asMap => <String, Object?>{
    for (final MapEntry(:key, :value) in entries)
      if (value is YamlMap)
        '$key': value.asMap
      else if (value is YamlList)
        '$key': value.asList
      else
        '$key': value,
  };
}

extension _YamlListToList on YamlList {
  List<Object?> get asList => <Object?>[
    for (final value in nodes)
      if (value is YamlMap)
        value.asMap
      else if (value is YamlList)
        value.asList
      else
        value,
  ];
}
