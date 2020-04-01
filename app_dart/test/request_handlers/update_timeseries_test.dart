// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_service/src/request_handlers/update_timeseries.dart';
import 'package:cocoon_service/src/model/appengine/time_series.dart';
import 'package:cocoon_service/src/service/datastore.dart';
import 'package:gcloud/db.dart';
import 'package:test/test.dart';

import '../src/datastore/fake_cocoon_config.dart';
import '../src/request_handling/api_request_handler_tester.dart';
import '../src/request_handling/fake_authentication.dart';

void main() {
  group('UpdateTimeSeries', () {
    FakeConfig config;
    ApiRequestHandlerTester tester;
    UpdateTimeSeries handler;

    setUp(() {
      config = FakeConfig();
      tester = ApiRequestHandlerTester();
      tester.requestData = <String, dynamic>{
        'TimeSeriesKey':
            'ahNzfmZsdXR0ZXItZGFzaGJvYXJkcjULEgpUaW1lc2VyaWVzIiVhbmFseXplcl9iZW5jaG1hcmsuZmx1dHRlcl9yZXBvX2JhdGNoDA',
        'Archived': true,
        'Baseline': 4.0,
        'Goal': -2.3,
        'Label': 'flutter_repo_batch',
        'TaskName': 'analyzer_benchmark',
        'Unit': 's'
      };
      handler = UpdateTimeSeries(
        config,
        FakeAuthenticationProvider(),
        datastoreProvider: ({DatastoreDB db, int maxEntityGroups}) =>
            DatastoreService(config.db, 5),
      );
    });

    test('updates datastore entry for benchmark targets', () async {
      final TimeSeries timeSeries = TimeSeries(
          key: config.db.emptyKey
              .append(TimeSeries, id: 'analyzer_benchmark.flutter_repo_batch'));
      config.db.values[timeSeries.key] = timeSeries;

      expect(timeSeries.archived, false);
      expect(timeSeries.baseline, isNot(4));
      expect(timeSeries.goal, isNot(-2.3));
      expect(timeSeries.label, isNot('flutter_repo_batch'));
      expect(timeSeries.taskName, isNot('analyzer_benchmark'));
      expect(timeSeries.unit, isNot('s'));

      final UpdateTimeSeriesResponse response = await tester.post(handler);

      expect(response.timeSeries.archived, true);
      expect(response.timeSeries.baseline, 4.0);
      expect(response.timeSeries.goal, 0);
      expect(response.timeSeries.label, 'flutter_repo_batch');
      expect(response.timeSeries.taskName, 'analyzer_benchmark');
      expect(response.timeSeries.unit, 's');
    });
  });
}
