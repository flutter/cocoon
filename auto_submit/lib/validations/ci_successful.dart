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

    // The status checks that are not related to changes in this PR.
    const Set<String> notInAuthorsControl = <String>{
      'luci-flutter', // flutter repo
      'luci-engine', // engine repo
      'submit-queue', // plugins repo
    };
    List<ContextNode> statuses = <ContextNode>[];
    Commit commit = pullRequest.commits!.nodes!.single.commit!;
    // Recently most of the repositories have migrated away of using the status
    // APIs and for those repos commit.status is null.
    if (commit.status != null && commit.status!.contexts!.isNotEmpty) {
      statuses.addAll(commit.status!.contexts!);
    }
    // Ensure repos with tree statuses have it set
    if (Config.reposWithTreeStatus.contains(slug)) {
      bool treeStatusExists = false;
      final String treeStatusName = 'luci-${slug.name}';

      // Scan list of statuses to see if the tree status exists (this list is expected to be <5 items)
      for (ContextNode status in statuses) {
        if (status.context == treeStatusName) {
          treeStatusExists = true;
        }
      }

      if (!treeStatusExists) {
        failures.add(FailureDetail('tree status $treeStatusName', 'https://flutter-dashboard.appspot.com/#/build'));
      }
    }
    // List of labels associated with the pull request.
    final List<String> labelNames = (messagePullRequest.labels as List<github.IssueLabel>)
        .map<String>((github.IssueLabel labelMap) => labelMap.name)
        .toList();
    final String overrideTreeStatusLabel = config.overrideTreeStatusLabel;
    log.info('Validating name: ${slug.name}, status: $statuses');
    for (ContextNode status in statuses) {
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
    final GithubService gitHubService = await config.createGithubService(slug);
    final String? sha = commit.oid;
    List<github.CheckRun> checkRuns = <github.CheckRun>[];
    if (messagePullRequest.head != null && sha != null) {
      // WOOHOO ---- this is where the error is coming from in the check service 
      // when the conclusion of 'skipped' is used.
      // when listCheckRunsForRef is run it tries to get the conclusion from the 
      // json string and it cannot process the skipped state so it throws and 
      // exception because the state is not known which is why we do not see the 
      // below log info message!
      checkRuns.addAll(await gitHubService.getCheckRuns(slug, sha));
    }
    log.info('Validating name: ${slug.name}, checks: $checkRuns');
    for (github.CheckRun checkRun in checkRuns) {
      final String? name = checkRun.name;
      if (checkRun.conclusion == github.CheckRunConclusion.success ||
          (checkRun.status == github.CheckRunStatus.completed &&
              checkRun.conclusion == github.CheckRunConclusion.neutral)) {
        continue;
      } else if (checkRun.status == github.CheckRunStatus.completed) {
        failures.add(FailureDetail(name!, checkRun.detailsUrl as String));
      }
      allSuccess = false;
    }
    if (!allSuccess && failures.isEmpty) {
      return ValidationResult(allSuccess, Action.IGNORE_TEMPORARILY, '');
    }
    Action action = labelNames.contains(config.overrideTreeStatusLabel) ? Action.IGNORE_FAILURE : Action.REMOVE_LABEL;
    return ValidationResult(allSuccess, action, '');
  }
}
