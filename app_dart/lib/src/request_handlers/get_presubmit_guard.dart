// Copyright 2026 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:cocoon_common/guard_status.dart';
import 'package:cocoon_common/rpc_model.dart' as rpc_model;
import 'package:cocoon_common/task_status.dart';
import 'package:cocoon_server/logging.dart';
import 'package:github/github.dart';
import 'package:meta/meta.dart';

import '../../cocoon_service.dart';
import '../model/common/checks_extension.dart';
import '../model/firestore/ci_staging.dart';
import '../request_handling/public_api_request_handler.dart';
import '../service/firestore/unified_check_run.dart';

/// For the Unified Check Run flow, this handler returns aggregated execution
/// details of the 'Dashboard Checks' GitHub check for a commit.
///
/// GET: /api/public/get-presubmit-guard
///
/// Parameters:
///   sha: (string in query) mandatory. The GitHub Commit SHA.
///   repo: (string in query) optional. The repository name. Defaults to 'flutter'.
///   owner: (string in query) optional. The repository owner. Defaults to 'flutter'.
///
/// Response: Status 200 OK
/// {
///   "pr_num": 181051,
///   "check_run_id": 82814077799,
///   "author": "ievdokdm",
///   "stages": [
///     {
///       "name": "fusion",
///       "created_at": 1782162074809,
///       "jobs": {
///         "Linux web_canvaskit_tests_0": "Succeeded",
///         "Mac_arm64 build_tests_2_5": "Failed",
///         "Windows tool_integration_tests_5_10": "In progress",
///         "Linux web_canvaskit_tests_1": "Pending",
///         "Mac_arm64 build_tests_3_5": "Infra failure",
///         "Windows tool_integration_tests_7_10": "Cancelled",
///         "Windows tool_integration_tests_6_10": "New",
///         "Windows tool_integration_tests_9_10": "Skipped",
///         "Windows tool_integration_tests_8_10": "Neutral",
///       }
///     },
///     {
///       "name": "engine",
///       "created_at": 1782160242084,
///       "jobs": {
///         "Linux windows_host_engine": "Succeeded",
///         "Linux web_host_engine": "Succeeded",
///       }
///     }
///   ],
///   "guard_status": "Failed",
///   "enable_gemini_log_analysis": true
/// }
@immutable
final class GetPresubmitGuard extends PublicApiRequestHandler {
  /// Defines the [GetPresubmitGuard] handler.
  const GetPresubmitGuard({
    required super.config,
    required FirestoreService firestore,
  }) : _firestore = firestore;

  final FirestoreService _firestore;

  /// The name of the query parameter for the repository name (e.g. 'flutter').
  static const String kRepoParam = 'repo';

  /// The name of the query parameter for the repository owner (e.g. 'flutter').
  static const String kOwnerParam = 'owner';

  /// The name of the query parameter for the commit SHA.
  static const String kShaParam = 'sha';

  /// Handles the HTTP GET request.
  ///
  /// Requires [kRepoParam] and [kShaParam] query parameters.
  /// Returns a JSON response with the aggregated presubmit guard data.
  @override
  Future<Response> get(Request request) async {
    checkRequiredQueryParameters(request, [kShaParam]);

    final repo = request.uri.queryParameters[kRepoParam] ?? 'flutter';
    final owner = request.uri.queryParameters[kOwnerParam] ?? 'flutter';
    final sha = request.uri.queryParameters[kShaParam]!;
    final slug = RepositorySlug(owner, repo);

    log.info('GetPresubmitGuard($slug, $sha)');
    final guards = await UnifiedCheckRun.getPresubmitGuardsForCommitSha(
      firestoreService: _firestore,
      slug: slug,
      commitSha: sha,
    );

    log.info('guards found: ${guards.length}');
    if (guards.isEmpty) {
      return _getCiStagingFallback(slug, sha);
    }

    // Consolidate metadata from the first record.
    final first = guards.first;

    var totalFailed = 0;
    var totalRemaining = 0;
    var totalBuilds = 0;
    for (final g in guards) {
      totalFailed += g.failedJobs;
      totalRemaining += g.remainingJobs;
      totalBuilds += g.jobs.length;
    }

    final guardStatus = GuardStatus.calculate(
      failedBuilds: totalFailed,
      remainingBuilds: totalRemaining,
      totalBuilds: totalBuilds,
    );

    final response = rpc_model.PresubmitGuardResponse(
      prNum: first.prNum,
      checkRunId: first.checkRunId,
      author: first.author,
      guardStatus: guardStatus,
      enableGeminiLogAnalysis: config.flags.enableGeminiLogAnalysis,
      stages: [
        for (final g in guards)
          rpc_model.PresubmitGuardStage(
            name: g.stage.name,
            createdAt: g.creationTime,
            jobs: g.jobs,
          ),
      ],
    );

    return Response.json(response);
  }

  Future<Response> _getCiStagingFallback(
    RepositorySlug slug,
    String sha,
  ) async {
    final (ciStagings, tasks, prInfo) = await (
      CiStaging.getCiStagingForCommitSha(
        firestoreService: _firestore,
        slug: slug,
        sha: sha,
      ),
      _firestore.queryAllTasksForCommit(commitSha: sha),
      PrCheckRuns.findPullRequestForSha(_firestore, sha),
    ).wait;

    if (ciStagings.isEmpty && tasks.isEmpty) {
      return Response.json({
        'error': 'No guard found for slug $slug and sha $sha',
      }, statusCode: HttpStatus.notFound);
    }

    var totalFailed = 0;
    var totalRemaining = 0;
    var totalBuilds = 0;
    for (final stage in ciStagings) {
      totalFailed += stage.failed;
      totalRemaining += stage.remaining;
      totalBuilds += stage.total;
    }

    /// Sort oldest first using a Schwartzian Transform with records to parse createTimestamp exactly once.
    final tasksWithTime = [
      for (final t in tasks) (task: t, time: t.createTimestamp),
    ]..sort((a, b) => a.time.compareTo(b.time));
    final sortedTasks = [for (final entry in tasksWithTime) entry.task];

    final taskStatusMap = <String, TaskStatus>{};
    for (final t in sortedTasks) {
      final taskName = t.taskName;
      final oldStatus = taskStatusMap[taskName];
      final newStatus = t.status;

      taskStatusMap[taskName] = newStatus;

      // Do not count bringup towards success/failure.
      if (t.bringup) continue;
      if (oldStatus == null) {
        totalBuilds++;
        if (newStatus.isFailure) {
          totalFailed++;
        } else if (newStatus.isBuildInProgress) {
          totalRemaining++;
        }
      } else {
        // Adjust failed builds count.
        switch ((oldStatus.isFailure, newStatus.isFailure)) {
          case (true, false):
            totalFailed--;
          case (false, true):
            totalFailed++;
          case _:
            break;
        }

        // Adjust remaining builds count.
        switch ((oldStatus.isBuildInProgress, newStatus.isBuildInProgress)) {
          case (true, false):
            totalRemaining--;
          case (false, true):
            totalRemaining++;
          case _:
            break;
        }
      }
    }

    // Note: In production, there is no overlap between the engine builds in ciStaging
    // and the post-submit tasks in tasks.
    final stages = <rpc_model.PresubmitGuardStage>[
      for (var ciStage in ciStagings)
        if (ciStage.stage case final stage?)
          rpc_model.PresubmitGuardStage(
            name: stage.name,
            createdAt:
                DateTime.tryParse(
                  ciStage.createTime ?? '',
                )?.millisecondsSinceEpoch ??
                0,
            jobs: {
              for (final MapEntry(:key, :value) in ciStage.checkRuns.entries)
                key: ChecksExtension.fromTaskConclusion(value),
            },
          ),

      if (sortedTasks.isNotEmpty)
        rpc_model.PresubmitGuardStage(
          name: 'tasks',
          createdAt: sortedTasks.first.createTimestamp,
          jobs: taskStatusMap,
        ),
    ];

    final guardStatus = GuardStatus.calculate(
      failedBuilds: totalFailed,
      remainingBuilds: totalRemaining,
      totalBuilds: totalBuilds,
    );

    var checkRunId = -1;
    if (ciStagings.isNotEmpty) {
      final guardJsonStr = ciStagings.first.checkRunGuard;
      if (guardJsonStr.isNotEmpty) {
        try {
          if (jsonDecode(guardJsonStr) case {'id': final int id}) {
            checkRunId = id;
          } else {
            checkRunId = 0;
          }
        } catch (_) {
          // ignore
        }
      }
    }

    final response = rpc_model.PresubmitGuardResponse(
      prNum: prInfo?.number ?? 0,
      checkRunId: checkRunId,
      author: prInfo?.user?.login ?? '',
      guardStatus: guardStatus,
      enableGeminiLogAnalysis: config.flags.enableGeminiLogAnalysis,
      stages: stages,
    );

    return Response.json(response);
  }
}
