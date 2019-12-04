// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert' show json;

import 'package:gcloud/db.dart';
import 'package:github/server.dart';
import 'package:meta/meta.dart';

import '../datastore/cocoon_config.dart';
import '../model/appengine/task.dart';
import '../request_handling/api_request_handler.dart';
import '../request_handling/authentication.dart';
import '../request_handling/body.dart';
import '../service/datastore.dart';
import '../service/github_service.dart';

const List<String> _failedStates = <String>['cancelled', 'timed_out', 'action_required', 'failure'];
const List<String> _inProgressStates = <String>['queued', 'in_progress'];

@immutable
class RefreshCirrusStatus extends ApiRequestHandler<RefreshCirrusStatusResponse> {
  const RefreshCirrusStatus(
    Config config,
    AuthenticationProvider authenticationProvider, {
    @visibleForTesting DatastoreServiceProvider datastoreProvider,
  })  : datastoreProvider = datastoreProvider ?? DatastoreService.defaultProvider,
        super(config: config, authenticationProvider: authenticationProvider);

  final DatastoreServiceProvider datastoreProvider;

  @override
  Future<RefreshCirrusStatusResponse> get() async {
    final DatastoreService datastore = datastoreProvider();
    final GitHub github = await config.createGitHubClient();
    final RepositorySlug slug = RepositorySlug('flutter', 'flutter');
    final GithubService githubService = GithubService(github, slug);

    final List<Task> tasks = [];

    await for (FullTask task in datastore.queryRecentTasks(taskName: 'cirrus', commitLimit: 15)) {
      final String sha = task.commit.sha;
      final String existingTaskStatus = task.task.status;
      log.debug('Found Cirrus task for commit $sha with existing status $existingTaskStatus');

      final List<String> statuses = <String>[];
      final List<String> conclusions = <String>[];
      for (dynamic runStatus in await githubService.checkRuns(slug, sha)) {
        final String status = runStatus['status'];
        final String conclusion = runStatus['conclusion'];
        final String taskName = runStatus['name'];
        log.debug('Found Cirrus build status for $sha: $taskName ($status, $conclusion)');
        statuses.add(status);
        conclusions.add(conclusion);
      }

      String newTaskStatus;
      if (conclusions.isEmpty) {
        newTaskStatus = Task.statusNew;
      } else if (conclusions.any(_failedStates.contains)) {
        newTaskStatus = Task.statusFailed;
        task.task.endTimestamp = DateTime.now().millisecondsSinceEpoch;
      } else if (statuses.any(_inProgressStates.contains)) {
        newTaskStatus = Task.statusInProgress;
      } else {
        newTaskStatus = Task.statusSucceeded;
        task.task.endTimestamp = DateTime.now().millisecondsSinceEpoch;
      }

      if (newTaskStatus != existingTaskStatus) {
        task.task.status = newTaskStatus;
        tasks.add(task.task);
        await config.db.withTransaction<void>((Transaction transaction) async {
          transaction.queueMutations(inserts: <Task>[task.task]);
          await transaction.commit();
        });
      }
    }

    return RefreshCirrusStatusResponse(tasks);
  }
}


@immutable
class RefreshCirrusStatusResponse extends JsonBody {
  const RefreshCirrusStatusResponse(this.tasks)
      : assert(tasks != null);

  final List<Task> tasks;

  @override
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'Updated Task Number': tasks.length,
    };
  }
}