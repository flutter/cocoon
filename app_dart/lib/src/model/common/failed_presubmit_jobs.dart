// Copyright 2026 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// @docImport 'failed_presubmit_jobs.dart';
library;

import 'package:collection/collection.dart';

import 'package:github/github.dart';

import '../firestore/base.dart';

/// Contains the list of failed jobs that are proposed to be re-run.
///
/// See: [UnifiedCheckRun.reInitializeFailedJobs]
class FailedJobsForRerun {
  final CheckRun dashboardChecks;
  final CiStage stage;
  final Map<String, int> jobRetries;

  const FailedJobsForRerun({
    required this.dashboardChecks,
    required this.stage,
    required this.jobRetries,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FailedJobsForRerun &&
          other.dashboardChecks == dashboardChecks &&
          other.stage == stage &&
          const DeepCollectionEquality().equals(other.jobRetries, jobRetries));

  @override
  int get hashCode => Object.hashAll([
    dashboardChecks,
    stage,
    ...jobRetries.keys,
    ...jobRetries.values,
  ]);

  @override
  String toString() =>
      'FailedChecksForRerun("$dashboardChecks", "$stage", "$jobRetries")';
}
