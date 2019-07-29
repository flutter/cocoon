// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:gcloud/db.dart';

@Kind(name: 'Timeseries', idType: IdType.String)
class TimeSeries extends Model {
  /// Creates a new [TimeSeries].
  TimeSeries({
    Key key,
    this.archived,
    this.baseline,
    this.goal,
    this.timeSeriesId,
    this.label,
    this.taskName,
    this.unit,
  }) {
    parentKey = key.parent;
    id = key.id;
  }

  @BoolProperty(propertyName: 'Archived', required: true)
  bool archived;

  @DoubleProperty(propertyName: 'Baseline')
  double baseline;

  @DoubleProperty(propertyName: 'Goal', required: true)
  double goal;

  @StringProperty(propertyName: 'ID', required: true)
  String timeSeriesId;

  @StringProperty(propertyName: 'Label', required: true)
  String label;

  @StringProperty(propertyName: 'TaskName')
  String taskName;

  @StringProperty(propertyName: 'Unit', required: true)
  String unit;

  @override
  String toString() {
    final StringBuffer buf = StringBuffer();
    buf
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
