// Copyright 2026 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:cocoon_common/guard_status.dart';
import 'package:cocoon_common/rpc_model.dart' as rpc_model;
import 'package:github/github.dart';
import 'package:meta/meta.dart';

import '../../cocoon_service.dart';
import '../model/firestore/presubmit_guard.dart';
import '../request_handling/api_request_handler.dart';
import '../service/firestore/unified_check_run.dart';

/// Request handler for retrieving all presubmit guards for a specific pull request.
@immutable
final class GetPresubmitGuards extends ApiRequestHandler {
  /// Defines the [GetPresubmitGuards] handler.
  const GetPresubmitGuards({
    required super.config,
    required super.authenticationProvider,
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
      final latestCreationTime = shaGuards.fold<int>(
        0,
        (int max, PresubmitGuard g) =>
            g.creationTime > max ? g.creationTime : max,
      );

      responseGuards.add(
        rpc_model.PresubmitGuardSummary(
          commitSha: sha,
          creationTime: latestCreationTime,
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
