// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:buildbucket/buildbucket_pb.dart' as bbv2;
import 'package:cocoon_server/logging.dart';
import 'package:github/github.dart' as github;

import '../foundation/github_checks_util.dart';
import 'config.dart';
import 'github_service.dart';
import 'luci_build_service.dart';

const String kGithubSummary = '''
**[Understanding a LUCI build failure](https://github.com/flutter/flutter/blob/master/docs/infra/Understanding-a-LUCI-build-failure.md)**

''';

final List<bbv2.Status> terminalStatuses = [
  bbv2.Status.CANCELED,
  bbv2.Status.FAILURE,
  bbv2.Status.INFRA_FAILURE,
  bbv2.Status.SUCCESS,
];

/// Controls triggering builds and updating their status in the Github UI.
class GithubChecksService {
  GithubChecksService(
    this.config, {
    GithubChecksUtil? githubChecksUtil,
  }) : githubChecksUtil = githubChecksUtil ?? const GithubChecksUtil();

  Config config;
  GithubChecksUtil githubChecksUtil;

  static Set<github.CheckRunConclusion> failedStatesSet = <github.CheckRunConclusion>{
    github.CheckRunConclusion.cancelled,
    github.CheckRunConclusion.failure,
  };

  /// Updates the Github build status using a [BuildPushMessage] sent by LUCI in
  /// a pub/sub notification.
  /// Relevant APIs:
  ///   https://docs.github.com/en/rest/reference/checks#update-a-check-run
  Future<bool> updateCheckStatus({
    required bbv2.Build build,
    required Map<String, dynamic> userDataMap,
    required LuciBuildService luciBuildService,
    required github.RepositorySlug slug,
    bool rescheduled = false,
  }) async {
    if (userDataMap.isEmpty) {
      return false;
    }

    if (!userDataMap.containsKey('check_run_id') ||
        !userDataMap.containsKey('repo_owner') ||
        !userDataMap.containsKey('repo_name')) {
      log.severe(
        'UserData did not contain check_run_id,'
        'repo_owner, or repo_name: $userDataMap',
      );
      return false;
    }

    github.CheckRunStatus status = statusForResult(build.status);
    log.info('status for build ${build.id} is ${status.value}');

    // Only `id` and `name` in the CheckRun are needed.
    // Instead of making an API call to get the details of each check run, we
    // generate the check run with only necessary info.
    final github.CheckRun checkRun = github.CheckRun.fromJson({
      'id': userDataMap['check_run_id'] as int?,
      'status': status,
      'check_suite': const {'id': null},
      'started_at': build.startTime.toDateTime().toString(),
      'conclusion': null,
      'name': build.builder.builder,
    });

    github.CheckRunConclusion? conclusion =
        (terminalStatuses.contains(build.status)) ? conclusionForResult(build.status) : null;
    log.info('conclusion for build ${build.id} is ${(conclusion != null) ? conclusion.value : null}');

    final String url = 'https://cr-buildbucket.appspot.com/build/${build.id}';
    github.CheckRunOutput? output;
    // If status has completed with failure then provide more details.
    if (taskFailed(build.status)) {
      log.info('failed presubmit task, ${build.id} has failed, status = ${build.status.toString()}');
      if (rescheduled) {
        status = github.CheckRunStatus.queued;
        conclusion = null;
        output = github.CheckRunOutput(
          title: checkRun.name!,
          summary: 'Note: this is an auto rerun. The timestamp above is based on the first attempt of this check run.',
        );
      } else {
        // summaryMarkdown should be present
        final bbv2.Build buildbucketBuild = await luciBuildService.getBuildById(
          build.id,
          buildMask: bbv2.BuildMask(
            // Need to use allFields as there is a bug with fieldMask and summaryMarkdown.
            allFields: true,
          ),
        );
        output = github.CheckRunOutput(
          title: checkRun.name!,
          summary: getGithubSummary(buildbucketBuild.summaryMarkdown),
        );
        log.fine('Updating check run with output: [${output.toJson().toString()}]');
      }
    }
    await githubChecksUtil.updateCheckRun(
      config,
      slug,
      checkRun,
      status: status,
      conclusion: conclusion,
      detailsUrl: url,
      output: output,
    );
    return true;
  }

  /// Check if task has completed with failure.
  bool taskFailed(bbv2.Status status) {
    final github.CheckRunStatus checkRunStatus = statusForResult(status);
    final github.CheckRunConclusion conclusion = conclusionForResult(status);
    return (checkRunStatus == github.CheckRunStatus.completed) && failedStatesSet.contains(conclusion);
  }

  /// Returns current reschedule attempt.
  ///
  /// It returns 1 if this is the first run, and +1 with each reschedule.
  int currentAttempt(final List<bbv2.StringPair> tags) {
    final bbv2.StringPair attempt = tags.firstWhere(
      (element) => element.key == 'current_attempt',
      orElse: () => bbv2.StringPair().createEmptyInstance(),
    );
    if (!attempt.hasKey()) {
      return 1;
    } else {
      return int.parse(attempt.value);
    }
  }

  /// Appends triage wiki page to `summaryMarkdown` from LUCI build so that people can easily
  /// reference from github check run page.
  String getGithubSummary(String? summary) {
    if (summary == null) {
      return '${kGithubSummary}Empty summaryMarkdown';
    }
    // This is an imposed GitHub limit
    const int checkSummaryLimit = 65535;
    // This is to give buffer room incase GitHub lowers the amount.
    const int checkSummaryBufferLimit = checkSummaryLimit - 10000 - kGithubSummary.length;
    // Return the last [checkSummaryBufferLimit] characters as they are likely the most relevant.
    if (summary.length > checkSummaryBufferLimit) {
      final String truncatedSummary = summary.substring(summary.length - checkSummaryBufferLimit);
      summary = '[TRUNCATED...] $truncatedSummary';
    }
    return '$kGithubSummary$summary';
  }

  /// Relevant APIs:
  ///   https://developer.github.com/v3/checks/runs/#check-runs
  github.CheckRunConclusion conclusionForResult(bbv2.Status status) {
    if (status == bbv2.Status.CANCELED || status == bbv2.Status.FAILURE || status == bbv2.Status.INFRA_FAILURE) {
      return github.CheckRunConclusion.failure;
    } else if (status == bbv2.Status.SUCCESS) {
      return github.CheckRunConclusion.success;
    } else {
      // Now that result is gone this is a non terminal step.
      return github.CheckRunConclusion.empty;
    }
  }

  /// Transforms a [push_message.Status] to a [github.CheckRunStatus].
  /// Relevant APIs:
  ///   https://developer.github.com/v3/checks/runs/#check-runs
  // TODO temporary as this needs to be adjusted as a COMPLETED state is no longer
  // a valid state from buildbucket v2.
  github.CheckRunStatus statusForResult(bbv2.Status status) {
    // ignore: exhaustive_cases
    switch (status) {
      case bbv2.Status.SUCCESS:
      case bbv2.Status.FAILURE:
      case bbv2.Status.CANCELED:
      case bbv2.Status.INFRA_FAILURE:
        return github.CheckRunStatus.completed;
      case bbv2.Status.SCHEDULED:
        return github.CheckRunStatus.queued;
      case bbv2.Status.STARTED:
        return github.CheckRunStatus.inProgress;
      default:
        throw StateError('unreachable');
    }
  }

  /// Given a [headSha] and [checkSuiteId], finds the [PullRequest] that matches.
  Future<github.PullRequest?> findMatchingPullRequest(
    github.RepositorySlug slug,
    String headSha,
    int checkSuiteId,
  ) async {
    final GithubService githubService = await config.createDefaultGitHubService();

    // There could be multiple PRs that have the same [headSha] commit.
    final List<github.Issue> prIssues = await githubService.searchIssuesAndPRs(slug, '$headSha type:pr');

    for (final prIssue in prIssues) {
      final int prNumber = prIssue.number;

      // Each PR can have multiple check suites.
      final List<github.CheckSuite> checkSuites = await githubChecksUtil.listCheckSuitesForRef(
        githubService.github,
        slug,
        ref: 'refs/pull/$prNumber/head',
      );

      // Use check suite ID equality to verify that we have iterated to the correct PR.
      final bool doesPrIncludeMatchingCheckSuite = checkSuites.any((checkSuite) => checkSuite.id! == checkSuiteId);
      if (doesPrIncludeMatchingCheckSuite) {
        return githubService.getPullRequest(slug, prNumber);
      }
    }

    return null;
  }
}
