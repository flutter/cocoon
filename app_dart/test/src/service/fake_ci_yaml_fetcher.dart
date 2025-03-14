// Copyright 2021 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_service/protos.dart' as pb;
import 'package:cocoon_service/src/model/ci_yaml/ci_yaml.dart';
import 'package:cocoon_service/src/service/config.dart';
import 'package:cocoon_service/src/service/scheduler/ci_yaml_fetcher.dart';
import 'package:github/src/common/model/repos.dart';
import 'package:yaml/yaml.dart';

final class FakeCiYamlFetcher extends CiYamlFetcher {
  FakeCiYamlFetcher({this.ciYaml, this.failCiYamlValidation = false})
    : super.forTesting();

  /// The value that should be returned as a canned response for [getCiYaml].
  ///
  /// If omitted (`null`) defaults to a configuration with a single target.
  CiYamlSet? ciYaml;

  /// Sets [ciYaml] by loading a YAML document.
  ///
  /// Optionally may also specify [engine] for a fusion [CiYamlSet].
  void setCiYamlFrom(String root, {String? engine}) {
    ciYaml = CiYamlSet(
      slug: Config.flutterSlug,
      branch: 'will-be-replaced',
      yamls: {
        CiType.any: pb.SchedulerConfig()..mergeFromProto3Json(loadYaml(root)),
        if (engine != null)
          CiType.fusionEngine:
              pb.SchedulerConfig()..mergeFromProto3Json(loadYaml(engine)),
      },
      isFusion: engine != null,
    );
  }

  /// If `true`, [getCiYaml] will throw a [FormatException].
  ///
  /// This simulates failing validation.
  bool failCiYamlValidation;

  @override
  Future<CiYamlSet> getCiYaml({
    required RepositorySlug slug,
    required String commitSha,
    required String commitBranch,
    bool validate = false,
  }) async {
    if (validate && failCiYamlValidation) {
      throw const FormatException('Failed validation!');
    }
    final ci = ciYaml ?? _createDefault(slug: slug, commitBranch: commitBranch);
    return CiYamlSet(
      slug: slug,
      branch: commitBranch,
      yamls: ci.configs.map((k, v) => MapEntry(k, v.config)),
      isFusion: ci.isFusion,
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
      },
    );
  }
}
