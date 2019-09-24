// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:appengine/appengine.dart';
import 'package:cocoon_service/src/model/appengine/time_series.dart';
import 'package:gcloud/db.dart';
import 'package:meta/meta.dart';

import '../model/appengine/key_helper.dart';
import '../request_handling/api_request_handler.dart';
import '../request_handling/authentication.dart';
import '../request_handling/body.dart';
import '../request_handling/exceptions.dart';
import '../service/datastore.dart';

@immutable
class UpdateBenchmarkTargets
    extends ApiRequestHandler<Body> {
  const UpdateBenchmarkTargets(
    AuthenticationProvider authenticationProvider, {
    @visibleForTesting
        this.datastoreProvider = DatastoreService.defaultProvider,
  }) : super(authenticationProvider: authenticationProvider);

  final DatastoreServiceProvider datastoreProvider;

  static const String timeSeriesKeyParam = 'TimeSeriesKey';
  static const String goalParam = 'Goal';
  static const String baselineParam = 'Baseline';

  @override
  Future<Body> post() async {
    checkRequiredParameters(
        <String>[timeSeriesKeyParam, goalParam, baselineParam]);

    final ClientContext clientContext = authContext.clientContext;
    final DatastoreService datastore = datastoreProvider();
    final KeyHelper keyHelper =
        KeyHelper(applicationContext: clientContext.applicationContext);
    double goal = requestData[goalParam];
    double baseline = requestData[baselineParam];

    Key timeSeriesKey;
    try {
      timeSeriesKey = keyHelper.decode(requestData[timeSeriesKeyParam]);
    } catch (error) {
      throw BadRequestException(
          'Bad timeSeries key: ${requestData[timeSeriesKeyParam]}');
    }

    if (goal < 0) {
      goal = 0;
    }
    if (baseline < 0) {
      baseline = 0;
    }

    final TimeSeries timeSeries =
        await datastore.db.lookupValue<TimeSeries>(timeSeriesKey, orElse: () {
      throw BadRequestException('No such task: ${timeSeriesKey.id}');
    });
    timeSeries.goal = goal;
    timeSeries.baseline = baseline;

    await datastore.db.commit(inserts: <TimeSeries>[timeSeries]);

    return Body.forJson(<String, dynamic>{
      'Label': timeSeries.label,
      'Goal': timeSeries.goal,
      'Baseline': timeSeries.baseline,
    });
  }
}