// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:cocoon_scheduler/scheduler.dart';
import 'package:github/github.dart';
import 'package:meta/meta.dart';

import '../foundation/utils.dart';
import '../model/appengine/commit.dart';
import '../model/appengine/github_build_status_update.dart';
import '../model/appengine/task.dart';
import '../request_handling/api_request_handler.dart';
import '../request_handling/authentication.dart';
import '../request_handling/body.dart';
import '../service/buildbucket.dart';
import '../service/config.dart';
import '../service/datastore.dart';
import '../service/luci.dart';
import '../service/luci_build_service.dart';
import '../service/scheduler.dart';

@immutable
class PushEngineStatusToGithub extends ApiRequestHandler<Body> {
  const PushEngineStatusToGithub(
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

    final RepositorySlug slug = config.engineSlug;
    final Commit engineTipOfTreeCommit = Commit(sha: config.defaultBranch, repository: slug.fullName);
    final SchedulerConfig schedulerConfig = await scheduler.getSchedulerConfig(engineTipOfTreeCommit);
    final List<Target> postsubmitTargets = scheduler.getPostSubmitTargets(engineTipOfTreeCommit, schedulerConfig);
    final List<LuciBuilder> postsubmitBuilders =
        postsubmitTargets.map((Target target) => LuciBuilder.fromTarget(target, engineTipOfTreeCommit.slug)).toList();
    final LuciService luciService = luciServiceProvider(this);
    final Map<LuciBuilder, List<LuciTask>> luciTasks = await luciService.getRecentTasks(builders: postsubmitBuilders);

    String status = GithubBuildStatusUpdate.statusSuccess;
    for (List<LuciTask> tasks in luciTasks.values) {
      final String latestStatus = await _getLatestStatus(tasks);
      if (status == GithubBuildStatusUpdate.statusSuccess && latestStatus == GithubBuildStatusUpdate.statusFailure) {
        status = GithubBuildStatusUpdate.statusFailure;
      }
    }
    // Insert build status to bigquery.
    const String bigqueryTableName = 'BuildStatus';
    final Map<String, dynamic> bigqueryData = <String, dynamic>{
      'Timestamp': DateTime.now().millisecondsSinceEpoch,
      'Status': status,
      'Branch': 'master',
      'Repo': 'engine'
    };
    await insertBigquery(bigqueryTableName, bigqueryData, await config.createTabledataResourceApi(), log);

    final DatastoreService datastore = datastoreProvider(config.db);
    final GitHub github = await config.createGitHubClient(slug);
    final List<GithubBuildStatusUpdate> updates = <GithubBuildStatusUpdate>[];
    await for (PullRequest pr in github.pullRequests.list(slug)) {
      final GithubBuildStatusUpdate update = await datastore.queryLastStatusUpdate(slug, pr);

      if (update.status != status) {
        log.debug('Updating status of ${slug.fullName}#${pr.number} from ${update.status}');
        final CreateStatus request = CreateStatus(status);
        request.targetUrl = 'https://ci.chromium.org/p/flutter/g/engine/console';
        request.context = 'luci-engine';
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
    log.debug('Committed all updates');
    return Body.empty;
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
          final int retries = tasks.where((LuciTask element) => element.commitSha == task.commitSha).length - 1;
          log.debug('markdown: ${task.summaryMarkdown}, builderName: ${task.builderName}, retries: $retries');
          await luciBuildService.checkRerunBuilder(
              commitSha: task.commitSha, luciTask: task, retries: retries, repo: 'engine');
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
