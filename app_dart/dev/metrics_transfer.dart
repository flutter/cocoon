// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Manually transfer Cocoon metrics to Skia perf GCS bucket.
//
// The operation is idempotent so you can transfer with the same start date
// multiple times without having to worrying about duplications.

import 'dart:io';

import 'package:clock/clock.dart';
import 'package:cocoon_service/src/model/appengine/time_series.dart';
import 'package:cocoon_service/src/model/appengine/time_series_value.dart';
import 'package:gcloud/db.dart';
import 'package:gcloud/storage.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:intl/intl.dart';
import 'package:metrics_center/metrics_center.dart';

// The official pub.dev/packages/gcloud documentation uses datastore_impl
// so we have to ignore implementation_imports here.
// ignore: implementation_imports
import 'package:gcloud/src/datastore_impl.dart';

Future<void> main() async {
  const String kProjectId = 'flutter-dashboard';
  _checkGithubToken();
  final AutoRefreshingAuthClient client = await clientViaUserConsent(
      ClientId(kOAuthClientId, _getOAuthClientSecret()),
      DatastoreImpl.SCOPES + Storage.SCOPES, (String uri) {
    print('Please follow the following URL for authentication: $uri');
  });
  final DatastoreDB db =
      DatastoreDB(DatastoreImpl(client, kProjectId));
  final SkiaPerfDestination destination = await SkiaPerfDestination.make(
    client,
    kProjectId,
    isTesting: true, // TODO(liyuqian): set isTesting to false
  );
  final TransferHandler handler = TransferHandler(db, destination);

  final DateTime start = _askStart();
  await handler.transfer(start);
}

/// A metric point that comes from a devicelab benchmark result.
class BenchmarkMetricPoint extends MetricPoint {
  BenchmarkMetricPoint(TimeSeries ts, TimeSeriesValue tsv)
      : super(
          tsv.value,
          <String, String>{
            // GitHub repository.
            kGithubRepoKey: 'flutter/flutter',
            // Git revision at which this measurement was taken.
            kGitRevisionKey: tsv.revision,
            // Git branch at which this measurement was taken.
            'branch': tsv.branch,
            // Name of the devicelab task.
            kNameKey: ts.taskName,
            // Name of a metric in the task. A task might have multiple metrics.
            kSubResultKey: ts.label,
            // Unit of this measurement.
            kUnitKey: ts.unit,
          },
        );
}

class TransferHandler {
  const TransferHandler(this._db, this._destination);

  /// Returns a map containing all time series keyed by its id.
  Future<Map<String, TimeSeries>> readTimeSeriesMap() async {
    final Map<String, TimeSeries> map = <String, TimeSeries>{};
    await for (TimeSeries ts in _db.query<TimeSeries>().run()) {
      // The id is string typed, see the definition of [TimeSeries].
      map[ts.id as String] = ts;
    }
    return map;
  }

  /// Reads benchmark records with [createTimestamp] later than [sinceMillis].
  /// And limits the result size to no larger than [batchSize].
  Future<List<TimeSeriesValue>> readTimeSeriesValue(
      int beginMillis, int endMillis,
      {int batchSize = 1000 * 1000}) async {
    final Query<TimeSeriesValue> query = _db.query<TimeSeriesValue>()
      ..filter('createTimestamp >=', beginMillis)
      ..filter('createTimestamp <', endMillis)
      ..limit(batchSize)
      ..order('createTimestamp');
    final List<TimeSeriesValue> result = await query.run().toList();
    if (result.length >= batchSize) {
      throw 'Reaching batch size limit $batchSize. Some data might be missing.';
    }
    return result;
  }

  /// Transform Cocoon metrics in the format of [TimeSeriesValue] and
  /// [TimeSeries] into [BenchmarkMetricPoint] that can be consumed by metrics
  /// center.
  Future<List<BenchmarkMetricPoint>> transform(
      Map<String, TimeSeries> timeSeriesMap,
      List<TimeSeriesValue> timeSeriesValues) async {
    final List<BenchmarkMetricPoint> points = <BenchmarkMetricPoint>[];
    for (TimeSeriesValue tsv in timeSeriesValues) {
      // The id is string typed, see the definition of [TimeSeries].
      final String parentId = tsv.parentKey.id as String;
      if (!timeSeriesMap.containsKey(parentId)) {
        print('TimeSeries with id: $parentId does not exist');
        continue;
      }
      final TimeSeries ts = timeSeriesMap[parentId];
      points.add(BenchmarkMetricPoint(ts, tsv));
    }
    return points;
  }

  /// Transfer Cocoon metrics from [start] to now into [SkiaPerfDestination].
  Future<void> transfer(DateTime start) async {
    final Map<String, TimeSeries> timeSeriesMap = await readTimeSeriesMap();

    final DateTime finish = clock.now().toUtc();
    final Duration timeSpan = finish.difference(start);
    final int stepCount = (timeSpan.inSeconds / _kStep.inSeconds).ceil();

    print('Current time: ${_t(finish)}');
    print('Start transferring from ${_t(start)} to ${_t(finish)}.');
    print('==================================================================');

    DateTime from = start, to = start.add(_kStep);
    for (int i = 1; i <= stepCount; from = to, to = to.add(_kStep), i += 1) {
      print('Step $i/$stepCount: transferring from ${_t(from)} to ${_t(to)}');
      final List<TimeSeriesValue> timeSeriesValues = await readTimeSeriesValue(
          from.millisecondsSinceEpoch, to.millisecondsSinceEpoch);
      print('  Read ${timeSeriesValues.length} TimeSeriesValues.');
      if (timeSeriesValues.isNotEmpty) {
        final List<BenchmarkMetricPoint> points =
            await transform(timeSeriesMap, timeSeriesValues);
        print('  Transformed ${points.length} metric points.');
        print('  The first one is ${_truncate(points.first.toString())}');
        await _destination.update(points);
      }

      final DateTime now = clock.now();
      final Duration timeSpent = now.difference(finish);
      final Duration averageTime = timeSpent ~/ i;
      print('  Step finished on ${_t(now)}.');
      print('  Average step time: $averageTime.');
      print('  Estimated time left: ${averageTime * (stepCount - i)}.');
    }
  }

  String _t(DateTime t) {
    return _dateFormat.format(t.toLocal());
  }

  final DatastoreDB _db;
  final SkiaPerfDestination _destination;
  static const Duration _kStep = Duration(days: 1);
  static final DateFormat _dateFormat = DateFormat('yyyy-MM-dd HH:mm:ss.SSS');
}

String _truncate(String s) {
  const int kMaxLen = 100;
  const String kEllipsis = '...';
  if (s.length <= kMaxLen) {
    return s;
  } else {
    return s.substring(0, kMaxLen - kEllipsis.length) + kEllipsis;
  }
}

DateTime _askStart() {
  while (true) {
    print('Input the start date of the transfer in the format of YYYY-mm-dd:');
    final String line = stdin.readLineSync();
    final DateTime result = DateTime.tryParse(line);
    if (result != null) {
      return result;
    }
    print('Cannot parse the input $line as a valid date.');
  }
}

String _getOAuthClientSecret() {
  final String secret = Platform.environment[kOAuthClientSecretKey];
  if (secret == null) {
    throw kMissingSecretMessage;
  }
  return secret;
}

void _checkGithubToken() {
  final String githubToken = Platform.environment[kGithubTokenKey];
  if (githubToken == null) {
    print('!!!!!!!!!!!!!!!!!!!!!!!!  WARNING  !!!!!!!!!!!!!!!!!!!!!!!!');
    print('!!                                                       !!');
    print('!! Environment variable GITHUB_TOKEN not found.          !!');
    print('!! Github may throttle this transfer without it.         !!');
    print('!!                                                       !!');
    print('!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!');
  }
}

const String kOAuthClientSecretKey = 'OAUTH_CLIENT_SECRET';
const String kOAuthClientId = '308150028417-8393psgs5bbp7h1v3m7eedaai865fbp6'
    '.apps.googleusercontent.com';
const String kGithubTokenKey = 'GITHUB_TOKEN';

const String kMissingSecretMessage =
    'Cannot find environment variable $kOAuthClientSecretKey. '
    'Please find the oauth client secret of $kOAuthClientId, and set it '
    'as environment variable $kOAuthClientSecretKey.';
