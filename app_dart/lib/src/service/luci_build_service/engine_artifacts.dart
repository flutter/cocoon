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

  /// This build should use engine artifacts built during pre-submit (i.e. from source) for [commitSha].
  const factory EngineArtifacts.builtFromSource({required String commitSha}) =
      SpecifiedEngineArtifacts._builtFromSourceUsingSha;

  /// This build should use engine artifacts built during post-submiut for [commitSha].
  const factory EngineArtifacts.usingExistingEngine({
    required String commitSha,
  }) = SpecifiedEngineArtifacts._alreadyBuiltAtExistingSha;
}

/// Required [EngineArtifacts].
final class SpecifiedEngineArtifacts extends EngineArtifacts {
  const SpecifiedEngineArtifacts._builtFromSourceUsingSha({
    required this.commitSha,
  }) : isBuiltFromSource = true;

  const SpecifiedEngineArtifacts._alreadyBuiltAtExistingSha({
    required this.commitSha,
  }) : isBuiltFromSource = false;

  /// What SHA to provide to `FLUTTER_PREBUILT_ENGINE_VERSION`.
  final String commitSha;

  /// Whether [commitSha] is built from source in the pull request.
  final bool isBuiltFromSource;

  /// Which storage upload bucket this artifact belongs to.
  ///
  /// From source (presubmit) builds are in a separate bucket than postsubmit builds.
  String get flutterRealm => isBuiltFromSource ? 'flutter_archives_v2' : '';

  @override
  bool operator ==(Object other) {
    return other is SpecifiedEngineArtifacts &&
        commitSha == other.commitSha &&
        isBuiltFromSource == other.isBuiltFromSource;
  }

  @override
  int get hashCode => Object.hash(commitSha, isBuiltFromSource);

  @override
  String toString() {
    return 'EngineArtifacts.${isBuiltFromSource ? 'builtFromSource' : 'usingExistingEngine'}(commitSha: $commitSha)';
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
