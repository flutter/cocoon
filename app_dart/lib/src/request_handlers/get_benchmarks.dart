// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:gcloud/db.dart';
import 'package:meta/meta.dart';

import '../datastore/cocoon_config.dart';
import '../model/appengine/commit.dart';
import '../model/appengine/key_helper.dart';
import '../model/appengine/time_series.dart';
import '../model/appengine/time_series_value.dart';
import '../request_handling/body.dart';
import '../request_handling/request_handler.dart';
import '../service/datastore.dart';

@immutable
class GetBenchmarks extends RequestHandler<Body> {
  const GetBenchmarks(
    Config config, {
    @visibleForTesting
        this.datastoreProvider = DatastoreService.defaultProvider,
  }) : super(config: config);

  final DatastoreServiceProvider datastoreProvider;

  static const String branchParam = 'branch';

  @override
  Future<Body> get() async {
    const String master = 'master';
    const int maxRecords = 50;

    final String branch = request.uri.queryParameters[branchParam] ?? master;
    final DatastoreService datastore = datastoreProvider(config.db);
    final DatastoreDB db = datastore.db;
    final List<Map<String, dynamic>> benchmarks = <Map<String, dynamic>>[];
    final KeyHelper keyHelper = config.keyHelper;

    Map<String, Result> releaseBranchMap = <String, Result>{};
    Map<String, Result> masterMap = <String, Result>{};
    int masterLimit = maxRecords;
    int timestamp = DateTime.now().millisecondsSinceEpoch;

    if (branch != master) {
      final List<Commit> releaseBranchCommits = await datastore
          .queryRecentCommits(limit: maxRecords, branch: branch)
          .toList();
      masterLimit = maxRecords > releaseBranchCommits.length
          ? maxRecords - releaseBranchCommits.length
          : 0;
      releaseBranchMap = await getBenchmarks(releaseBranchCommits.length,
          branch, db, releaseBranchCommits, benchmarks, timestamp);
      //log.debug('releaseBranchMap.last: ${releaseBranchMap.keys.first}');
      //log.debug('releaseBranchMap.last length: ${releaseBranchMap[releaseBranchMap.keys.first].timeSeriesValues.length}');
      //log.debug('releaseBranchMap.last: ${releaseBranchMap[releaseBranchMap.keys.first].timeSeriesValues.map((e) => e.value.toString()).toList().join(',')}');
      timestamp = releaseBranchCommits.last.timestamp;
    }
    if (branch == master || masterLimit > 0) {
      final List<Commit> masterCommits = await datastore
          .queryRecentCommits(timestamp: timestamp+1, limit: masterLimit)
          .toList();
      masterMap = await getBenchmarks(
          masterLimit, master, db, masterCommits, benchmarks, timestamp);
      //log.debug('masterMap.last: ${masterMap.keys.first}');
      //log.debug('masterMap.last length: ${masterMap[masterMap.keys.first].timeSeriesValues.length}');
      //log.debug('masterMap.last length: ${masterMap[masterMap.keys.first].timeSeriesValues.map((e) => e.value.toString()).toList().join(',')}');
    }

    for (String task in releaseBranchMap.keys) {
      //log.debug('!!!!!$task');
      //log.debug('releaseBranchMap containsKey: ${releaseBranchMap.containsKey(task)}');
      //log.debug('masterMap containsKey: ${masterMap.containsKey(task)}');
      final List<TimeSeriesValue> timeSeriesValues = <TimeSeriesValue>[];
      timeSeriesValues.addAll(
          releaseBranchMap[task].timeSeriesValues ?? <TimeSeriesValue>[]);
      timeSeriesValues.addAll(masterMap.containsKey(task)
          ? masterMap[task].timeSeriesValues ?? <TimeSeriesValue>[]
          : <TimeSeriesValue>[]);
      benchmarks.add(<String, dynamic>{
        'Timeseries': <String, dynamic>{
          'Timeseries': releaseBranchMap[task].timeSeries,
          'Key': keyHelper.encode(releaseBranchMap[task].timeSeries.key)
        },
        'Values': timeSeriesValues,
      });
    }

    return Body.forJson(<String, dynamic>{
      'Benchmarks': benchmarks,
    });
  }

  Future<Map<String, Result>> getBenchmarks(
      int limit,
      String branch,
      DatastoreDB db,
      List<Commit> commits,
      List<Map<String, dynamic>> benchmarks,
      int timestamp) async {
    final Map<String, Result> map = <String, Result>{};

    await for (TimeSeries series in db.query<TimeSeries>().run()) {
      //log.debug('--------TimeSeries: ${series.taskName}.${series.label}');
      final Query<TimeSeriesValue> query = db.query<TimeSeriesValue>(
          ancestorKey: series.key)
        ..filter('branch =', branch)
        ..filter(
            'createTimestamp <',
            DateTime.fromMillisecondsSinceEpoch(timestamp)
                .add(const Duration(hours: 1))
                .millisecondsSinceEpoch)
        ..order('-createTimestamp')
        ..limit(limit);

      final Map<String, TimeSeriesValue> valuesByCommit =
          <String, TimeSeriesValue>{};
      await for (TimeSeriesValue value in query.run()) {
        //log.debug('--------TimeSeriesValue: ${value.value}, commit: ${value.revision}');
        valuesByCommit[value.revision] = value;
      }

      final List<TimeSeriesValue> values = <TimeSeriesValue>[];
      for (Commit commit in commits) {
        TimeSeriesValue value;

        if (valuesByCommit.containsKey(commit.sha)) {
          //log.debug('++++++++commit: ${commit.sha}');
          value = valuesByCommit[commit.sha];
          if (value.value < 0) {
            // We sometimes get negative values, e.g. memory delta between runs
            // can be negative if GC decided to run in between. Our metrics are
            // smaller-is-better with zero being the perfect score. Instead of
            // trying to visualize them, a quick and dirty solution is to zero
            // them out. This logic can be updated later if we find a
            // reasonable interpretation/visualization for negative values.
            value.value = 0;
          }
        } else {
          // Insert placeholder entries for missing values.
          value = TimeSeriesValue(
            revision: commit.sha,
            createTimestamp: commit.timestamp,
            dataMissing: true,
            value: 0,
          );
        }

        values.add(value);
      }

      map['${series.taskName}.${series.label}'] = Result(series, values);
      /*
      benchmarks.add(<String, dynamic>{
        'Timeseries': <String, dynamic>{
          'Timeseries': series,
          'Key': keyHelper.encode(series.key)
        },
        'Values': values,
      });*/
    }
    return map;
  }
}

class Result {
  const Result(this.timeSeries, this.timeSeriesValues)
      : assert(timeSeries != null),
        assert(timeSeriesValues != null);

  final TimeSeries timeSeries;
  final List<TimeSeriesValue> timeSeriesValues;
}
