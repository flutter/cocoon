// Copyright 2022 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:auto_submit/configuration/repository_configuration.dart';
import 'package:auto_submit/model/auto_submit_query_result.dart' as auto;
import 'package:auto_submit/service/config.dart';
import 'package:auto_submit/service/github_service.dart';
import 'package:auto_submit/validations/required_check_runs.dart';
import 'package:auto_submit/validations/validation.dart';
import 'package:github/github.dart' as github;
import 'package:retry/retry.dart';

import '../service/log.dart';

class Revert extends Validation {
  Revert({
    required super.config,
    RetryOptions? retryOptions,
  }) : retryOptions = retryOptions ?? Config.requiredChecksRetryOptions;

  final RetryOptions retryOptions;

  @override
  String get name => 'revert';

  @override
  Future<ValidationResult> validate(auto.QueryResult result, github.PullRequest messagePullRequest) async {
    final auto.PullRequest pullRequest = result.repository!.pullRequest!;
    final String? author = pullRequest.author!.login;

    final github.RepositorySlug slug = messagePullRequest.base!.repo!.slug();

    final RepositoryConfiguration repositoryConfiguration = await config.getRepositoryConfiguration(slug);

    GithubService githubService = await config.createGithubService(slug);
    final github.PullRequest updatedPullRequest = await githubService.getPullRequest(
      slug,
      messagePullRequest.number!,
    );

    if (!await githubService.isTeamMember(repositoryConfiguration.approvalGroup, author!, slug.owner)) {
      final String message = 'The author $author does not have permissions to make this request.';
      log.info(message);
      return ValidationResult(false, Action.REMOVE_LABEL, message);
    }

    final bool? canMerge = updatedPullRequest.mergeable;

    if (canMerge == null) {
      // if canMerge is null that means github still needs to calculate whether or
      // not the change can be merged.
      final String message = 'Github is still calculating mergeability of pr# ${updatedPullRequest.number}.';
      log.info(message);
      return ValidationResult(false, Action.IGNORE_TEMPORARILY, message);
    }

    if (!canMerge) {
      // if canMerge is false then github has detected merge conflicts and the user
      // will need to address them.
      const String message =
          'This pull request cannot be merged due to conflicts. Please resolve conflicts and re-add the revert label.';
      log.info(message);
      return ValidationResult(false, Action.REMOVE_LABEL, message);
    }

    final String? pullRequestBody = updatedPullRequest.body;
    final String? revertLink = extractLinkFromText(pullRequestBody);
    if (revertLink == null) {
      const String message =
          'A reverts link could not be found or was formatted incorrectly. Format is \'Reverts owner/repo#id\'';
      log.info(message);
      return ValidationResult(false, Action.REMOVE_LABEL, message);
    }

    final github.RepositorySlug repositorySlug = _getSlugFromLink(revertLink);
    githubService = await config.createGithubService(repositorySlug);

    // TODO(ricardoamador) this should be moved out to the main validations class as a separate check.
    final RequiredCheckRuns requiredCheckRuns = RequiredCheckRuns(config: config, retryOptions: retryOptions);
    final ValidationResult validationResult = await requiredCheckRuns.validate(
      result,
      updatedPullRequest,
    );

    if (!validationResult.result) {
      return ValidationResult(
        false,
        Action.IGNORE_TEMPORARILY,
        'Some of the required checks did not complete in time.',
      );
    }

    final int pullRequestId = _getPullRequestNumberFromLink(revertLink);
    final github.PullRequest requestToRevert = await githubService.getPullRequest(repositorySlug, pullRequestId);

    final bool requestsMatch =
        await githubService.comparePullRequests(repositorySlug, requestToRevert, updatedPullRequest);

    if (requestsMatch) {
      return ValidationResult(
        true,
        Action.IGNORE_FAILURE,
        'Revert request has been verified and will be queued for merge.',
      );
    }

    return ValidationResult(
      false,
      Action.REMOVE_LABEL,
      'Validation of the revert request has failed. Verify the files in the revert request are the same as the original PR and resubmit the revert request.',
    );
  }

  /// The full text here is 'Reverts flutter/cocoon#XXXXX' as output by github
  /// the link must be in the form github.com/flutter/repo/pull/id
  String? extractLinkFromText(String? bodyText) {
    if (bodyText == null) {
      return null;
    }
    final RegExp regExp = RegExp(r'[Rr]everts[\s]+([-\.a-zA-Z_]+/[-\.a-zA-Z_]+#[0-9]+)', multiLine: true);
    final Iterable<RegExpMatch> matches = regExp.allMatches(bodyText);

    if (matches.isNotEmpty && matches.length == 1) {
      return matches.elementAt(0).group(1);
    } else if (matches.isNotEmpty && matches.length != 1) {
      log.warning('Detected more than 1 revert link. Cannot process more than one link.');
    }
    return null;
  }

  /// Split a reverts link on the '#' then the '/' to get the parts of the repo
  /// slug. It is assumed that the link has the format flutter/repo#id.
  github.RepositorySlug _getSlugFromLink(String link) {
    final List<String> linkSplit = link.split('#');
    final List<String> slugSplit = linkSplit.elementAt(0).split('/');
    return github.RepositorySlug(slugSplit.elementAt(0), slugSplit.elementAt(1));
  }

  /// Split a reverts link on the '#' to get the id part of the link.
  /// It is assumed that the link has the format flutter/repo#id.
  int _getPullRequestNumberFromLink(String link) {
    final List<String> linkSplit = link.split('#');
    return int.parse(linkSplit.elementAt(1));
  }
}
