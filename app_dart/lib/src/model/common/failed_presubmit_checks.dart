// Copyright 2026 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// @docImport 'failed_presubmit_checks.dart';
library;

import 'package:github/github.dart';

/// Contains the list of failed checks that are proposed to be re-run.
///
/// See: [UnifiedCheckRun.reInitializeFailedChecks]
class FailedChecksForRerun {
  final CheckRun checkRunGuard;
  final List<String> checkNames;

  const FailedChecksForRerun({
    required this.checkRunGuard,
    required this.checkNames,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FailedChecksForRerun &&
          other.checkRunGuard == checkRunGuard &&
          other.checkNames == checkNames);

  @override
  int get hashCode => Object.hashAll([checkRunGuard, checkNames]);

  @override
  String toString() => 'FailedChecksForRerun("$checkRunGuard", "$checkNames")';
}
