// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

//import 'package:gcloud/db.dart';
import 'package:cocoon_service/src/model/appengine/key_converter.dart';
import 'package:json_annotation/json_annotation.dart';
import 'time_series.dart';

part 'time_series_entity.g.dart';

@JsonSerializable(nullable: true)
class TimeseriesEntity {
  const TimeseriesEntity({this.timeSeries});

  factory TimeseriesEntity.fromJson(Map<String, dynamic> json) =>
      _$TimeseriesEntityFromJson(json);

  @JsonKey(name: 'TimeSeries')
  final TimeSeries timeSeries;

  @JsonKey(name: 'Key')
  String get key => const KeyConverter().toJson(timeSeries.key);

  Map<String, dynamic> toJson() => _$TimeseriesEntityToJson(this);
}
