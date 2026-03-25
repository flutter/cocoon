// Copyright 2026 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:github/github.dart' as github;

import '../model/auto_submit_query_result.dart';
import 'validation.dart';

/// Validates that a pull request is not affected by an active code freeze.
class CodeFreeze extends Validation {
  CodeFreeze({required super.config});

  @override
  Future<ValidationResult> validate(
    QueryResult result,
    github.PullRequest pr,
  ) async {
    final slug = pr.base!.repo!.slug();
    final criteria = config.codeFreezeConfiguration.getFreezeCriteria(slug);

    if (criteria.isEmpty) {
      return ValidationResult(true, Action.IGNORE_FAILURE, '');
    }

    // Check labels first as it is cheaper.
    final prLabels =
        pr.labels?.map((label) => label.name).toSet() ?? <String>{};
    final matchedLabels = criteria.frozenLabels.intersection(prLabels);
    if (matchedLabels.isNotEmpty) {
      final message =
          'This pull request is blocked due to an active code freeze for the following labels: ${matchedLabels.join(", ")}.';
      return ValidationResult(false, Action.REMOVE_LABEL, message);
    }

    // Check paths if frozen paths are defined.
    if (criteria.frozenPaths.isNotEmpty) {
      final githubService = await config.createGithubService(slug);
      final files = await githubService.getPullRequestFiles(slug, pr);
      final matchedPaths = <String>{};

      for (final file in files) {
        final filename = file.filename;
        if (filename == null) continue;
        for (final frozenPath in criteria.frozenPaths) {
          if (filename.startsWith(frozenPath)) {
            matchedPaths.add(frozenPath);
          }
        }
      }

      if (matchedPaths.isNotEmpty) {
        final message =
            'This pull request is blocked due to an active code freeze for the following paths: ${matchedPaths.join(", ")}.';
        return ValidationResult(false, Action.REMOVE_LABEL, message);
      }
    }

    return ValidationResult(true, Action.IGNORE_FAILURE, '');
  }

  @override
  String get name => 'CodeFreeze';
}
