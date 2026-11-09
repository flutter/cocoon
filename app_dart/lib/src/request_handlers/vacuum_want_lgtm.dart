// Copyright 2026 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:github/github.dart' as gh;
import 'package:meta/meta.dart';

import '../foundation/github_checks_util.dart';
import '../request_handling/api_request_handler.dart';
import '../request_handling/http_utils.dart';
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

  static const _paramRepo = 'repo';
  static const _paramDryRun = 'dry_run';

  @override
  Future<Response> get(Request request) async {
    final (:slug, :error) = _resolveRepo(request);
    if (error != null) {
      return error;
    }

    final dryRun =
        request.uri.queryParameters[_paramDryRun]?.toLowerCase() == 'true';
    final checkWriter = WantLgtmCheckWriter(
      config: config,
      githubChecksUtil: _githubChecksUtil,
      firestoreService: _firestore,
    );
    final swept = await checkWriter.sweepInProgressRuns(
      slug: slug,
      dryRun: dryRun,
    );

    return Response.json(<String, Object?>{
      'swept': swept,
      'dry_run': dryRun,
      if (slug != null) 'repo': slug.fullName,
    });
  }

  ({gh.RepositorySlug? slug, Response? error}) _resolveRepo(Request request) {
    final specific = request.uri.queryParameters[_paramRepo];
    if (specific == null) {
      return (slug: null, error: null);
    }
    if (specific.split('/') case [
      final owner,
      final name,
    ] when owner.isNotEmpty && name.isNotEmpty) {
      final repo = gh.RepositorySlug(owner, name);
      if (!config.supportedRepos.contains(repo)) {
        return (
          slug: null,
          error: Response.json({
            'error': 'repo not found: $repo',
          }, statusCode: HttpStatus.notFound),
        );
      }
      return (slug: repo, error: null);
    }
    return (
      slug: null,
      error: Response.json({
        'error': 'Invalid repo parameter: $specific',
      }, statusCode: HttpStatus.badRequest),
    );
  }
}
