// Copyright 2025 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:json_annotation/json_annotation.dart';
import 'package:meta/meta.dart';

part 'content_aware_hashing_flags.g.dart';

@JsonSerializable()
@immutable
final class ContentAwareHasingJson {
  ContentAwareHasingJson({required this.waitOnContentHash});

  /// Merge Groups should wait for the content hash before scheduling.
  @JsonKey(defaultValue: false)
  final bool waitOnContentHash;

  /// Connect the generated [_$ContentAwareHasingJsonFromJson] function to the `fromJson`
  /// factory.
  factory ContentAwareHasingJson.fromJson(Map<String, Object?>? json) =>
      _$ContentAwareHasingJsonFromJson(json ?? {});

  /// Connect the generated [_$ContentAwareHasingJsonToJson] function to the `toJson` method.
  Map<String, dynamic> toJson() => _$ContentAwareHasingJsonToJson(this);
}
