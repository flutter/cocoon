// Copyright 2026 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:math';

import 'package:cocoon_common/guard_status.dart';
import 'package:cocoon_common/rpc_model.dart' as rpc_model;
import 'package:github/github.dart';
import 'package:meta/meta.dart';

import '../../cocoon_service.dart';
import '../request_handling/public_api_request_handler.dart';
import '../service/firestore/unified_check_run.dart';

/// Request handler for retrieving all presubmit guards for a specific pull request.
///
/// GET: /api/get-presubmit-guard-summaries
///
/// Parameters:
///   repo: (string in query) required. The repository name (e.g., 'flutter').
///   pr: (int in query) required. The pull request number.
///   owner: (string in query) optional. The repository owner (e.g., 'flutter').
@immutable
final class GetPresubmitGuardSummaries extends PublicApiRequestHandler {
  /// Defines the [GetPresubmitGuardSummaries] handler.
  const GetPresubmitGuardSummaries({
    required super.config,
    required FirestoreService firestore,
  }) : _firestore = firestore;

  final FirestoreService _firestore;

  /// The name of the query parameter for the repository name (e.g. 'flutter').
  static const String kRepoParam = 'repo';

  /// The name of the query parameter for the pull request number.
  static const String kPRParam = 'pr';

  /// The name of the query parameter for the repository owner (e.g. 'flutter').
  static const String kOwnerParam = 'owner';

  @override
  Future<Response> get(Request request) async {
    checkRequiredQueryParameters(request, [kRepoParam, kPRParam]);

    final repo = request.uri.queryParameters[kRepoParam]!;
    final prNumber = int.parse(request.uri.queryParameters[kPRParam]!);
    final owner = request.uri.queryParameters[kOwnerParam] ?? 'flutter';

    final slug = RepositorySlug(owner, repo);
    final guards = await UnifiedCheckRun.getPresubmitGuardsForPullRequest(
      firestoreService: _firestore,
      slug: slug,
      pullRequestId: prNumber,
    );

    if (guards.isEmpty) {
      return Response.json({
        'error': 'No guards found for PR $prNumber in $slug',
      }, statusCode: HttpStatus.notFound);
    }

    // Group guards by commitSha
    final groupedGuards = <String, List<PresubmitGuard>>{};
    for (final guard in guards) {
      groupedGuards.putIfAbsent(guard.commitSha, () => []).add(guard);
    }

    final responseGuards = <rpc_model.PresubmitGuardSummary>[];
    for (final entry in groupedGuards.entries) {
      final sha = entry.key;
      final shaGuards = entry.value;

      final totalFailed = shaGuards.fold<int>(
        0,
        (int sum, PresubmitGuard g) => sum + g.failedBuilds,
      );
      final totalRemaining = shaGuards.fold<int>(
        0,
        (int sum, PresubmitGuard g) => sum + g.remainingBuilds,
      );
      final totalBuilds = shaGuards.fold<int>(
        0,
        (int sum, PresubmitGuard g) => sum + g.builds.length,
      );
      final earliestCreationTime = shaGuards.fold<int>(
        // assuming creation time is always in the past :)
        DateTime.now().millisecondsSinceEpoch,
        (int curr, PresubmitGuard g) => min(g.creationTime, curr),
      );

      responseGuards.add(
        rpc_model.PresubmitGuardSummary(
          commitSha: sha,
          creationTime: earliestCreationTime,
          guardStatus: GuardStatus.calculate(
            failedBuilds: totalFailed,
            remainingBuilds: totalRemaining,
            totalBuilds: totalBuilds,
          ),
        ),
      );
    }

    return Response.json(responseGuards);
  }
}
