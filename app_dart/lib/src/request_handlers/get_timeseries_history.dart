// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:appengine/appengine.dart';
import 'package:gcloud/db.dart';
import 'package:meta/meta.dart';

import '../datastore/cocoon_config.dart';
import '../model/appengine/benchmark_data.dart';
import '../model/appengine/commit.dart';
import '../model/appengine/key_converter.dart';
import '../model/appengine/key_helper.dart';
import '../model/appengine/time_series.dart';
import '../model/appengine/time_series_entity.dart';
import '../model/appengine/time_series_value.dart';
import '../request_handling/body.dart';
import '../request_handling/exceptions.dart';
import '../request_handling/no_auth_request_handler.dart';
import '../service/datastore.dart';

@immutable
class GetTimeSeriesHistory extends NoAuthRequestHandler<GetTimeSeriesHistoryResponse> {
  const GetTimeSeriesHistory(
    Config config, {
    @visibleForTesting DatastoreServiceProvider datastoreProvider,
  })  : datastoreProvider = datastoreProvider ?? DatastoreService.defaultProvider,
        super(config: config);

  final DatastoreServiceProvider datastoreProvider;
  static const String timeSeriesKeyParam = 'TimeSeriesKey';
  static const String startFromParam = 'StartFrom';

  @override
  Future<GetTimeSeriesHistoryResponse> post() async {
    checkRequiredParameters(<String>[timeSeriesKeyParam]);
    // This number inherites from earlier GO backend. Up to change if necessary.
    const int maxRecords = 6000;
    final DatastoreService datastore = datastoreProvider(config.db);
    final KeyHelper keyHelper = KeyHelper(applicationContext: AppEngineContext(false, '', '', '', '', '', Uri()));
    final Set<Commit> commits = await datastore.queryRecentCommits(limit: maxRecords).toSet();

    Key<String> timeSeriesKey;
    try {
      timeSeriesKey = keyHelper.decode(requestData[timeSeriesKeyParam] as String) as Key<String>;
    } on FormatException {
      throw BadRequestException('Bad timeSeries key: ${requestData[timeSeriesKeyParam]}');
    }

    final TimeSeries timeSeries = await config.db.lookupValue<TimeSeries>(timeSeriesKey, orElse: () {
      throw BadRequestException('No such timeseries: ${timeSeriesKey.id}');
    });

    List<TimeSeriesValue> timeSeriesValues =
        await datastore.queryRecentTimeSeriesValues(timeSeries, startFrom: startFromParam, limit: maxRecords).toList();
    timeSeriesValues = insertMissingTimeseriesValues(timeSeriesValues, commits);

    return GetTimeSeriesHistoryResponse(timeSeries, timeSeriesValues);
  }
}

@immutable
class GetTimeSeriesHistoryResponse extends JsonBody {
  const GetTimeSeriesHistoryResponse(this.timeSeries, this.timeSeriesValues) : assert(timeSeries != null);

  final TimeSeries timeSeries;
  final List<TimeSeriesValue> timeSeriesValues;

  @override
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'BenchmarkData': BenchmarkData(
          timeSeriesEntity:
              TimeseriesEntity(timeSeries: timeSeries, key: const StringKeyConverter().toJson(timeSeries.key)),
          values: timeSeriesValues),
      // TODO(keyonghan): implemement last position
      // https://github.com/flutter/flutter/issues/42362
      'LastPosition': null,
    };
  }
}

List<TimeSeriesValue> insertMissingTimeseriesValues(List<TimeSeriesValue> timeSerialsValues, Set<Commit> commits) {
  final List<TimeSeriesValue> values = <TimeSeriesValue>[];
  final Map<String, TimeSeriesValue> valuesByCommit = <String, TimeSeriesValue>{};
  for (TimeSeriesValue value in timeSerialsValues) {
    valuesByCommit[value.revision] = value;
  }

  for (Commit commit in commits) {
    TimeSeriesValue value;

    if (valuesByCommit.containsKey(commit.sha)) {
      value = valuesByCommit[commit.sha];
      // This logic inherites from earlier GO backend. Up to change if necessary.
      if (value.value < 0) {
        value.value = 0;
      }
    } else {
      // Insert placeholder entries for missing values.
      // Missing values happen when there is any queried timeSeriesValue
      // whose commit does not appear in the queried top [maxRecords] commits
      value = TimeSeriesValue(
        revision: commit.sha,
        createTimestamp: commit.timestamp,
        dataMissing: true,
        value: 0,
      );
    }
    values.add(value);
  }
  return values;
}
