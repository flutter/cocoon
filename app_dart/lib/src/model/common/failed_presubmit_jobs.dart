// Copyright 2026 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// @docImport 'failed_presubmit_jobs.dart';
library;

import 'package:github/github.dart';

import '../firestore/base.dart';

/// Contains the list of failed jobs that are proposed to be re-run.
///
/// See: [UnifiedCheckRun.reInitializeFailedJobs]
class FailedJobsForRerun {
  final CheckRun checkRunGuard;
  final CiStage stage;
  final List<String> checkNames;

  const FailedJobsForRerun({
    required this.checkRunGuard,
    required this.stage,
    required this.checkNames,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FailedJobsForRerun &&
          other.checkRunGuard == checkRunGuard &&
          other.stage == stage &&
          other.checkNames == checkNames);

  @override
  int get hashCode => Object.hashAll([checkRunGuard, stage, checkNames]);

  @override
  String toString() =>
      'FailedJobsForRerun("$checkRunGuard", "$stage", "$checkNames")';
}
