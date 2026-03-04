// Copyright 2025 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:github/github.dart';

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
///   build_name: (string in body) mandatory. The name of the build to re-run.
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
  static const String kBuildNameParam = 'build_name';

  @override
  Future<Response> post(Request request) async {
    final requestData = await request.readBodyAsJson();
    checkRequiredParameters(requestData, [kPrParam, kBuildNameParam]);

    final owner = requestData[kOwnerParam] as String? ?? 'flutter';
    final repo = requestData[kRepoParam] as String? ?? 'flutter';
    final prNumber = requestData[kPrParam] as int;
    final buildName = requestData[kBuildNameParam] as String;

    final slug = RepositorySlug(owner, repo);

    final guard = await UnifiedCheckRun.getLatestPresubmitGuardByPullRequestNum(
      firestoreService: _firestore,
      slug: slug,
      pullRequestNum: prNumber,
    );
    if (guard == null) {
      throw NotFoundException('No PresubmitGuard found for PR $slug/$prNumber');
    }

    final pullRequest = await _scheduler.findPullRequestCachedForPullRequestNum(
      slug,
      prNumber,
    );

    if (pullRequest == null) {
      throw NotFoundException('No pull request found for PR $slug/$prNumber');
    }

    final rerunInfo = await UnifiedCheckRun.reInitializeFailedJob(
      firestoreService: _firestore,
      slug: slug,
      pullRequestId: prNumber,
      guardCheckRunId: guard.checkRunId,
      buildName: buildName,
    );

    if (rerunInfo == null) {
      throw BadRequestException(
        'Build $buildName is not a failed job in PR $slug/$prNumber',
      );
    }

    final (targets, artifacts) = await _scheduler.getAllTargetsForPullRequest(
      slug,
      pullRequest,
    );

    final target = targets.firstWhere(
      (t) => t.name == buildName,
      orElse: () =>
          throw BadRequestException('Target $buildName not found in .ci.yaml'),
    );

    await _luciBuildService.scheduleTryBuilds(
      targets: [target],
      pullRequest: pullRequest,
      engineArtifacts: artifacts,
      checkRunGuard: rerunInfo.checkRunGuard,
      stage: rerunInfo.stage,
    );

    return Response.json({'builder': buildName, 'status': 'rescheduled'});
  }
}
