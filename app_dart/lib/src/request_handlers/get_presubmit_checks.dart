// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:cocoon_common/rpc_model.dart';

import '../../cocoon_service.dart';
import '../request_handling/public_api_request_handler.dart';
import '../service/firestore/unified_check_run.dart';

/// Returns all checks for a specific presubmit check run.
///
/// GET: /api/get-presubmit-checks
///
/// Parameters:
///   check_run_id: (int in query) mandatory. The GitHub Check Run ID.
///   build_name: (string in query) mandatory. The name of the check/build.
///
/// Response: Status 200 OK
/// [
///   {
///     "attempt_number": 1,
///     "build_name": "Linux Device Doctor",
///     "creation_time": 1620134239000,
///     "start_time": 1620134240000,
///     "end_time": 1620134250000,
///     "status": "Succeeded",
///     "summary": "Check passed"
///   }
/// ]
final class GetPresubmitChecks extends PublicApiRequestHandler {
  const GetPresubmitChecks({
    required super.config,
    required FirestoreService firestore,
  }) : _firestore = firestore;

  final FirestoreService _firestore;

  /// The query parameter for the GitHub Check Run ID.
  static const String kCheckRunIdParam = 'check_run_id';

  /// The query parameter for the build name.
  static const String kBuildNameParam = 'build_name';

  @override
  Future<Response> get(Request request) async {
    final checkRunIdString = request.uri.queryParameters[kCheckRunIdParam];
    final buildName = request.uri.queryParameters[kBuildNameParam];

    if (checkRunIdString == null || buildName == null) {
      return Response.json({
        'error':
            'Missing mandatory parameters: $kCheckRunIdParam, $kBuildNameParam',
      }, statusCode: HttpStatus.badRequest);
    }

    final checkRunId = int.tryParse(checkRunIdString);
    if (checkRunId == null) {
      return Response.json({
        'error': 'Parameter $kCheckRunIdParam must be an integer',
      }, statusCode: HttpStatus.badRequest);
    }

    final checks = await UnifiedCheckRun.getPresubmitCheckDetails(
      firestoreService: _firestore,
      checkRunId: checkRunId,
      buildName: buildName,
    );

    if (checks.isEmpty) {
      return Response.json({
        'error':
            'No checks found for check_run_id $checkRunId and build_name $buildName',
      }, statusCode: HttpStatus.notFound);
    }

    final rpcChecks = [
      for (final check in checks)
        PresubmitCheckResponse(
          attemptNumber: check.attemptNumber,
          buildName: check.buildName,
          creationTime: check.creationTime,
          startTime: check.startTime,
          endTime: check.endTime,
          status: check.status.value,
          summary: check.summary,
          buildNumber: check.buildNumber,
        ),
    ];

    return Response.json(rpcChecks);
  }
}
