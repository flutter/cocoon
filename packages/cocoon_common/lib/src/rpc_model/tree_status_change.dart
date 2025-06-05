// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:json_annotation/json_annotation.dart';
import 'package:meta/meta.dart';

import 'base.dart';

part 'tree_status_change.g.dart';

@JsonSerializable(checked: true)
@immutable
final class TreeStatusChange extends Model {
  TreeStatusChange({
    required this.createdOn,
    required this.status,
    required this.authoredBy,
    required this.reason,
  });

  factory TreeStatusChange.fromJson(Map<String, Object?> json) {
    return _$TreeStatusChangeFromJson(json);
  }

  @JsonKey(name: 'createdOn')
  final DateTime createdOn;

  @JsonKey(name: 'status')
  final TreeStatus status;

  @JsonKey(name: 'author')
  final String authoredBy;

  @JsonKey(name: 'reason')
  final String? reason;

  @override
  Map<String, Object?> toJson() {
    return _$TreeStatusChangeToJson(this);
  }
}

/// Whether the [TreeStatusChange] was a success or failure.
enum TreeStatus { success, failure }
