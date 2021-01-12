// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:github/github.dart';
import 'package:meta/meta.dart';

import '../datastore/cocoon_config.dart';
import '../foundation/utils.dart';
import '../model/appengine/github_build_status_update.dart';
import '../model/appengine/task.dart';
import '../request_handling/api_request_handler.dart';
import '../request_handling/authentication.dart';
import '../request_handling/body.dart';
import '../service/buildbucket.dart';
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
      buildBucketClient: BuildBucketClient(),
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
    const String bigqueryTableName = 'BuildStatus';
    final Map<String, dynamic> bigqueryData = <String, dynamic>{
      'Timestamp': DateTime.now().millisecondsSinceEpoch,
      'Status': latestStatus,
      'Branch': 'master',
      'Repo': 'engine'
    };
    await insertBigquery(bigqueryTableName, bigqueryData, await config.createTabledataResourceApi(), log);

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

  /// This function gets called with the last 40 builds fo a given builder ordered
  /// by creation time starting with the last one first.
  String _getLatestStatus(List<LuciTask> tasks) {
    for (LuciTask task in tasks) {
      if (task.ref != 'refs/heads/master') {
        log.debug('Skipping ${task.status} from commit ${task.commitSha} ref ${task.ref} builder ${task.builderName}');
        continue;
      }
      switch (task.status) {
        case Task.statusFailed:
        case Task.statusInfraFailure:
          log.debug('Using ${task.status} from commit ${task.commitSha} ref ${task.ref} builder ${task.builderName}');
          return GithubBuildStatusUpdate.statusFailure;
        case Task.statusSucceeded:
          log.debug('Using ${task.status} from commit ${task.commitSha} ref ${task.ref} builder ${task.builderName}');
          return GithubBuildStatusUpdate.statusSuccess;
      }
    }
    // No state means we don't have a state for the last 40 commits which should
    // close the tree.
    return GithubBuildStatusUpdate.statusFailure;
  }
}
