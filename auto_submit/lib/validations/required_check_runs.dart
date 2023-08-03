// Copyright 2022 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Note that we need this file because Github does not expose a field within the
// checks that states whether or not a particular check is required or not.

import 'package:auto_submit/configuration/repository_configuration.dart';
import 'package:auto_submit/exception/retryable_exception.dart';
import 'package:auto_submit/model/auto_submit_query_result.dart' as auto;
import 'package:auto_submit/service/config.dart';
import 'package:auto_submit/service/github_service.dart';
import 'package:auto_submit/service/log.dart';
import 'package:auto_submit/validations/validation.dart';
import 'package:github/github.dart' as github;
import 'package:retry/retry.dart';

const String ciyamlValidation = 'ci.yaml validation';

/// Required check runs are check runs noted in the autosubmit.yaml configuration.
/// In order for a pull request to be merged any check runs specified in the
/// required check runs must pass before the bot will merge the pull request
/// regardless of review status.
class RequiredCheckRuns extends Validation {
  const RequiredCheckRuns({
    required super.config,
    RetryOptions? retryOptions,
  }) : retryOptions = retryOptions ?? Config.requiredChecksRetryOptions;

  final RetryOptions retryOptions;

  Future<bool> waitForRequiredChecks({
    required github.RepositorySlug slug,
    required String sha,
    required Set<String> checkNames,
  }) async {
    final GithubService githubService = await config.createGithubService(slug);
    final List<github.CheckRun> targetCheckRuns = [];

    for (String checkRun in checkNames) {
      targetCheckRuns.addAll(
        await githubService.getCheckRunsFiltered(
          slug: slug,
          ref: sha,
          checkName: checkRun,
        ),
      );
    }

    bool checksCompleted = true;

    try {
      for (github.CheckRun checkRun in targetCheckRuns) {
        await retryOptions.retry(
          () async {
            await _verifyCheckRunCompleted(
              slug,
              githubService,
              checkRun,
            );
          },
          retryIf: (Exception e) => e is RetryableException,
        );
      }
    } catch (e) {
      log.warning('Required check has not completed in time. ${e.toString()}');
      checksCompleted = false;
    }

    return checksCompleted;
  }

  @override
  String get name => 'RequiredCheckRuns';

  @override
  Future<ValidationResult> validate(auto.QueryResult result, github.PullRequest messagePullRequest) async {
    final auto.PullRequest pullRequest = result.repository!.pullRequest!;
    final auto.Commit commit = pullRequest.commits!.nodes!.single.commit!;
    final String? sha = commit.oid;
    final github.RepositorySlug slug = messagePullRequest.base!.repo!.slug();

    final RepositoryConfiguration repositoryConfiguration = await config.getRepositoryConfiguration(slug);
    final Set<String> requiredCheckRuns = repositoryConfiguration.requiredCheckRunsOnRevert;

    final bool success = await waitForRequiredChecks(slug: slug, sha: sha!, checkNames: requiredCheckRuns);

    return ValidationResult(
      success,
      success ? Action.REMOVE_LABEL : Action.IGNORE_TEMPORARILY,
      success ? 'All required check runs have completed.' : 'Some of the required checks did not complete in time.',
    );
  }
}

/// Function signature that will be executed with retries.
typedef RetryHandler = Function();

/// Simple function to wait on completed checkRuns with retries.
Future<void> _verifyCheckRunCompleted(
  github.RepositorySlug slug,
  GithubService githubService,
  github.CheckRun targetCheckRun,
) async {
  final List<github.CheckRun> checkRuns = await githubService.getCheckRunsFiltered(
    slug: slug,
    ref: targetCheckRun.headSha!,
    checkName: targetCheckRun.name,
  );

  if (checkRuns.first.name != targetCheckRun.name || checkRuns.first.conclusion != github.CheckRunConclusion.success) {
    throw RetryableException('${targetCheckRun.name} has not yet completed.');
  }
}
