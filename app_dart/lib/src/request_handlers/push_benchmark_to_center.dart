// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
import 'dart:async';

import 'package:appengine/appengine.dart';
import 'package:gcloud/db.dart';
import 'package:meta/meta.dart';
import 'package:metrics_center/flutter.dart' as mc;

import '../datastore/cocoon_config.dart';
import '../foundation/providers.dart';
import '../model/appengine/time_series.dart';
import '../model/appengine/time_series_value.dart';
import '../request_handling/body.dart';
import '../request_handling/request_handler.dart';
import '../service/datastore.dart';

/// Pushes devicelab benchmark results to Metrics Center storage.
///
/// Metrics Center aggregates benchmark data in the unified [MetricPoint] format
/// and sends them to performance dashboards.
@immutable
class PushBenchmarkToCenter extends RequestHandler<Body> {
  PushBenchmarkToCenter(
    Config config, {
    @visibleForTesting Logging logger,
    @visibleForTesting DatastoreService datastoreService,
    @visibleForTesting FlutterDestinationProvider flutterDestinationProvider,
  })  : logger = logger ?? Providers.serviceScopeLogger(),
        datastoreService =
            datastoreService ?? DatastoreService.defaultProvider(config.db),
        flutterDestinationProvider =
            flutterDestinationProvider ?? defaultFlutterDestinationProvider,
        super(config: config);

  final Logging logger;
  final DatastoreService datastoreService;
  final FlutterDestinationProvider flutterDestinationProvider;

  @override
  Future<Body> get() async {
    final int sinceTimeMillis =
        parseSinceTimeMillis(request.uri.queryParameters);
    if (sinceTimeMillis == null) {
      logger.error('The sinceTimeMillis parameter is missing');
      return Body.empty;
    }

    final List<TimeSeriesValue> timeSeriesValues =
        await readTimeSeriesValue(sinceTimeMillis);
    final Map<String, TimeSeries> timeSeriesMap = await readTimeSeriesMap();

    final List<BenchmarkMetricPoint> points =
        await transform(timeSeriesMap, timeSeriesValues);
    logger.debug('Transformed ${points.length} metric points.');
    logger.debug('The first one is ${points.first}');

    final mc.FlutterDestination destination =
        await flutterDestinationProvider(config);
    await destination.update(points);
    return Body.empty;
  }

  @visibleForTesting
  int parseSinceTimeMillis(Map<String, String> queryParameters) {
    final String s = queryParameters['sinceTimeMillis'] ?? '';
    return int.tryParse(s);
  }

  /// Returns a map containing all time series keyed by its id.
  Future<Map<String, TimeSeries>> readTimeSeriesMap() async {
    final Map<String, TimeSeries> map = <String, TimeSeries>{};
    await for (TimeSeries ts in datastoreService.db.query<TimeSeries>().run()) {
      // The id is string typed, see the defination of [TimeSeries].
      map[ts.id as String] = ts;
    }
    return map;
  }

  /// Reads benchmark records with [createTimestamp] later than [sinceMillis].
  /// And limits the result size to no larger than [batchSize].
  Future<List<TimeSeriesValue>> readTimeSeriesValue(int sinceMillis,
      {int batchSize = 1000}) async {
    final Query<TimeSeriesValue> query =
        datastoreService.db.query<TimeSeriesValue>()
          ..filter('createTimestamp >', sinceMillis)
          ..limit(batchSize)
          ..order('createTimestamp');
    return query.run().toList();
  }

  Future<List<BenchmarkMetricPoint>> transform(
      Map<String, TimeSeries> timeSeriesMap,
      List<TimeSeriesValue> timeSeriesValues) async {
    final List<BenchmarkMetricPoint> points = <BenchmarkMetricPoint>[];
    for (TimeSeriesValue tsv in timeSeriesValues) {
      // The id is string typed, see the defination of [TimeSeries].
      final String parentId = tsv.parentKey.id as String;
      if (!timeSeriesMap.containsKey(parentId)) {
        logger.warning('TimeSeries with id: $parentId does not exist');
        continue;
      }
      final TimeSeries ts = timeSeriesMap[parentId];
      points.add(BenchmarkMetricPoint(ts, tsv));
    }
    return points;
  }
}

/// A metric point that comes from a devicelab benchmark result.
class BenchmarkMetricPoint extends mc.MetricPoint {
  BenchmarkMetricPoint(TimeSeries ts, TimeSeriesValue tsv)
      : super(
            tsv.value,
            <String, String>{
              // GitHub repository.
              mc.kGithubRepoKey: 'flutter/flutter',
              // Git revision at which this measurement was taken.
              mc.kGitRevisionKey: tsv.revision,
              // Git branch at which this measurement was taken.
              'branch': tsv.branch,
              // Where this measurement was created.
              mc.kOriginIdKey: kOrigin,
              // Name of the devicelab task.
              mc.kTaskNameKey: ts.taskName,
              // Name of a metric in the task. A task might have mutiple metrics.
              mc.kNameKey: ts.label,
              // Unit of this measurement.
              mc.kUnitKey: ts.unit,
            },
            kOrigin);

  static const String kOrigin = 'devicelab';
}

typedef FlutterDestinationProvider = Future<mc.FlutterDestination> Function(
    Config config);

Future<mc.FlutterDestination> defaultFlutterDestinationProvider(
    Config config) async {
  return mc.FlutterDestination.makeFromCredentialsJson(
      await config.metricsCenterServiceAccountJson);
}
