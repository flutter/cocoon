// Copyright 2026 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_server/logging.dart';
import 'package:github/github.dart';

import '../../cocoon_service.dart';
import '../request_handling/exceptions.dart';

/// Ensures that [pullRequest] is the pull request that [guard] was created for.
///
/// Re-run handlers authorize a re-run using the [guard] for the requested
/// [prNumber] (it must contain a failed job), but schedule the build using
/// the [pullRequest] stored in [PrCheckRuns]. Those must refer to the same
/// pull request and commit, otherwise a re-run could build code from a
/// different pull request than the one whose results authorized it.
///
/// Throws [BadRequestException] on any mismatch.
void ensurePullRequestMatchesGuard({
  required RepositorySlug slug,
  required int prNumber,
  required PresubmitGuard guard,
  required PullRequest pullRequest,
}) {
  final prSlug = pullRequest.base?.repo?.slug();
  final prHeadSha = pullRequest.head?.sha;
  final mismatches = [
    if (guard.slug != slug) 'guard slug ${guard.slug} != requested $slug',
    if (guard.prNum != prNumber)
      'guard PR ${guard.prNum} != requested $prNumber',
    if (prSlug != slug) 'stored PR slug $prSlug != requested $slug',
    if (pullRequest.number != prNumber)
      'stored PR ${pullRequest.number} != requested $prNumber',
    if (prHeadSha != guard.commitSha)
      'stored PR head $prHeadSha != guard head ${guard.commitSha}',
  ];
  if (mismatches.isNotEmpty) {
    log.warn(
      'Refusing re-run for $slug/$prNumber (guard ${guard.checkRunId}): '
      '${mismatches.join('; ')}',
    );
    throw BadRequestException(
      'Stored pull request does not match the presubmit guard for '
      '$slug/$prNumber',
    );
  }
}
