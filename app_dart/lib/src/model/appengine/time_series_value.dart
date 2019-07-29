// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:gcloud/db.dart';

/// Class that represents an individual measurement of a metric as part of a
/// [TimeSeries].
@Kind(name: 'TimeseriesValue')
class TimeSeriesValue extends Model {
  /// Creates a new [TimeSeriesValue].
  TimeSeriesValue({
    Key key,
    this.dataMissing = false,
    this.value,
    this.createTimestamp,
    this.taskKey,
    this.revision,
  }) {
    parentKey = key?.parent;
    id = key?.id;
  }

  /// Whether data is missing for this measurement.
  @BoolProperty(propertyName: 'DataMissing', required: true)
  bool dataMissing;

  /// The value of this measurement.
  ///
  /// The unit against which to interpret this value is stored in the value's
  /// [TimeSeries].
  @DoubleProperty(propertyName: 'Value', required: true)
  double value;

  /// The timestamp (in milliseconds since the Epoch) that this value was
  /// created.
  @IntProperty(propertyName: 'CreateTimestamp', required: true)
  int createTimestamp;

  /// The key of the task whose execution produced this measurement.
  @ModelKeyProperty(propertyName: 'TaskKey', required: true)
  Key taskKey;

  /// The SHA1 hash of the commit at which this measurement was taken.
  ///
  /// See also:
  ///
  ///  * [Commit.sha]
  @StringProperty(propertyName: 'Revision', required: true)
  String revision;

  @override
  String toString() {
    final StringBuffer buf = StringBuffer()
      ..write('$runtimeType(')
      ..write('id: $id')
      ..write(', parentKey: ${parentKey?.id}')
      ..write(', key: ${parentKey == null ? null : key.id}')
      ..write(', dataMissing: $dataMissing')
      ..write(', value: $value')
      ..write(', createTimestamp: $createTimestamp')
      ..write(', taskKey: ${taskKey?.id}')
      ..write(', revision: $revision')
      ..write(')');
    return buf.toString();
  }
}
