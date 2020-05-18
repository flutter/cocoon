// Copyright 2019 The Chromium Authors. All rights reserved.
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

@immutable
class UpdateTaskStatus extends ApiRequestHandler<UpdateTaskStatusResponse> {
  const UpdateTaskStatus(
    Config config,
    AuthenticationProvider authenticationProvider, {
    @visibleForTesting
        this.datastoreProvider = DatastoreService.defaultProvider,
  }) : super(config: config, authenticationProvider: authenticationProvider);

  final DatastoreServiceProvider datastoreProvider;

  static const String taskKeyParam = 'TaskKey';
  static const String newStatusParam = 'NewStatus';
  static const String resultsParam = 'ResultData';
  static const String scoreKeysParam = 'BenchmarkScoreKeys';

  /// const variables for [BigQuery] operations
  static const String projectId = 'flutter-dashboard';
  static const String dataset = 'cocoon';
  static const String table = 'Task';

  @override
  Future<UpdateTaskStatusResponse> post() async {
    checkRequiredParameters(<String>[taskKeyParam, newStatusParam]);

    final DatastoreService datastore = datastoreProvider(config.db);
    final ClientContext clientContext = authContext.clientContext;
    final KeyHelper keyHelper =
        KeyHelper(applicationContext: clientContext.applicationContext);
    final String newStatus = requestData[newStatusParam] as String;
    final Map<String, dynamic> resultData =
        requestData[resultsParam] as Map<String, dynamic> ??
            const <String, dynamic>{};
    final List<String> scoreKeys =
        (requestData[scoreKeysParam] as List<dynamic>)?.cast<String>() ??
            const <String>[];

    Key taskKey;
    try {
      taskKey = keyHelper.decode(requestData[taskKeyParam] as String);
    } catch (error) {
      throw BadRequestException('Bad task key: ${requestData[taskKeyParam]}');
    }

    if (newStatus != Task.statusSucceeded && newStatus != Task.statusFailed) {
      throw const BadRequestException(
          'NewStatus can be one of "Succeeded", "Failed"');
    }

    final Task task = await datastore.db.lookupValue<Task>(taskKey, orElse: () {
      throw BadRequestException('No such task: ${taskKey.id}');
    });

    final Commit commit =
        await datastore.db.lookupValue<Commit>(task.commitKey, orElse: () {
      throw BadRequestException('No such task: ${task.commitKey}');
    });

    if (newStatus == Task.statusFailed) {
      // Attempt to de-flake the test.
      final int maxRetries = config.maxTaskRetries;
      if (task.attempts >= maxRetries) {
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
      final TimeSeries series =
          await _getOrCreateTimeSeries(task, scoreKey, datastore);
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

  Future<void> _insertBigquery(Commit commit, Task task) async {
    final TabledataResourceApi tabledataResourceApi =
        await config.createTabledataResourceApi();
    final List<Map<String, Object>> requestRows = <Map<String, Object>>[];

    requestRows.add(<String, Object>{
      'json': <String, Object>{
        'ID': 'flutter/flutter/${commit.sha}',
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
    final TableDataInsertAllRequest request =
        TableDataInsertAllRequest.fromJson(
            <String, Object>{'rows': requestRows});

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
    final Key timeSeriesKey =
        Key.emptyKey(Partition(null)).append(TimeSeries, id: id);
    TimeSeries series =
        (await datastore.lookupByKey<TimeSeries>(<Key>[timeSeriesKey])).single;

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
