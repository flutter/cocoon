// Copyright 2022 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_server/logging.dart';
import 'package:github/github.dart' as github;

import '../model/auto_submit_query_result.dart';
import '../model/pull_request_data_types.dart';
import '../service/config.dart';
import 'validation.dart';

/// Validates all the CI build/tests ran and were successful.
class CiSuccessful extends Validation {
  /// The status checks that are not related to changes in this PR.
  static const Set<String> notInAuthorsControl = <String>{
    'tree-status', // flutter/engine repo
    'submit-queue', // packages repo
  };

  CiSuccessful({required super.config});

  @override
  String get name => 'CiSuccessful';

  @override
  /// Implements the CI build/tests validations.
  Future<ValidationResult> validate(
    QueryResult result,
    github.PullRequest messagePullRequest,
  ) async {
    var allSuccess = true;
    final slug = messagePullRequest.base!.repo!.slug();
    final prNumber = messagePullRequest.number!;
    final prState =
        (messagePullRequest.state == 'closed')
            ? PullRequestState.closed
            : PullRequestState.open;
    final pullRequest = result.repository!.pullRequest!;
    final failures = <FailureDetail>{};

    final statuses = <ContextNode>[];
    final commit = pullRequest.commits!.nodes!.single.commit!;
    final author = result.repository!.pullRequest!.author!;

    // Recently most of the repositories have migrated away of using the status
    // APIs and for those repos commit.status is null.
    if (commit.status != null && commit.status!.contexts!.isNotEmpty) {
      statuses.addAll(commit.status!.contexts!);
    }

    final repositoryConfiguration = await config.getRepositoryConfiguration(
      slug,
    );
    final targetBranch = repositoryConfiguration.defaultBranch;
    // Check tree status of repos. If the tree status is not ready,
    // we want to hold and wait for the status, same as waiting
    // for checks to finish.
    final baseBranch = messagePullRequest.base!.ref;
    if (baseBranch == targetBranch) {
      // Only validate tree status where base branch is the default branch.
      if (!isTreeStatusReporting(slug, prNumber, statuses)) {
        log.warn(
          'Statuses were not ready for ${slug.fullName}/$prNumber, sha: $commit.',
        );
        return ValidationResult(
          false,
          Action.IGNORE_TEMPORARILY,
          'Hold to wait for the tree status ready.',
        );
      }
    } else {
      log.info(
        'Target branch is $baseBranch for ${slug.fullName}/$prNumber, skipping tree status check.',
      );
    }

    // List of labels associated with the pull request.
    final labelNames =
        (messagePullRequest.labels as List<github.IssueLabel>)
            .map<String>((github.IssueLabel labelMap) => labelMap.name)
            .toList();

    /// Validate if all statuses have been successful.
    allSuccess = validateStatuses(
      slug,
      prNumber,
      prState,
      author,
      labelNames,
      statuses,
      failures,
      allSuccess,
    );

    final gitHubService = await config.createGithubService(slug);
    final sha = commit.oid;

    final checkRuns = <github.CheckRun>[];
    if (messagePullRequest.head != null && sha != null) {
      checkRuns.addAll(await gitHubService.getCheckRuns(slug, sha));
    }

    /// Validate if all checkRuns have succeeded.
    allSuccess = validateCheckRuns(
      slug,
      prNumber,
      prState,
      checkRuns,
      failures,
      allSuccess,
      author,
    );

    if (!allSuccess && failures.isEmpty) {
      return ValidationResult(allSuccess, Action.IGNORE_TEMPORARILY, '');
    }

    final buffer = StringBuffer();
    if (failures.isNotEmpty) {
      for (var detail in failures) {
        buffer.writeln(
          '- The status or check suite ${detail.markdownLink} has failed. Please fix the '
          'issues identified (or deflake) before re-applying this label.',
        );
      }
    }
    final action =
        labelNames.contains(Config.kEmergencyLabel)
            ? Action.IGNORE_FAILURE
            : Action.REMOVE_LABEL;
    return ValidationResult(allSuccess, action, buffer.toString());
  }

  /// Return true if the tree status check has been reported, or if doesn't have
  /// to be reported.
  ///
  /// Tree status is pushed by [PushBuildStatusToGithub], which is asynchronous
  /// relative to the creation of the PR. At the time the CI status is being
  /// checked, the tree status may not have been reported yet.
  ///
  /// If a repo has a tree status, we should wait for it to show up instead of posting
  /// a failure to GitHub pull request.
  ///
  /// If a repo doesn't have a tree status, simply return `true`.
  bool isTreeStatusReporting(
    github.RepositorySlug slug,
    int prNumber,
    List<ContextNode> statuses,
  ) {
    var treeStatusValid = false;
    if (!Config.reposWithTreeStatus.contains(slug)) {
      return true;
    }
    if (statuses.isEmpty) {
      return false;
    }
    const treeStatusName = 'tree-status';
    log.info(
      '${slug.fullName}/$prNumber: Validating tree status for ${slug.name}/tree-status, statuses: $statuses',
    );

    /// Scan list of statuses to see if the tree status exists (this list is expected to be <5 items)
    for (var status in statuses) {
      if (status.context == treeStatusName) {
        // Does only one tree status need to be set for the condition?
        treeStatusValid = true;
      }
    }
    return treeStatusValid;
  }

  /// Validate the ci build test run statuses to see which have succeeded and
  /// which have failed.
  ///
  /// Failures will be added the set of overall failures.
  /// Returns allSuccess unmodified if there were no failures, false otherwise.
  bool validateStatuses(
    github.RepositorySlug slug,
    int prNumber,
    PullRequestState prState,
    Author author,
    List<String> labelNames,
    List<ContextNode> statuses,
    Set<FailureDetail> failures,
    bool allSuccess,
  ) {
    log.info('Validating name: ${slug.name}/$prNumber, statuses: $statuses');

    final staleStatuses = <ContextNode>[];
    for (var status in statuses) {
      // How can name be null but presumed to not be null below when added to failure?
      final name = status.context;

      if (status.state != STATUS_SUCCESS) {
        if (notInAuthorsControl.contains(name) &&
            labelNames.contains(Config.kEmergencyLabel)) {
          continue;
        }
        allSuccess = false;
        if (status.state == STATUS_FAILURE &&
            !notInAuthorsControl.contains(name)) {
          failures.add(FailureDetail(name!, status.targetUrl!));
        }
        if (status.state == STATUS_PENDING &&
            prState == PullRequestState.open &&
            status.createdAt != null &&
            isStale(status.createdAt!) &&
            supportStale(author, slug)) {
          staleStatuses.add(status);
        }
      }
    }
    if (staleStatuses.isNotEmpty) {
      log.warn(
        'Pull request https://github.com/${slug.fullName}/pull/$prNumber from ${slug.name} repo auto roller has been running over ${Config.kGitHubCheckStaleThreshold} hours due to: ${staleStatuses.map((e) => e.context).toList()}',
      );
    }

    return allSuccess;
  }

  /// Validate the checkRuns to see if all have completed successfully or not.
  ///
  /// Failures will be added the set of overall failures.
  /// Returns allSuccess unmodified if there were no failures, false otherwise.
  bool validateCheckRuns(
    github.RepositorySlug slug,
    int prNumber,
    PullRequestState prState,
    List<github.CheckRun> checkRuns,
    Set<FailureDetail> failures,
    bool allSuccess,
    Author author,
  ) {
    log.info('Validating name: ${slug.name}/$prNumber, checkRuns: $checkRuns');

    final staleCheckRuns = <github.CheckRun>[];
    for (var checkRun in checkRuns) {
      final name = checkRun.name;

      if (checkRun.name == Config.kMergeQueueLockName) {
        // Merge Queue Guard is not used to determine the status of CI.
        continue;
      }

      if (checkRun.conclusion == github.CheckRunConclusion.skipped ||
          checkRun.conclusion == github.CheckRunConclusion.success ||
          (checkRun.status == github.CheckRunStatus.completed &&
              checkRun.conclusion == github.CheckRunConclusion.neutral)) {
        // checkrun has passed.
        continue;
      } else if (checkRun.status == github.CheckRunStatus.completed) {
        // checkrun has failed.
        log.info('${slug.name}/$prNumber: CheckRun $name failed.');
        failures.add(FailureDetail(name!, checkRun.detailsUrl as String));
      } else if (checkRun.status == github.CheckRunStatus.queued) {
        if (prState == PullRequestState.open &&
            isStale(checkRun.startedAt) &&
            supportStale(author, slug)) {
          staleCheckRuns.add(checkRun);
        }
      }
      allSuccess = false;
    }
    if (staleCheckRuns.isNotEmpty) {
      log.warn(
        'Pull request https://github.com/${slug.fullName}/pull/$prNumber from ${slug.name} repo auto roller has been running over ${Config.kGitHubCheckStaleThreshold} hours due to: ${staleCheckRuns.map((e) => e.name).toList()}',
      );
    }

    return allSuccess;
  }

  // Treat any GitHub check run as stale if created over [Config.kGitHubCheckStaleThreshold] hours ago.
  bool isStale(DateTime dateTime) {
    return dateTime.compareTo(
          DateTime.now().subtract(
            const Duration(hours: Config.kGitHubCheckStaleThreshold),
          ),
        ) <
        0;
  }

  /// Perform stale check only on Engine related rolled PRs.
  ///
  /// This includes those rolled PRs from upstream to Engine repo and those
  /// rolled PRs from Engine to Framework.
  bool supportStale(Author author, github.RepositorySlug slug) {
    return isEngineToFrameworkRoller(author, slug);
  }

  bool isEngineToFrameworkRoller(Author author, github.RepositorySlug slug) {
    return author.login! == 'engine-flutter-autoroll' &&
        slug == Config.flutterSlug;
  }
}
