// Copyright 2021 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_service/protos.dart' as pb;
import 'package:cocoon_service/src/model/ci_yaml/ci_yaml.dart';
import 'package:cocoon_service/src/model/commit_ref.dart';
import 'package:cocoon_service/src/service/config.dart';
import 'package:cocoon_service/src/service/scheduler/ci_yaml_fetcher.dart';
import 'package:github/src/common/model/repos.dart';
import 'package:yaml/yaml.dart';

final class FakeCiYamlFetcher implements CiYamlFetcher {
  FakeCiYamlFetcher({
    this.ciYaml,
    this.totCiYaml,
    this.failCiYamlValidation = false,
  });

  static CiYamlSet _from(
    String root, {
    String? branch,
    String? engine,
    CiYamlSet? totCiYaml,
  }) {
    return CiYamlSet(
      slug: Config.flutterSlug,
      branch: branch ?? Config.defaultBranch(Config.flutterSlug),
      yamls: {
        CiType.any: pb.SchedulerConfig()..mergeFromProto3Json(loadYaml(root)),
        if (engine != null)
          CiType.fusionEngine:
              pb.SchedulerConfig()..mergeFromProto3Json(loadYaml(engine)),
      },
      totConfig: totCiYaml,
    );
  }

  /// The value that should be returned as a canned response for [getCiYamlByCommit].
  ///
  /// If omitted (`null`) defaults to a configuration with a single target.
  CiYamlSet? ciYaml;

  /// Sets [ciYaml] by loading a YAML document.
  ///
  /// Optionally may also specify [engine] for a fusion [CiYamlSet].
  void setCiYamlFrom(String root, {String? engine}) {
    ciYaml = _from(root, engine: engine, totCiYaml: totCiYaml);
  }

  /// The value that should be returned as a canned response for [getTipOfTreeCiYaml].
  ///
  /// If omitted (`null`), defaults to the same response as [ciYaml].
  CiYamlSet? totCiYaml;

  /// Sets [totCiYaml] by loading a YAML document.
  ///
  /// Optionally may also specify [engine] for a fusion [CiYamlSet].
  void setTotCiYamlFrom(String root, {String? engine}) {
    totCiYaml = _from(root, engine: engine);
  }

  /// If `true`, [getCiYamlByCommit] will throw a [FormatException].
  ///
  /// This simulates failing validation.
  bool failCiYamlValidation;

  @override
  Future<CiYamlSet> getCiYamlByCommit(
    CommitRef commit, {
    bool? validate,
    bool postsubmit = false,
  }) async {
    validate ??= commit.branch == Config.defaultBranch(commit.slug);
    if (validate && failCiYamlValidation) {
      throw const FormatException('Failed validation!');
    }
    final ci =
        ciYaml ??
        _createDefault(slug: commit.slug, commitBranch: commit.branch);
    return CiYamlSet(
      slug: commit.slug,
      branch: commit.branch,
      yamls: ci.configs.map((k, v) => MapEntry(k, v.config)),
      totConfig: totCiYaml,
    );
  }

  @override
  Future<CiYamlSet> getTipOfTreeCiYaml({required RepositorySlug slug}) async {
    final ci =
        totCiYaml ??
        ciYaml ??
        _createDefault(slug: slug, commitBranch: Config.defaultBranch(slug));
    return CiYamlSet(
      slug: slug,
      branch: Config.defaultBranch(slug),
      yamls: ci.configs.map((k, v) => MapEntry(k, v.config)),
    );
  }

  static CiYamlSet _createDefault({
    required RepositorySlug slug,
    required String commitBranch,
  }) {
    return CiYamlSet(
      slug: slug,
      branch: commitBranch,
      yamls: {
        CiType.any: pb.SchedulerConfig(
          enabledBranches: [commitBranch],
          targets: <pb.Target>[
            pb.Target(name: 'Linux A', scheduler: pb.SchedulerSystem.luci),
          ],
        ),
        CiType.fusionEngine: pb.SchedulerConfig(
          enabledBranches: [commitBranch],
          targets: <pb.Target>[
            pb.Target(name: 'Linux B', scheduler: pb.SchedulerSystem.luci),
          ],
        ),
      },
    );
  }
}
