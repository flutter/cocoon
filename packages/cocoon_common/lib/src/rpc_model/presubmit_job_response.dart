// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:json_annotation/json_annotation.dart';
import 'package:meta/meta.dart';

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
    required this.buildName,
    required this.creationTime,
    this.startTime,
    this.endTime,
    required this.status,
    this.summary,
    this.buildNumber,
  });

  /// Creates a [PresubmitJobResponse] from [json] representation.
  factory PresubmitJobResponse.fromJson(Map<String, Object?> json) {
    try {
      return _$PresubmitJobResponseFromJson(json);
    } on CheckedFromJsonException catch (e) {
      throw FormatException('Invalid PresubmitJobResponse: $e', json);
    }
  }

  /// The attempt number for this job.
  final int attemptNumber;

  /// The name of the build.
  final String buildName;

  /// The time the job was created in milliseconds since the epoch.
  final int creationTime;

  /// The time the job started in milliseconds since the epoch.
  final int? startTime;

  /// The time the job ended in milliseconds since the epoch.
  final int? endTime;

  /// The status of the job.
  final String status;

  /// A brief summary of the job result or link to logs.
  final String? summary;

  /// The LUCI build number.
  final int? buildNumber;

  @override
  Map<String, Object?> toJson() => _$PresubmitJobResponseToJson(this);
}
