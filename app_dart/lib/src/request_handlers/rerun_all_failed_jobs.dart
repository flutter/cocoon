// Copyright 2025 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:github/github.dart';
import 'package:retry/retry.dart';

import '../../cocoon_service.dart';
import '../model/ci_yaml/target.dart';
import '../request_handling/api_request_handler.dart';
import '../request_handling/exceptions.dart';
import '../service/firestore/unified_check_run.dart';

/// Re-runs all failed jobs for a unified check run.
///
/// POST: /api/rerun-all-failed-jobs
///
/// Parameters:
///   owner: (string in body) mandatory. The GitHub repository owner.
///   repo: (string in body) mandatory. The GitHub repository name.
///   pr: (int in body) mandatory. The Pull Request number.
final class RerunAllFailedJobs extends ApiRequestHandler {
  const RerunAllFailedJobs({
    required super.config,
    required super.authenticationProvider,
    required Scheduler scheduler,
    required LuciBuildService luciBuildService,
    required FirestoreService firestore,
  }) : _scheduler = scheduler,
       _luciBuildService = luciBuildService,
       _firestore = firestore;

  final Scheduler _scheduler;
  final LuciBuildService _luciBuildService;
  final FirestoreService _firestore;

  static const String kOwnerParam = 'owner';
  static const String kRepoParam = 'repo';
  static const String kPrParam = 'pr';

  @override
  Future<Response> post(Request request) async {
    final requestData = await request.readBodyAsJson();
    checkRequiredParameters(requestData, [kPrParam]);

    final owner = requestData[kOwnerParam] as String? ?? 'flutter';
    final repo = requestData[kRepoParam] as String? ?? 'flutter';
    final prNumber = requestData[kPrParam] as int;

    final slug = RepositorySlug(owner, repo);

    final guard = await UnifiedCheckRun.getLatestPresubmitGuardForPrNum(
      firestoreService: _firestore,
      slug: slug,
      prNum: prNumber,
    );
    if (guard == null) {
      throw NotFoundException('No PresubmitGuard found for PR $slug/$prNumber');
    }

    final PullRequest pullRequest;
    try {
      pullRequest = await PrCheckRuns.findPullRequestFor(
        _firestore,
        guard.checkRunId,
        Config.kFlutterPresubmitsName,
      );
    } catch (e) {
      throw NotFoundException(
        'No pull request found for ${Config.kFlutterPresubmitsName} with ${guard.checkRunId} id',
      );
    }

    // We're doing a transactional update, which could fail if multiple tasks
    // are running at the same time so retry a sane amount of times before
    // giving up.
    final failedChecks = await const RetryOptions().retry(
      () => UnifiedCheckRun.reInitializeFailedJobs(
        firestoreService: _firestore,
        slug: slug,
        prNum: prNumber,
        guardCheckRunId: guard.checkRunId,
      ),
    );

    if (failedChecks == null) {
      throw const BadRequestException('No failed jobs found to re-run');
    }

    final (targets, artifacts) = await _scheduler.getAllTargetsForPullRequest(
      slug,
      pullRequest,
    );

    final checkRetries = <Target, int>{};
    for (final target in targets) {
      if (failedChecks.jobRetries.containsKey(target.name)) {
        checkRetries[target] = failedChecks.jobRetries[target.name]!;
      }
    }

    if (checkRetries.length != failedChecks.jobRetries.length) {
      throw const NotFoundException(
        'Failed to find all failed targets in presubmit targets',
      );
    }

    await _luciBuildService.reScheduleTryBuilds(
      targets: checkRetries,
      pullRequest: pullRequest,
      engineArtifacts: artifacts,
      checkRunGuard: failedChecks.checkRunGuard,
      stage: failedChecks.stage,
    );

    return Response.json({
      'results': checkRetries.keys
          .map((t) => {'builder': t.name, 'status': 'rescheduled'})
          .toList(),
    });
  }
}
