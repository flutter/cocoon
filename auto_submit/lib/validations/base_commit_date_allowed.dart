// Copyright 2025 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_server/logging.dart';
import 'package:github/github.dart' as github;

import '../model/auto_submit_query_result.dart';
import 'validation.dart';

/// Validates that the base of the PR commit is not older than a specified in
/// configuration number of days.
class BaseCommitDateAllowed extends Validation {
  BaseCommitDateAllowed({required super.config});

  @override
  String get name => 'BaseCommitDateAllowed';

  @override
  /// Implements the validation.
  Future<ValidationResult> validate(
    QueryResult result,
    github.PullRequest messagePullRequest,
  ) async {
    final slug = messagePullRequest.base!.repo!.slug();
    final gitHubService = await config.createGithubService(slug);
    final sha = messagePullRequest.base!.sha!;
    final repositoryConfiguration = await config.getRepositoryConfiguration(
      slug,
    );

    // If the base_commit_expiration is empty then the validation is turned off
    // and the base commit creation date is ignored.
    if (repositoryConfiguration.stalePrProtectionInDaysForBaseRefs.isEmpty) {
      log.info('PR base commit creation date validation turned off');
      return ValidationResult(
        true,
        Action.IGNORE_FAILURE,
        'PR base commit creation date validation turned off',
      );
    }

    // Check if PR base expiration validation is configured for this branch.
    if (!repositoryConfiguration.stalePrProtectionInDaysForBaseRefs.containsKey(
      '${slug.fullName}/${messagePullRequest.base!.ref}',
    )) {
      log.info(
        'PR ${slug.fullName}/${messagePullRequest.number} is for branch: '
        '${messagePullRequest.base!.ref} which does not match any configured PR '
        'base for stale protection',
      );
      return ValidationResult(
        true,
        Action.IGNORE_FAILURE,
        'The base commit expiration validation is not configured for this '
        'branch.',
      );
    }

    // If the base commit creation date is null then the validation fails but
    // should not block the PR merging.
    final commit = await gitHubService.getCommit(slug, sha);
    if (commit.commit?.author?.date == null) {
      log.info(
        'PR ${slug.fullName}/${messagePullRequest.number} base commit creation '
        'date is null.',
      );
      return ValidationResult(
        false,
        Action.IGNORE_FAILURE,
        'Could not find the base commit creation date of the PR '
        '${slug.fullName}/${messagePullRequest.number}.',
      );
    }

    log.info(
      'PR ${slug.fullName}/${messagePullRequest.number} requested for branch: '
      '${messagePullRequest.base!.ref} with base creation date: '
      '${commit.commit?.author?.date}.',
    );

    final isBaseRecent = commit.commit!.author!.date!.isAfter(
      DateTime.now().subtract(
        Duration(
          days: repositoryConfiguration
              .stalePrProtectionInDaysForBaseRefs['${slug.fullName}/${messagePullRequest.base!.ref}']!,
        ),
      ),
    );

    final message = isBaseRecent
        ? 'The base commit of the PR is recent enough for merging.'
        : 'The base commit of the PR is older than '
              '${repositoryConfiguration.stalePrProtectionInDaysForBaseRefs['${slug.fullName}/${messagePullRequest.base!.ref}']} '
              'days and can not be merged. Please merge the latest changes '
              'from the main into this branch and resubmit the PR.';

    return ValidationResult(isBaseRecent, Action.REMOVE_LABEL, message);
  }
}
