// Copyright 2025 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:github/github.dart';
import 'package:retry/retry.dart';

import '../../cocoon_service.dart';
import '../request_handling/api_request_handler.dart';
import '../request_handling/exceptions.dart';
import '../service/firestore/unified_check_run.dart';

/// Re-runs a specific failed job for a unified check run.
///
/// POST: /api/rerun-failed-job
///
/// Parameters:
///   owner: (string in body) mandatory. The GitHub repository owner.
///   repo: (string in body) mandatory. The GitHub repository name.
///   pr: (int in body) mandatory. The Pull Request number.
///   job_name: (string in body) mandatory. The name of the job to re-run.
final class RerunFailedJob extends ApiRequestHandler {
  const RerunFailedJob({
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
  static const String kJobNameParam = 'job_name';

  @override
  Future<Response> post(Request request) async {
    final requestData = await request.readBodyAsJson();
    checkRequiredParameters(requestData, [kPrParam, kJobNameParam]);

    final owner = requestData[kOwnerParam] as String? ?? 'flutter';
    final repo = requestData[kRepoParam] as String? ?? 'flutter';
    final prNumber = requestData[kPrParam] as int;
    final jobName = requestData[kJobNameParam] as String;

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
    final rerunInfo = await const RetryOptions().retry(
      () => UnifiedCheckRun.reInitializeFailedJob(
        firestoreService: _firestore,
        slug: slug,
        prNum: prNumber,
        guardCheckRunId: guard.checkRunId,
        jobName: jobName,
      ),
    );

    if (rerunInfo == null) {
      throw BadRequestException(
        'Job $jobName is not a failed job in PR $slug/$prNumber',
      );
    }

    final (targets, artifacts) = await _scheduler.getAllTargetsForPullRequest(
      slug,
      pullRequest,
    );

    final target = targets.firstWhere(
      (t) => t.name == jobName,
      orElse: () =>
          throw BadRequestException('Target $jobName not found in .ci.yaml'),
    );

    final retries = rerunInfo.jobRetries[jobName]!;

    await _luciBuildService.reScheduleTryBuilds(
      targets: {target: retries},
      pullRequest: pullRequest,
      engineArtifacts: artifacts,
      checkRunGuard: rerunInfo.checkRunGuard,
      stage: rerunInfo.stage,
    );

    return Response.json({'builder': jobName, 'status': 'rescheduled'});
  }
}
