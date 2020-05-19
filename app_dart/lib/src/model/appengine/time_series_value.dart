// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:gcloud/db.dart';
import 'package:json_annotation/json_annotation.dart';

import 'key_converter.dart';

part 'time_series_value.g.dart';

/// Class that represents an individual measurement of a metric as part of a
/// [TimeSeries].
@JsonSerializable(ignoreUnannotated: true)
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
    this.branch,
  }) {
    parentKey = key?.parent;
    id = key?.id;
  }

  factory TimeSeriesValue.fromJson(Map<String, dynamic> json) =>
      _$TimeSeriesValueFromJson(json);

  /// Whether data is missing for this measurement.
  @BoolProperty(propertyName: 'DataMissing')
  @JsonKey(name: 'DataMissing', defaultValue: false)
  bool dataMissing;

  /// The value of this measurement.
  ///
  /// The unit against which to interpret this value is stored in the value's
  /// [TimeSeries].
  @DoubleProperty(propertyName: 'Value', required: true)
  @JsonKey(name: 'Value')
  double value;

  /// The timestamp (in milliseconds since the Epoch) that this value was
  /// created.
  @IntProperty(propertyName: 'CreateTimestamp', required: true)
  @JsonKey(name: 'CreateTimestamp')
  int createTimestamp;

  /// The key of the task whose execution produced this measurement.
  @ModelKeyProperty(propertyName: 'TaskKey', required: true)
  @JsonKey(name: 'TaskKey')
  @KeyConverter()
  Key taskKey;

  /// The SHA1 hash of the commit at which this measurement was taken.
  ///
  /// See also:
  ///
  ///  * [Commit.sha]
  @StringProperty(propertyName: 'Revision', required: true)
  @JsonKey(name: 'Revision')
  String revision;

  /// The branch of [commit].
  @StringProperty(propertyName: 'Branch')
  String branch;

  /// Serializes this object to a JSON primitive.
  Map<String, dynamic> toJson() => _$TimeSeriesValueToJson(this);

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
      ..write(', branch: $branch')
      ..write(')');
    return buf.toString();
  }
}
