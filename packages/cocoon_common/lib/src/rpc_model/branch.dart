// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:json_annotation/json_annotation.dart';
import 'package:meta/meta.dart';

import 'base.dart';

part 'branch.g.dart';

@JsonSerializable(checked: true)
@immutable
final class Branch extends Model {
  /// Creates a branch [reference] associated with a [channel].
  Branch({required this.channel, required this.reference});

  /// Creates a branch from [json] representation.
  factory Branch.fromJson(Map<String, Object?> json) {
    try {
      return _$BranchFromJson(json);
    } on CheckedFromJsonException catch (e) {
      throw FormatException('Invalid Branch: $e', json);
    }
  }

  /// Which deployment channel this branch is associated with.
  ///
  /// An example might be `master`, `stable`, or `beta`.
  @JsonKey(name: 'channel')
  final String channel;

  /// The reference name of the branch.
  ///
  /// An example might be `master` or `flutter-0.42-candidate.0`.
  @JsonKey(name: 'reference')
  final String reference;

  @override
  Map<String, Object?> toJson() => _$BranchToJson(this);
}
