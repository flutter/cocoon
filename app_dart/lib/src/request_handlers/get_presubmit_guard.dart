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

/// Request handler for retrieving the aggregated presubmit guard status.
///
/// This handler queries the presubmit guards for a specific commit SHA and
/// returns an aggregated response including the overall guard status and
/// individual stage statuses.
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
      stages: [
        for (final g in guards)
          rpc_model.PresubmitGuardStage(
            name: g.stage.name,
            createdAt: g.creationTime,
            builds: g.jobs,
          ),
      ],
    );

    return Response.json(response);
  }
}
