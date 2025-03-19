// Copyright 2022 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Note that we need this file because Github does not expose a field within the
// checks that states whether or not a particular check is required or not.

import 'package:cocoon_server/logging.dart';
import 'package:github/github.dart' as github;
import 'package:retry/retry.dart';

import '../exception/retryable_exception.dart';
import '../model/auto_submit_query_result.dart' as auto;
import '../service/config.dart';
import '../service/github_service.dart';
import 'validation.dart';

const String ciyamlValidation = 'ci.yaml validation';

/// Required check runs are check runs noted in the autosubmit.yaml configuration.
/// In order for a pull request to be merged any check runs specified in the
/// required check runs must pass before the bot will merge the pull request
/// regardless of review status.
class RequiredCheckRuns extends Validation {
  const RequiredCheckRuns({required super.config, RetryOptions? retryOptions})
    : retryOptions = retryOptions ?? Config.requiredChecksRetryOptions;

  final RetryOptions retryOptions;

  Future<bool> waitForRequiredChecks({
    required github.RepositorySlug slug,
    required String sha,
    required Set<String> checkNames,
  }) async {
    final githubService = await config.createGithubService(slug);
    final targetCheckRuns = <github.CheckRun>[];

    for (var checkRun in checkNames) {
      targetCheckRuns.addAll(
        await githubService.getCheckRunsFiltered(
          slug: slug,
          ref: sha,
          checkName: checkRun,
        ),
      );
    }

    var checksCompleted = true;

    try {
      for (var checkRun in targetCheckRuns) {
        await retryOptions.retry(() async {
          await _verifyCheckRunCompleted(slug, githubService, checkRun);
        }, retryIf: (Exception e) => e is RetryableException);
      }
    } catch (e, s) {
      log.warn('Required check has not completed in time', e, s);
      checksCompleted = false;
    }

    return checksCompleted;
  }

  @override
  String get name => 'RequiredCheckRuns';

  @override
  Future<ValidationResult> validate(
    auto.QueryResult result,
    github.PullRequest messagePullRequest,
  ) async {
    final pullRequest = result.repository!.pullRequest!;
    final commit = pullRequest.commits!.nodes!.single.commit!;
    final sha = commit.oid;
    final slug = messagePullRequest.base!.repo!.slug();

    final repositoryConfiguration = await config.getRepositoryConfiguration(
      slug,
    );
    final requiredCheckRuns = repositoryConfiguration.requiredCheckRunsOnRevert;

    final success = await waitForRequiredChecks(
      slug: slug,
      sha: sha!,
      checkNames: requiredCheckRuns,
    );

    return ValidationResult(
      success,
      success ? Action.REMOVE_LABEL : Action.IGNORE_TEMPORARILY,
      success
          ? 'All required check runs have completed.'
          : 'Some of the required checks did not complete in time.',
    );
  }
}

/// Function signature that will be executed with retries.
typedef RetryHandler = void Function();

/// Simple function to wait on completed checkRuns with retries.
Future<void> _verifyCheckRunCompleted(
  github.RepositorySlug slug,
  GithubService githubService,
  github.CheckRun targetCheckRun,
) async {
  final checkRuns = await githubService.getCheckRunsFiltered(
    slug: slug,
    ref: targetCheckRun.headSha!,
    checkName: targetCheckRun.name,
  );

  if (checkRuns.first.name != targetCheckRun.name ||
      checkRuns.first.conclusion != github.CheckRunConclusion.success) {
    throw RetryableException('${targetCheckRun.name} has not yet completed.');
  }
}
