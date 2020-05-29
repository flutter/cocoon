// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:gcloud/db.dart';
import 'package:meta/meta.dart';

import '../datastore/cocoon_config.dart';
import '../foundation/providers.dart';
import '../foundation/typedefs.dart';
import '../foundation/utils.dart';
import '../model/appengine/commit.dart';
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
    final Map<LuciBuilder, List<LuciTask>> luciTasks =
        await luciService.getRecentTasks(
      repo: 'flutter',
      requireTaskName: true,
    );
    final List<String> branches = await config.flutterBranches;

    for (LuciBuilder luciBuilder in luciTasks.keys) {
      await runTransactionWithRetries(() async {
        await _updateStatus(
          luciBuilder,
          branches,
          datastore,
          luciTasks,
        );
      });
    }
    return Body.empty;
  }

  /// Update chromebot tasks statuses in datastore for [builder],
  /// based on latest [luciTasks] statuses.
  Future<void> _updateStatus(
      LuciBuilder builder,
      List<String> branches,
      DatastoreService datastore,
      Map<LuciBuilder, List<LuciTask>> luciTasks) async {
    for (String branch in branches) {
      final List<FullTask> tasks = await datastore
          .queryRecentTasks(taskName: builder.taskName, branch: branch)
          .toList();
      final List<LuciTask> allLuciTasks = luciTasks[builder];
      final Set<LuciTask> updatedLuciTasks = <LuciTask>{};

      /// Scan both [tasks] and [luciTasks] from old to new, since [luciTasks] may
      /// contain new re-run builds which are not in datastore yet. If matched, then
      /// update accordingly.
      for (int i = tasks.length - 1; i >= 0; i--) {
        final FullTask task = tasks[i];
        for (int j = allLuciTasks.length - 1; j >= 0; j--) {
          final LuciTask luciTask = allLuciTasks[j];
          if (_taskMatched(task, luciTask, branch) &&
              !updatedLuciTasks.contains(luciTask)) {
            final Task update = task.task;
            update.status = luciTask.status;
            update.buildId = luciTask.buildId;
            await datastore.insert(<Task>[update]);
            updatedLuciTasks.add(luciTask);
            break;
          }
        }
      }

      final List<Task> newTasks =
          _getNewTasks(updatedLuciTasks, builder, allLuciTasks, datastore);
      await datastore.insert(newTasks);
    }
  }

  bool _taskMatched(FullTask task, LuciTask luciTask, String branch) {
    return luciTask.commitSha == task.commit.sha &&
        luciTask.ref == 'refs/heads/$branch' &&
        (task.task.buildId == null || task.task.buildId == luciTask.buildId);
  }

  /// Get new re-run luci builds by excluding existing updated ones. /api/
  /// refresh-github-commits always inserts luci tasks for any new commit.
  /// However when people re-run luci builds afterwards, there are no
  /// corresponding tasks in datastore to be updated.
  ///
  /// When there are re-run luci builds, `_getNewTasks` returns them to be
  /// inserted into datastore.
  ///
  /// The best time to add re-run luci builds to datastore is when
  /// re-running them (push rather than pull).
  // TODO(keyonghan): add new tasks to datastore when re-running luci builds,
  // https://github.com/flutter/flutter/issues/58268
  List<Task> _getNewTasks(Set<LuciTask> updatedLuciTasks, LuciBuilder builder,
      List<LuciTask> allLuciTasks, DatastoreService datastore) {
    final List<Task> tasks = <Task>[];
    for (LuciTask luciTask in allLuciTasks) {
      if (!updatedLuciTasks.contains(luciTask) &&
          updatedLuciTasks.any((LuciTask e) =>
              e.commitSha == luciTask.commitSha && e.ref == luciTask.ref)) {
        final String id =
            'flutter/flutter/${luciTask.ref.split('/')[2]}/${luciTask.commitSha}';
        final Key key = datastore.db.emptyKey.append(Commit, id: id);
        tasks.add(Task(
          key: key.append(Task),
          commitKey: key,
          createTimestamp: DateTime.now().millisecondsSinceEpoch,
          startTimestamp: 0,
          endTimestamp: 0,
          name: builder.taskName,
          attempts: 0,
          isFlaky: false,
          timeoutInMinutes: 0,
          requiredCapabilities: <String>['can-update-chromebots'],
          stageName: 'chromebot',
          status: luciTask.status,
          buildId: luciTask.buildId,
        ));
      }
    }
    return tasks;
  }
}
