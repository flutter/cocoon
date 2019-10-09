// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:cocoon_service/src/model/appengine/benchmark_data.dart';
import 'package:cocoon_service/src/model/appengine/time_series_value.dart';
import 'package:gcloud/db.dart';
import 'package:meta/meta.dart';

import '../datastore/cocoon_config.dart';
import '../model/appengine/commit.dart';
import '../model/appengine/key_helper.dart';
import '../model/appengine/time_series.dart';
import '../model/appengine/time_series_entity.dart';
import '../request_handling/body.dart';
import '../request_handling/exceptions.dart';
import '../request_handling/regular_request_handler.dart';
import '../service/datastore.dart';

@immutable
class GetTimeSeriesHistory extends RegularRequestHandler<Body> {
  const GetTimeSeriesHistory(
    Config config, {
    @visibleForTesting DatastoreServiceProvider datastoreProvider,
  })  : datastoreProvider =
            datastoreProvider ?? DatastoreService.defaultProvider,
        super(config: config);

  final DatastoreServiceProvider datastoreProvider;
  static const String timeSeriesKeyParam = 'TimeSeriesKey';
  static const String startFromParam = 'StartFrom';

  @override
  Future<GetTimeSeriesHistoryResponse> post() async {
    checkRequiredParameters(<String>[timeSeriesKeyParam]);
    const int maxRecords = 1500;
    final DatastoreService datastore = datastoreProvider();
    final KeyHelper keyHelper = KeyHelper();
    final Set<Commit> commits =
        await datastore.queryRecentCommits(limit: maxRecords).toSet();

    Key timeSeriesKey;
    try {
      timeSeriesKey = keyHelper.decode(requestData[timeSeriesKeyParam]);
    } catch (error) {
      throw BadRequestException(
          'Bad timeSeries key: ${requestData[timeSeriesKeyParam]}');
    }

    final TimeSeries timeSeries =
        await config.db.lookupValue<TimeSeries>(timeSeriesKey, orElse: () {
      throw BadRequestException('No such timeseries: ${timeSeriesKey.id}');
    });

    List<TimeSeriesValue> timeSeriesValues = await datastore
        .queryRecentTimeSeriesValues(timeSeries,
            startFrom: startFromParam, limit: maxRecords)
        .toList();
    timeSeriesValues = insertMissingTimeseriesValues(timeSeriesValues, commits);

    return GetTimeSeriesHistoryResponse(timeSeries, timeSeriesValues);
  }
}

@immutable
class GetTimeSeriesHistoryResponse extends JsonBody {
  const GetTimeSeriesHistoryResponse(this.timeSeries, this.timeSeriesValues)
      : assert(timeSeries != null);

  final TimeSeries timeSeries;
  final List<TimeSeriesValue> timeSeriesValues;

  @override
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'BenchmarkData': BenchmarkData(
          timeSeriesEntity: TimeseriesEntity(timeSeries: timeSeries),
          values: timeSeriesValues),
      //LastPosition to do @Keyong
      'LastPosition': null,
    };
  }
}

List<TimeSeriesValue> insertMissingTimeseriesValues(
    List<TimeSeriesValue> timeSerialsValues, Set<Commit> commits) {
  final List<TimeSeriesValue> values = <TimeSeriesValue>[];
  final Map<String, TimeSeriesValue> valuesByCommit =
      <String, TimeSeriesValue>{};
  for (TimeSeriesValue value in timeSerialsValues) {
    valuesByCommit[value.revision] = value;
  }

  for (Commit commit in commits) {
    TimeSeriesValue value;

    if (valuesByCommit.containsKey(commit.sha)) {
      value = valuesByCommit[commit.sha];
      if (value.value < 0) {
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
  return values;
}
