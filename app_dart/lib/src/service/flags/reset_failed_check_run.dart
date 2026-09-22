// Copyright 2026 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:json_annotation/json_annotation.dart';
import 'package:meta/meta.dart';

part 'reset_failed_check_run.g.dart';

/// Flag that controls whether to reset failed check run to in progress.
@JsonSerializable()
@immutable
final class ResetFailedCheckRun {
  /// Default configuration for [ResetFailedCheckRun].
  static const defaultInstance = ResetFailedCheckRun._(
    useForAll: false,
    useForUsers: [],
  );

  /// Whether to to reset failed check run to in progress for all users.
  @JsonKey()
  final bool useForAll;

  /// List of users to to reset failed check run to in progress.
  @JsonKey()
  final List<String> useForUsers;

  const ResetFailedCheckRun._({
    required this.useForAll,
    required this.useForUsers,
  });

  /// Creates [ResetFailedCheckRun] flags from the provided fields.
  ///
  /// Any omitted fields default to the values in [defaultInstance].
  factory ResetFailedCheckRun({bool? useForAll, List<String>? useForUsers}) {
    return ResetFailedCheckRun._(
      useForAll: useForAll ?? defaultInstance.useForAll,
      useForUsers: useForUsers != null
          ? List<String>.unmodifiable(useForUsers)
          : defaultInstance.useForUsers,
    );
  }

  /// Creates [ResetFailedCheckRun] flags from a [json] object.
  ///
  /// Any omitted fields default to the values in [defaultInstance].
  factory ResetFailedCheckRun.fromJson(Map<String, Object?>? json) {
    return _$ResetFailedCheckRunFromJson(json ?? {});
  }

  /// The inverse operation of [ResetFailedCheckRun.fromJson].
  Map<String, Object?> toJson() => _$ResetFailedCheckRunToJson(this);
}
