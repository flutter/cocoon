// Copyright 2024 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:buildbucket/buildbucket_pb.dart';
import 'package:cocoon_common/task_status.dart';
import 'package:github/github.dart';
import 'package:meta/meta.dart';

import '../../foundation/utils.dart';
import '../../service/luci_build_service/build_tags.dart';
import '../../service/luci_build_service/user_data.dart';
import '../bbv2_extension.dart';
import '../firestore/base.dart';
import '../github/checks.dart' as cocoon_checks;
import 'checks_extension.dart';

/// Unified representation of a completed presubmit check.
///
/// This class abstracts away the source of the check (GitHub CheckRun or BuildBucket Build)
/// to allow unified processing logic.
@immutable
class PresubmitCompletedCheck {
  final String name;
  final String sha;
  final RepositorySlug slug;
  final TaskStatus status;
  final bool isMergeGroup;

  final int? checkRunId;
  final int? checkSuiteId;
  final String? headBranch;
  final bool isUnifiedCheckRun;
  final CiStage? stage;
  final int? pullRequestNumber;
  final int attempt;
  final int? startTime;
  final int? endTime;
  final String? summary;

  const PresubmitCompletedCheck({
    required this.name,
    required this.sha,
    required this.slug,
    required this.status,
    required this.isMergeGroup,
    required this.checkRunId,
    required this.checkSuiteId,
    required this.headBranch,
    required this.isUnifiedCheckRun,
    this.stage,
    this.pullRequestNumber,
    this.attempt = 1,
    this.startTime,
    this.endTime,
    this.summary,
  });

  /// Creates a [PresubmitCompletedCheck] from a GitHub [CheckRun].
  factory PresubmitCompletedCheck.fromCheckRun(
    cocoon_checks.CheckRun checkRun,
    RepositorySlug slug,
  ) {
    return PresubmitCompletedCheck(
      name: checkRun.name!,
      sha: checkRun.headSha!,
      slug: slug,
      status: ChecksExtension.fromConclusion(checkRun.conclusion),
      isMergeGroup: _isMergeGroup(checkRun.checkSuite?.headBranch),
      checkRunId: checkRun.id,
      checkSuiteId: checkRun.checkSuite?.id,
      headBranch: checkRun.checkSuite?.headBranch,
      isUnifiedCheckRun: false,
      // CheckRun model doesn't have time/summary fields currently
      startTime: null,
      endTime: null,
      summary: null,
    );
  }

  /// Creates a [PresubmitCompletedCheck] from a BuildBucket [Build].
  factory PresubmitCompletedCheck.fromBuild(
    Build build,
    PresubmitUserData userData,
  ) {
    return PresubmitCompletedCheck(
      name: build.builder.builder,
      sha: userData.commit.sha,
      slug: userData.commit.slug,
      status: build.status.toTaskStatus(),
      isMergeGroup: _isMergeGroup(userData.commit.branch),
      checkRunId: userData.guardCheckRunId != null
          ? userData.guardCheckRunId!
          : userData.checkRunId,
      checkSuiteId: userData.checkSuiteId,
      headBranch: userData.commit.branch,
      isUnifiedCheckRun: userData.guardCheckRunId != null,
      stage: userData.stage,
      pullRequestNumber: userData.pullRequestNumber,
      attempt: _getAttempt(build),
      startTime: build.startTime.toDateTime().microsecondsSinceEpoch,
      endTime: build.endTime.toDateTime().microsecondsSinceEpoch,
      summary: build.summaryMarkdown,
    );
  }

  static int _getAttempt(Build build) {
    final tagSet = BuildTags.fromStringPairs(build.tags);
    return tagSet.currentAttempt;
  }

  cocoon_checks.CheckRun get checkRun {
    return cocoon_checks.CheckRun(
      id: checkRunId,
      name: isUnifiedCheckRun ? 'Merge Queue Guard' : name,
      headSha: sha,
      conclusion: status.toConclusion(),
      checkSuite: CheckSuite(
        id: checkSuiteId,
        headBranch: headBranch,
        headSha: sha,
        conclusion: CheckRunConclusion.empty,
        pullRequests: [],
      ),
    );
  }

  static bool _isMergeGroup(String? headBranch) {
    if (headBranch == null) {
      return false;
    }
    return tryParseGitHubMergeQueueBranch(headBranch).parsed;
  }
}
