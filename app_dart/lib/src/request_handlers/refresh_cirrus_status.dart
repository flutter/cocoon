// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:gcloud/db.dart';
import 'package:googleapis/bigquery/v2.dart';
import 'package:meta/meta.dart';

import '../datastore/cocoon_config.dart';
import '../model/appengine/task.dart';
import '../request_handling/api_request_handler.dart';
import '../request_handling/authentication.dart';
import '../request_handling/body.dart';
import '../service/datastore.dart';
import '../service/github_service.dart';

const List<String> _failedStates = <String>[
  'cancelled',
  'timed_out',
  'action_required',
  'failure'
];
const List<String> _inProgressStates = <String>['queued', 'in_progress'];

@immutable
class RefreshCirrusStatus extends ApiRequestHandler<Body> {
  const RefreshCirrusStatus(
    Config config,
    AuthenticationProvider authenticationProvider, {
    @visibleForTesting DatastoreServiceProvider datastoreProvider,
  })  : datastoreProvider =
            datastoreProvider ?? DatastoreService.defaultProvider,
        super(config: config, authenticationProvider: authenticationProvider);

  final DatastoreServiceProvider datastoreProvider;

  @override
  Future<Body> get() async {
    final DatastoreService datastore = datastoreProvider();
    final GithubService githubService = await config.createGithubService();

    await for (FullTask task
        in datastore.queryRecentTasks(taskName: 'cirrus', commitLimit: 15)) {
      final String sha = task.commit.sha;
      final String existingTaskStatus = task.task.status;
      log.debug(
          'Found Cirrus task for commit $sha with existing status $existingTaskStatus');

      final List<String> statuses = <String>[];
      final List<String> conclusions = <String>[];

      for (dynamic runStatus in await githubService.checkRuns(sha)) {
        final String status = runStatus['status'];
        final String conclusion = runStatus['conclusion'];
        final String taskName = runStatus['name'];
        log.debug(
            'Found Cirrus build status for $sha: $taskName ($status, $conclusion)');
        statuses.add(status);
        conclusions.add(conclusion);
      }

      String newTaskStatus;
      if (conclusions.isEmpty) {
        newTaskStatus = Task.statusNew;
      } else if (conclusions.any(_failedStates.contains)) {
        newTaskStatus = Task.statusFailed;
      } else if (statuses.any(_inProgressStates.contains)) {
        newTaskStatus = Task.statusInProgress;
        if (existingTaskStatus != Task.statusInProgress) {
          task.task.startTimestamp = DateTime.now().millisecondsSinceEpoch;
        }
      } else {
        newTaskStatus = Task.statusSucceeded;
      }

      if (newTaskStatus != existingTaskStatus) {
        task.task.status = newTaskStatus;
        if (newTaskStatus == Task.statusSucceeded ||
            newTaskStatus == Task.statusFailed) {
          task.task.endTimestamp = DateTime.now().millisecondsSinceEpoch;
          // Insert task status to bigquery.
          await _insertBigquery(task);
        }
        await config.db.withTransaction<void>((Transaction transaction) async {
          transaction.queueMutations(inserts: <Task>[task.task]);
          await transaction.commit();
        });
      }
    }

    return Body.empty;
  }

  Future<void> _insertBigquery(FullTask task) async {
    // Define const variables for [BigQuery] operations.
    const String projectId = 'flutter-dashboard';
    const String dataset = 'cocoon';
    const String table = 'Task';

    final TabledataResourceApi tabledataResourceApi =
        await config.createTabledataResourceApi();
    final List<Map<String, Object>> requestRows = <Map<String, Object>>[];

    requestRows.add(<String, Object>{
      'json': <String, Object>{
        'ID': 'flutter/flutter/${task.commit.sha}',
        'CreateTimestamp': task.task.createTimestamp,
        'StartTimestamp': task.task.startTimestamp,
        'EndTimestamp': task.task.endTimestamp,
        'Name': task.task.name,
        'Attempts': task.task.attempts,
        'IsFlaky': task.task.isFlaky,
        'TimeoutInMinutes': task.task.timeoutInMinutes,
        'RequiredCapabilities': task.task.requiredCapabilities,
        'StageName': task.task.stageName,
        'Status': task.task.status,
      },
    });

    /// Obtain [rows] to be inserted to [BigQuery].
    final TableDataInsertAllRequest request =
        TableDataInsertAllRequest.fromJson(
            <String, Object>{'rows': requestRows});

    try {
      await tabledataResourceApi.insertAll(request, projectId, dataset, table);
    } catch (ApiRequestError) {
      log.warning(
          'Failed to add ${task.task.name} to BigQuery: $ApiRequestError');
    }
  }
}
