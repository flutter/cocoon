// Copyright 2025 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:json_annotation/json_annotation.dart';
import 'package:meta/meta.dart';

part 'ci_yaml_flags.g.dart';

/// Flags related to resolving `.ci.yaml`.
@JsonSerializable()
@immutable
final class CiYamlFlags {
  /// Default configuration for [CiYamlFlags] flags.
  static const defaultInstance = CiYamlFlags._();

  const CiYamlFlags._();

  /// Creates [CiYamlFlags] flags from the provided fields.
  ///
  /// Any omitted fields default to the values in [defaultInstance].
  factory CiYamlFlags() {
    return const CiYamlFlags._();
  }

  /// Creates [ContentAwareHashing] flags from a [json] object.
  ///
  /// Any omitted fields default to the values in [defaultInstance].
  factory CiYamlFlags.fromJson(Map<String, Object?>? json) {
    return _$CiYamlFlagsFromJson(json ?? {});
  }

  /// The inverse operation of [CiYamlFlags.fromJson].
  Map<String, Object?> toJson() => _$CiYamlFlagsToJson(this);
}
