// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:gcloud/db.dart';
import 'package:meta/meta.dart';

import '../datastore/cocoon_config.dart';
import '../model/appengine/commit.dart';
import '../model/appengine/task.dart';
import '../request_handling/api_request_handler.dart';
import '../request_handling/authentication.dart';
import '../request_handling/body.dart';

import '../service/luci.dart';

@visibleForTesting
typedef LuciServiceProvider = LuciService Function(RefreshChromebotStatus handler);

@immutable
class RefreshChromebotStatus extends ApiRequestHandler<Body> {
  const RefreshChromebotStatus(
    Config config,
    AuthenticationProvider authenticationProvider, {
    @visibleForTesting LuciServiceProvider luciServiceProvider,
  })  : luciServiceProvider = luciServiceProvider ?? _createLuciService,
        super(config: config, authenticationProvider: authenticationProvider);

  final LuciServiceProvider luciServiceProvider;

  static LuciService _createLuciService(RefreshChromebotStatus handler) {
    return LuciService(
      config: handler.config,
      clientContext: handler.authContext.clientContext,
    );
  }

  @override
  Future<Body> get() async {
    final LuciService luciService = luciServiceProvider(this);
    final Map<LuciBuilder, List<LuciTask>> luciTasks = await luciService.getRecentTasks();

    for (LuciBuilder builder in luciTasks.keys) {
      final List<FullTask> tasks = await getRecentTasksByName(builder.taskName);
      await config.db.withTransaction<void>((Transaction transaction) async {
        try {
          for (FullTask task in tasks) {
            for (LuciTask luciTask in luciTasks[builder]) {
              if (luciTask.commitSha == task.commit.sha) {
                final Task update = task.task;
                update.status = luciTask.status;
                transaction.queueMutations(inserts: <Task>[update]);
              }
            }
          }
          await transaction.commit();
        } catch (error) {
          await transaction.rollback();
          rethrow;
        }
      });
    }

    return Body.empty;
  }

  Future<List<FullTask>> getRecentTasksByName(String taskName) async {
    final List<FullTask> results = <FullTask>[];

    final Query<Commit> recentCommits = config.db.query<Commit>()
      ..limit(20)
      ..order('-timestamp');

    await for (Commit commit in recentCommits.run()) {
      final Query<Task> recentTasks = config.db.query<Task>(ancestorKey: commit.key)
        ..limit(20)
        ..order('-createTimestamp')
        ..filter('name =', taskName);
      results.addAll(
          await recentTasks.run().map<FullTask>((Task task) => FullTask(task, commit)).toList());
    }

    return results;
  }
}
