// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:appengine/appengine.dart';
import 'package:gcloud/db.dart';
import 'package:googleapis/bigquery/v2.dart';
import 'package:meta/meta.dart';

import '../datastore/cocoon_config.dart';
import '../model/appengine/commit.dart';
import '../model/appengine/key_helper.dart';
import '../model/appengine/task.dart';
import '../model/appengine/time_series.dart';
import '../model/appengine/time_series_value.dart';
import '../request_handling/api_request_handler.dart';
import '../request_handling/authentication.dart';
import '../request_handling/body.dart';
import '../request_handling/exceptions.dart';
import '../service/datastore.dart';

/// Endpoint for task runners to update Cocoon with test run information.
///
/// This handler requires (1) task identifier and (2) task status information.
///
/// 1. There are two ways to identify tasks:
///  A. [taskKeyParam] (Legacy Cocoon agents)
///  B. [gitBranchParam], [gitShaParam], [builderNameParam] (LUCI bots)
///
/// 2. Task status information
///  A. Required: [newStatusParam], either [Task.statusSucceeded] or [Task.statusFailed].
///  B. Optional: [resultsParam] and [scoreKeysParam] which hold performance benchmark data.
///
/// If [newStatusParam] is [Task.statusFailed], and the task attempts is less than the
/// retry limit, it will mark it as [Task.statusNew] to allow for the task to be retried.
@immutable
class UpdateTaskStatus extends ApiRequestHandler<UpdateTaskStatusResponse> {
  const UpdateTaskStatus(
    Config config,
    AuthenticationProvider authenticationProvider, {
    @visibleForTesting this.datastoreProvider = DatastoreService.defaultProvider,
  }) : super(config: config, authenticationProvider: authenticationProvider);

  final DatastoreServiceProvider datastoreProvider;

  static const String gitBranchParam = 'CommitBranch';
  static const String gitShaParam = 'CommitSha';
  static const String newStatusParam = 'NewStatus';
  static const String resultsParam = 'ResultData';
  static const String scoreKeysParam = 'BenchmarkScoreKeys';
  static const String taskKeyParam = 'TaskKey';
  static const String builderNameParam = 'BuilderName';

  /// const variables for [BigQuery] operations
  static const String projectId = 'flutter-dashboard';
  static const String dataset = 'cocoon';
  static const String table = 'Task';

  @override
  Future<UpdateTaskStatusResponse> post() async {
    checkRequiredParameters(<String>[newStatusParam]);
    if (requestData.containsKey(taskKeyParam)) {
      checkRequiredParameters(<String>[taskKeyParam]);
    } else {
      checkRequiredParameters(<String>[gitBranchParam, gitShaParam, builderNameParam]);
    }

    final DatastoreService datastore = datastoreProvider(config.db);
    final String newStatus = requestData[newStatusParam] as String;
    final Map<String, dynamic> resultData =
        requestData[resultsParam] as Map<String, dynamic> ?? const <String, dynamic>{};
    final List<String> scoreKeys = (requestData[scoreKeysParam] as List<dynamic>)?.cast<String>() ?? const <String>[];

    if (newStatus != Task.statusSucceeded && newStatus != Task.statusFailed) {
      throw const BadRequestException('NewStatus can be one of "Succeeded", "Failed"');
    }

    final Task task = await _getTask(datastore);

    final Commit commit = await datastore.db.lookupValue<Commit>(task.commitKey, orElse: () {
      throw BadRequestException('No such task: ${task.commitKey}');
    });

    if (newStatus == Task.statusFailed) {
      // Attempt to de-flake the test.
      final int maxRetries = config.maxTaskRetries;
      if (task.attempts >= maxRetries || task.isFlaky) {
        task.status = Task.statusFailed;
        task.reason = 'Task failed on agent';
        task.endTimestamp = DateTime.now().millisecondsSinceEpoch;
      } else {
        // This will cause this task to be picked up by an agent again.
        task.status = Task.statusNew;
        task.startTimestamp = 0;
      }
    } else {
      task.status = newStatus;
      task.endTimestamp = DateTime.now().millisecondsSinceEpoch;
    }
    await datastore.insert(<Task>[task]);
    if (task.endTimestamp > 0) {
      await _insertBigquery(commit, task);
    }

    // TODO(tvolkert): PushBuildStatusToGithub
    for (String scoreKey in scoreKeys) {
      final TimeSeries series = await _getOrCreateTimeSeries(task, scoreKey, datastore);
      final num value = resultData[scoreKey] as num;

      final TimeSeriesValue seriesValue = TimeSeriesValue(
        key: series.key.append(TimeSeriesValue),
        createTimestamp: DateTime.now().millisecondsSinceEpoch,
        revision: commit.sha,
        branch: commit.branch,
        taskKey: task.key,
        value: value.toDouble(),
      );
      await datastore.insert(<TimeSeriesValue>[seriesValue]);
    }
    return UpdateTaskStatusResponse(task);
  }

  /// Retrieve [Task] to update from [DatastoreService].
  Future<Task> _getTask(DatastoreService datastore) async {
    if (requestData.containsKey(taskKeyParam)) {
      return _getTaskFromEncodedKey(datastore);
    }

    return _getTaskFromNamedParams(datastore);
  }

  /// Retrieve [Task] from [DatastoreService] when given [taskKeyParam].
  ///
  /// This is used for Devicelab test runs from Cocoon agents. The Cocoon agent is scheduled tasks
  /// from the Cocoon backend and is aware of the Datastore task key.
  ///
  // TODO(chillers): Remove this when Devicelab is migrated to LUCI. https://github.com/flutter/flutter/projects/151
  Future<Task> _getTaskFromEncodedKey(DatastoreService datastore) {
    final ClientContext clientContext = authContext.clientContext;
    final KeyHelper keyHelper = KeyHelper(applicationContext: clientContext.applicationContext);
    final Key taskKey = keyHelper.decode(requestData[taskKeyParam] as String);
    return datastore.db.lookupValue<Task>(taskKey, orElse: () {
      throw BadRequestException('No such task: ${taskKey.id}');
    });
  }

  /// Retrieve [Task] from [DatastoreService] when given [gitShaParam], [gitBranchParam], and [builderNameParam].
  ///
  /// This is used when the DeviceLab test runner is uploading results to Cocoon for runs on LUCI.
  /// LUCI does not know the [Key] assigned to task when scheduling the build, but Cocoon can
  /// lookup the task based on these key values.
  ///
  /// To lookup the value, we construct the ancestor key, which corresponds to the [Commit].
  /// Then we query the tasks with that ancestor key and search for the one that matches the builder name.
  Future<Task> _getTaskFromNamedParams(DatastoreService datastore) async {
    final Key commitKey = await _constructCommitKey(datastore);

    final String builderName = requestData[builderNameParam] as String;
    final Query<Task> query = datastore.db.query<Task>(ancestorKey: commitKey);
    final List<Task> initialTasks = await query.run().toList();
    log.debug('Found ${initialTasks.length} tasks for commit');
    final List<Task> tasks = <Task>[];
    log.debug('Searching for task with builderName=$builderName');
    for (Task task in initialTasks) {
      if (task.builderName == builderName) {
        tasks.add(task);
      }
    }

    if (tasks.length != 1) {
      log.error('Found ${tasks.length} entries for builder $builderName');
      throw InternalServerError('Expected to find 1 task for $builderName, but found ${tasks.length}');
    }

    return tasks.first;
  }

  /// Construct the Datastore key for [Commit] that is the ancestor to this [Task].
  ///
  /// Throws [BadRequestException] if the given git branch does not exist in [CocoonConfig].
  Future<Key> _constructCommitKey(DatastoreService datastore) async {
    final String gitBranch = requestData[gitBranchParam] as String;
    final List<String> flutterBranches = await config.flutterBranches;
    if (!flutterBranches.contains(gitBranch)) {
      throw BadRequestException('Failed to find flutter/flutter branch: $gitBranch\n'
          'If this is a valid branch, '
          'see https://github.com/flutter/cocoon/tree/master/app_dart#branching-support-for-flutter-repo');
    }
    final String id = 'flutter/flutter/$gitBranch/${requestData[gitShaParam]}';
    final Key commitKey = datastore.db.emptyKey.append(Commit, id: id);
    log.debug('Constructed commit key=$id');
    // Return the official key from Datastore for task lookups.
    final Commit commit = await config.db.lookupValue<Commit>(commitKey, orElse: () {
      throw BadRequestException('No such commit: $id');
    });
    return commit.key;
  }

  Future<void> _insertBigquery(Commit commit, Task task) async {
    final TabledataResourceApi tabledataResourceApi = await config.createTabledataResourceApi();
    final List<Map<String, Object>> requestRows = <Map<String, Object>>[];

    requestRows.add(<String, Object>{
      'json': <String, Object>{
        'ID': 'flutter/flutter/${commit.branch}/${commit.sha}',
        'CreateTimestamp': task.createTimestamp,
        'StartTimestamp': task.startTimestamp,
        'EndTimestamp': task.endTimestamp,
        'Name': task.name,
        'Attempts': task.attempts,
        'IsFlaky': task.isFlaky,
        'TimeoutInMinutes': task.timeoutInMinutes,
        'RequiredCapabilities': task.requiredCapabilities,
        'ReservedForAgentID': task.reservedForAgentId,
        'StageName': task.stageName,
        'Status': task.status,
      },
    });

    /// [rows] to be inserted to [BigQuery]
    final TableDataInsertAllRequest request = TableDataInsertAllRequest.fromJson(<String, Object>{'rows': requestRows});

    try {
      await tabledataResourceApi.insertAll(request, projectId, dataset, table);
    } on ApiRequestError {
      log.warning('Failed to add ${task.name} to BigQuery: $ApiRequestError');
    }
  }

  Future<TimeSeries> _getOrCreateTimeSeries(
    Task task,
    String scoreKey,
    DatastoreService datastore,
  ) async {
    final String id = '${task.name}.$scoreKey';
    final Key timeSeriesKey = Key.emptyKey(Partition(null)).append(TimeSeries, id: id);
    TimeSeries series = (await datastore.lookupByKey<TimeSeries>(<Key>[timeSeriesKey])).single;

    if (series == null) {
      series = TimeSeries(
        key: timeSeriesKey,
        timeSeriesId: id,
        taskName: task.name,
        label: scoreKey,
        unit: 'ms',
      );
      await datastore.insert(<TimeSeries>[series]);
    }

    return series;
  }
}

@immutable
class UpdateTaskStatusResponse extends JsonBody {
  const UpdateTaskStatusResponse(this.task) : assert(task != null);

  final Task task;

  @override
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'Name': task.name,
      'Status': task.status,
    };
  }
}
