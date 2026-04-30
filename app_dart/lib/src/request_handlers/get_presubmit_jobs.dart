// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:cocoon_common/rpc_model.dart';
import 'package:github/github.dart';

import '../../cocoon_service.dart';
import '../request_handling/public_api_request_handler.dart';
import '../service/firestore/unified_check_run.dart';

/// Returns all jobs for a specific presubmit job.
///
/// GET: /api/public/get-presubmit-jobs
///
/// Parameters:
///   check_run_id: (int in query) mandatory. The GitHub Check Run ID.
///   job_name: (string in query) mandatory. The name of the job.
///   repo: (string in query) optional. The repository name.
///   owner: (string in query) optional. The repository owner.
///
/// Response: Status 200 OK
/// [
///   {
///     "attempt_number": 1,
///     "job_name": "Linux Device Doctor",
///     "creation_time": 1620134239000,
///     "start_time": 1620134240000,
///     "end_time": 1620134250000,
///     "status": "Succeeded",
///     "summary": "Check passed"
///   }
/// ]
final class GetPresubmitJobs extends PublicApiRequestHandler {
  const GetPresubmitJobs({
    required super.config,
    required FirestoreService firestore,
  }) : _firestore = firestore;

  final FirestoreService _firestore;

  /// The query parameter for the GitHub Check Run ID.
  static const String kCheckRunIdParam = 'check_run_id';

  /// The query parameter for the job name.
  static const String kJobNameParam = 'job_name';

  /// The name of the query parameter for the repository name (e.g. 'flutter').
  static const String kRepoParam = 'repo';

  /// The name of the query parameter for the repository owner (e.g. 'flutter').
  static const String kOwnerParam = 'owner';

  @override
  Future<Response> get(Request request) async {
    final checkRunIdString = request.uri.queryParameters[kCheckRunIdParam];
    final jobName = request.uri.queryParameters[kJobNameParam];
    final repo = request.uri.queryParameters[kRepoParam] ?? 'flutter';
    final owner = request.uri.queryParameters[kOwnerParam] ?? 'flutter';

    if (checkRunIdString == null || jobName == null) {
      return Response.json({
        'error':
            'Missing mandatory parameters: $kCheckRunIdParam, $kJobNameParam',
      }, statusCode: HttpStatus.badRequest);
    }

    final checkRunId = int.tryParse(checkRunIdString);
    if (checkRunId == null) {
      return Response.json({
        'error': 'Parameter $kCheckRunIdParam must be an integer',
      }, statusCode: HttpStatus.badRequest);
    }

    final slug = RepositorySlug(owner, repo);
    final jobs = await UnifiedCheckRun.getPresubmitJobDetails(
      firestoreService: _firestore,
      checkRunId: checkRunId,
      jobName: jobName,
      slug: slug,
    );

    if (jobs.isEmpty) {
      return Response.json({
        'error':
            'No checks found for check_run_id $checkRunId and job_name $jobName',
      }, statusCode: HttpStatus.notFound);
    }

    final rpcChecks = [
      for (final job in jobs)
        PresubmitJobResponse(
          attemptNumber: job.attemptNumber,
          jobName: job.jobName,
          creationTime: job.creationTime,
          startTime: job.startTime,
          endTime: job.endTime,
          status: job.status,
          summary: job.summary,
          buildNumber: job.buildNumber,
          buildId: job.buildId,
          logAnalysis: job.logAnalysis,
        ),
    ];

    return Response.json(rpcChecks);
  }
}
