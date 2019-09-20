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
class UpdateTimeSeries
    extends ApiRequestHandler<UpdateTimeSeriesResponse> {
  const UpdateTimeSeries(
    Config config,
    AuthenticationProvider authenticationProvider, {
    @visibleForTesting
        this.datastoreProvider = DatastoreService.defaultProvider,
  }) : super(config: config, authenticationProvider: authenticationProvider);

  final DatastoreServiceProvider datastoreProvider;
  static const String timeSeriesKeyParam = 'TimeSeriesKey';
  static const String goalParam = 'Goal';
  static const String baselineParam = 'Baseline';
  static const String taskNameParam = 'TaskName';
  static const String labelParam = 'Label';
  static const String unitParam = 'Unit';
  static const String archivedParam = 'Archived';

  @override
  Future<UpdateTimeSeriesResponse> post() async {
    checkRequiredParameters(
        <String>[timeSeriesKeyParam, goalParam, baselineParam]);

    final ClientContext clientContext = authContext.clientContext;
    final KeyHelper keyHelper =
        KeyHelper(applicationContext: clientContext.applicationContext);
    double goal = requestData[goalParam]?.toDouble();
    double baseline = requestData[baselineParam]?.toDouble();
    final String taskName = requestData[taskNameParam];
    final String label = requestData[labelParam];
    final String unit = requestData[unitParam];
    final bool archived = requestData[archivedParam]; 

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
    if (taskName.isEmpty) {
      throw BadRequestException('Missing required parameter: TaskName');
    }
    if (label.isEmpty) {
      throw BadRequestException('Missing required parameter: Label');
    }
    if (unit.isEmpty) {
      throw BadRequestException('Missing required parameter: Unit');
    }

    final TimeSeries timeSeries =
        await config.db.lookupValue<TimeSeries>(timeSeriesKey, orElse: () {
      throw BadRequestException('No such task: ${timeSeriesKey.id}');
    });
    timeSeries.goal = goal;
    timeSeries.taskName = taskName;
    timeSeries.label = label;
    timeSeries.unit = unit;
    timeSeries.baseline = baseline;
    timeSeries.archived = archived;

    await config.db.withTransaction<void>((Transaction transaction) async {
      transaction.queueMutations(inserts: <TimeSeries>[timeSeries]);
      await transaction.commit();
    });

    return UpdateTimeSeriesResponse(timeSeries);
  }
}

@immutable
class UpdateTimeSeriesResponse extends JsonBody {
  const UpdateTimeSeriesResponse(this.timeSeries)
      : assert(timeSeries != null);

  final TimeSeries timeSeries;

  @override
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'Goal': timeSeries.goal,
      'TaskName': timeSeries.taskName,
      'Label': timeSeries.label,
      'Unit': timeSeries.unit,
      'Baseline': timeSeries.baseline,
      'Archived': timeSeries.archived,
    };
  }
}
