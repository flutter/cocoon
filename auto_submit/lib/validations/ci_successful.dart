// Copyright 2022 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:auto_submit/configuration/repository_configuration.dart';
import 'package:auto_submit/model/auto_submit_query_result.dart';
import 'package:auto_submit/service/github_service.dart';
import 'package:auto_submit/validations/validation.dart';
import 'package:github/github.dart' as github;

import '../service/config.dart';
import '../service/log.dart';

/// Validates all the CI build/tests ran and were successful.
class CiSuccessful extends Validation {
  /// The status checks that are not related to changes in this PR.
  static const Set<String> notInAuthorsControl = <String>{
    // TODO(keyonghan): Remove `luci-<repo>` when `tree-status` populates.
    // https://github.com/flutter/flutter/issues/92931
    'luci-flutter', // flutter repo
    'luci-engine', // engine repo
    'tree-status', // flutter/engine repo
    'submit-queue', // packages repo
  };

  CiSuccessful({
    required super.config,
  });

  @override

  /// Implements the CI build/tests validations.
  Future<ValidationResult> validate(QueryResult result, github.PullRequest messagePullRequest) async {
    bool allSuccess = true;
    final github.RepositorySlug slug = messagePullRequest.base!.repo!.slug();
    final PullRequest pullRequest = result.repository!.pullRequest!;
    final Set<FailureDetail> failures = <FailureDetail>{};

    final List<ContextNode> statuses = <ContextNode>[];
    final Commit commit = pullRequest.commits!.nodes!.single.commit!;
    final Author author = result.repository!.pullRequest!.author!;

    // Recently most of the repositories have migrated away of using the status
    // APIs and for those repos commit.status is null.
    if (commit.status != null && commit.status!.contexts!.isNotEmpty) {
      statuses.addAll(commit.status!.contexts!);
    }

    final RepositoryConfiguration repositoryConfiguration = await config.getRepositoryConfiguration(slug);
    final String targetBranch = repositoryConfiguration.defaultBranch;
    // Check tree status of repos. If the tree status is not ready,
    // we want to hold and wait for the status, same as waiting
    // for checks to finish.
    final String? baseBranch = messagePullRequest.base!.ref;
    if (baseBranch == targetBranch) {
      // Only validate tree status where base branch is the default branch.
      if (!treeStatusCheck(slug, statuses)) {
        log.warning('Statuses were not ready for ${slug.fullName}, sha: $commit.');
        return ValidationResult(false, Action.IGNORE_TEMPORARILY, 'Hold to wait for the tree status ready.');
      }
    } else {
      log.info('Target branch is $baseBranch, skipping tree status check.');
    }

    // List of labels associated with the pull request.
    final List<String> labelNames = (messagePullRequest.labels as List<github.IssueLabel>)
        .map<String>((github.IssueLabel labelMap) => labelMap.name)
        .toList();

    /// Validate if all statuses have been successful.
    allSuccess = validateStatuses(slug, author, labelNames, statuses, failures, allSuccess);

    final GithubService gitHubService = await config.createGithubService(slug);
    final String? sha = commit.oid;

    final List<github.CheckRun> checkRuns = <github.CheckRun>[];
    if (messagePullRequest.head != null && sha != null) {
      checkRuns.addAll(await gitHubService.getCheckRuns(slug, sha));
    }

    /// Validate if all checkRuns have succeeded.
    allSuccess = validateCheckRuns(slug, checkRuns, failures, allSuccess);

    if (!allSuccess && failures.isEmpty) {
      return ValidationResult(allSuccess, Action.IGNORE_TEMPORARILY, '');
    }

    final StringBuffer buffer = StringBuffer();
    if (failures.isNotEmpty) {
      for (FailureDetail detail in failures) {
        buffer.writeln('- The status or check suite ${detail.markdownLink} has failed. Please fix the '
            'issues identified (or deflake) before re-applying this label.');
      }
    }
    final Action action =
        labelNames.contains(config.overrideTreeStatusLabel) ? Action.IGNORE_FAILURE : Action.REMOVE_LABEL;
    return ValidationResult(allSuccess, action, buffer.toString());
  }

  /// Check the tree status.
  ///
  /// If a repo has a tree status, we should wait for it to show up instead of posting
  /// a failure to GitHub pull request.
  /// If a repo doesn't have a tree status, simply return `true`.
  bool treeStatusCheck(github.RepositorySlug slug, List<ContextNode> statuses) {
    bool treeStatusValid = false;
    if (!Config.reposWithTreeStatus.contains(slug)) {
      return true;
    }
    if (statuses.isEmpty) {
      return false;
    }
    // TODO(keyonghan): Remove `luci-<repo>` when `tree-status` populates.
    // https://github.com/flutter/flutter/issues/92931
    final List<String> treeStatusNames = ['luci-${slug.name}', 'tree-status'];
    log.info('Validating tree status: ${slug.name}/tree-status, statuses: $statuses');

    /// Scan list of statuses to see if the tree status exists (this list is expected to be <5 items)
    for (ContextNode status in statuses) {
      if (treeStatusNames.contains(status.context)) {
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
    Author author,
    List<String> labelNames,
    List<ContextNode> statuses,
    Set<FailureDetail> failures,
    bool allSuccess,
  ) {
    final String overrideTreeStatusLabel = config.overrideTreeStatusLabel;
    log.info('Validating name: ${slug.name}, statuses: $statuses');

    for (ContextNode status in statuses) {
      // How can name be null but presumed to not be null below when added to failure?
      final String? name = status.context;

      // If the account author is a roller account do not block merge on flutter-gold check.
      if (config.rollerAccounts.contains(author.login!) && slug == Config.engineSlug && name == 'flutter-gold') {
        log.info('Skipping status check for flutter-gold, pr author: $author, slug: ${slug.fullName}.');
        continue;
      }

      if (status.state != STATUS_SUCCESS) {
        if (notInAuthorsControl.contains(name) && labelNames.contains(overrideTreeStatusLabel)) {
          continue;
        }
        allSuccess = false;
        if (status.state == STATUS_FAILURE && !notInAuthorsControl.contains(name)) {
          failures.add(FailureDetail(name!, status.targetUrl!));
        }
      }
    }

    return allSuccess;
  }

  /// Validate the checkRuns to see if all have completed successfully or not.
  ///
  /// Failures will be added the set of overall failures.
  /// Returns allSuccess unmodified if there were no failures, false otherwise.
  bool validateCheckRuns(
    github.RepositorySlug slug,
    List<github.CheckRun> checkRuns,
    Set<FailureDetail> failures,
    bool allSuccess,
  ) {
    log.info('Validating name: ${slug.name}, checkRuns: $checkRuns');

    for (github.CheckRun checkRun in checkRuns) {
      final String? name = checkRun.name;

      if (checkRun.conclusion == github.CheckRunConclusion.skipped ||
          checkRun.conclusion == github.CheckRunConclusion.success ||
          (checkRun.status == github.CheckRunStatus.completed &&
              checkRun.conclusion == github.CheckRunConclusion.neutral)) {
        // checkrun has passed.
        continue;
      } else if (checkRun.status == github.CheckRunStatus.completed) {
        // checkrun has failed.
        failures.add(FailureDetail(name!, checkRun.detailsUrl as String));
      }
      allSuccess = false;
    }

    return allSuccess;
  }
}
