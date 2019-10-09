// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_service/src/model/appengine/commit.dart';
import 'package:cocoon_service/src/model/appengine/time_series.dart';
import 'package:cocoon_service/src/model/appengine/time_series_value.dart';
import 'package:cocoon_service/src/request_handlers/get_timeseries_history.dart';
import 'package:cocoon_service/src/service/datastore.dart';
import 'package:test/test.dart';

import '../src/datastore/fake_cocoon_config.dart';
import '../src/datastore/fake_datastore.dart';
import '../src/request_handling/regular_request_handler_tester.dart';

void main() {
  group('GetTimeSeriesHistory', () {
    FakeConfig config;
    FakeDatastoreDB db;
    GetTimeSeriesHistory handler;
    RegularRequestHandlerTester tester;

    setUp(() {
      config = FakeConfig();
      db = FakeDatastoreDB();
      tester = RegularRequestHandlerTester();
      tester.requestData = <String, dynamic>{
        'TimeSeriesKey':
            'ahNzfmZsdXR0ZXItZGFzaGJvYXJkcjULEgpUaW1lc2VyaWVzIiVhbmFseXplcl9iZW5jaG1hcmsuZmx1dHRlcl9yZXBvX2JhdGNoDA',
      };
      handler = GetTimeSeriesHistory(
        config,
        datastoreProvider: () => DatastoreService(db: db),
      );
    });

    test('get timeseries value based on timeseries key', () async {
      final TimeSeries timeSeries =
          TimeSeries(key: config.db.emptyKey.append(TimeSeries, id: 'analyzer_benchmark.flutter_repo_batch'));
      config.db.values[timeSeries.key] = timeSeries;
    
      final Commit commit = Commit(sha: 'abc', timestamp: 4);
      final List<Commit> reportedCommits = <Commit>[
        commit,
      ];

      final TimeSeriesValue timeSeriesValue = TimeSeriesValue(value: 4.5, createTimestamp: 5, revision: 'abc');
      final List<TimeSeriesValue> reportedTimeSeriesValues = <TimeSeriesValue>[
        timeSeriesValue,
      ];

      db.addOnQuery<Commit>((Iterable<Commit> commits) => reportedCommits);
      db.addOnQuery<TimeSeriesValue>((Iterable<TimeSeriesValue> agents) => reportedTimeSeriesValues);
      final GetTimeSeriesHistoryResponse response = await tester.post(handler);

      expect(response.timeSeriesValues.first.value, 4.5);
    });
  });
}
