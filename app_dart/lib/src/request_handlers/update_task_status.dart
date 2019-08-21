// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:appengine/appengine.dart';
import 'package:gcloud/db.dart';
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

@immutable
class UpdateTaskStatus extends ApiRequestHandler<UpdateTaskStatusResponse> {
  const UpdateTaskStatus(
    Config config,
    AuthenticationProvider authenticationProvider,
  ) : super(config: config, authenticationProvider: authenticationProvider);

  static const String taskKeyParam = 'TaskKey';
  static const String newStatusParam = 'NewStatus';
  static const String resultsParam = 'ResultData';
  static const String scoreKeysParam = 'BenchmarkScoreKeys';

  @override
  Future<UpdateTaskStatusResponse> post() async {
    checkRequiredParameters(<String>[taskKeyParam, newStatusParam]);

    final ClientContext clientContext = authContext.clientContext;
    final KeyHelper keyHelper = KeyHelper(applicationContext: clientContext.applicationContext);
    final String newStatus = requestData[newStatusParam];
    final Map<String, dynamic> resultData = requestData[resultsParam] ?? const <String, dynamic>{};
    final List<String> scoreKeys = requestData[scoreKeysParam]?.cast<String>() ?? const <String>[];

    Key taskKey;
    try {
      taskKey = keyHelper.decode(requestData[taskKeyParam]);
    } catch (error) {
      throw BadRequestException('Bad task key: ${requestData[taskKeyParam]}');
    }

    if (newStatus != Task.statusSucceeded && newStatus != Task.statusFailed) {
      throw const BadRequestException('NewStatus can be one of "Succeeded", "Failed"');
    }

    final Task task = await config.db.lookupValue<Task>(taskKey, orElse: () {
      throw BadRequestException('No such task: ${taskKey.id}');
    });

    final Commit commit = await config.db.lookupValue<Commit>(task.commitKey);

    if (newStatus == Task.statusFailed) {
      // Attempt to de-flake the test.
      final int maxRetries = await config.maxTaskRetries;
      if (task.attempts >= maxRetries) {
        task.status = Task.statusFailed;
        task.reason = 'Task failed on agent';
      } else {
        // This will cause this task to be picked up by an agent again.
        task.status = Task.statusNew;
        task.startTimestamp = 0;
      }
    } else {
      task.status = newStatus;
    }

    await config.db.withTransaction<void>((Transaction transaction) async {
      transaction.queueMutations(inserts: <Task>[task]);
      await transaction.commit();
    });

    // TODO(tvolkert): PushBuildStatusToGithub

    if (newStatus == Task.statusSucceeded && scoreKeys.isNotEmpty) {
      for (String scoreKey in scoreKeys) {
        await config.db.withTransaction<void>((Transaction transaction) async {
          final TimeSeries series = await _getOrCreateTimeSeries(transaction, task, scoreKey);
          final num value = resultData[scoreKey];

          final TimeSeriesValue seriesValue = TimeSeriesValue(
            key: series.key.append(TimeSeriesValue),
            createTimestamp: DateTime.now().millisecondsSinceEpoch,
            revision: commit.sha,
            taskKey: task.key,
            value: value.toDouble(),
          );

          transaction.queueMutations(inserts: <TimeSeriesValue>[seriesValue]);
          await transaction.commit();
        });
      }
    }

    return UpdateTaskStatusResponse(task);
  }

  Future<TimeSeries> _getOrCreateTimeSeries(
    Transaction transaction,
    Task task,
    String scoreKey,
  ) async {
    final String id = '${task.name}.$scoreKey';
    final Key timeSeriesKey = Key.emptyKey(Partition(null)).append(TimeSeries, id: id);
    TimeSeries series = (await transaction.lookup<TimeSeries>(<Key>[timeSeriesKey])).single;

    if (series == null) {
      series = TimeSeries(
        key: timeSeriesKey,
        timeSeriesId: id,
        taskName: task.name,
        label: scoreKey,
        unit: 'ms',
      );
      transaction.queueMutations(inserts: <TimeSeries>[series]);
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
