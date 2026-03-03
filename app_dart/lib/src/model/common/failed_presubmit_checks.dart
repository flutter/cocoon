// Copyright 2026 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// @docImport 'failed_presubmit_checks.dart';
library;

import 'package:collection/collection.dart';

import 'package:github/github.dart';

import '../firestore/base.dart';

/// Contains the list of failed checks that are proposed to be re-run.
///
/// See: [UnifiedCheckRun.reInitializeFailedChecks]
class FailedChecksForRerun {
  final CheckRun checkRunGuard;
  final CiStage stage;
  final Map<String, int> checkRetries;

  const FailedChecksForRerun({
    required this.checkRunGuard,
    required this.stage,
    required this.checkRetries,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FailedChecksForRerun &&
          other.checkRunGuard == checkRunGuard &&
          other.stage == stage &&
          const DeepCollectionEquality().equals(
            other.checkRetries,
            checkRetries,
          ));

  @override
  int get hashCode => Object.hashAll([
    checkRunGuard,
    stage,
    ...checkRetries.keys,
    ...checkRetries.values,
  ]);

  @override
  String toString() =>
      'FailedChecksForRerun("$checkRunGuard", "$stage", "$checkRetries")';
}
