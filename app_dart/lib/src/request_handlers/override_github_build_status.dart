// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:appengine/appengine.dart';
import 'package:cocoon_service/src/service/datastore.dart';
import 'package:github/github.dart';
import 'package:googleapis/bigquery/v2.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:meta/meta.dart';

import '../datastore/cocoon_config.dart';
import '../foundation/providers.dart';
import '../foundation/typedefs.dart';
import '../foundation/utils.dart';
import '../model/appengine/github_tree_status_override.dart';
import '../request_handling/api_request_handler.dart';
import '../request_handling/authentication.dart';
import '../request_handling/body.dart';
import '../request_handling/exceptions.dart';
import '../service/github_service.dart';

part 'override_github_build_status.g.dart';

/// The request body for [OverrideGitHubBuildStatus].
///
/// This request will set a status on the specified [repository] that will
/// either close or open the tree. The [reason] string is shown in the GitHub
/// UI.
@JsonSerializable()
class OverrideGitHubBuildStatusRequest extends JsonBody {
  const OverrideGitHubBuildStatusRequest({
    @required this.repository,
    @required this.closed,
    @required this.reason,
  })  : assert(repository != null),
        assert(closed != null),
        assert(reason != null);

  static OverrideGitHubBuildStatusRequest fromJson(Map<String, dynamic> json) =>
      _$OverrideGitHubBuildStatusRequestFromJson(json);

  /// The repository to override, e.g. "flutter/flutter" or "flutter/engine".
  final String repository;

  /// True if the tree should be closed, false if it should be open.
  final bool closed;

  /// The string to display in the GitHub status as to why the tree is closed or
  /// open.
  final String reason;

  void _validate() {
    if (repository == null || closed == null || reason == null) {
      throw const BadRequestException();
    }
  }

  @override
  Map<String, dynamic> toJson() => _$OverrideGitHubBuildStatusRequestToJson(this);
}

@JsonSerializable()
class TreeOverrideStatusRow extends JsonBody {
  const TreeOverrideStatusRow({
    this.repository,
    this.user,
    this.reason,
    this.closed,
    this.timestamp,
  });

  static TreeOverrideStatusRow fromJson(Map<String, dynamic> json) => _$TreeOverrideStatusRowFromJson(json);

  /// Assumes the following order:
  ///
  /// - repository
  /// - user
  /// - reason
  /// - closed
  /// - timestamp
  static List<TreeOverrideStatusRow> fromRows(List<TableRow> rows) {
    if (rows == null) {
      return <TreeOverrideStatusRow>[];
    }

    return rows.map((TableRow row) {
      return TreeOverrideStatusRow(
        repository: row.f[0].v as String,
        user: row.f[1].v as String,
        reason: row.f[2].v as String,
        closed: row.f[3].v == 'true' || row.f[3].v == true,
        timestamp: int.parse(row.f[4].v as String),
      );
    }).toList();
  }

  final String repository;
  final String user;
  final String reason;
  final bool closed;
  final int timestamp;

  @override
  Map<String, dynamic> toJson() => _$TreeOverrideStatusRowToJson(this);
}

/// A request handler that will force the tree status for the specified
/// repository to green or red.
///
/// The [get] method will report on the latest status for tracked repositories
/// after pushing statuses to github PRs. It is invoked by a cron job, and
/// is safe to invoke by end users since it tracks the last status it thinks
/// it posted to GitHub.
///
/// The [post] method is used to update the latest status, and appends a new
/// record into the history. It also immediately kicks off a GitHub update.
@immutable
class OverrideGitHubBuildStatus extends ApiRequestHandler<Body> {
  const OverrideGitHubBuildStatus(
    Config config,
    AuthenticationProvider authenticationProvider, {
    @visibleForTesting DatastoreServiceProvider datastoreProvider,
    @visibleForTesting LoggingProvider loggingProvider,
  })  : datastoreProvider = datastoreProvider ?? DatastoreService.defaultProvider,
        loggingProvider = loggingProvider ?? Providers.serviceScopeLogger,
        super(config: config, authenticationProvider: authenticationProvider);

  final DatastoreServiceProvider datastoreProvider;
  final LoggingProvider loggingProvider;

  @override
  Future<Body> get() async {
    final List<TreeOverrideStatusRow> result = await _queryLatestStatuses();

    for (final TreeOverrideStatusRow row in result) {
      await _updateGitHub(
        RepositorySlug.full(row.repository),
        row.closed,
        row.reason,
      );
    }
    return Body.forJson(jsonEncode(result));
  }

  @override
  Future<Body> post() async {
    if (authContext.email == null) {
      throw const Forbidden();
    }

    final OverrideGitHubBuildStatusRequest overrideRequest = OverrideGitHubBuildStatusRequest.fromJson(requestData)
      .._validate();

    await insertBigquery(
      'TreeStatusOverride',
      <String, dynamic>{
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'repository': overrideRequest.repository,
        'user': authContext.email,
        'reason': overrideRequest.reason,
        'closed': overrideRequest.closed,
      },
      await config.createTabledataResourceApi(),
      log,
    );
    await _updateGitHub(
      RepositorySlug.full(overrideRequest.repository),
      overrideRequest.closed,
      overrideRequest.reason,
    );

    return Body.empty;
  }

  Future<List<TreeOverrideStatusRow>> _queryLatestStatuses() async {
    final JobsResourceApi jobsResourceApi = await config.createJobsResourceApi();
    final QueryResponse queryResponse = await jobsResourceApi.query(
      QueryRequest()
        ..query = '''
SELECT
   repository
  ,user
  ,reason
  ,closed
  ,timestamp
FROM (
  SELECT
       ROW_NUMBER() OVER(PARTITION BY repository ORDER BY timestamp DESC) as rn
      ,repository
      ,user
      ,reason
      ,closed
      ,timestamp
    FROM cocoon.TreeStatusOverride)
WHERE rn = 1;''',
      'flutter-dashboard',
    );
    return TreeOverrideStatusRow.fromRows(queryResponse.rows);
  }

  Future<void> _updateGitHub(RepositorySlug slug, bool closed, String reason) async {
    final DatastoreService datastore = datastoreProvider(config.db);
    final Logging log = loggingProvider();
    final GithubService githubService = await config.createGithubService(slug.owner, slug.name);
    for (PullRequest pr in await githubService.listPullRequests(slug, 'master')) {
      final GitHubTreeStatusOverride update = await datastore.queryLastOverrideStatusUpdate(slug, pr);
      if (update.closed != closed) {
        log.debug('Updating tree status of ${slug.fullName}#${pr.number} (closed = $closed)');
        final CreateStatus request = CreateStatus(closed ? 'failure' : 'success')
          ..targetUrl = 'https://flutter-dashboard.appspot.com/api/override-github-build-status'
          ..context = 'tree-status'
          ..description = reason;

        try {
          await githubService.github.repositories.createStatus(slug, pr.head.sha, request);
        } catch (error) {
          log.error('Failed to post status update to ${slug.fullName}#${pr.number}: $error');
        }
      }
    }
  }
}
