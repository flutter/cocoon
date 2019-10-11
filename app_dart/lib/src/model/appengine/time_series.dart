// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:gcloud/db.dart';
import 'package:json_annotation/json_annotation.dart';

import 'key_converter.dart';

part 'time_series.g.dart';

/// Class that represents a quantifiable metric that is tracked at every commit
/// for the Flutter benchmarks.
///
/// Values in a series  are stored in [TimeSeriesValue], whose keys are
/// children of [TimeSeries] keys.
@JsonSerializable(ignoreUnannotated: true)
@Kind(name: 'Timeseries', idType: IdType.String)
class TimeSeries extends Model {
  /// Creates a new [TimeSeries].
  TimeSeries({
    Key key,
    this.archived = false,
    this.baseline = 0,
    this.goal = 0,
    this.timeSeriesId,
    this.label,
    this.taskName,
    this.unit,
  }) {
    parentKey = key?.parent;
    id = key?.id;
  }

  factory TimeSeries.fromJson(Map<String, dynamic> json) =>
      _$TimeSeriesFromJson(json);

  /// Whether the series has been archived and is no longer active.
  @BoolProperty(propertyName: 'Archived', required: true)
  @JsonKey(name: 'Archived')
  bool archived;

  /// The metric value that defines the baseline for this series.
  ///
  /// Values above this baseline will be flagged in the Flutter dashboard as
  /// needing attention.
  @DoubleProperty(propertyName: 'Baseline')
  @JsonKey(name: 'Baseline')
  double baseline;

  /// The metric value that the series is striving to achieve.
  @DoubleProperty(propertyName: 'Goal', required: true)
  @JsonKey(name: 'Goal')
  double goal;

  /// The identifier of the series.
  @StringProperty(propertyName: 'ID', required: true)
  @JsonKey(name: 'ID')
  String timeSeriesId;

  /// The human readable name of the series (e.g. "aot_snapshot_build_millis").
  @StringProperty(propertyName: 'Label', required: true)
  @JsonKey(name: 'Label')
  String label;

  /// The name of the [Task] whose execution records values for this series.
  @StringProperty(propertyName: 'TaskName')
  @JsonKey(name: 'TaskName')
  String taskName;

  /// The unit of measurement against which values in this series are applied
  /// (e.g. "ms", "bytes").
  @StringProperty(propertyName: 'Unit', required: true)
  @JsonKey(name: 'Unit')
  String unit;

  /// Serializes this object to a JSON primitive.
  Map<String, dynamic> toJson() => _$TimeSeriesToJson(this);

  @override
  String toString() {
    final StringBuffer buf = StringBuffer()
      ..write('$runtimeType(')
      ..write('id: $id')
      ..write(', parentKey: ${parentKey?.id}')
      ..write(', key: ${parentKey == null ? null : key.id}')
      ..write(', archived: $archived')
      ..write(', baseline: $baseline')
      ..write(', goal: $goal')
      ..write(', timeSeriesId: $timeSeriesId')
      ..write(', label: $label')
      ..write(', taskName: $taskName')
      ..write(', unit: $unit')
      ..write(')');
    return buf.toString();
  }
}

/// The serialized representation of a [TimeSeries].
// TODO(tvolkert): Directly serialize [TimeSeries] once frontends migrate to new format.
@JsonSerializable(createFactory: false)
class SerializableTimeSeries {
  const SerializableTimeSeries({
    this.series,
  });

  @JsonKey(name: 'Timeseries')
  final TimeSeries series;

  @JsonKey(name: 'Key')
  @KeyConverter()
  Key get key => series.key;

  /// Serializes this object to a JSON primitive.
  Map<String, dynamic> toJson() => _$SerializableTimeSeriesToJson(this);
}
