// Copyright 2021 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:meta/meta.dart';

/// Determines how CI should download and use engine artifacts, if necessary.
@immutable
sealed class EngineArtifacts {
  const EngineArtifacts();

  /// This build does not run framework tests in `flutter/flutter` and does not need an engine.
  const factory EngineArtifacts.noFrameworkTests({required String reason}) =
      UnnecessaryEngineArtifacts._;

  /// This build should use engine artifacts built during pre-submit (i.e. from source).
  const factory EngineArtifacts.builtFromSource() =
      ContentAwareEngineArtifacts._buildDuringPresubmit;

  /// This build should use engine artifacts built during post-submit (i.e. from a previous build).
  const factory EngineArtifacts.usingExistingEngine() =
      ContentAwareEngineArtifacts._builtPreviousPostsubmit;
}

/// Required [EngineArtifacts] that use content-aware hashing.
final class ContentAwareEngineArtifacts extends EngineArtifacts {
  const ContentAwareEngineArtifacts._buildDuringPresubmit()
    : isBuiltFromSource = true;

  const ContentAwareEngineArtifacts._builtPreviousPostsubmit()
    : isBuiltFromSource = false;

  /// Whether the artifacts were built from source in the pull request.
  final bool isBuiltFromSource;

  /// Which storage upload bucket this artifact belongs to.
  ///
  /// From source (presubmit) builds are in a separate bucket than postsubmit builds.
  String get flutterRealm => isBuiltFromSource ? 'flutter_archives_v2' : '';

  @override
  bool operator ==(Object other) {
    return other is ContentAwareEngineArtifacts &&
        isBuiltFromSource == other.isBuiltFromSource;
  }

  @override
  int get hashCode =>
      Object.hash(ContentAwareEngineArtifacts, isBuiltFromSource);

  @override
  String toString() {
    return 'EngineArtifacts.${isBuiltFromSource ? 'builtFromSource' : 'usingExistingEngine'}';
  }
}

/// Unnecessary [EngineArtifacts].
///
/// This is a marker class because `engineArtifacts: EngineArtifacts.noFrameworkTests` reads better than `engineArtifacts: null`.
final class UnnecessaryEngineArtifacts extends EngineArtifacts {
  const UnnecessaryEngineArtifacts._({required this.reason});

  /// Human-readable description of why engine artifacts were not necessary.
  ///
  /// Used for debugging.
  final String reason;

  @override
  bool operator ==(Object other) {
    return other is UnnecessaryEngineArtifacts && reason == other.reason;
  }

  @override
  int get hashCode => reason.hashCode;

  @override
  String toString() {
    return 'EngineArtifacts.noFrameworkTests(reason: $reason)';
  }
}
