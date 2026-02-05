// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:json_annotation/json_annotation.dart';
import 'package:meta/meta.dart';

import 'base.dart';

part 'presubmit_check.g.dart';

/// RPC model for a presubmit check attempt.
@JsonSerializable(checked: true)
@immutable
final class PresubmitCheck extends Model {
  /// Creates a [PresubmitCheck] with the given properties.
  PresubmitCheck({
    required this.attemptNumber,
    required this.taskName,
    required this.creationTime,
    this.startTime,
    this.endTime,
    required this.status,
    this.summary,
  });

  /// Creates a [PresubmitCheck] from [json] representation.
  factory PresubmitCheck.fromJson(Map<String, Object?> json) {
    try {
      return _$PresubmitCheckFromJson(json);
    } on CheckedFromJsonException catch (e) {
      throw FormatException('Invalid PresubmitCheck: $e', json);
    }
  }

  /// The attempt number for this check.
  @JsonKey(name: 'attempt_number')
  final int attemptNumber;

  /// The name of the task.
  @JsonKey(name: 'task_name')
  final String taskName;

  /// The time the check was created.
  @JsonKey(name: 'creation_time')
  final int creationTime;

  /// The time the check started.
  @JsonKey(name: 'start_time')
  final int? startTime;

  /// The time the check ended.
  @JsonKey(name: 'end_time')
  final int? endTime;

  /// The status of the check.
  @JsonKey(name: 'status')
  final String status;

  /// A brief summary of the check result or link to logs.
  @JsonKey(name: 'summary')
  final String? summary;

  @override
  Map<String, Object?> toJson() => _$PresubmitCheckToJson(this);
}
