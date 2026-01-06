// Copyright 2025 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:json_annotation/json_annotation.dart';
import 'package:meta/meta.dart';

part 'unified_check_run_flow_flags.g.dart';

/// Flags related to content-aware hashing.
@JsonSerializable()
@immutable
final class UnifiedCheckRunFlow {
  /// Default configuration for [UnifiedCheckRunFlow] flags.
  static const defaultInstance = UnifiedCheckRunFlow._(
    useForAll: false,
    useForUsers: [],
  );

  /// Whether to use unified check-run flow with only one check-run created
  /// for all LUCI tests or legacy check-run flow.
  @JsonKey()
  final bool useForAll;

  /// List of users to use unified check-run flow.
  @JsonKey()
  final List<String> useForUsers;

  const UnifiedCheckRunFlow._({
    required this.useForAll, //
    required this.useForUsers, //
  });

  /// Creates [UnifiedCheckRunFlow] flags from the provided fields.
  ///
  /// Any omitted fields default to the values in [defaultInstance].
  factory UnifiedCheckRunFlow({bool? useForAll, List<String>? useForUsers}) {
    return UnifiedCheckRunFlow._(
      useForAll: useForAll ?? defaultInstance.useForAll,
      useForUsers: useForUsers ?? defaultInstance.useForUsers,
    );
  }

  /// Creates [UnifiedCheckRunFlow] flags from a [json] object.
  ///
  /// Any omitted fields default to the values in [defaultInstance].
  factory UnifiedCheckRunFlow.fromJson(Map<String, Object?>? json) {
    return _$UnifiedCheckRunFlowFromJson(json ?? {});
  }

  /// The inverse operation of [UnifiedCheckRunFlow.fromJson].
  Map<String, Object?> toJson() => _$UnifiedCheckRunFlowToJson(this);
}
