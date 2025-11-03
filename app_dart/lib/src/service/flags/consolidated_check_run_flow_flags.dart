// Copyright 2025 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:json_annotation/json_annotation.dart';
import 'package:meta/meta.dart';

part 'consolidated_check_run_flow_flags.g.dart';

/// Flags related to content-aware hashing.
@JsonSerializable()
@immutable
final class ConsolidatedCheckRunFlow {
  /// Default configuration for [ConsolidatedCheckRunFlow] flags.
  static const defaultInstance = ConsolidatedCheckRunFlow._(
    use: false,
    useForUsers: [],
  );

  /// Whether to use consolidated check-run flow with only one check-run created
  /// for all LUCI tests or legacy check-run flow.
  @JsonKey()
  final bool use;

  /// List of users to use consolidated check-run flow.
  @JsonKey()
  final List<String> useForUsers;

  const ConsolidatedCheckRunFlow._({
    required this.use, //
    required this.useForUsers, //
  });

  /// Creates [ConsolidatedCheckRunFlow] flags from the provided fields.
  ///
  /// Any omitted fields default to the values in [defaultInstance].
  factory ConsolidatedCheckRunFlow({bool? use, List<String>? useForUsers}) {
    return ConsolidatedCheckRunFlow._(
      use: use ?? defaultInstance.use,
      useForUsers: useForUsers ?? defaultInstance.useForUsers,
    );
  }

  /// Creates [ConsolidatedCheckRunFlow] flags from a [json] object.
  ///
  /// Any omitted fields default to the values in [defaultInstance].
  factory ConsolidatedCheckRunFlow.fromJson(Map<String, Object?>? json) {
    return _$ConsolidatedCheckRunFlowFromJson(json ?? {});
  }

  /// The inverse operation of [ConsolidatedCheckRunFlow.fromJson].
  Map<String, Object?> toJson() => _$ConsolidatedCheckRunFlowToJson(this);
}
