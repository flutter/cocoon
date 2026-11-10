// Copyright 2026 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:meta/meta.dart';

import '../foundation/github_checks_util.dart';
import '../request_handling/api_request_handler.dart';
import '../request_handling/request_handler.dart';
import '../request_handling/response.dart';
import '../service/firestore.dart';
import '../service/want_lgtm/want_lgtm_check_writer.dart';

/// Sweeps open `in_progress` `WANT_LGTM` check runs to `neutral` on
/// repositories where the `flags.wantLgtm` rollout flag is disabled.
@immutable
final class VacuumWantLgtm extends ApiRequestHandler {
  const VacuumWantLgtm({
    required super.config,
    required super.authenticationProvider,
    required FirestoreService firestore,
    @visibleForTesting
    GithubChecksUtil githubChecksUtil = const GithubChecksUtil(),
  }) : _firestore = firestore,
       _githubChecksUtil = githubChecksUtil;

  final FirestoreService _firestore;
  final GithubChecksUtil _githubChecksUtil;

  static const _paramDryRun = 'dry_run';

  @override
  Future<Response> get(Request request) async {
    final dryRun =
        request.uri.queryParameters[_paramDryRun]?.toLowerCase() == 'true';
    final checkWriter = WantLgtmCheckWriter(
      config: config,
      githubChecksUtil: _githubChecksUtil,
      firestoreService: _firestore,
    );
    final swept = await checkWriter.sweepInProgressRuns(dryRun: dryRun);

    return Response.json(<String, Object?>{'swept': swept, 'dry_run': dryRun});
  }
}
