// Copyright 2022 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:auto_submit/model/auto_submit_query_result.dart' as auto;
import 'package:auto_submit/service/github_service.dart';
import 'package:auto_submit/validations/validation.dart';
import 'package:github/github.dart' as github;

import '../service/config.dart';
import '../service/log.dart';

class Revert extends Validation {
  Revert({
    required Config config,
  }) : super(config: config);

  static const Set<String> allowedReviewers = <String>{ORG_MEMBER, ORG_OWNER};

  @override
  Future<ValidationResult> validate(auto.QueryResult result, github.PullRequest messagePullRequest) async {
    final auto.PullRequest pullRequest = result.repository!.pullRequest!;
    final String authorAssociation = pullRequest.authorAssociation!;
    final String? author = pullRequest.author!.login;

    if (!isValidAuthor(author, authorAssociation)) {
      String message = 'The author $author does not have permissions to make this request.';
      log.info(message);
      return ValidationResult(false, Action.REMOVE_LABEL, message);
    }

    bool? canMerge = messagePullRequest.mergeable;
    if (canMerge == null || !canMerge) {
      String message =
          'This pull request cannot be merged due to conflicts. Please resolve conflicts and re-add the revert label.';
      log.info(message);
      return ValidationResult(false, Action.REMOVE_LABEL, message);
    }

    String? pullRequestBody = messagePullRequest.body;
    String? revertLink = extractLinkFromText(pullRequestBody);
    if (revertLink == null) {
      String message =
          'A reverts link could not be found or was formatted incorrectly. Format is \'Reverts owner/repo#id\'';
      log.info(message);
      return ValidationResult(false, Action.REMOVE_LABEL, message);
    }

    github.RepositorySlug repositorySlug = _getSlugFromLink(revertLink);
    GithubService githubService = await config.createGithubService(repositorySlug);
    int pullRequestId = _getPullRequestIdFromLink(revertLink);
    github.PullRequest requestToRevert = await githubService.getPullRequest(repositorySlug, pullRequestId);

    bool requestsMatch = await githubService.comparePullRequests(repositorySlug, requestToRevert, messagePullRequest);

    if (requestsMatch) {
      return ValidationResult(
          true, Action.IGNORE_FAILURE, 'Revert request has been verified and will be queued for merge.');
    }

    return ValidationResult(false, Action.REMOVE_LABEL,
        'Validation of the revert request has failed. Verify the files in the revert request are the same as the original PR and resubmit the revert request.');
  }

  /// Only a team member and code owner can submit a revert request without a review.
  bool isValidAuthor(String? author, String authorAssociation) {
    return config.rollerAccounts.contains(author) || allowedReviewers.contains(authorAssociation);
  }

  /// The full text here is 'Reverts flutter/cocoon#XXXXX' as output by github
  /// the link must be in the form github.com/flutter/repo/pull/id
  String? extractLinkFromText(String? bodyText) {
    if (bodyText == null) {
      return null;
    }
    final RegExp regExp = RegExp(r'^[Rr]everts[\s]+([-\.a-zA-Z_]+/[-\.a-zA-Z_]+#[0-9]+)$', multiLine: true);
    Iterable<RegExpMatch> matches = regExp.allMatches(bodyText);
    if (matches.isNotEmpty) {
      return matches.elementAt(0).group(1);
    }
    return null;
  }

  /// Split a reverts link on the '#' then the '/' to get the parts of the repo
  /// slug. It is assumed that the link has the format flutter/repo#id.
  github.RepositorySlug _getSlugFromLink(String link) {
    List<String> linkSplit = link.split('#');
    List<String> slugSplit = linkSplit.elementAt(0).split('/');
    return github.RepositorySlug(slugSplit.elementAt(0), slugSplit.elementAt(1));
  }

  /// Split a reverts link on the '#' to get the id part of the link.
  /// It is assumed that the link has the format flutter/repo#id.
  int _getPullRequestIdFromLink(String link) {
    List<String> linkSplit = link.split('#');
    return int.parse(linkSplit.elementAt(1));
  }
}
