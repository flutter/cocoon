// Copyright 2016 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:json_annotation/json_annotation.dart';

part 'models.g.dart';


@JsonSerializable(nullable: true)
class GetBenchmarksResult {
  const GetBenchmarksResult({this.benchmarks});

  factory GetBenchmarksResult.fromJson(Map<String, dynamic> json) => _$GetBenchmarksResultFromJson(json);

  @JsonKey(name: 'Benchmarks')
  final List<BenchmarkData> benchmarks;

  Map<String, dynamic> toJson() => _$GetBenchmarksResultToJson(this);
}

@JsonSerializable(nullable: true)
class BenchmarkData {
  const BenchmarkData({this.timeseries, this.values});

  factory BenchmarkData.fromJson(Map<String, dynamic> json) => _$BenchmarkDataFromJson(json);

  @JsonKey(name: 'Timeseries')
  final TimeseriesEntity timeseries;

  @JsonKey(name: 'Values')
  final List<TimeseriesValue> values;

  Map<String, dynamic> toJson() => _$BenchmarkDataToJson(this);
}

@JsonSerializable(nullable: true)
class GetTimeseriesHistoryResult {
  const GetTimeseriesHistoryResult({
    this.benchmarkData,
    this.lastPosition,
  });

  factory GetTimeseriesHistoryResult.fromJson(Map<String, dynamic> json) => _$GetTimeseriesHistoryResultFromJson(json);

  @JsonKey(name: 'BenchmarkData')
  final BenchmarkData benchmarkData;

  @JsonKey(name: 'LastPosition', fromJson: fromCursor)
  final String lastPosition;

  Map<String, dynamic> toJson() => _$GetTimeseriesHistoryResultToJson(this);
}

@JsonSerializable(nullable: true)
class TimeseriesEntity {
  const TimeseriesEntity({
    this.key,
    this.timeseries,
  });

  factory TimeseriesEntity.fromJson(Map<String, dynamic> json) => _$TimeseriesEntityFromJson(json);

  @JsonKey(name: 'Key')
  final String key;

  @JsonKey(name: 'Timeseries')
  final Timeseries timeseries;

  Map<String, dynamic> toJson() => _$TimeseriesEntityToJson(this);
}

@JsonSerializable(nullable: true)
class Timeseries {
  const Timeseries({
    this.id,
    this.taskName,
    this.label,
    this.unit,
    this.goal,
    this.baseline,
    this.isArchived,
  });

  factory Timeseries.fromJson(Map<String, dynamic> json) => _$TimeseriesFromJson(json);

  @JsonKey(name: 'ID')
  final String id;

  @JsonKey(name: 'TaskName')
  final String taskName;

  @JsonKey(name: 'Label')
  final String label;

  @JsonKey(name: 'Unit')
  final String unit;

  @JsonKey(name: 'Goal')
  final double goal;

  @JsonKey(name: 'Baseline')
  final double baseline;

  @JsonKey(name: 'Archived')
  final bool isArchived;

  Map<String, dynamic> toJson() => _$TimeseriesToJson(this);
}

@JsonSerializable(nullable: true)
class BranchList {
  const BranchList({
    this.branches,
  });

  factory BranchList.fromJson(Map<String, dynamic> json) => _$BranchListFromJson(json);

  @JsonKey(name: 'Branches')
  final List<String> branches;

  Map<String, dynamic> toJson() => _$BranchListToJson(this);
}

@JsonSerializable(nullable: true)
class TimeseriesValue {
  const TimeseriesValue({
    this.createTimestamp,
    this.revision,
    this.value,
    this.isDataMissing,
  });

  factory TimeseriesValue.fromJson(Map<String, dynamic> json) => _$TimeseriesValueFromJson(json);

  @JsonKey(name: 'CreateTimestamp')
  final int createTimestamp;

  @JsonKey(name: 'Revision')
  final String revision;

  @JsonKey(name: 'Value')
  final double value;

  @JsonKey(name: 'DataMissing', defaultValue: false)
  final bool isDataMissing;

  Map<String, dynamic> toJson() => _$TimeseriesValueToJson(this);
}

/// Creates a [DateTime] object from milliseconds.
///
/// Used in a [JsonKey] annotation to deserialize a [DateTime] from an [int].
DateTime fromMilliseconds(int millisecondsSinceEpoch) {
  return new DateTime.fromMillisecondsSinceEpoch(millisecondsSinceEpoch);
}

/// Creates a string which represents a Cursor object
String fromCursor(Object value) {
  return value?.toString() ?? '';
}
