// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:gcloud/db.dart';

/// Class that represents a quantifiable metric that is tracked at every commit
/// for the Flutter benchmarks.
///
/// Values in a series  are stored in [TimeSeriesValue], whose keys are
/// children of [TimeSeries] keys.
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

  /// Whether the series has been archived and is no longer active.
  @BoolProperty(propertyName: 'Archived', required: true)
  bool archived;

  /// The metric value that defines the baseline for this series.
  ///
  /// Values above this baseline will be flagged in the Flutter dashboard as
  /// needing attention.
  @DoubleProperty(propertyName: 'Baseline')
  double baseline;

  /// The metric value that the series is striving to achieve.
  @DoubleProperty(propertyName: 'Goal', required: true)
  double goal;

  /// The identifier of the series.
  @StringProperty(propertyName: 'ID', required: true)
  String timeSeriesId;

  /// The human readable name of the series (e.g. "aot_snapshot_build_millis").
  @StringProperty(propertyName: 'Label', required: true)
  String label;

  /// The name of the [Task] whose execution records values for this series.
  @StringProperty(propertyName: 'TaskName')
  String taskName;

  /// The unit of measurement against which values in this series are applied
  /// (e.g. "ms", "bytes").
  @StringProperty(propertyName: 'Unit', required: true)
  String unit;

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
