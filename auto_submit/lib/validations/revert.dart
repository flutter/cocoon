// Copyright 2022 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:auto_submit/model/auto_submit_query_result.dart' as auto;
import 'package:auto_submit/validations/validation.dart';
import 'package:github/github.dart' as github;
import 'package:auto_submit/service/github_service.dart';
import 'package:github/github.dart';

import '../service/config.dart';
import '../service/log.dart';

class Revert extends Validation { 
  Revert({
    required Config config,
  }) : super(config: config);

  static const Set<String> allowedReviewers = <String>{ORG_MEMBER, ORG_OWNER};

  /// Validate a revert pull request.
  @override
  Future<ValidationResult> validate(auto.QueryResult result, github.PullRequest messagePullRequest) async {
    final auto.PullRequest pullRequest = result.repository!.pullRequest!;
    final String authorAssociation = pullRequest.authorAssociation!;
    final String? author = pullRequest.author!.login;

    // Check to make sure the author is valid.
    if (!isValidAuthor(author, authorAssociation)) {
      String message = 'The author $author does not have permissions to make this request.';
      log.info(message);
      return ValidationResult(false, Action.REMOVE_LABEL, message);
    }

    // check if the PR is mergeable
    bool? canMerge = messagePullRequest.mergeable;
    if (canMerge == null || !canMerge) {
      String message = 'This pull request cannot be merged due to conflicts. Please resolve conflicts and re-add the revert label.';
      log.info(message);
      return ValidationResult(false, Action.REMOVE_LABEL, message);
    }

    // Get the reverts link from the pull request.
    String? pullRequestBody = messagePullRequest.body;
    String? revertLink = extractLinkFromText(pullRequestBody);
    if (revertLink == null) {
      String message = 'A reverts link could not be found or was formatted incorrectly. Format is \'Reverts owner/repo#id\'';
      log.info(message);
      return ValidationResult(false, Action.REMOVE_LABEL, message);
    }

    // Get the reverts pull request.
    github.RepositorySlug repositorySlug = _getSlugFromLink(revertLink);
    int pullRequestId = _getPullRequestIdFromLink(revertLink);
    github.PullRequest requestToRevert = await getPullRequest(repositorySlug, pullRequestId);

    // Compare the changes made with the linked pull request.
    bool requestsMatch = await comparePullRequests(repositorySlug, requestToRevert, messagePullRequest);

    // if the changes are a revert then approve the pull request.
    if (requestsMatch) {
      // create a follow on issue to track the review request for this revert.
      return ValidationResult(true, Action.IGNORE_FAILURE, 'Revert request has been verified and will be queued for merge.');
    }

    // The requests do not match so we need to notify the user.
    return ValidationResult(false, Action.REMOVE_LABEL, 'Validation of the revert request has failed. Verify the files in the revert request are the same as the original PR and resubmit the revert request.');
  }

  /// Only a team member and code owner can submit a revert request with a review.
  bool isValidAuthor(String? author, String authorAssociation) {
    return config.rollerAccounts.contains(author) || allowedReviewers.contains(authorAssociation);
  }

  /// The full text here is 'Reverts flutter/cocoon#XXXXX' as output by github
  /// the link must be in the form github.com/flutter/repo/pull/id
  final RegExp _regExp = RegExp(r'^[Rr]everts[\s]+([-\.a-zA-Z_]+/[-\.a-zA-Z_]+#[0-9]+)$', multiLine: true);
  String? extractLinkFromText(String? bodyText) {
    if (bodyText == null) {
      return null;
    }
    var matches = _regExp.allMatches(bodyText);
    // look at only the first match
    if (matches.isNotEmpty) {
      // return the first group
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

  /// Method to wrap functionality for getting the revert request. Done mainly
  /// for testing purposes.
  Future<github.PullRequest> getPullRequest(github.RepositorySlug repositorySlug, int issueId) async {
    final GithubService gitHubService = await config.createGithubService(repositorySlug);
    return gitHubService.getPullRequest(repositorySlug, issueId);
  }

  /// Proposer the current pull request we want to compare against proposee. If
  /// the files in proposer are the same or a subset of proposee then we can
  /// consider this a revert request.
  Future<bool> comparePullRequests(
      github.RepositorySlug repositorySlug, github.PullRequest revert, github.PullRequest current) async {
    final GithubService githubService = await config.createGithubService(repositorySlug);
    List<PullRequestFile> originalPullRequestFiles = await githubService.getPullRequestFiles(repositorySlug, revert);
    List<PullRequestFile> currentPullRequestFiles = await githubService.getPullRequestFiles(repositorySlug, current);

    return validateFileSetsAreEqual(originalPullRequestFiles, currentPullRequestFiles);
  }

  /// Validate that each pull request has the same number of files and that the 
  /// file names match. This must be the case in order to process the revert.
  bool validateFileSetsAreEqual(
      List<PullRequestFile> revertPullRequestFiles, List<PullRequestFile> currentPullRequestFiles) {
    List<String?> revertFileNames = [];
    List<String?> currentFileNames = [];

    for (var element in revertPullRequestFiles) {
      revertFileNames.add(element.filename);
    }
    for (var element in currentPullRequestFiles) {
      currentFileNames.add(element.filename);
    }

    return revertFileNames.toSet().containsAll(currentFileNames) &&
        currentFileNames.toSet().containsAll(revertFileNames);
  }
}
