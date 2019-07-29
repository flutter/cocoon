// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:gcloud/db.dart';

@Kind(name: 'TimeseriesValue')
class TimeSeriesValue extends Model {
  /// Creates a new [TimeSeriesValue].
  TimeSeriesValue({
    Key key,
    this.dataMissing,
    this.value,
    this.createTimestamp,
    this.taskKey,
    this.revision,
  }) {
    parentKey = key.parent;
    id = key.id;
  }

  @BoolProperty(propertyName: 'DataMissing', required: true)
  bool dataMissing;

  @DoubleProperty(propertyName: 'Value', required: true)
  double value;

  @IntProperty(propertyName: 'CreateTimestamp', required: true)
  int createTimestamp;

  @ModelKeyProperty(propertyName: 'TaskKey', required: true)
  Key taskKey;

  @StringProperty(propertyName: 'Revision', required: true)
  String revision;

  @override
  String toString() {
    final StringBuffer buf = StringBuffer();
    buf
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
