// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:collection/collection.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:meta/meta.dart';

import 'base.dart';

part 'build_status_response.g.dart';

enum BuildStatus {
  success,
  failure;

  factory BuildStatus._byName(String name) {
    final result = values.firstWhereOrNull((e) => e.name == name);
    if (result == null) {
      throw FormatException('Unexpected name', name);
    }
    return result;
  }

  static String _toName(BuildStatus status) => status.name;
}

@JsonSerializable(checked: true)
@immutable
final class BuildStatusResponse extends Model {
  BuildStatusResponse({
    required this.buildStatus,
    required Iterable<String> failingTasks,
  }) : failingTasks = List.unmodifiable(failingTasks);

  factory BuildStatusResponse.fromJson(Map<String, Object?> json) {
    try {
      return _$BuildStatusResponseFromJson(json);
    } on CheckedFromJsonException catch (e) {
      throw FormatException('Invalid BuildStatusResponse: $e', json);
    }
  }

  @JsonKey(
    name: 'buildStatus',
    fromJson: BuildStatus._byName,
    toJson: BuildStatus._toName,
  )
  final BuildStatus buildStatus;

  @JsonKey(name: 'failingTasks', defaultValue: <String>[])
  final List<String> failingTasks;

  @override
  Map<String, Object?> toJson() => _$BuildStatusResponseToJson(this);
}
