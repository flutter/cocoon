// Copyright 2026 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:json_annotation/json_annotation.dart';
import 'package:meta/meta.dart';

import '../../guard_status.dart';

part 'presubmit_guards_response.g.dart';

/// Response model for a list of Presubmit Guards.
@immutable
@JsonSerializable(fieldRename: FieldRename.snake)
final class PresubmitGuardsResponse {
  const PresubmitGuardsResponse({
    required this.guards,
  });

  /// The list of presubmit guards.
  final List<PresubmitGuardItem> guards;

  /// Creates a [PresubmitGuardsResponse] from a JSON map.
  factory PresubmitGuardsResponse.fromJson(Map<String, Object?> json) =>
      _$PresubmitGuardsResponseFromJson(json);

  /// Converts this [PresubmitGuardsResponse] to a JSON map.
  Map<String, Object?> toJson() => _$PresubmitGuardsResponseToJson(this);
}

/// Represents a single presubmit guard item in a list.
@immutable
@JsonSerializable(fieldRename: FieldRename.snake)
final class PresubmitGuardItem {
  const PresubmitGuardItem({
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

  /// Creates a [PresubmitGuardItem] from a JSON map.
  factory PresubmitGuardItem.fromJson(Map<String, Object?> json) =>
      _$PresubmitGuardItemFromJson(json);

  /// Converts this [PresubmitGuardItem] to a JSON map.
  Map<String, Object?> toJson() => _$PresubmitGuardItemToJson(this);
}
