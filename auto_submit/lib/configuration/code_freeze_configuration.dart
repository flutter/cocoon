// Copyright 2026 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:github/github.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:meta/meta.dart';
import 'package:yaml/yaml.dart';

part 'code_freeze_configuration.g.dart';

/// Configuration for repository-specific code freezes.
@JsonSerializable(explicitToJson: true)
@immutable
final class CodeFreezeConfiguration {
  const CodeFreezeConfiguration([this.repoFreezeCriteria = const <String, FreezeCriteria>{}]);

  /// A mapping of repository slugs to their freeze criteria.
  @JsonKey(name: 'repoFreezeCriteria')
  final Map<String, FreezeCriteria> repoFreezeCriteria;

  /// Parses the configuration from a YAML string.
  factory CodeFreezeConfiguration.fromYaml(String yaml) {
    final yamlDoc = loadYaml(yaml) as YamlMap;
    final map = <String, dynamic>{
      'repoFreezeCriteria': yamlDoc.asMap,
    };
    return CodeFreezeConfiguration.fromJson(map);
  }

  /// Creates [CodeFreezeConfiguration] from a [json] object.
  factory CodeFreezeConfiguration.fromJson(Map<String, dynamic> json) => _$CodeFreezeConfigurationFromJson(json);

  /// Converts [CodeFreezeConfiguration] to a [json] object.
  Map<String, dynamic> toJson() => _$CodeFreezeConfigurationToJson(this);

  /// Returns the freeze criteria for the given [slug].
  FreezeCriteria getFreezeCriteria(RepositorySlug slug) {
    return repoFreezeCriteria[slug.fullName] ?? const FreezeCriteria();
  }
}

/// Criteria used to determine if a PR is affected by a code freeze.
@JsonSerializable()
@immutable
final class FreezeCriteria {
  const FreezeCriteria({
    this.frozenLabels = const <String>{},
    this.frozenPaths = const <String>{},
  });

  final Set<String> frozenLabels;
  final Set<String> frozenPaths;

  /// Creates [FreezeCriteria] from a [json] object.
  factory FreezeCriteria.fromJson(Map<String, dynamic> json) => _$FreezeCriteriaFromJson(json);

  /// Converts [FreezeCriteria] to a [json] object.
  Map<String, dynamic> toJson() => _$FreezeCriteriaToJson(this);

  bool get isEmpty => frozenLabels.isEmpty && frozenPaths.isEmpty;
}

extension _YamlMapToMap on YamlMap {
  Map<String, dynamic> get asMap => <String, dynamic>{
    for (final MapEntry(:key, :value) in entries)
      if (value is YamlMap)
        '$key': value.asMap
      else if (value is YamlList)
        '$key': value.asList
      else if (value is YamlScalar)
        '$key': value.value
      else
        '$key': value,
  };
}

extension _YamlListToList on YamlList {
  List<dynamic> get asList => <dynamic>[
    for (final node in nodes)
      if (node is YamlMap)
        node.asMap
      else if (node is YamlList)
        node.asList
      else if (node is YamlScalar)
        node.value
      else
        node,
  ];
}
