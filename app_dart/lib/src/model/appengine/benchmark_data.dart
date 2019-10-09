// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_service/src/model/appengine/time_series_entity.dart';
import 'package:json_annotation/json_annotation.dart';
import 'time_series_entity.dart';
import 'time_series_value.dart';

part 'benchmark_data.g.dart';

@JsonSerializable(nullable: true)
class BenchmarkData {
  const BenchmarkData({this.timeSeriesEntity, this.values});

  factory BenchmarkData.fromJson(Map<String, dynamic> json) =>
      _$BenchmarkDataFromJson(json);

  @JsonKey(name: 'TimeSeries')
  final TimeseriesEntity timeSeriesEntity;

  @JsonKey(name: 'Values')
  final List<TimeSeriesValue> values;

  Map<String, dynamic> toJson() => _$BenchmarkDataToJson(this);
}
