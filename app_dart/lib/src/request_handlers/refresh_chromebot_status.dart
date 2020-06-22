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
    @visibleForTesting
        this.branchHttpClientProvider = Providers.freshHttpClient,
    @visibleForTesting this.gitHubBackoffCalculator = twoSecondLinearBackoff,
  })  : luciServiceProvider = luciServiceProvider ?? _createLuciService,
        datastoreProvider =
            datastoreProvider ?? DatastoreService.defaultProvider,
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
    final Map<BranchLuciBuilder, Map<String, List<LuciTask>>> luciTasks =
        await luciService.getBranchRecentTasks(
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
  Future<void> _updateStatus(LuciBuilder builder, String branch,
      DatastoreService datastore, Map<String, List<LuciTask>> luciTasks) async {
    final List<FullTask> datastoreTasks = await datastore
        .queryRecentTasks(taskName: builder.taskName, branch: branch)
        .toList();
    final Set<LuciTask> updatedLuciTasks = <LuciTask>{};

    /// Since [datastoreTasks] may contain new re-run builds which are not scheduled yet in luci,
    /// there may not be a strict one-to-one mapping. Therefore we scan both [datastoreTasks]
    /// and [luciTasks] from old to new. If matched, then update accordingly.
    for (FullTask datastoreTask in datastoreTasks.reversed) {
      if (!luciTasks.containsKey(datastoreTask.commit.sha)) {
        continue;
      }
      for (LuciTask luciTask in luciTasks[datastoreTask.commit.sha].reversed) {
        if (!updatedLuciTasks.contains(luciTask) &&
            _buildNumberMatched(datastoreTask, luciTask)) {
          final Task update = datastoreTask.task;
          update.status = luciTask.status;
          update.buildNumber = luciTask.buildNumber;
          update.builderName = builder.name;
          update.luciPoolName = 'luci.flutter.prod';
          await datastore.insert(<Task>[update]);
          updatedLuciTasks.add(luciTask);
          break;
        }
      }
    }
  }

  bool _buildNumberMatched(FullTask task, LuciTask luciTask) {
    return task.task.buildNumber == null ||
        task.task.buildNumber == luciTask.buildNumber;
  }
}
