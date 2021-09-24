// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:github/github.dart' as github;

import '../foundation/github_checks_util.dart';
import '../model/github/checks.dart';
import '../model/luci/buildbucket.dart';
import '../model/luci/push_message.dart' as push_message;
import '../service/logging.dart';
import 'config.dart';
import 'luci_build_service.dart';
import 'scheduler.dart';

const String kGithubSummary = '''
**[Understanding a LUCI build failure](https://github.com/flutter/flutter/wiki/Understanding-a-LUCI-build-failure)**

''';

/// Controls triggering builds and updating their status in the Github UI.
class GithubChecksService {
  GithubChecksService(this.config, {GithubChecksUtil? githubChecksUtil})
      : githubChecksUtil = githubChecksUtil ?? const GithubChecksUtil();

  Config config;
  GithubChecksUtil githubChecksUtil;

  static Set<github.CheckRunConclusion> failedStatesSet = <github.CheckRunConclusion>{
    github.CheckRunConclusion.cancelled,
    github.CheckRunConclusion.failure,
  };

  /// Takes a [CheckSuiteEvent] and trigger all the relevant builds if this is a
  /// new commit or only failed builds if the event was generated by a click on
  /// the re-run all button in the Github UI.
  /// Relevant API docs:
  ///   https://docs.github.com/en/rest/reference/checks#create-a-check-suite
  ///   https://docs.github.com/en/rest/reference/checks#rerequest-a-check-suite
  Future<void> handleCheckSuite(CheckSuiteEvent checkSuiteEvent, Scheduler scheduler) async {
    final github.RepositorySlug slug = checkSuiteEvent.repository.slug();
    final github.PullRequest pullRequest = checkSuiteEvent.checkSuite.pullRequests![0];
    final int? prNumber = pullRequest.number;
    final String? commitSha = checkSuiteEvent.checkSuite.headSha;
    switch (checkSuiteEvent.action) {
      case 'requested':
        // Trigger all try builders.
        await scheduler.triggerPresubmitTargets(
          branch: pullRequest.base!.ref!,
          prNumber: prNumber!,
          commitSha: commitSha!,
          slug: checkSuiteEvent.repository.slug(),
        );
        break;

      case 'rerequested':
        return await scheduler.retryPresubmitTargets(
          slug: slug,
          prNumber: prNumber!,
          commitSha: commitSha!,
          checkSuiteEvent: checkSuiteEvent,
        );
    }
  }

  /// Updates the Github build status using a [BuildPushMessage] sent by LUCI in
  /// a pub/sub notification.
  /// Relevant APIs:
  ///   https://docs.github.com/en/rest/reference/checks#update-a-check-run
  Future<bool> updateCheckStatus(
    push_message.BuildPushMessage buildPushMessage,
    LuciBuildService luciBuildService,
    github.RepositorySlug slug,
  ) async {
    final push_message.Build? build = buildPushMessage.build;
    if (buildPushMessage.userData!.isEmpty) {
      return false;
    }
    final Map<String, dynamic> userData = jsonDecode(buildPushMessage.userData!) as Map<String, dynamic>;
    if (!userData.containsKey('check_run_id') ||
        !userData.containsKey('repo_owner') ||
        !userData.containsKey('repo_name')) {
      log.severe(
        'UserData did not contain check_run_id,'
        'repo_owner, or repo_name: $userData',
      );
      return false;
    }
    final github.CheckRun checkRun = await githubChecksUtil.getCheckRun(
      config,
      slug,
      userData['check_run_id'] as int?,
    );
    final github.CheckRunStatus status = statusForResult(build!.status);
    final github.CheckRunConclusion? conclusion =
        (buildPushMessage.build!.result != null) ? conclusionForResult(buildPushMessage.build!.result) : null;
    // Do not override url for completed status.
    final String? url = status == github.CheckRunStatus.completed ? checkRun.detailsUrl : buildPushMessage.build!.url;
    github.CheckRunOutput? output;
    // If status has completed with failure then provide more details.
    if (status == github.CheckRunStatus.completed && failedStatesSet.contains(conclusion)) {
      final Build build =
          await luciBuildService.getTryBuildById(buildPushMessage.build!.id, fields: 'id,builder,summaryMarkdown');
      output = github.CheckRunOutput(title: checkRun.name!, summary: getGithubSummary(build.summaryMarkdown));
    }
    log.debug('Updating check run with output: [$output]');
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

  /// Appends triage wiki page to `summaryMarkdown` from LUCI build so that people can easily
  /// reference from github check run page.
  String getGithubSummary(String? summary) {
    if (summary == null) {
      return kGithubSummary + 'Empty summaryMarkdown';
    }
    // This is an imposed GitHub limit
    const int checkSummaryLimit = 65535;
    // This is to give buffer room incase GitHub lowers the amount.
    const int checkSummaryBufferLimit = checkSummaryLimit - 10000 - kGithubSummary.length;
    // Return the last [checkSummaryBufferLimit] characters as they are likely the most relevant.
    if (summary.length > checkSummaryBufferLimit) {
      summary = '[TRUNCATED...] ' + summary.substring(summary.length - checkSummaryBufferLimit);
    }
    return kGithubSummary + summary;
  }

  /// Transforms a [push_message.Result] to a [github.CheckRunConclusion].
  /// Relevant APIs:
  ///   https://developer.github.com/v3/checks/runs/#check-runs
  github.CheckRunConclusion conclusionForResult(push_message.Result? result) {
    switch (result) {
      case push_message.Result.canceled:
        // Set conclusion cancelled as a failure to ensure developers can retry
        // tasks when builds timeout.
        return github.CheckRunConclusion.failure;
      case push_message.Result.failure:
        return github.CheckRunConclusion.failure;
      case push_message.Result.success:
        return github.CheckRunConclusion.success;
      case null:
        throw StateError('unreachable');
    }
  }

  /// Transforms a [ush_message.Status] to a [github.CheckRunStatus].
  /// Relevant APIs:
  ///   https://developer.github.com/v3/checks/runs/#check-runs
  github.CheckRunStatus statusForResult(push_message.Status? status) {
    switch (status) {
      case push_message.Status.completed:
        return github.CheckRunStatus.completed;
      case push_message.Status.scheduled:
        return github.CheckRunStatus.queued;
      case push_message.Status.started:
        return github.CheckRunStatus.inProgress;
      case null:
        throw StateError('unreachable');
    }
  }
}
