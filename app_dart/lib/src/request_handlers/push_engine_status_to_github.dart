// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:github/github.dart';
import 'package:googleapis/bigquery/v2.dart';
import 'package:meta/meta.dart';

import '../datastore/cocoon_config.dart';
import '../model/appengine/github_build_status_update.dart';
import '../model/appengine/task.dart';
import '../request_handling/api_request_handler.dart';
import '../request_handling/authentication.dart';
import '../request_handling/body.dart';
import '../service/datastore.dart';
import '../service/luci.dart';

@immutable
class PushEngineStatusToGithub extends ApiRequestHandler<Body> {
  const PushEngineStatusToGithub(
    Config config,
    AuthenticationProvider authenticationProvider, {
    @visibleForTesting LuciServiceProvider luciServiceProvider,
    @visibleForTesting DatastoreServiceProvider datastoreProvider,
  })  : luciServiceProvider = luciServiceProvider ?? _createLuciService,
        datastoreProvider = datastoreProvider ?? DatastoreService.defaultProvider,
        super(config: config, authenticationProvider: authenticationProvider);

  final LuciServiceProvider luciServiceProvider;
  final DatastoreServiceProvider datastoreProvider;

  static LuciService _createLuciService(ApiRequestHandler<dynamic> handler) {
    return LuciService(
      config: handler.config,
      clientContext: handler.authContext.clientContext,
    );
  }

  @override
  Future<Body> get() async {
    if (authContext.clientContext.isDevelopmentEnvironment) {
      // Don't push GitHub status from the local dev server.
      return Body.empty;
    }

    final LuciService luciService = luciServiceProvider(this);
    final Map<LuciBuilder, List<LuciTask>> luciTasks = await luciService.getRecentTasks(repo: 'engine');

    String latestStatus = GithubBuildStatusUpdate.statusSuccess;
    for (List<LuciTask> tasks in luciTasks.values) {
      latestStatus = _getLatestStatus(tasks);
      if (latestStatus == GithubBuildStatusUpdate.statusFailure) {
        break;
      }
    }
    // Insert build status to bigquery.
    await _insertBigquery(latestStatus);

    final RepositorySlug slug = RepositorySlug('flutter', 'engine');
    final DatastoreService datastore = datastoreProvider(config.db);
    final GitHub github = await config.createGitHubClient(slug.owner, slug.name);
    final List<GithubBuildStatusUpdate> updates = <GithubBuildStatusUpdate>[];
    await for (PullRequest pr in github.pullRequests.list(slug)) {
      final GithubBuildStatusUpdate update = await datastore.queryLastStatusUpdate(slug, pr);

      if (update.status != latestStatus) {
        log.debug('Updating status of ${slug.fullName}#${pr.number} from ${update.status}');
        final CreateStatus request = CreateStatus(latestStatus);
        request.targetUrl = 'https://ci.chromium.org/p/flutter/g/engine/console';
        request.context = 'luci-engine';
        if (latestStatus != GithubBuildStatusUpdate.statusSuccess) {
          request.description = 'Flutter build is currently broken. Please do not merge this '
              'PR unless it contains a fix to the broken build.';
        }

        try {
          await github.repositories.createStatus(slug, pr.head.sha, request);
          update.status = latestStatus;
          update.updates += 1;
          update.updateTimeMillis = DateTime.now().millisecondsSinceEpoch;
          updates.add(update);
        } catch (error) {
          log.error('Failed to post status update to ${slug.fullName}#${pr.number}: $error');
        }
      }
    }
    await datastore.insert(updates);
    log.debug('Committed all updates');
    return Body.empty;
  }

  String _getLatestStatus(List<LuciTask> tasks) {
    for (LuciTask task in tasks) {
      switch (task.status) {
        case Task.statusFailed:
          return GithubBuildStatusUpdate.statusFailure;
        case Task.statusSucceeded:
          return GithubBuildStatusUpdate.statusSuccess;
      }
    }
    return GithubBuildStatusUpdate.statusSuccess;
  }

  Future<void> _insertBigquery(String buildStatus) async {
    // Define const variables for [BigQuery] operations.
    const String projectId = 'flutter-dashboard';
    const String dataset = 'cocoon';
    const String table = 'EngineBuildStatus';

    final TabledataResourceApi tabledataResourceApi = await config.createTabledataResourceApi();
    final List<Map<String, Object>> requestRows = <Map<String, Object>>[];

    requestRows.add(<String, Object>{
      'json': <String, Object>{
        'Timestamp': DateTime.now().millisecondsSinceEpoch,
        'Status': buildStatus,
      },
    });

    // Obtain [rows] to be inserted to [BigQuery].
    final TableDataInsertAllRequest request = TableDataInsertAllRequest.fromJson(<String, Object>{'rows': requestRows});

    try {
      await tabledataResourceApi.insertAll(request, projectId, dataset, table);
    } on ApiRequestError {
      log.warning('Failed to add build status to BigQuery: $ApiRequestError');
    }
  }
}
