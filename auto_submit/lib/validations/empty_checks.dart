// Copyright 2022 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:github/github.dart' as github;

import '../model/auto_submit_query_result.dart';
import 'validation.dart';

/// Validates that the list of checks for the PR is not empty.
class EmptyChecks extends Validation {
  EmptyChecks({
    required super.config,
  });

  @override
  String get name => 'EmptyChecks';

  @override

  /// Implements the validation to verify the list of checks is not empty.
  Future<ValidationResult> validate(
      QueryResult result, github.PullRequest messagePullRequest) async {
    final slug = messagePullRequest.base!.repo!.slug();
    final gitHubService = await config.createGithubService(slug);
    final pullRequest = result.repository!.pullRequest!;
    final commit = pullRequest.commits!.nodes!.single.commit!;
    final sha = commit.oid;
    final checkRuns = await gitHubService.getCheckRuns(slug, sha!);
    const message =
        '- This commit has no checks. Please check that ci.yaml validation has started'
        ' and there are multiple checks. If not, try uploading an empty commit.';
    return ValidationResult(checkRuns.isNotEmpty, Action.REMOVE_LABEL, message);
  }
}
