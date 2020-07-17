// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:json_annotation/json_annotation.dart';
import 'time_series.dart';

part 'time_series_entity.g.dart';

@JsonSerializable(nullable: true)
class TimeseriesEntity {
  const TimeseriesEntity({this.timeSeries, this.key});

  factory TimeseriesEntity.fromJson(Map<String, dynamic> json) => _$TimeseriesEntityFromJson(json);

  @JsonKey(name: 'Timeseries')
  final TimeSeries timeSeries;

  @JsonKey(name: 'Key')
  final String key;

  Map<String, dynamic> toJson() => _$TimeseriesEntityToJson(this);
}
