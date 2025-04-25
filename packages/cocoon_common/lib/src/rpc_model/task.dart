// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:json_annotation/json_annotation.dart';
import 'package:meta/meta.dart';

import 'base.dart';

part 'task.g.dart';

@JsonSerializable(checked: true)
@immutable
final class Task extends Model {
  /// Creates a task with the given properties.
  Task({
    required this.createTimestamp,
    required this.startTimestamp,
    required this.endTimestamp,
    required this.attempts,
    required this.isBringup,
    required this.isFlaky,
    required this.status,
    required this.buildNumberList,
    required this.builderName,
    required this.lastAttemptFailed,
    required this.currentBuildNumber,
  });

  /// Creates a task from [json] representation.
  factory Task.fromJson(Map<String, Object?> json) {
    try {
      return _$TaskFromJson(json);
    } on CheckedFromJsonException catch (e) {
      throw FormatException('Invalid Task: $e', json);
    }
  }

  @JsonKey(name: 'CreateTimestamp')
  final int createTimestamp;

  @JsonKey(name: 'StartTimestamp')
  final int startTimestamp;

  @JsonKey(name: 'EndTimestamp')
  final int endTimestamp;

  @JsonKey(name: 'Attempts')
  final int attempts;

  @JsonKey(name: 'IsBringup')
  final bool isBringup;

  @JsonKey(name: 'IsFlaky')
  final bool isFlaky;

  @JsonKey(name: 'Status')
  final String status;

  @JsonKey(name: 'BuildNumberList')
  final List<int> buildNumberList;

  @JsonKey(name: 'BuilderName')
  final String builderName;

  // TODO(matanlurey): It would be nice to encode a lot more of this bool-ish
  // state into status, i.e. have status be a more complex object than a string,
  // or consider how it could be bundled in interesting ways.

  @JsonKey(name: 'LastAttemptFailed')
  final bool lastAttemptFailed;

  @JsonKey(name: 'CurrentBuildNumber')
  final int? currentBuildNumber;

  @override
  Map<String, Object?> toJson() => _$TaskToJson(this);
}
