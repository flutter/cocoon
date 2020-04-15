// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:cocoon_service/src/model/appengine/commit.dart';
import 'package:cocoon_service/src/model/appengine/time_series.dart';
import 'package:cocoon_service/src/model/appengine/time_series_value.dart';
import 'package:cocoon_service/src/request_handlers/get_benchmarks.dart';
import 'package:cocoon_service/src/request_handling/body.dart';
import 'package:cocoon_service/src/service/datastore.dart';
import 'package:gcloud/db.dart';
import 'package:test/test.dart';

import '../src/datastore/fake_cocoon_config.dart';
import '../src/request_handling/fake_authentication.dart';
import '../src/request_handling/fake_http.dart';
import '../src/request_handling/request_handler_tester.dart';

void main() {
  group('GetBenchmarks', () {
    FakeConfig config;
    FakeClientContext clientContext;
    FakeKeyHelper keyHelper;
    RequestHandlerTester tester;
    GetBenchmarks handler;

    Future<T> decodeHandlerBody<T>() async {
      final Body body = await tester.get(handler);
      return await utf8.decoder
          .bind(body.serialize())
          .transform(json.decoder)
          .single as T;
    }

    setUp(() {
      clientContext = FakeClientContext();
      keyHelper =
          FakeKeyHelper(applicationContext: clientContext.applicationContext);
      tester = RequestHandlerTester();
      config = FakeConfig(keyHelperValue: keyHelper);
      handler = GetBenchmarks(
        config,
        datastoreProvider: (DatastoreDB db) => DatastoreService(config.db, 5),
      );
    });

    test('reports statuses without input branch', () async {
      config.maxRecordsValue = 2;
      final TimeSeries timeSeries = TimeSeries(
          key: config.db.emptyKey.append(TimeSeries, id: 'test.test1'),
          taskName: 'test',
          label: 'test1',
          archived: false,
          baseline: 0,
          goal: 0,
          timeSeriesId: 'abc',
          unit: 's');

      final TimeSeriesValue timeSeriesValue1 = TimeSeriesValue(
          key: timeSeries.key.append(TimeSeriesValue, id: 1),
          value: 1,
          branch: 'master');
      final Commit commit1 = Commit(
          key: config.db.emptyKey.append(Commit, id: 'abc'),
          timestamp: 1,
          branch: 'master');
      final Commit commit2 = Commit(
          key: config.db.emptyKey.append(Commit, id: 'def'),
          timestamp: 2,
          branch: 'master');
      final Commit commit3 = Commit(
          key: config.db.emptyKey.append(Commit, id: 'ghi'),
          timestamp: 3,
          branch: 'master');
      config.db.values[timeSeriesValue1.key] = timeSeriesValue1;
      config.db.values[timeSeries.key] = timeSeries;
      config.db.values[commit1.key] = commit1;
      config.db.values[commit2.key] = commit2;
      config.db.values[commit3.key] = commit3;
      handler = GetBenchmarks(
        config,
        datastoreProvider: (DatastoreDB db) => DatastoreService(config.db, 5),
      );

      expect(config.db.values.length, 5);

      final Map<String, dynamic> result = await decodeHandlerBody();

      expect(result['Benchmarks'].length, 1);
      final List<dynamic> benchmarks = result['Benchmarks'] as List<dynamic>;
      final Map<String, dynamic> benchmark =
          benchmarks.first as Map<String, dynamic>;
      expect(benchmark['Values'].length, 2);
    });

    test('reports statuses with input branch', () async {
      config.maxRecordsValue = 2;
      final TimeSeries timeSeries = TimeSeries(
          key: config.db.emptyKey.append(TimeSeries, id: 'test.test1'),
          taskName: 'test',
          label: 'test1',
          archived: false,
          baseline: 0,
          goal: 0,
          timeSeriesId: 'abc',
          unit: 's');

      final TimeSeriesValue timeSeriesValue1 = TimeSeriesValue(
          key: timeSeries.key.append(TimeSeriesValue, id: 123),
          value: 1,
          branch: 'flutter-1.1-candidate.1');
      final TimeSeriesValue timeSeriesValue2 = TimeSeriesValue(
          key: timeSeries.key.append(TimeSeriesValue, id: 456),
          value: 2,
          branch: 'master');
      final Commit commit1 = Commit(
          key: config.db.emptyKey.append(Commit, id: 'abc'),
          timestamp: 1,
          branch: 'master');
      final Commit commit2 = Commit(
          key: config.db.emptyKey.append(Commit, id: 'def'),
          timestamp: 2,
          branch: 'master');
      final Commit commit3 = Commit(
          key: config.db.emptyKey.append(Commit, id: 'ghi'),
          timestamp: 3,
          branch: 'flutter-1.1-candidate.1');
      config.db.values[timeSeriesValue1.key] = timeSeriesValue1;
      config.db.values[timeSeriesValue2.key] = timeSeriesValue2;
      config.db.values[timeSeries.key] = timeSeries;
      config.db.values[commit1.key] = commit1;
      config.db.values[commit2.key] = commit2;
      config.db.values[commit3.key] = commit3;

      handler = GetBenchmarks(
        config,
        datastoreProvider: (DatastoreDB db) => DatastoreService(config.db, 5),
      );

      const String branch = 'flutter-1.1-candidate.1';

      expect(config.db.values.length, 6);

      tester.request = FakeHttpRequest(queryParametersValue: <String, String>{
        GetBenchmarks.branchParam: branch,
      });
      final Map<String, dynamic> result = await decodeHandlerBody();

      expect(result['Benchmarks'].length, 1);
      final List<dynamic> benchmarks = result['Benchmarks'] as List<dynamic>;
      final Map<String, dynamic> benchmark =
          benchmarks.first as Map<String, dynamic>;
      expect(benchmark['Values'].length, 2);
      final List<dynamic> timeSeriesValues = benchmark['Values'] as List<dynamic>;
      expect(timeSeriesValues[0]['Value'], 1.0);
      expect(timeSeriesValues[1]['Value'], 2.0);
    });
  });
}
