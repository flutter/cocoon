// Copyright 2026 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:cocoon_common/guard_status.dart';
import 'package:cocoon_common/rpc_model.dart' as rpc_model;
import 'package:github/github.dart';
import 'package:meta/meta.dart';

import '../../cocoon_service.dart';
import '../request_handling/public_api_request_handler.dart';
import '../service/firestore/unified_check_run.dart';

/// For the Unified Check Run flow, this handler returns aggregated execution
/// details of the 'Dashboard Checks' GitHub check for a commit.
///
/// GET: /api/public/get-presubmit-guard
///
/// Parameters:
///   commit_sha: (string in query) mandatory. The GitHub Commit SHA.
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
    final guards = await UnifiedCheckRun.getPresubmitGuardsForCommitSha(
      firestoreService: _firestore,
      slug: slug,
      commitSha: sha,
    );

    if (guards.isEmpty) {
      return Response.json({
        'error': 'No guard found for slug $slug and sha $sha',
      }, statusCode: HttpStatus.notFound);
    }

    // Consolidate metadata from the first record.
    final first = guards.first;

    final totalFailed = guards.fold<int>(0, (sum, g) => sum + g.failedJobs);
    final totalRemaining = guards.fold<int>(
      0,
      (sum, g) => sum + g.remainingJobs,
    );
    final totalBuilds = guards.fold<int>(0, (sum, g) => sum + g.jobs.length);

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
}
