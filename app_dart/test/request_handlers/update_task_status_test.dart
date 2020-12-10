// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_service/src/model/appengine/commit.dart';
import 'package:cocoon_service/src/model/appengine/task.dart';
import 'package:cocoon_service/src/model/appengine/time_series.dart';
import 'package:cocoon_service/src/request_handlers/update_task_status.dart';
import 'package:cocoon_service/src/request_handling/exceptions.dart';
import 'package:cocoon_service/src/service/datastore.dart';
import 'package:gcloud/db.dart';
import 'package:googleapis/bigquery/v2.dart';
import 'package:test/test.dart';

import '../src/bigquery/fake_tabledata_resource.dart';
import '../src/datastore/fake_cocoon_config.dart';
import '../src/datastore/fake_datastore.dart';
import '../src/request_handling/api_request_handler_tester.dart';
import '../src/request_handling/fake_authentication.dart';

void main() {
  group('UpdateTaskStatus', () {
    FakeConfig config;
    ApiRequestHandlerTester tester;
    UpdateTaskStatus handler;
    final FakeTabledataResourceApi tabledataResourceApi = FakeTabledataResourceApi();

    Commit commit;
    const String commitSha = '78cbfbff4267643bb1913bc820f5ce8a3e591b40';
    const int taskId = 4506830800027648;
    const String taskKeyEncoded =
        'ahNzfmZsdXR0ZXItZGFzaGJvYXJkcl8LEglDaGVja2xpc3QiP2ZsdXR0ZXIvZmx1dHRlci9tYXN0ZXIvNzhjYmZiZmY0MjY3NjQzYmIxOTEzYmM4MjBmNWNlOGEzZTU5MWI0MAwLEgRUYXNrGICAmIeF3oAIDA';

    setUp(() {
      final FakeDatastoreDB datastoreDB = FakeDatastoreDB();
      config = FakeConfig(
        dbValue: datastoreDB,
        flutterBranchesValue: <String>['master'],
        tabledataResourceApi: tabledataResourceApi,
        maxTaskRetriesValue: 2,
      );
      tester = ApiRequestHandlerTester();
      tester.requestData = <String, dynamic>{
        'TaskKey': taskKeyEncoded,
        'NewStatus': 'Succeeded',
        'ResultData': <String, dynamic>{'90th_percentile_frame_build_time_millis': 3.12},
        'BenchmarkScoreKeys': <String>['90th_percentile_frame_build_time_millis'],
      };
      handler = UpdateTaskStatus(
        config,
        FakeAuthenticationProvider(),
        datastoreProvider: (DatastoreDB db) => DatastoreService(config.db, 5),
      );
      commit = Commit(
        key: config.db.emptyKey.append(Commit, id: 'flutter/flutter/master/$commitSha'),
        sha: commitSha,
      );
    });

    test('updates datastore/bigquery entry for Task/TimeSeriesValue', () async {
      final Task task =
          Task(key: commit.key.append(Task, id: taskId), commitKey: commit.key, requiredCapabilities: <String>['ios']);
      config.db.values[commit.key] = commit;
      config.db.values[task.key] = task;

      final TimeSeries timeSeries = TimeSeries(
          key: config.db.emptyKey
              .append(TimeSeries, id: 'cubic_bezier_perf__timeline_summary.90th_percentile_frame_build_time_millis'));
      config.db.values[timeSeries.key] = timeSeries;

      expect(task.status, isNull);

      await tester.post(handler);
      final TableDataList tableDataList = await tabledataResourceApi.list('test', 'test', 'test');
      final Map<String, Object> value = tableDataList.rows[0].f[0].v as Map<String, Object>;

      expect(task.status, 'Succeeded');

      /// Test for [BigQuery] insert
      expect(tableDataList.totalRows, '1');
      expect(value['RequiredCapabilities'], <String>['ios']);
    });

    test('failed tasks are automatically retried', () async {
      final Task task = Task(
        key: commit.key.append(Task, id: taskId),
        attempts: 1,
        commitKey: commit.key,
        isFlaky: false,
        requiredCapabilities: <String>['ios'],
      );
      config.db.values[commit.key] = commit;
      config.db.values[task.key] = task;
      tester.requestData = <String, dynamic>{
        'TaskKey': taskKeyEncoded,
        'NewStatus': 'Failed',
      };

      await tester.post(handler);

      expect(task.status, 'New');
    });

    test('flaky failed tasks are not automatically retried', () async {
      final Task task = Task(
        key: commit.key.append(Task, id: taskId),
        attempts: 1,
        commitKey: commit.key,
        isFlaky: true,
        requiredCapabilities: <String>['ios'],
      );
      config.db.values[commit.key] = commit;
      config.db.values[task.key] = task;
      tester.requestData = <String, dynamic>{
        'TaskKey': taskKeyEncoded,
        'NewStatus': 'Failed',
      };

      await tester.post(handler);

      expect(task.status, 'Failed');
      expect(task.attempts, 1);
    });

    test('task name requests can update tasks', () async {
      final Task task = Task(
        key: commit.key.append(Task, id: taskId),
        name: 'integration_ui_ios',
        builderName: 'linux_integration_ui_ios',
        attempts: 1,
        isFlaky: true, // mark flaky so it doesn't get auto-retried
        commitKey: commit.key,
      );
      config.db.values[commit.key] = commit;
      config.db.values[task.key] = task;
      tester.requestData = <String, dynamic>{
        UpdateTaskStatus.gitBranchParam: 'master',
        UpdateTaskStatus.gitShaParam: commitSha,
        UpdateTaskStatus.newStatusParam: 'Failed',
        UpdateTaskStatus.builderNameParam: 'linux_integration_ui_ios',
      };

      await tester.post(handler);

      expect(task.status, 'Failed');
      expect(task.attempts, 1);
    });

    test('task name requests when task does not exists returns exception', () async {
      tester.requestData = <String, dynamic>{
        UpdateTaskStatus.gitBranchParam: 'master',
        UpdateTaskStatus.gitShaParam: commitSha,
        UpdateTaskStatus.newStatusParam: 'Failed',
        UpdateTaskStatus.builderNameParam: 'linux_integration_ui_ios',
      };
      expect(tester.post(handler), throwsA(isA<BadRequestException>()));
    });

    test('task name request updates when there is both a Cocoon and Luci task', () async {
      config.db.values[commit.key] = commit;
      final Task cocoonTask = Task(
        key: commit.key.append(Task, id: taskId),
        name: 'integration_ui_ios',
        attempts: 0,
        isFlaky: true, // mark flaky so it doesn't get auto-retried
        commitKey: commit.key,
        status: Task.statusNew,
      );
      config.db.values[cocoonTask.key] = cocoonTask;
      final Task luciTask = Task(
        key: commit.key.append(Task, id: taskId),
        name: 'integration_ui_ios',
        builderName: 'linux_integration_ui_ios',
        attempts: 1,
        isFlaky: true, // mark flaky so it doesn't get auto-retried
        commitKey: commit.key,
      );
      config.db.values[luciTask.key] = luciTask;
      tester.requestData = <String, dynamic>{
        UpdateTaskStatus.gitBranchParam: 'master',
        UpdateTaskStatus.gitShaParam: commitSha,
        UpdateTaskStatus.newStatusParam: 'Failed',
        UpdateTaskStatus.builderNameParam: 'linux_integration_ui_ios',
      };

      await tester.post(handler);

      expect(luciTask.status, Task.statusFailed);
      expect(luciTask.attempts, 1);

      expect(cocoonTask.status, Task.statusNew);
      expect(cocoonTask.attempts, 0);
    });

    test('task name request fails when there is only a Cocoon task', () async {
      config.db.values[commit.key] = commit;
      final Task cocoonTask = Task(
        key: commit.key.append(Task, id: taskId),
        name: 'integration_ui_ios',
        attempts: 0,
        isFlaky: true, // mark flaky so it doesn't get auto-retried
        commitKey: commit.key,
        status: Task.statusNew,
      );
      config.db.values[cocoonTask.key] = cocoonTask;
      tester.requestData = <String, dynamic>{
        UpdateTaskStatus.gitBranchParam: 'master',
        UpdateTaskStatus.gitShaParam: commitSha,
        UpdateTaskStatus.newStatusParam: 'Failed',
        UpdateTaskStatus.builderNameParam: 'linux_integration_ui_ios',
      };
      expect(tester.post(handler), throwsA(isA<InternalServerError>()));
    });

    test('task name request fails with unknown branches', () async {
      tester.requestData = <String, dynamic>{
        UpdateTaskStatus.gitBranchParam: 'release-abc',
        UpdateTaskStatus.gitShaParam: commitSha,
        UpdateTaskStatus.newStatusParam: 'Failed',
        UpdateTaskStatus.builderNameParam: 'linux_integration_ui_ios',
      };
      expect(tester.post(handler), throwsA(isA<BadRequestException>()));
    });
  });
}
