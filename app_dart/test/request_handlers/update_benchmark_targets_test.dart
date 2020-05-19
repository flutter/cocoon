// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_service/src/model/appengine/time_series.dart';
import 'package:cocoon_service/src/request_handlers/update_benchmark_targets.dart';
import 'package:cocoon_service/src/service/datastore.dart';
import 'package:gcloud/db.dart';
import 'package:test/test.dart';

import '../src/datastore/fake_cocoon_config.dart';
import '../src/request_handling/api_request_handler_tester.dart';
import '../src/request_handling/fake_authentication.dart';

void main() {
  group('UpdateBenchmarkTargets', () {
    FakeConfig config;
    ApiRequestHandlerTester tester;
    UpdateBenchmarkTargets handler;

    setUp(() {
      config = FakeConfig();
      tester = ApiRequestHandlerTester();
      tester.requestData = <String, dynamic>{
        'TimeSeriesKey':
            'ahNzfmZsdXR0ZXItZGFzaGJvYXJkcjULEgpUaW1lc2VyaWVzIiVhbmFseXplcl9iZW5jaG1hcmsuZmx1dHRlcl9yZXBvX2JhdGNoDA',
        'Goal': -2.3,
        'Baseline': 4.0
      };
      handler = UpdateBenchmarkTargets(
        config,
        FakeAuthenticationProvider(),
        datastoreProvider: (
          DatastoreDB db,
        ) =>
            DatastoreService(config.db, 5),
      );
    });

    test('updates datastore entry for benchmark targets', () async {
      final TimeSeries timeSeries = TimeSeries(
          key: config.db.emptyKey
              .append(TimeSeries, id: 'analyzer_benchmark.flutter_repo_batch'));
      config.db.values[timeSeries.key] = timeSeries;

      expect(timeSeries.goal, isNot(-2.3));
      expect(timeSeries.baseline, isNot(4));

      final UpdateBenchmarkTargetsResponse response =
          await tester.post(handler);
      final TimeSeries timeSeries2 =
          config.db.values[timeSeries.key] as TimeSeries;

      expect(timeSeries2.goal, 0);
      expect(response.timeSeries.baseline, 4.0);
    });
  });
}
