// Copyright 2021 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_server/logging.dart';
import 'package:github/github.dart';

import '../config.dart';
import '../get_files_changed.dart';
import 'ci_yaml_fetcher.dart';

/// Using [GetFilesChanged], determines if build optimizations can be applied.
final class FilesChangedOptimizer {
  const FilesChangedOptimizer({
    required GetFilesChanged getFilesChanged,
    required CiYamlFetcher ciYamlFetcher,
    required Config config,
  }) : _getFilesChanged = getFilesChanged,
       _ciYamlFetcher = ciYamlFetcher,
       _config = config;

  final GetFilesChanged _getFilesChanged;

  // TODO(matanlurey): Use or remove this.
  //
  // It would be nice not to bake this optimization too deep into the code
  // and instead make it a configurable part of `.ci.yaml`, that is something
  // like:
  // ```yaml
  // optimizations:
  //   skip-engine-if-not-changed:
  //     - DEPS
  //     - engine/**
  //   skip-all-if-only-changed:
  //     - CHANGELOG.md
  // ```
  final CiYamlFetcher _ciYamlFetcher;

  final Config _config;

  /// Returns an optimization type possible given the pull request.
  Future<FilesChangedOptimization> checkPullRequest(PullRequest pr) async {
    final slug = pr.base!.repo!.slug();
    final commitSha = pr.head!.sha!;
    final commitBranch = pr.base!.ref!;

    final ciYaml = await _ciYamlFetcher.getCiYaml(
      slug: slug,
      commitSha: commitSha,
      commitBranch: commitBranch,
    );

    final refusePrefix = 'Not optimizing: ${slug.fullName}/pulls/${pr.number}';
    if (!ciYaml.isFusion) {
      log.debug('$refusePrefix is not flutter/flutter');
      return FilesChangedOptimization.none;
    }
    if (pr.changedFilesCount! > _config.maxFilesChangedForSkippingEnginePhase) {
      log.info('$refusePrefix has ${pr.changedFilesCount} files');
      return FilesChangedOptimization.none;
    }

    final filesChanged = await _getFilesChanged.get(slug, pr.number!);
    switch (filesChanged) {
      case InconclusiveFilesChanged(:final reason):
        log.warn('$refusePrefix: $reason');
        return FilesChangedOptimization.none;
      case SuccessfulFilesChanged(:final filesChanged):
        if (filesChanged.length == 1 && filesChanged.contains('CHANGELOG.md')) {
          return FilesChangedOptimization.skipPresubmitAll;
        }
        for (final file in filesChanged) {
          if (file == 'DEPS' || file.startsWith('engine/')) {
            log.info(
              '$refusePrefix: Engine sources changed.\n${filesChanged.join('\n')}',
            );
            return FilesChangedOptimization.none;
          }
        }
        return FilesChangedOptimization.skipPresubmitEngine;
    }
  }
}

/// Given a [FilesChanged], a determined safe optimization that can be made.
enum FilesChangedOptimization {
  /// No optimization is possible or desired.
  none,

  /// Engine builds (and tests) can be skipped for this presubmit run.
  skipPresubmitEngine,

  /// All builds (and tests) can be skipped for this presubmit run.
  skipPresubmitAll,
}
