// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:json_annotation/json_annotation.dart';
import 'package:meta/meta.dart';

import 'base.dart';

part 'presubmit_check_response.g.dart';

/// RPC model for a presubmit check.
@JsonSerializable(
  checked: true,
  fieldRename: FieldRename.snake,
  includeIfNull: false,
)
@immutable
final class PresubmitCheckResponse extends Model {
  /// Creates a [PresubmitCheckResponse] with the given properties.
  PresubmitCheckResponse({
    required this.attemptNumber,
    required this.buildName,
    required this.creationTime,
    this.startTime,
    this.endTime,
    required this.status,
    this.summary,
    this.buildNumber,
  });

  /// Creates a [PresubmitCheckResponse] from [json] representation.
  factory PresubmitCheckResponse.fromJson(Map<String, Object?> json) {
    try {
      return _$PresubmitCheckResponseFromJson(json);
    } on CheckedFromJsonException catch (e) {
      throw FormatException('Invalid PresubmitCheckResponse: $e', json);
    }
  }

  /// The attempt number for this check.
  final int attemptNumber;

  /// The name of the build.
  final String buildName;

  /// The time the check was created in milliseconds since the epoch.
  final int creationTime;

  /// The time the check started in milliseconds since the epoch.
  final int? startTime;

  /// The time the check ended in milliseconds since the epoch.
  final int? endTime;

  /// The status of the check.
  final String status;

  /// A brief summary of the check result or link to logs.
  final String? summary;

  /// The LUCI build number.
  final int? buildNumber;

  @override
  Map<String, Object?> toJson() => _$PresubmitCheckResponseToJson(this);
}
