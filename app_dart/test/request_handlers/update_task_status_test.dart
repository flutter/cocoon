// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_service/src/model/appengine/commit.dart';
import 'package:cocoon_service/src/model/appengine/task.dart';
import 'package:cocoon_service/src/model/appengine/time_series.dart';
import 'package:cocoon_service/src/request_handlers/update_task_status.dart';
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
    final FakeTabledataResourceApi tabledataResourceApi =
        FakeTabledataResourceApi();

    setUp(() {
      final FakeDatastoreDB datastoreDB = FakeDatastoreDB();
      config = FakeConfig(
          dbValue: datastoreDB, tabledataResourceApi: tabledataResourceApi);
      tester = ApiRequestHandlerTester();
      tester.requestData = <String, dynamic>{
        'TaskKey':
            'ag9zfnR2b2xrZXJ0LXRlc3RyWAsSCUNoZWNrbGlzdCI4Zmx1dHRlci9mbHV0dGVyLzdkMDMzNzE2MTBjMDc5NTNhNWRlZjUwZDUwMDA0NTk0MWRlNTE2YjgMCxIEVGFzaxiAgIDg5eGTCAw',
        'NewStatus': 'Succeeded',
        'ResultData': <String, dynamic>{
          '90th_percentile_frame_build_time_millis': 3.12
        },
        'BenchmarkScoreKeys': <String>[
          '90th_percentile_frame_build_time_millis'
        ],
      };
      handler = UpdateTaskStatus(
        config,
        FakeAuthenticationProvider(),
        datastoreProvider: (DatastoreDB db) => DatastoreService(config.db, 5),
      );
    });

    test('updates datastore/bigquery entry for Task/TimeSeriesValue', () async {
      final Commit commit = Commit(
          key: config.db.emptyKey.append(Commit,
              id: 'flutter/flutter/7d03371610c07953a5def50d500045941de516b8'));
      final Task task = Task(
          key: commit.key.append(Task, id: 4590522719010816),
          commitKey: commit.key,
          requiredCapabilities: <String>['ios']);
      config.db.values[commit.key] = commit;
      config.db.values[task.key] = task;

      final TimeSeries timeSeries = TimeSeries(
          key: config.db.emptyKey.append(TimeSeries,
              id: 'cubic_bezier_perf__timeline_summary.90th_percentile_frame_build_time_millis'));
      config.db.values[timeSeries.key] = timeSeries;

      expect(task.status, isNull);

      await tester.post(handler);
      final TableDataList tableDataList =
          await tabledataResourceApi.list('test', 'test', 'test');
      final Map<String, Object> value =
          tableDataList.rows[0].f[0].v as Map<String, Object>;

      expect(task.status, 'Succeeded');

      /// Test for [BigQuery] insert
      expect(tableDataList.totalRows, '1');
      expect(value['RequiredCapabilities'], <String>['ios']);
    });
  });
}
