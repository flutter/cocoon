// Copyright 2021 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_server/logging.dart';
import 'package:github/github.dart';
import 'package:path/path.dart' as p;

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
  //   skip-framework-if-only-changed:
  //     - **/*.md
  // ```
  final CiYamlFetcher _ciYamlFetcher;

  // See https://github.com/flutter/flutter/issues/162403.
  static const _doNotSkipFrameworkTestsForBranch = {'flutter-3.29-candidate.0'};

  final Config _config;

  /// Returns an optimization type possible given the pull request.
  Future<FilesChangedOptimization> checkPullRequest(PullRequest pr) async {
    final slug = pr.base!.repo!.slug();
    final commitSha = pr.head!.sha!;
    final commitBranch = pr.base!.ref!;

    if (_doNotSkipFrameworkTestsForBranch.contains(commitBranch)) {
      log.info('$commitBranch does not support the framework-only optimizer');
      return FilesChangedOptimization.none;
    }

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
        var markdownOnly = true;
        for (final file in filesChanged) {
          if (file == 'DEPS' || file.startsWith('engine/')) {
            log.info(
              '$refusePrefix: Engine sources changed.\n${filesChanged.join('\n')}',
            );
            return FilesChangedOptimization.none;
          }
          if (markdownOnly && p.posix.extension(file) != '.md') {
            markdownOnly = false;
          }
        }
        if (!markdownOnly) {
          return FilesChangedOptimization.skipPresubmitEngine;
        } else {
          return FilesChangedOptimization.skipPresubmitAllExceptFlutterAnalyze;
        }
    }
  }
}

/// Given a [FilesChanged], a determined safe optimization that can be made.
enum FilesChangedOptimization {
  /// No optimization is possible or desired.
  none,

  /// Engine builds (and tests) can be skipped for this presubmit run.
  skipPresubmitEngine,

  /// Almost all builds (and tests) can be skipped for this presubmit run.
  skipPresubmitAllExceptFlutterAnalyze;

  /// Whether the engine should be prebuilt.
  bool get shouldUsePrebuiltEngine => !shouldBuildEngineFromSource;

  /// Whether the engine must be built from source.
  bool get shouldBuildEngineFromSource => this == none;
}
