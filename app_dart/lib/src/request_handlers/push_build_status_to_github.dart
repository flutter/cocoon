// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:github/github.dart';
import 'package:meta/meta.dart';

import '../../cocoon_service.dart';
import '../../src/service/luci.dart';
import '../model/appengine/commit.dart';
import '../model/appengine/github_build_status_update.dart';
import '../model/proto/internal/scheduler.pb.dart';
import '../request_handling/api_request_handler.dart';
import '../service/build_status_provider.dart';
import '../service/datastore.dart';
import '../service/logging.dart';

@immutable
class PushBuildStatusToGithub extends ApiRequestHandler<Body> {
  const PushBuildStatusToGithub(
    Config config,
    AuthenticationProvider authenticationProvider,
    this.luciBuildService, {
    this.scheduler,
    @visibleForTesting LuciServiceProvider? luciServiceProvider,
    @visibleForTesting DatastoreServiceProvider? datastoreProvider,
    @visibleForTesting BuildStatusServiceProvider? buildStatusServiceProvider,
  })  : luciServiceProvider = luciServiceProvider ?? _createLuciService,
        datastoreProvider = datastoreProvider ?? DatastoreService.defaultProvider,
        buildStatusServiceProvider = buildStatusServiceProvider ?? BuildStatusService.defaultProvider,
        super(config: config, authenticationProvider: authenticationProvider);

  final LuciBuildService luciBuildService;
  final LuciServiceProvider luciServiceProvider;
  final BuildStatusServiceProvider buildStatusServiceProvider;
  final DatastoreServiceProvider datastoreProvider;
  final Scheduler? scheduler;
  static const String fullNameRepoParam = 'repo';

  static LuciService _createLuciService(ApiRequestHandler<dynamic> handler) {
    return LuciService(
      buildBucketClient: BuildBucketClient(),
      config: handler.config,
      clientContext: handler.authContext!.clientContext,
    );
  }

  @override
  Future<Body> get() async {
    if (authContext!.clientContext.isDevelopmentEnvironment) {
      // Don't push GitHub status from the local dev server.
      log.fine('GitHub statuses are not pushed from local dev environments');
      return Body.empty;
    }

    final String repo = request!.uri.queryParameters[fullNameRepoParam] ?? 'flutter/flutter';
    final RepositorySlug slug = RepositorySlug.full(repo);
    final DatastoreService datastore = datastoreProvider(config.db);
    final BuildStatusService buildStatusService = buildStatusServiceProvider(datastore);

    final Commit tipOfTreeCommit = Commit(
      sha: config.defaultBranch,
      repository: slug.fullName,
    );
    final SchedulerConfig schedulerConfig = await scheduler!.getSchedulerConfig(tipOfTreeCommit);
    List<LuciBuilder> postsubmitBuilders = await scheduler!.getPostSubmitBuilders(tipOfTreeCommit, schedulerConfig);
    // Filter the builders to only those that can block the tree
    postsubmitBuilders = postsubmitBuilders.where((LuciBuilder builder) => !builder.flaky!).toList();
    final LuciService luciService = luciServiceProvider(this);
    final Map<LuciBuilder, List<LuciTask>> luciTasks = await luciService.getRecentTasks(builders: postsubmitBuilders);

    String status = GithubBuildStatusUpdate.statusSuccess;

    await Future.forEach(luciTasks.entries, (MapEntry<LuciBuilder, List<LuciTask>> luciTask) async {
      final List<LuciTask> tasks = luciTask.value;
      if (tasks.isEmpty) {
        log.fine('No tasks returned for builder: ${luciTask.key.name}');
      }
      final String latestStatus = await buildStatusService.latestLUCIStatus(tasks);
      if (status == GithubBuildStatusUpdate.statusSuccess && latestStatus == GithubBuildStatusUpdate.statusFailure) {
        status = GithubBuildStatusUpdate.statusFailure;
      }
    });
    await _insertBigquery(slug, status, config.defaultBranch, config);
    await _updatePRs(slug, status, datastore);
    log.fine('All the PRs for $repo have been updated with $status');

    return Body.empty;
  }

  Future<void> _updatePRs(RepositorySlug slug, String status, DatastoreService datastore) async {
    final GitHub github = await config.createGitHubClient(slug);
    final List<GithubBuildStatusUpdate> updates = <GithubBuildStatusUpdate>[];
    await for (PullRequest pr in github.pullRequests.list(slug, base: config.defaultBranch)) {
      final GithubBuildStatusUpdate update = await datastore.queryLastStatusUpdate(slug, pr);
      if (update.status != status) {
        log.fine('Updating status of ${slug.fullName}#${pr.number} from ${update.status} to $status');
        final CreateStatus request = CreateStatus(status);
        request.targetUrl = 'https://ci.chromium.org/p/flutter/g/${slug.name}/console';
        request.context = 'luci-${slug.name}';
        if (status != GithubBuildStatusUpdate.statusSuccess) {
          request.description = config.flutterBuildDescription;
        }
        try {
          await github.repositories.createStatus(slug, pr.head!.sha!, request);
          update.status = status;
          update.updates = (update.updates ?? 0) + 1;
          update.updateTimeMillis = DateTime.now().millisecondsSinceEpoch;
          updates.add(update);
        } catch (error) {
          log.severe('Failed to post status update to ${slug.fullName}#${pr.number}: $error');
        }
      }
    }
    await datastore.insert(updates);
  }

  Future<void> _insertBigquery(RepositorySlug slug, String status, String branch, Config config) async {
    const String bigqueryTableName = 'BuildStatus';
    final Map<String, dynamic> bigqueryData = <String, dynamic>{
      'Timestamp': DateTime.now().millisecondsSinceEpoch,
      'Status': status,
      'Branch': branch,
      'Repo': slug.name,
    };
    await insertBigquery(bigqueryTableName, bigqueryData, await config.createTabledataResourceApi());
  }
}
