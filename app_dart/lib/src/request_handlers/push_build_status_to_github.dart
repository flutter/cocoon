// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:appengine/appengine.dart';
import 'package:cocoon_scheduler/models/scheduler.pb.dart';
import 'package:github/github.dart';
import 'package:meta/meta.dart';

import '../../cocoon_service.dart';
import '../../src/service/luci.dart';
import '../model/appengine/commit.dart';
import '../model/appengine/github_build_status_update.dart';
import '../model/appengine/task.dart';
import '../request_handling/api_request_handler.dart';
import '../request_handling/authentication.dart';
import '../request_handling/body.dart';
import '../service/config.dart';
import '../service/datastore.dart';

@immutable
class PushBuildStatusToGithub extends ApiRequestHandler<Body> {
  const PushBuildStatusToGithub(
    Config config,
    AuthenticationProvider authenticationProvider,
    this.luciBuildService, {
    this.scheduler,
    @visibleForTesting LuciServiceProvider luciServiceProvider,
    @visibleForTesting DatastoreServiceProvider datastoreProvider,
  })  : luciServiceProvider = luciServiceProvider ?? _createLuciService,
        datastoreProvider = datastoreProvider ?? DatastoreService.defaultProvider,
        super(config: config, authenticationProvider: authenticationProvider);

  final LuciBuildService luciBuildService;
  final LuciServiceProvider luciServiceProvider;
  final DatastoreServiceProvider datastoreProvider;
  final Scheduler scheduler;
  static const String fullNameRepoParam = 'repo';

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
    luciBuildService.setLogger(log);

    final String repo = request.uri.queryParameters[fullNameRepoParam] ?? 'flutter/flutter';
    final RepositorySlug slug = RepositorySlug.full(repo);

    for (String branch in await config.getSupportedBranches(slug)) {
      final Commit tipOfTreeCommit = Commit(sha: branch, repository: slug.fullName);
      final SchedulerConfig schedulerConfig = await scheduler.getSchedulerConfig(tipOfTreeCommit);
      final List<LuciBuilder> postsubmitBuilders =
          await scheduler.getPostSubmitBuilders(tipOfTreeCommit, schedulerConfig);
      final LuciService luciService = luciServiceProvider(this);
      final Map<LuciBuilder, List<LuciTask>> luciTasks = await luciService.getRecentTasks(builders: postsubmitBuilders);

      String status = GithubBuildStatusUpdate.statusSuccess;
      for (List<LuciTask> tasks in luciTasks.values) {
        final String latestStatus = await _getLatestStatus(tasks);
        if (status == GithubBuildStatusUpdate.statusSuccess && latestStatus == GithubBuildStatusUpdate.statusFailure) {
          status = GithubBuildStatusUpdate.statusFailure;
        }
      }

      await _insertBigquery(slug, status, branch, log, config);
      final DatastoreService datastore = datastoreProvider(config.db);
      await _updatePRs(slug, status, datastore);
      log.debug('All the PRs for $repo have been updated with $status');
    }

    return Body.empty;
  }

  Future<void> _updatePRs(RepositorySlug slug, String status, DatastoreService datastore) async {
    final GitHub github = await config.createGitHubClient(slug);
    final List<GithubBuildStatusUpdate> updates = <GithubBuildStatusUpdate>[];
    await for (PullRequest pr in github.pullRequests.list(slug)) {
      final GithubBuildStatusUpdate update = await datastore.queryLastStatusUpdate(slug, pr);
      if (update.status != status) {
        log.debug('Updating status of ${slug.fullName}#${pr.number} from ${update.status} to $status');
        final CreateStatus request = CreateStatus(status);
        request.targetUrl = 'https://ci.chromium.org/p/flutter/g/engine/console';
        request.context = 'luci-${slug.name}';
        if (status != GithubBuildStatusUpdate.statusSuccess) {
          request.description = config.flutterBuildDescription;
        }
        try {
          await github.repositories.createStatus(slug, pr.head.sha, request);
          update.status = status;
          update.updates += 1;
          update.updateTimeMillis = DateTime.now().millisecondsSinceEpoch;
          updates.add(update);
        } catch (error) {
          log.error('Failed to post status update to ${slug.fullName}#${pr.number}: $error');
        }
      }
    }
    await datastore.insert(updates);
  }

  /// This function gets called with the last 40 builds fo a given builder ordered
  /// by creation time starting with the last one first.
  Future<String> _getLatestStatus(List<LuciTask> tasks) async {
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

  Future<void> _insertBigquery(RepositorySlug slug, String status, String branch, Logging log, Config config) async {
    const String bigqueryTableName = 'BuildStatus';
    final Map<String, dynamic> bigqueryData = <String, dynamic>{
      'Timestamp': DateTime.now().millisecondsSinceEpoch,
      'Status': status,
      'Branch': branch,
      'Repo': slug.name,
    };
    await insertBigquery(bigqueryTableName, bigqueryData, await config.createTabledataResourceApi(), log);
  }
}
