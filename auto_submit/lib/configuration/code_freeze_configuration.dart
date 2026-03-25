// Copyright 2026 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:github/github.dart';
import 'package:yaml/yaml.dart';

/// Configuration for repository-specific code freezes.
class CodeFreezeConfiguration {
  CodeFreezeConfiguration(this.repoFreezeCriteria);

  /// A mapping of repository slugs to their freeze criteria.
  final Map<String, FreezeCriteria> repoFreezeCriteria;

  /// Parses the configuration from a YAML string.
  factory CodeFreezeConfiguration.fromYaml(String yaml) {
    final dynamic yamlDoc = loadYaml(yaml);
    final repoFreezeCriteria = <String, FreezeCriteria>{};

    if (yamlDoc is YamlMap) {
      for (final entry in yamlDoc.entries) {
        final repoName = entry.key as String;
        final repoConfig = entry.value as YamlMap?;
        if (repoConfig != null) {
          final frozenLabels = <String>{};
          final yamlLabels = repoConfig['frozen_labels'] as YamlList?;
          if (yamlLabels != null) {
            frozenLabels.addAll(yamlLabels.map((label) => label as String));
          }

          final frozenPaths = <String>{};
          final yamlPaths = repoConfig['frozen_paths'] as YamlList?;
          if (yamlPaths != null) {
            frozenPaths.addAll(yamlPaths.map((path) => path as String));
          }

          repoFreezeCriteria[repoName] = FreezeCriteria(
            frozenLabels: frozenLabels,
            frozenPaths: frozenPaths,
          );
        }
      }
    }

    return CodeFreezeConfiguration(repoFreezeCriteria);
  }

  /// Returns the freeze criteria for the given [slug].
  FreezeCriteria getFreezeCriteria(RepositorySlug slug) {
    return repoFreezeCriteria[slug.fullName] ?? const FreezeCriteria();
  }
}

/// Criteria used to determine if a PR is affected by a code freeze.
class FreezeCriteria {
  const FreezeCriteria({
    this.frozenLabels = const <String>{},
    this.frozenPaths = const <String>{},
  });

  final Set<String> frozenLabels;
  final Set<String> frozenPaths;

  bool get isEmpty => frozenLabels.isEmpty && frozenPaths.isEmpty;
}
