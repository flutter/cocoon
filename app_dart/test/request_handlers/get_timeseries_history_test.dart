// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_service/src/model/appengine/commit.dart';
import 'package:cocoon_service/src/model/appengine/time_series.dart';
import 'package:cocoon_service/src/model/appengine/time_series_value.dart';
import 'package:cocoon_service/src/request_handlers/get_timeseries_history.dart';
import 'package:cocoon_service/src/service/datastore.dart';
import 'package:gcloud/db.dart';
import 'package:test/test.dart';

import '../src/datastore/fake_cocoon_config.dart';
import '../src/datastore/fake_datastore.dart';
import '../src/request_handling/no_auth_request_handler_tester.dart';

void main() {
  group('GetTimeSeriesHistory', () {
    FakeConfig config;
    FakeDatastoreDB db;
    GetTimeSeriesHistory handler;
    NoAuthRequestHandlerTester tester;

    setUp(() {
      db = FakeDatastoreDB();
      config = FakeConfig(dbValue: db);
      tester = NoAuthRequestHandlerTester();
      tester.requestData = <String, dynamic>{
        'TimeSeriesKey':
            'ahNzfmZsdXR0ZXItZGFzaGJvYXJkcjULEgpUaW1lc2VyaWVzIiVhbmFseXplcl9iZW5jaG1hcmsuZmx1dHRlcl9yZXBvX2JhdGNoDA',
      };
      handler = GetTimeSeriesHistory(
        config,
        datastoreProvider: (DatastoreDB db) => DatastoreService(config.db, 5),
      );
    });

    test('return 0 when no commit exist', () async {
      final TimeSeries timeSeries = TimeSeries(
          key: config.db.emptyKey
              .append(TimeSeries, id: 'analyzer_benchmark.flutter_repo_batch'));
      config.db.values[timeSeries.key] = timeSeries;

      final Commit commit = Commit(sha: 'abc', timestamp: 4);
      final List<Commit> reportedCommits = <Commit>[
        commit,
      ];

      final TimeSeriesValue timeSeriesValue =
          TimeSeriesValue(value: 4.5, createTimestamp: 5, revision: 'def');
      final List<TimeSeriesValue> reportedTimeSeriesValues = <TimeSeriesValue>[
        timeSeriesValue,
      ];

      db.addOnQuery<Commit>((Iterable<Commit> commits) => reportedCommits);
      db.addOnQuery<TimeSeriesValue>(
          (Iterable<TimeSeriesValue> agents) => reportedTimeSeriesValues);
      final GetTimeSeriesHistoryResponse response = await tester.post(handler);

      expect(response.timeSeriesValues.first.value, 0);
    });

    test('return timeseries value when commit exists', () async {
      final TimeSeries timeSeries = TimeSeries(
          key: config.db.emptyKey
              .append(TimeSeries, id: 'analyzer_benchmark.flutter_repo_batch'));
      config.db.values[timeSeries.key] = timeSeries;

      final Commit commit = Commit(sha: 'abc', timestamp: 4, branch: 'test');
      final List<Commit> reportedCommits = <Commit>[
        commit,
      ];

      final TimeSeriesValue timeSeriesValue =
          TimeSeriesValue(value: 4.5, createTimestamp: 5, revision: 'abc');
      final List<TimeSeriesValue> reportedTimeSeriesValues = <TimeSeriesValue>[
        timeSeriesValue,
      ];

      db.addOnQuery<Commit>((Iterable<Commit> commits) => reportedCommits);
      db.addOnQuery<TimeSeriesValue>(
          (Iterable<TimeSeriesValue> agents) => reportedTimeSeriesValues);
      final GetTimeSeriesHistoryResponse response = await tester.post(handler);

      expect(response.timeSeriesValues.first.value, 4.5);
    });

    test('return timeseries values when multiple commits exist', () async {
      final TimeSeries timeSeries = TimeSeries(
          key: config.db.emptyKey
              .append(TimeSeries, id: 'analyzer_benchmark.flutter_repo_batch'));
      config.db.values[timeSeries.key] = timeSeries;

      final Commit commit1 = Commit(sha: 'abc', timestamp: 4);
      final Commit commit2 = Commit(sha: 'def', timestamp: 5);
      final List<Commit> reportedCommits = <Commit>[commit1, commit2];

      final TimeSeriesValue timeSeriesValue1 =
          TimeSeriesValue(value: 3.5, createTimestamp: 5, revision: 'abc');
      final TimeSeriesValue timeSeriesValue2 =
          TimeSeriesValue(value: 4.5, createTimestamp: 5, revision: 'def');
      final List<TimeSeriesValue> reportedTimeSeriesValues = <TimeSeriesValue>[
        timeSeriesValue1,
        timeSeriesValue2
      ];

      db.addOnQuery<Commit>((Iterable<Commit> commits) => reportedCommits);
      db.addOnQuery<TimeSeriesValue>(
          (Iterable<TimeSeriesValue> agents) => reportedTimeSeriesValues);
      final GetTimeSeriesHistoryResponse response = await tester.post(handler);

      expect(response.timeSeriesValues.first.value, 3.5);
      expect(response.timeSeriesValues.last.value, 4.5);
    });
  });
}
