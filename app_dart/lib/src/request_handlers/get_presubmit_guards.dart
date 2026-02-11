// Copyright 2026 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:cocoon_common/guard_status.dart';
import 'package:github/github.dart';
import 'package:meta/meta.dart';

import '../../cocoon_service.dart';
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

    final response = guards.map((g) {
      return {
        'commit_sha': g.commitSha,
        'check_run_id': g.checkRunId,
        'creation_time': g.creationTime,
        'guard_status': GuardStatus.calculate(
          failedBuilds: g.failedBuilds,
          remainingBuilds: g.remainingBuilds,
          totalBuilds: g.builds.length,
        ).value,
      };
    }).toList();

    return Response.json(response);
  }
}
