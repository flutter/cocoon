// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:github/github.dart';
import 'package:meta/meta.dart';

import '../foundation/providers.dart';
import '../foundation/typedefs.dart';
import '../foundation/utils.dart';
import '../model/appengine/commit.dart';
import '../model/appengine/task.dart';
import '../model/ci_yaml/ci_yaml.dart';
import '../request_handling/api_request_handler.dart';
import '../request_handling/authentication.dart';
import '../request_handling/body.dart';
import '../service/buildbucket.dart';
import '../service/config.dart';
import '../service/datastore.dart';
import '../service/logging.dart';
import '../service/luci.dart';
import '../service/luci_build_service.dart';
import '../service/scheduler.dart';

@immutable
class RefreshChromebotStatus extends ApiRequestHandler<Body> {
  const RefreshChromebotStatus(
    Config config,
    AuthenticationProvider authenticationProvider,
    this.luciBuildService, {
    required this.scheduler,
    @visibleForTesting LuciServiceProvider? luciServiceProvider,
    @visibleForTesting DatastoreServiceProvider? datastoreProvider,
    @visibleForTesting this.branchHttpClientProvider = Providers.freshHttpClient,
    @visibleForTesting this.gitHubBackoffCalculator = twoSecondLinearBackoff,
  })  : luciServiceProvider = luciServiceProvider ?? _createLuciService,
        datastoreProvider = datastoreProvider ?? DatastoreService.defaultProvider,
        super(config: config, authenticationProvider: authenticationProvider);

  final LuciBuildService luciBuildService;
  final LuciServiceProvider luciServiceProvider;
  final DatastoreServiceProvider datastoreProvider;
  final HttpClientProvider branchHttpClientProvider;
  final GitHubBackoffCalculator gitHubBackoffCalculator;
  final Scheduler scheduler;

  static const String kRepoParam = 'repo';

  static LuciService _createLuciService(ApiRequestHandler<dynamic> handler) {
    return LuciService(
      buildBucketClient: BuildBucketClient(),
      config: handler.config,
      clientContext: handler.authContext!.clientContext,
    );
  }

  @override
  Future<Body> get() async {
    final String repoName = request!.uri.queryParameters[kRepoParam] ?? Config.flutterSlug.name;
    final RepositorySlug slug = RepositorySlug('flutter', repoName);
    final LuciService luciService = luciServiceProvider(this);
    final DatastoreService datastore = datastoreProvider(config.db);
    final Commit latestCommit = await datastore.queryRecentCommits(limit: 1, slug: slug).single;
    final CiYaml ciYaml = await scheduler.getCiYaml(latestCommit);
    final List<LuciBuilder> postsubmitBuilders = await scheduler.getPostSubmitBuilders(ciYaml);
    final Map<BranchLuciBuilder, Map<String, List<LuciTask>>> luciTasks = await luciService.getBranchRecentTasks(
      builders: postsubmitBuilders,
      requireTaskName: true,
    );
    log.fine('${luciTasks.keys.length} builders retrieved');

    for (BranchLuciBuilder branchLuciBuilder in luciTasks.keys) {
      await runTransactionWithRetries(() async {
        await _updateStatus(
          branchLuciBuilder.luciBuilder!,
          branchLuciBuilder.branch,
          datastore,
          luciTasks[branchLuciBuilder],
          slug,
        );
      });
    }
    return Body.empty;
  }

  /// Update chromebot tasks statuses in datastore for [builder],
  /// based on latest [luciTasks] statuses.
  Future<void> _updateStatus(
    LuciBuilder builder,
    String? branch,
    DatastoreService datastore,
    Map<String, List<LuciTask>>? luciTasksMap,
    RepositorySlug slug,
  ) async {
    final List<FullTask> datastoreTasks = await datastore
        .queryRecentTasks(
          taskName: builder.taskName,
          branch: branch,
          slug: slug,
        )
        .toList();

    /// Update [devicelabTask] when first [luciTask] run finishes. There may be
    /// reruns for the same commit and same builder. Update [devicelabTask]
    /// [builderNumberList] when luci rerun happens, and update [devicelabTask]
    /// status when the status of latest luci run changes.
    for (FullTask datastoreTask in datastoreTasks) {
      final String commitSha = datastoreTask.commit.sha!;
      if (!luciTasksMap!.containsKey(commitSha)) {
        continue;
      }
      final List<LuciTask> luciTasks = luciTasksMap[commitSha]!;
      final String buildNumberList =
          luciTasks.reversed.map((LuciTask luciTask) => luciTask.buildNumber.toString()).toList().join(',');
      final LuciTask latestLuciTask = luciTasks.first;
      if (buildNumberList != datastoreTask.task.buildNumberList || latestLuciTask.status != datastoreTask.task.status) {
        final Task update = datastoreTask.task;
        update.status = latestLuciTask.status;

        /// Use `update.attempts - 1` as the `retries` to skip the initial run.
        if (await luciBuildService.checkRerunBuilder(
            commit: datastoreTask.commit,
            luciTask: latestLuciTask,
            retries: update.attempts! - 1,
            datastore: datastore,
            repo: slug.name,
            isFlaky: datastoreTask.task.isFlaky)) {
          update.status = Task.statusNew;
          update.attempts = (update.attempts ?? 0) + 1;
        }

        update.buildNumberList = buildNumberList;
        update.builderName = builder.name;
        update.luciBucket = builder.flaky ?? false ? 'luci.flutter.staging' : 'luci.flutter.prod';
        await datastore.insert(<Task>[update]);
        // Save luci task record to BigQuery only when task finishes.
        if (update.status == Task.statusFailed || update.status == Task.statusSucceeded) {
          await _insertBigquery(update);
        }
      }
    }
  }

  Future<void> _insertBigquery(Task task) async {
    const String bigqueryTableName = 'Task';
    final Map<String, dynamic> bigqueryData = <String, dynamic>{
      'ID': task.commitKey?.id,
      'CreateTimestamp': task.createTimestamp,
      'StartTimestamp': task.startTimestamp,
      'EndTimestamp': task.endTimestamp,
      'Name': task.name,
      'Attempts': task.attempts,
      'IsFlaky': task.isFlaky,
      'TimeoutInMinutes': task.timeoutInMinutes ?? 0,
      'RequiredCapabilities': task.requiredCapabilities ?? <String>[],
      'ReservedForAgentID': task.reservedForAgentId,
      'StageName': task.stageName ?? 'unknown',
      'Status': task.status,
    };
    await insertBigquery(bigqueryTableName, bigqueryData, await config.createTabledataResourceApi());
  }
}
