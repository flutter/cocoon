// Copyright 2026 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:json_annotation/json_annotation.dart';
import 'package:meta/meta.dart';

import '../../guard_status.dart';

part 'presubmit_guard_summary.g.dart';

/// Represents a summary of presubmit guard for a specific commit.
@immutable
@JsonSerializable(fieldRename: FieldRename.snake)
final class PresubmitGuardSummary {
  const PresubmitGuardSummary({
    required this.commitSha,
    required this.creationTime,
    required this.guardStatus,
  });

  /// The commit SHA.
  final String commitSha;

  /// The creation timestamp in microseconds since epoch.
  final int creationTime;

  /// The status of the guard.
  final GuardStatus guardStatus;

  /// Creates a [PresubmitGuardSummary] from a JSON map.
  factory PresubmitGuardSummary.fromJson(Map<String, Object?> json) =>
      _$PresubmitGuardSummaryFromJson(json);

  /// Converts this [PresubmitGuardSummary] to a JSON map.
  Map<String, Object?> toJson() => _$PresubmitGuardSummaryToJson(this);
}
