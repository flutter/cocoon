// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:gcloud/db.dart';
import 'package:meta/meta.dart';

import '../datastore/cocoon_config.dart';
import '../model/appengine/commit.dart';
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

  @override
  Future<Body> get() async {
    const int maxRecords = 50;
    final DatastoreService datastore = datastoreProvider(config.db);
    final DatastoreDB db = datastore.db;

    final List<Map<String, dynamic>> benchmarks = <Map<String, dynamic>>[];
    final Set<Commit> commits =
        await datastore.queryRecentCommits(limit: maxRecords).toSet();
    await for (TimeSeries series in db.query<TimeSeries>().run()) {
      final Query<TimeSeriesValue> query =
          db.query<TimeSeriesValue>(ancestorKey: series.key)
            ..order('-createTimestamp')
            ..limit(maxRecords);

      final Map<String, TimeSeriesValue> valuesByCommit =
          <String, TimeSeriesValue>{};
      await for (TimeSeriesValue value in query.run()) {
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

      benchmarks.add(<String, dynamic>{
        'Timeseries': SerializableTimeSeries(series: series),
        'Values': values,
      });
    }

    return Body.forJson(<String, dynamic>{
      'Benchmarks': benchmarks,
    });
  }
}
