// Copyright 2026 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:github/github.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:meta/meta.dart';

part 'want_lgtm_flags.g.dart';

/// Flags related to WANT_LGTM pull request merge blocking.
@JsonSerializable()
@immutable
final class WantLgtmFlags {
  /// Default configuration for [WantLgtmFlags].
  static const defaultInstance = WantLgtmFlags._(
    enabled: false,
    useForAllRepos: false,
    enabledRepos: <String>[],
  );

  /// Global kill-switch for WANT_LGTM reconciliation and check run mutations.
  @JsonKey()
  final bool enabled;

  /// Whether WANT_LGTM should be evaluated across all repositories.
  @JsonKey()
  final bool useForAllRepos;

  /// Specific repository slugs (e.g. 'flutter/cocoon') enabled for WANT_LGTM.
  @JsonKey()
  final List<String> enabledRepos;

  const WantLgtmFlags._({
    required this.enabled,
    required this.useForAllRepos,
    required this.enabledRepos,
  });

  /// Creates [WantLgtmFlags] from the provided fields.
  ///
  /// Any omitted fields default to the values in [defaultInstance].
  factory WantLgtmFlags({
    bool? enabled,
    bool? useForAllRepos,
    List<String>? enabledRepos,
  }) {
    return WantLgtmFlags._(
      enabled: enabled ?? defaultInstance.enabled,
      useForAllRepos: useForAllRepos ?? defaultInstance.useForAllRepos,
      enabledRepos: enabledRepos ?? defaultInstance.enabledRepos,
    );
  }

  /// Creates [WantLgtmFlags] from a [json] object.
  factory WantLgtmFlags.fromJson(Map<String, Object?>? json) {
    return _$WantLgtmFlagsFromJson(json ?? {});
  }

  /// The inverse operation of [WantLgtmFlags.fromJson].
  Map<String, Object?> toJson() => _$WantLgtmFlagsToJson(this);

  /// Returns whether WANT_LGTM is enabled for the given [slug].
  bool isEnabledForRepo(RepositorySlug slug) {
    if (!enabled) {
      return false;
    }
    if (useForAllRepos) {
      return true;
    }
    final normalized = slug.fullName.toLowerCase();
    return enabledRepos.any((repo) => repo.toLowerCase() == normalized);
  }
}
