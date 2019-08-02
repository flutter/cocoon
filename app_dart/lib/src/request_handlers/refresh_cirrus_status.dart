// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:gcloud/db.dart';
import 'package:github/server.dart';
import 'package:meta/meta.dart';

import '../datastore/cocoon_config.dart';
import '../model/appengine/commit.dart';
import '../model/appengine/task.dart';
import '../request_handling/api_request_handler.dart';
import '../request_handling/authentication.dart';
import '../request_handling/body.dart';

const List<String> _failedStates = <String>['error', 'failure'];
const List<String> _inProgressStates = <String>['pending'];

@immutable
class RefreshCirrusStatus extends ApiRequestHandler<Body> {
  const RefreshCirrusStatus(Config config, AuthenticationProvider authenticationProvider)
      : super(config: config, authenticationProvider: authenticationProvider);

  @override
  Future<Body> get() async {
    final GitHub github = await config.createGitHubClient();
    final RepositorySlug slug = RepositorySlug('flutter', 'flutter');

    final List<FullTask> cirrusTasks = await getRecentTasksByName('cirrus');
    for (FullTask task in cirrusTasks) {
      final String sha = task.commit.sha;
      final Map<String, RepositoryStatus> mostRecentStatuses = <String, RepositoryStatus>{};
      await for (RepositoryStatus status in github.repositories.listStatuses(slug, sha)) {
        final bool isCirrusStatus = status.targetUrl.contains('cirrus-ci.com');
        if (isCirrusStatus) {
          final String taskName = status.context;
          final RepositoryStatus existingStatus = mostRecentStatuses[taskName];
          if (existingStatus == null || existingStatus.updatedAt.isBefore(status.updatedAt)) {
            mostRecentStatuses[taskName] = status;
          }
        }
      }

      await config.db.withTransaction<void>((Transaction transaction) async {
        try {
          if (mostRecentStatuses.isEmpty) {
            task.task.status = Task.statusNew;
          } else if (mostRecentStatuses.values.any(_failedStates.contains)) {
            task.task.status = Task.statusFailed;
          } else if (mostRecentStatuses.values.any(_inProgressStates.contains)) {
            task.task.status = Task.statusInProgress;
          } else {
            task.task.status = Task.statusSucceeded;
          }
          transaction.queueMutations(inserts: <Task>[task.task]);
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
