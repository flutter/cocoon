// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:meta/meta.dart';

import '../datastore/cocoon_config.dart';
import '../foundation/providers.dart';
import '../foundation/typedefs.dart';
import '../foundation/utils.dart';
import '../model/appengine/task.dart';
import '../request_handling/api_request_handler.dart';
import '../request_handling/authentication.dart';
import '../request_handling/body.dart';
import '../service/datastore.dart';
import '../service/luci.dart';

@immutable
class RefreshChromebotStatus extends ApiRequestHandler<Body> {
  const RefreshChromebotStatus(
    Config config,
    AuthenticationProvider authenticationProvider, {
    @visibleForTesting LuciServiceProvider luciServiceProvider,
    @visibleForTesting DatastoreServiceProvider datastoreProvider,
    @visibleForTesting this.branchHttpClientProvider = Providers.freshHttpClient,
    @visibleForTesting this.gitHubBackoffCalculator = twoSecondLinearBackoff,
  })  : luciServiceProvider = luciServiceProvider ?? _createLuciService,
        datastoreProvider = datastoreProvider ?? DatastoreService.defaultProvider,
        assert(branchHttpClientProvider != null),
        assert(gitHubBackoffCalculator != null),
        super(config: config, authenticationProvider: authenticationProvider);

  final LuciServiceProvider luciServiceProvider;
  final DatastoreServiceProvider datastoreProvider;
  final HttpClientProvider branchHttpClientProvider;
  final GitHubBackoffCalculator gitHubBackoffCalculator;

  static LuciService _createLuciService(ApiRequestHandler<dynamic> handler) {
    return LuciService(
      config: handler.config,
      clientContext: handler.authContext.clientContext,
    );
  }

  @override
  Future<Body> get() async {
    final LuciService luciService = luciServiceProvider(this);
    final DatastoreService datastore = datastoreProvider(config.db);
    final Map<BranchLuciBuilder, Map<String, List<LuciTask>>> luciTasks = await luciService.getBranchRecentTasks(
      repo: 'flutter',
      requireTaskName: true,
    );

    for (BranchLuciBuilder branchLuciBuilder in luciTasks.keys) {
      await runTransactionWithRetries(() async {
        await _updateStatus(
          branchLuciBuilder.luciBuilder,
          branchLuciBuilder.branch,
          datastore,
          luciTasks[branchLuciBuilder],
        );
      });
    }
    return Body.empty;
  }

  /// Update chromebot tasks statuses in datastore for [builder],
  /// based on latest [luciTasks] statuses.
  Future<void> _updateStatus(
      LuciBuilder builder, String branch, DatastoreService datastore, Map<String, List<LuciTask>> luciTasksMap) async {
    final List<FullTask> datastoreTasks =
        await datastore.queryRecentTasks(taskName: builder.taskName, branch: branch).toList();

    /// Update [devicelabTask] when first [luciTask] run finishes. There may be
    /// reruns for the same commit and same builder. Update [devicelabTask]
    /// [builderNumberList] when luci rerun happens, and update [devicelabTask]
    /// status when the status of latest luci run changes.
    for (FullTask datastoreTask in datastoreTasks) {
      if (luciTasksMap.containsKey(datastoreTask.commit.sha)) {
        final List<LuciTask> luciTasks = luciTasksMap[datastoreTask.commit.sha];
        final String buildNumberList =
            luciTasks.reversed.map((LuciTask luciTask) => luciTask.buildNumber.toString()).toList().join(',');
        if (buildNumberList != datastoreTask.task.buildNumberList ||
            luciTasks.last.status != datastoreTask.task.status) {
          final Task update = datastoreTask.task;
          update.status = luciTasks.first.status;
          update.buildNumberList = buildNumberList;
          update.builderName = builder.name;
          update.luciBucket = 'luci.flutter.prod';
          if (luciTasks.last.status == Task.statusFailed || luciTasks.last.status == Task.statusSucceeded) {
            update.attempts += 1;
          }
          await datastore.insert(<Task>[update]);
        }
      }
    }
  }
}
