// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:fixnum/fixnum.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:meta/meta.dart';

import '../../task_status.dart';
import 'base.dart';

part 'presubmit_job_response.g.dart';

/// RPC model for a presubmit job.
@JsonSerializable(
  checked: true,
  fieldRename: FieldRename.snake,
  includeIfNull: false,
)
@immutable
final class PresubmitJobResponse extends Model {
  /// Creates a [PresubmitJobResponse] with the given properties.
  PresubmitJobResponse({
    required this.attemptNumber,
    required this.jobName,
    required this.creationTime,
    this.startTime,
    this.endTime,
    required this.status,
    this.summary,
    this.buildNumber,
    this.buildId,
    this.logAnalysis,
  });

  /// Creates a [PresubmitJobResponse] from [json] representation.
  factory PresubmitJobResponse.fromJson(Map<String, Object?> json) {
    try {
      return _$PresubmitJobResponseFromJson(json);
    } on CheckedFromJsonException catch (e) {
      throw FormatException('Invalid PresubmitJobResponse: $e', json);
    }
  }

  /// The attempt number for this check.
  final int attemptNumber;

  /// The name of the build.
  final String jobName;

  /// The time the job was created in milliseconds since the epoch.
  final int creationTime;

  /// The time the job started in milliseconds since the epoch.
  final int? startTime;

  /// The time the job ended in milliseconds since the epoch.
  final int? endTime;

  /// The status of the job.
  final TaskStatus status;

  /// A brief summary of the job result or link to logs.
  final String? summary;

  /// The LUCI build number.
  final int? buildNumber;

  /// The LUCI build ID.
  @Int64Converter()
  final Int64? buildId;

  /// The log analysis result.
  final String? logAnalysis;

  @override
  Map<String, Object?> toJson() => _$PresubmitJobResponseToJson(this);
}

/// A JSON converter for [Int64] fields that supports deserializing both strings
/// and numbers, and serializes back to string to preserve precision.
class Int64Converter implements JsonConverter<Int64?, Object?> {
  const Int64Converter();

  @override
  Int64? fromJson(Object? json) {
    if (json == null) {
      return null;
    }
    if (json is String) {
      return Int64.parseInt(json);
    }
    if (json is num) {
      return Int64(json.toInt());
    }
    throw FormatException('Cannot convert $json to Int64');
  }

  @override
  Object? toJson(Int64? object) => object?.toString();
}
