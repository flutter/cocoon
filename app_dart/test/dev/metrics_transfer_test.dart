// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:clock/clock.dart';
import 'package:cocoon_service/src/model/appengine/time_series.dart';
import 'package:cocoon_service/src/model/appengine/time_series_value.dart';
import 'package:fake_async/fake_async.dart';
import 'package:gcloud/db.dart';
import 'package:metrics_center/metrics_center.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import '../../dev/metrics_transfer.dart';
import '../src/datastore/fake_cocoon_config.dart';

class MockSkiaPerfDestination extends Mock implements SkiaPerfDestination {}

class MockDb extends Mock implements DatastoreDB {}

class MockTsQuery extends Mock implements Query<TimeSeries> {}

class MockTsvQuery extends Mock implements Query<TimeSeriesValue> {}

Future<void> main() async {
  final FakeConfig config = FakeConfig();
  final TimeSeries ts = TimeSeries(
    key: config.db.emptyKey.append<String>(TimeSeries, id: 'fakeTsId'),
    label: 'fakeMetricName',
    taskName: 'fakeTaskName',
    unit: 'seconds',
  );
  final TimeSeriesValue tsv = TimeSeriesValue(
    key: ts.key.append<int>(TimeSeriesValue, id: 1),
    value: 2.0,
    branch: 'master',
    revision: 'fakeSha',
  );
  final MockSkiaPerfDestination dst = MockSkiaPerfDestination();
  final MockDb db = MockDb();
  final MockTsQuery tsQuery = MockTsQuery();
  final MockTsvQuery tsvQuery = MockTsvQuery();
  when(db.query()).thenAnswer((Invocation invocation) {
    switch (invocation.typeArguments[0]) {
      case TimeSeries:
        return tsQuery;
      case TimeSeriesValue:
        return tsvQuery;
    }
    throw 'Unexpected invocation $invocation';
  });
  when(tsQuery.run()).thenAnswer(
    (_) => Stream<TimeSeries>.fromIterable(<TimeSeries>[ts]),
  );
  when(tsvQuery.run()).thenAnswer(
    (_) => Stream<TimeSeriesValue>.fromIterable(<TimeSeriesValue>[tsv]),
  );
  when(dst.update(any)).thenAnswer((_) async {
    await Future<void>.delayed(const Duration(seconds: 30));
  });
  final TransferHandler handler = TransferHandler(db, dst);

  test('TransferHandler prints time info.', () {
    void fakeAsyncTest(FakeAsync fakeAsync) {
      final DateTime now = clock.now();
      final DateTime threeDaysAgo = now.subtract(const Duration(days: 3));
      handler.transfer(threeDaysAgo);
      fakeAsync.elapse(const Duration(seconds: 90));
    }

    void fakeAsyncTestWithClock() {
      fakeAsync((FakeAsync fakeAsync) {
        withClock(
          fakeAsync.getClock(DateTime(2020, 12, 10)),
          () => fakeAsyncTest(fakeAsync),
        );
      });
    }

    // Capture print for verifications.
    final List<String> prints = <String>[];
    final ZoneSpecification spec =
        ZoneSpecification(print: (_, __, ___, String msg) => prints.add(msg));
    Zone.current.fork(specification: spec).run<void>(fakeAsyncTestWithClock);

    expect(
      prints.join('\n'),
      '''
Current time: 2020-12-10 00:00:00.000
Start transferring from 2020-12-07 00:00:00.000 to 2020-12-10 00:00:00.000.
==================================================================
Step 1/3: transferring from 2020-12-07 00:00:00.000 to 2020-12-08 00:00:00.000
  Read 1 TimeSeriesValues.
  Transformed 1 metric points.
  The first one is MetricPoint(value=2.0, tags={branch: master, gitRepo: flutter/flutter, gitRevision: fakeSha, name...
  Step finished on 2020-12-10 00:00:30.000.
  Average step time: 0:00:30.000000.
  Estimated time left: 0:01:00.000000.
Step 2/3: transferring from 2020-12-08 00:00:00.000 to 2020-12-09 00:00:00.000
  Read 1 TimeSeriesValues.
  Transformed 1 metric points.
  The first one is MetricPoint(value=2.0, tags={branch: master, gitRepo: flutter/flutter, gitRevision: fakeSha, name...
  Step finished on 2020-12-10 00:01:00.000.
  Average step time: 0:00:30.000000.
  Estimated time left: 0:00:30.000000.
Step 3/3: transferring from 2020-12-09 00:00:00.000 to 2020-12-10 00:00:00.000
  Read 1 TimeSeriesValues.
  Transformed 1 metric points.
  The first one is MetricPoint(value=2.0, tags={branch: master, gitRepo: flutter/flutter, gitRevision: fakeSha, name...
  Step finished on 2020-12-10 00:01:30.000.
  Average step time: 0:00:30.000000.
  Estimated time left: 0:00:00.000000.''',
    );
  });

  test('readTimeSeriesMap returns a map.', () async {
    final Map<String, TimeSeries> map = await handler.readTimeSeriesMap();
    expect(map, <String, TimeSeries>{'fakeTsId': ts});
  });

  test('readTimeSeriesValue returns a list.', () async {
    final List<TimeSeriesValue> list = await handler.readTimeSeriesValue(0, 0);
    expect(list, <TimeSeriesValue>[tsv]);
  });

  test('transform returns a list.', () async {
    final List<BenchmarkMetricPoint> points = await handler.transform(
        <String, TimeSeries>{'fakeTsId': ts}, <TimeSeriesValue>[tsv]);

    expect(points.first.value, 2.0);
    expect(points.first.tags, <String, String>{
      'gitRepo': 'flutter/flutter',
      'gitRevision': 'fakeSha',
      'branch': 'master',
      'name': 'fakeTaskName',
      'unit': 'seconds',
      'subResult': 'fakeMetricName',
    });
  });
}
