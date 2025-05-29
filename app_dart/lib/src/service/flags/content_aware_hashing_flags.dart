// Copyright 2025 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:json_annotation/json_annotation.dart';
import 'package:meta/meta.dart';

part 'content_aware_hashing_flags.g.dart';

/// Flags related to content-aware hashing.
@JsonSerializable()
@immutable
final class ContentAwareHashing {
  /// Default configuration for [ContentAwareHashing] flags.
  static const defaultInstance = ContentAwareHashing._(
    waitOnContentHash: false,
  );

  /// Whether merge groups should wait for the content hash before scheduling.
  @JsonKey()
  final bool waitOnContentHash;

  const ContentAwareHashing._({
    required this.waitOnContentHash, //
  });

  /// Creates [ContentAwareHashing] flags from the provided fields.
  ///
  /// Any omitted fields default to the values in [defaultInstance].
  factory ContentAwareHashing({bool? waitOnContentHash}) {
    return ContentAwareHashing._(
      waitOnContentHash: waitOnContentHash ?? defaultInstance.waitOnContentHash,
    );
  }

  /// Creates [ContentAwareHashing] flags from a [json] object.
  ///
  /// Any omitted fields default to the values in [defaultInstance].
  factory ContentAwareHashing.fromJson(Map<String, Object?>? json) {
    return _$ContentAwareHashingFromJson(json ?? {});
  }

  /// The inverse operation of [ContentAwareHashing.fromJson].
  Map<String, Object?> toJson() => _$ContentAwareHashingToJson(this);
}
