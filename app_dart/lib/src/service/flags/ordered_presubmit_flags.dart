// Copyright 2025 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:json_annotation/json_annotation.dart';
import 'package:meta/meta.dart';

part 'ordered_presubmit_flags.g.dart';

/// Flags related to ordered presubmit configuration.
@JsonSerializable()
@immutable
final class OrderedPresubmit {
  /// Default configuration for [OrderedPresubmit] flags.
  static const defaultInstance = OrderedPresubmit._(
    useForAll: false,
    useForUsers: [],
  );

  /// Whether to process LUCI notifications of builds progress ordered within check run
  /// for all users.
  @JsonKey()
  final bool useForAll;

  /// List of users to process LUCI notifications of builds progress ordered within check run.
  @JsonKey()
  final List<String> useForUsers;

  const OrderedPresubmit._({
    required this.useForAll, //
    required this.useForUsers, //
  });

  /// Creates [OrderedPresubmit] flags from the provided fields.
  ///
  /// Any omitted fields default to the values in [defaultInstance].
  factory OrderedPresubmit({bool? useForAll, List<String>? useForUsers}) {
    return OrderedPresubmit._(
      useForAll: useForAll ?? defaultInstance.useForAll,
      useForUsers: useForUsers ?? defaultInstance.useForUsers,
    );
  }

  /// Creates [OrderedPresubmit] flags from a [json] object.
  ///
  /// Any omitted fields default to the values in [defaultInstance].
  factory OrderedPresubmit.fromJson(Map<String, Object?>? json) {
    return _$OrderedPresubmitFromJson(json ?? {});
  }

  /// The inverse operation of [OrderedPresubmit.fromJson].
  Map<String, Object?> toJson() => _$OrderedPresubmitToJson(this);
}
