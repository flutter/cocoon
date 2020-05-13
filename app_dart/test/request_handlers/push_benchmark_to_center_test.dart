// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
import 'package:cocoon_service/cocoon_service.dart';
import 'package:cocoon_service/src/model/appengine/time_series.dart';
import 'package:cocoon_service/src/model/appengine/time_series_value.dart';
import 'package:metrics_center/flutter.dart' as mc;
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import '../src/datastore/fake_cocoon_config.dart';
import '../src/request_handling/fake_http.dart';
import '../src/request_handling/fake_logging.dart';
import '../src/request_handling/request_handler_tester.dart';

void main() {
  FakeConfig config;
  FakeLogging logger;
  MockFlutterDestination flutterDestination;
  PushBenchmarkToCenter handler;

  setUp(() {
    config = FakeConfig();
    logger = FakeLogging();
    flutterDestination = MockFlutterDestination();
    handler = PushBenchmarkToCenter(
      config,
      logger: logger,
      flutterDestinationProvider: (Config config) =>
          Future<mc.FlutterDestination>.value(flutterDestination),
    );
  });

  group('parseSinceTimeMillis', () {
    test('with missing parameter', () {
      final int sinceTimeMillis =
          handler.parseSinceTimeMillis(<String, String>{});
      expect(sinceTimeMillis, isNull);
    });

    test('parses correctly', () {
      final int sinceTimeMillis = handler
          .parseSinceTimeMillis(<String, String>{'sinceTimeMillis': '123'});
      expect(sinceTimeMillis, 123);
    });
  });

  group('readTimeSeriesMap', () {
    test('returns a map', () async {
      final TimeSeries ts =
          TimeSeries(key: config.db.emptyKey.append(TimeSeries, id: 'tsId'));
      config.db.values[ts.key] = ts;

      final Map<String, TimeSeries> map = await handler.readTimeSeriesMap();

      expect(map, <String, TimeSeries>{'tsId': ts});
    });
  });

  group('readTimeSeriesValue', () {
    test('returns a list', () async {
      final TimeSeries ts =
          TimeSeries(key: config.db.emptyKey.append(TimeSeries, id: 'tsId'));
      final TimeSeriesValue tsv = TimeSeriesValue(
        key: ts.key.append(TimeSeriesValue, id: 1),
        value: 2,
        branch: 'master',
      );
      config.db.values[tsv.key] = tsv;

      final List<TimeSeriesValue> list = await handler.readTimeSeriesValue(100);

      expect(list, <TimeSeriesValue>[tsv]);
    });
  });

  group('transform', () {
    test('returns a list', () async {
      final TimeSeries ts = TimeSeries(
        key: config.db.emptyKey.append(TimeSeries, id: 'fakeTsId'),
        label: 'fakeMetricName',
        taskName: 'fakeTaskName',
        unit: 'seconds',
      );
      final TimeSeriesValue tsv = TimeSeriesValue(
        key: ts.key.append(TimeSeriesValue, id: 1),
        value: 2.0,
        branch: 'master',
        revision: 'fakeSha',
      );

      final List<BenchmarkMetricPoint> points = await handler.transform(
          <String, TimeSeries>{'fakeTsId': ts}, <TimeSeriesValue>[tsv]);

      expect(points.first.value, 2.0);
      expect(points.first.tags, <String, String>{
        'gitRepo': 'flutter/flutter',
        'gitRevision': 'fakeSha',
        'branch': 'master',
        'originId': 'devicelab',
        'taskName': 'fakeTaskName',
        'unit': 'seconds',
        'name': 'fakeMetricName',
      });
      expect(points.first.originId, 'devicelab');
    });
  });

  test('a typical request', () async {
    final TimeSeries ts = TimeSeries(
      key: config.db.emptyKey.append(TimeSeries, id: 'fakeTsId'),
      label: 'fakeMetricName',
      taskName: 'fakeTaskName',
      unit: 'seconds',
    );
    final TimeSeriesValue tsv = TimeSeriesValue(
      key: ts.key.append(TimeSeriesValue, id: 1),
      value: 2.0,
      branch: 'master',
      revision: 'fakeSha',
    );
    config.db.values[ts.key] = ts;
    config.db.values[tsv.key] = tsv;

    final RequestHandlerTester tester = RequestHandlerTester(
      request: FakeHttpRequest(
        queryParametersValue: <String, String>{'sinceTimeMillis': '123'},
      ),
    );

    await tester.get(handler);

    final List<BenchmarkMetricPoint> points =
        verify(flutterDestination.update(captureAny)).captured.first
            as List<BenchmarkMetricPoint>;
    expect(points.first.value, 2.0);
    expect(points.first.tags, <String, String>{
      'gitRepo': 'flutter/flutter',
      'gitRevision': 'fakeSha',
      'branch': 'master',
      'originId': 'devicelab',
      'taskName': 'fakeTaskName',
      'unit': 'seconds',
      'name': 'fakeMetricName',
    });
    expect(points.first.originId, 'devicelab');
  });
}

class MockFlutterDestination extends Mock implements mc.FlutterDestination {}
