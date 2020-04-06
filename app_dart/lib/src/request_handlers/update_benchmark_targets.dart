// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:appengine/appengine.dart';
import 'package:cocoon_service/src/model/appengine/time_series.dart';
import 'package:gcloud/db.dart';
import 'package:meta/meta.dart';

import '../datastore/cocoon_config.dart';
import '../model/appengine/key_helper.dart';
import '../request_handling/api_request_handler.dart';
import '../request_handling/authentication.dart';
import '../request_handling/body.dart';
import '../request_handling/exceptions.dart';
import '../service/datastore.dart';

@immutable
class UpdateBenchmarkTargets
    extends ApiRequestHandler<UpdateBenchmarkTargetsResponse> {
  const UpdateBenchmarkTargets(
    Config config,
    AuthenticationProvider authenticationProvider, {
    @visibleForTesting
        this.datastoreProvider = DatastoreService.defaultProvider,
  }) : super(config: config, authenticationProvider: authenticationProvider);

  final DatastoreServiceProvider datastoreProvider;

  static const String timeSeriesKeyParam = 'TimeSeriesKey';
  static const String goalParam = 'Goal';
  static const String baselineParam = 'Baseline';

  @override
  Future<UpdateBenchmarkTargetsResponse> post() async {
    checkRequiredParameters(
        <String>[timeSeriesKeyParam, goalParam, baselineParam]);

    final ClientContext clientContext = authContext.clientContext;
    final DatastoreService datastore = datastoreProvider(
        db: config.db, maxEntityGroups: config.maxEntityGroups);
    final KeyHelper keyHelper =
        KeyHelper(applicationContext: clientContext.applicationContext);
    double goal = requestData[goalParam] as double;
    double baseline = requestData[baselineParam] as double;

    Key timeSeriesKey;
    try {
      timeSeriesKey =
          keyHelper.decode(requestData[timeSeriesKeyParam] as String);
    } catch (error) {
      throw BadRequestException(
          'Bad timeSeries key: ${requestData[timeSeriesKeyParam]}');
    }

    final TimeSeries timeSeries = await config.db.lookupValue<TimeSeries>(
      timeSeriesKey,
      orElse: () {
        throw BadRequestException('Invalid time series Key: $timeSeriesKey');
      },
    );

    if (goal < 0) {
      goal = 0;
    }
    if (baseline < 0) {
      baseline = 0;
    }

    timeSeries.goal = goal;
    timeSeries.baseline = baseline;

    await datastore.db.commit(inserts: <TimeSeries>[timeSeries]);

    return UpdateBenchmarkTargetsResponse(timeSeries);
  }
}

@immutable
class UpdateBenchmarkTargetsResponse extends JsonBody {
  const UpdateBenchmarkTargetsResponse(this.timeSeries)
      : assert(timeSeries != null);

  final TimeSeries timeSeries;

  @override
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'Goal': timeSeries.goal,
      'Baseline': timeSeries.baseline,
    };
  }
}
