// Copyright 2021 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_common/cocoon_common.dart';
import 'package:cocoon_common_test/cocoon_common_test.dart';
import 'package:cocoon_server/logging.dart';
import 'package:cocoon_server_test/test_logging.dart';
import 'package:cocoon_service/protos.dart' as pb;
import 'package:cocoon_service/src/model/ci_yaml/ci_yaml.dart';
import 'package:cocoon_service/src/service/config.dart';
import 'package:cocoon_service/src/service/get_files_changed.dart';
import 'package:cocoon_service/src/service/scheduler/ci_yaml_fetcher.dart';
import 'package:cocoon_service/src/service/scheduler/files_changed_optimization.dart';
import 'package:github/github.dart';
import 'package:test/test.dart';

import '../../src/fake_config.dart';
import '../../src/service/fake_ci_yaml_fetcher.dart';
import '../../src/service/fake_get_files_changed.dart';
import '../../src/utilities/entity_generators.dart';

void main() {
  useTestLoggerPerTest();

  GetFilesChanged filesChanged(Iterable<String> files) {
    return FakeGetFilesChanged(cannedFiles: [...files]);
  }

  CiYamlFetcher ciYamlFetcher({required RepositorySlug slug, String? branch}) {
    branch ??= Config.defaultBranch(slug);
    return FakeCiYamlFetcher(
      ciYaml: CiYamlSet(
        slug: slug,
        branch: branch,
        yamls: {
          CiType.any: pb.SchedulerConfig(enabledBranches: [branch]),
          if (slug == Config.flutterSlug)
            CiType.fusionEngine: pb.SchedulerConfig(enabledBranches: [branch]),
        },
      ),
    );
  }

  Config config({required int maxFilesChangedForSkippingEnginePhase}) {
    return FakeConfig(
      maxFilesChangedForSkippingEnginePhaseValue:
          maxFilesChangedForSkippingEnginePhase,
    );
  }

  test('skips non-flutter/flutter (fusion) repos', () async {
    final optimizer = FilesChangedOptimizer(
      getFilesChanged: filesChanged([]),
      ciYamlFetcher: ciYamlFetcher(slug: Config.packagesSlug),
      config: config(maxFilesChangedForSkippingEnginePhase: 100),
    );

    await expectLater(
      optimizer.checkPullRequest(generatePullRequest(repo: 'packages')),
      completion(FilesChangedOptimization.none),
    );

    expect(
      log,
      bufferedLoggerOf(
        contains(logThat(message: contains('is not flutter/flutter'))),
      ),
    );
  });

  test('skips PRs that change too many files', () async {
    final optimizer = FilesChangedOptimizer(
      getFilesChanged: filesChanged([
        // Doesn't matter, the PR itself has >100 files in changedFiles.
      ]),
      ciYamlFetcher: ciYamlFetcher(slug: Config.flutterSlug),
      config: config(maxFilesChangedForSkippingEnginePhase: 100),
    );

    await expectLater(
      optimizer.checkPullRequest(
        generatePullRequest(repo: 'flutter', changedFilesCount: 101),
      ),
      completion(FilesChangedOptimization.none),
    );

    expect(
      log,
      bufferedLoggerOf(contains(logThat(message: contains('has 101 files')))),
    );
  });

  test('skips PRs where getFilesChanged errors', () async {
    final optimizer = FilesChangedOptimizer(
      // TODO(matanlurey): Would be better to make this explicit with a named
      // constructor, i.e. FakeGetFilesChanged.alwaysInconclusive().
      getFilesChanged: FakeGetFilesChanged(),
      ciYamlFetcher: ciYamlFetcher(slug: Config.flutterSlug),
      config: config(maxFilesChangedForSkippingEnginePhase: 100),
    );

    await expectLater(
      optimizer.checkPullRequest(
        generatePullRequest(repo: 'flutter', changedFilesCount: 1, number: 123),
      ),
      completion(FilesChangedOptimization.none),
    );

    expect(
      log,
      bufferedLoggerOf(
        contains(
          logThat(
            severity: equals(Severity.warning),
            message: contains('Not optimizing: flutter/flutter/pulls/123'),
          ),
        ),
      ),
    );
  });

  test('only CHANGELOG.md', () async {
    final optimizer = FilesChangedOptimizer(
      getFilesChanged: filesChanged(['CHANGELOG.md']),
      ciYamlFetcher: ciYamlFetcher(slug: Config.flutterSlug),
      config: config(maxFilesChangedForSkippingEnginePhase: 100),
    );

    await expectLater(
      optimizer.checkPullRequest(
        generatePullRequest(repo: 'flutter', changedFilesCount: 1, number: 123),
      ),
      completion(FilesChangedOptimization.skipPresubmitAllExceptFlutterAnalyze),
    );
  });

  test('only non-engine files', () async {
    final optimizer = FilesChangedOptimizer(
      getFilesChanged: filesChanged(['packages/flutter/lib/flutter.dart']),
      ciYamlFetcher: ciYamlFetcher(slug: Config.flutterSlug),
      config: config(maxFilesChangedForSkippingEnginePhase: 100),
    );

    await expectLater(
      optimizer.checkPullRequest(
        generatePullRequest(repo: 'flutter', changedFilesCount: 1, number: 123),
      ),
      completion(FilesChangedOptimization.skipPresubmitEngine),
    );
  });

  test('DEPS is considered an engine file', () async {
    final optimizer = FilesChangedOptimizer(
      getFilesChanged: filesChanged(['DEPS']),
      ciYamlFetcher: ciYamlFetcher(slug: Config.flutterSlug),
      config: config(maxFilesChangedForSkippingEnginePhase: 100),
    );

    await expectLater(
      optimizer.checkPullRequest(
        generatePullRequest(repo: 'flutter', changedFilesCount: 1, number: 123),
      ),
      completion(FilesChangedOptimization.none),
    );

    expect(
      log,
      bufferedLoggerOf(
        contains(logThat(message: contains('Engine sources changed'))),
      ),
    );
  });

  test('engine/** is considered an engine file', () async {
    final optimizer = FilesChangedOptimizer(
      getFilesChanged: filesChanged(['engine/src/flutter/flutter.c']),
      ciYamlFetcher: ciYamlFetcher(slug: Config.flutterSlug),
      config: config(maxFilesChangedForSkippingEnginePhase: 100),
    );

    await expectLater(
      optimizer.checkPullRequest(
        generatePullRequest(repo: 'flutter', changedFilesCount: 1, number: 123),
      ),
      completion(FilesChangedOptimization.none),
    );

    expect(
      log,
      bufferedLoggerOf(
        contains(logThat(message: contains('Engine sources changed'))),
      ),
    );
  });
}
