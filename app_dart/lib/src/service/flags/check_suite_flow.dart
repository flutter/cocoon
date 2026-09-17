// Copyright 2026 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:json_annotation/json_annotation.dart';
import 'package:meta/meta.dart';

part 'check_suite_flow.g.dart';

/// Flag that controls whether to use checks suite flow.
@JsonSerializable()
@immutable
final class CheckSuiteFlow {
  /// Default configuration for [CheckSuiteFlow].
  static const defaultInstance = CheckSuiteFlow._(
    useForAll: false,
    useForUsers: [],
  );

  /// Whether to use checks suite flow for all users.
  @JsonKey()
  final bool useForAll;

  /// List of users to use checks suite flow.
  @JsonKey()
  final List<String> useForUsers;

  const CheckSuiteFlow._({
    required this.useForAll, //
    required this.useForUsers, //
  });

  /// Creates [CheckSuiteFlow] flags from the provided fields.
  ///
  /// Any omitted fields default to the values in [defaultInstance].
  factory CheckSuiteFlow({bool? useForAll, List<String>? useForUsers}) {
    return CheckSuiteFlow._(
      useForAll: useForAll ?? defaultInstance.useForAll,
      useForUsers: useForUsers != null
          ? List<String>.unmodifiable(useForUsers)
          : defaultInstance.useForUsers,
    );
  }

  /// Creates [CheckSuiteFlow] flags from a [json] object.
  ///
  /// Any omitted fields default to the values in [defaultInstance].
  factory CheckSuiteFlow.fromJson(Map<String, Object?>? json) {
    return _$CheckSuiteFlowFromJson(json ?? {});
  }

  /// The inverse operation of [CheckSuiteFlow.fromJson].
  Map<String, Object?> toJson() => _$CheckSuiteFlowToJson(this);
}
