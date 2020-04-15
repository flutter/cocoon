// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:meta/meta.dart';

import '../datastore/cocoon_config.dart';
import '../model/appengine/commit.dart';
import '../model/appengine/key_helper.dart';
import '../model/appengine/time_series.dart';
import '../model/appengine/time_series_value.dart';
import '../request_handling/body.dart';
import '../request_handling/request_handler.dart';
import '../service/datastore.dart';

/// Return benchmarks for [TimeSeries]. If request is for `master` branch,
/// it will return results of recent [maxRecords] commits. If request is for
/// a `release` branch, it queries all commits of the branch first and then
/// appends remaining [masterLimit] commits from master.
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

    final int maxRecords = config.maxRecords;
    final String branch = request.uri.queryParameters[branchParam] ?? master;
    final DatastoreService datastore = datastoreProvider(config.db);
    final List<Map<String, dynamic>> benchmarks = <Map<String, dynamic>>[];

    Map<String, Result> releaseBranchMap = <String, Result>{};
    Map<String, Result> masterMap = <String, Result>{};
    int masterLimit = maxRecords;
    int timestamp = DateTime.now().millisecondsSinceEpoch;

    /// Query all commits of the release branch first. Then calcalute the
    /// number of commits to retrieve from master branch, and obtain
    /// the starting [timestamp] to filter master commits.
    if (branch != master) {
      final List<Commit> releaseBranchCommits = await datastore
          .queryRecentCommits(limit: maxRecords, branch: branch)
          .toList();
      releaseBranchMap = await _getBenchmarks(releaseBranchCommits.length,
          branch, datastore, releaseBranchCommits, benchmarks, timestamp);
      masterLimit = maxRecords > releaseBranchCommits.length
          ? maxRecords - releaseBranchCommits.length
          : 0;
      timestamp = releaseBranchCommits.last.timestamp;
    }

    /// Query all remaining commits from master.
    if (branch == master || masterLimit > 0) {
      /// `+1` is to guarantee picking up the master commit, from which
      /// the release branch is derived.
      final List<Commit> masterCommits = await datastore
          .queryRecentCommits(timestamp: timestamp + 1, limit: masterLimit)
          .toList();

      masterMap = await _getBenchmarks(
          masterLimit, master, datastore, masterCommits, benchmarks, timestamp);
    }

    _combineValues(releaseBranchMap, masterMap, benchmarks);

    return Body.forJson(<String, dynamic>{
      'Benchmarks': benchmarks,
    });
  }

  /// Combine results for both release and master branches.
  void _combineValues(Map<String, Result> releaseBranchMap,
      Map<String, Result> masterMap, List<Map<String, dynamic>> benchmarks) {
    final KeyHelper keyHelper = config.keyHelper;
    final Map<String, Result> map =
        releaseBranchMap.isNotEmpty ? releaseBranchMap : masterMap;
    for (String task in map.keys) {
      final List<TimeSeriesValue> timeSeriesValues = <TimeSeriesValue>[];

      timeSeriesValues.addAll(releaseBranchMap.containsKey(task)
          ? releaseBranchMap[task].timeSeriesValues ?? <TimeSeriesValue>[]
          : <TimeSeriesValue>[]);
      timeSeriesValues.addAll(masterMap.containsKey(task)
          ? masterMap[task].timeSeriesValues ?? <TimeSeriesValue>[]
          : <TimeSeriesValue>[]);

      benchmarks.add(<String, dynamic>{
        'Timeseries': <String, dynamic>{
          'Timeseries': map[task].timeSeries,
          'Key': keyHelper.encode(map[task].timeSeries.key)
        },
        'Values': timeSeriesValues,
      });
    }
  }

  Future<Map<String, Result>> _getBenchmarks(
      int limit,
      String branch,
      DatastoreService datastore,
      List<Commit> commits,
      List<Map<String, dynamic>> benchmarks,
      int timestamp) async {
    final Map<String, Result> map = <String, Result>{};

    await for (TimeSeries series in datastore.db.query<TimeSeries>().run()) {
      final Map<String, TimeSeriesValue> valuesByCommit =
          <String, TimeSeriesValue>{};

      /// Adding `1` hour to [timestamp] to guarantee all [values] belonging to
      /// commits are picked up. It is not uncommon that [values] are inserted
      /// into `datastore` later than [commit]. `1` hour is a reasonable timeframe
      /// considering executing time of a commit row is less than `1` hour now.
      await for (TimeSeriesValue value in datastore.queryRecentTimeSeriesValues(
          series,
          limit: limit,
          branch: branch,
          timestamp: DateTime.fromMillisecondsSinceEpoch(timestamp)
              .add(const Duration(hours: 1))
              .millisecondsSinceEpoch)) {
        valuesByCommit[value.revision] = value;
      }

      final List<TimeSeriesValue> values = <TimeSeriesValue>[];
      for (Commit commit in commits) {
        TimeSeriesValue value;

        if (valuesByCommit.containsKey(commit.sha)) {
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
