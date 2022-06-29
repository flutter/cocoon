// Copyright 2022 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

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
    'luci-flutter', // flutter repo
    'luci-engine', // engine repo
    'submit-queue', // plugins repo
  };

  CiSuccessful({
    required Config config,
  }) : super(config: config);

  @override

  /// Implements the CI build/tests validations.
  Future<ValidationResult> validate(QueryResult result, github.PullRequest messagePullRequest) async {
    bool allSuccess = true;
    github.RepositorySlug slug = messagePullRequest.base!.repo!.slug();
    final PullRequest pullRequest = result.repository!.pullRequest!;
    Set<FailureDetail> failures = <FailureDetail>{};

    List<ContextNode> statuses = <ContextNode>[];
    Commit commit = pullRequest.commits!.nodes!.single.commit!;

    // Recently most of the repositories have migrated away of using the status
    // APIs and for those repos commit.status is null.
    if (commit.status != null && commit.status!.contexts!.isNotEmpty) {
      statuses.addAll(commit.status!.contexts!);
    }

    /// Validate tree statuses are set.
    validateTreeStatusIsSet(slug, statuses, failures);

    // List of labels associated with the pull request.
    final List<String> labelNames = (messagePullRequest.labels as List<github.IssueLabel>)
        .map<String>((github.IssueLabel labelMap) => labelMap.name)
        .toList();

    /// Validate if all statuses have been successful.
    allSuccess = validateStatuses(slug, labelNames, statuses, failures, allSuccess);

    final GithubService gitHubService = await config.createGithubService(slug);
    final String? sha = commit.oid;

    List<github.CheckRun> checkRuns = <github.CheckRun>[];
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
    Action action = labelNames.contains(config.overrideTreeStatusLabel) ? Action.IGNORE_FAILURE : Action.REMOVE_LABEL;
    return ValidationResult(allSuccess, action, buffer.toString());
  }

  /// Validate that the tree status exists for all statuses in the supplied list.
  /// If a failure is found it is added to the set of overall failures.
  void validateTreeStatusIsSet(github.RepositorySlug slug, List<ContextNode> statuses, Set<FailureDetail> failures) {
    if (Config.reposWithTreeStatus.contains(slug)) {
      bool treeStatusExists = false;
      final String treeStatusName = 'luci-${slug.name}';

      /// Scan list of statuses to see if the tree status exists (this list is expected to be <5 items)
      for (ContextNode status in statuses) {
        if (status.context == treeStatusName) {
          // Does only one tree status need to be set for the condition?
          treeStatusExists = true;
        }
      }

      if (!treeStatusExists) {
        failures.add(FailureDetail('tree status $treeStatusName', 'https://flutter-dashboard.appspot.com/#/build'));
      }
    }
  }

  /// Validate the ci build test run statuses to see which have succeeded and
  /// which have failed. Failures will be added the set of overall failures.
  /// Returns allSuccess unmodified if there were no failures, false otherwise.
  bool validateStatuses(github.RepositorySlug slug, List<String> labelNames, List<ContextNode> statuses,
      Set<FailureDetail> failures, bool allSuccess) {
    final String overrideTreeStatusLabel = config.overrideTreeStatusLabel;

    log.info('Validating name: ${slug.name}, status: $statuses');
    for (ContextNode status in statuses) {
      // How can name be null but presumed to not be null below when added to failure?
      final String? name = status.context;

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
  /// Failures will be added the set of overall failures.
  /// Returns allSuccess unmodified if there were no failures, false otherwise.
  bool validateCheckRuns(
      github.RepositorySlug slug, List<github.CheckRun> checkRuns, Set<FailureDetail> failures, bool allSuccess) {
    log.info('Validating name: ${slug.name}, checks: $checkRuns');
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
