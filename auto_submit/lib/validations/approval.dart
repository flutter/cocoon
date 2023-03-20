// Copyright 2022 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:auto_submit/configuration/repository_configuration.dart';
import 'package:auto_submit/service/config.dart';
import 'package:auto_submit/model/auto_submit_query_result.dart';
import 'package:auto_submit/service/github_service.dart';
import 'package:auto_submit/validations/validation.dart';
import 'package:github/github.dart' as github;

import '../service/log.dart';

/// Validates that a PR has been approved in accordance with the code review
/// guidelines.
class Approval extends Validation {
  Approval({
    required super.config,
  });

  /// Implements the code review approval logic.
  @override
  Future<ValidationResult> validate(QueryResult result, github.PullRequest messagePullRequest) async {
    final PullRequest pullRequest = result.repository!.pullRequest!;
    final String authorAssociation = pullRequest.authorAssociation!;
    final String? author = pullRequest.author!.login;
    final List<ReviewNode> reviews = pullRequest.reviews!.nodes!;
    final github.RepositorySlug slug = github.RepositorySlug.full(messagePullRequest.base!.repo!.fullName);

    final RepositoryConfiguration repositoryConfiguration = await config.getRepositoryConfiguration(slug);

    bool approved = false;
    String message = '';
    if (repositoryConfiguration.autoApprovalAccounts.contains(author)) {
      approved = true;
      log.info('PR approved by roller account: $author');
      return ValidationResult(approved, Action.REMOVE_LABEL, '');
    } else {
      final Approver approver = Approver(
        repositoryConfiguration,
        await config.createGithubService(slug),
        author,
        reviews,
      );
      await approver.computeApproval();
      approved = approver.approved;

      log.info(
        'PR approved $approved, approvers: ${approver.approvers}, remaining approvals: ${approver.remainingReviews}, request authors: ${approver.changeRequestAuthors}',
      );

      String approvedMessage;

      // Changes were requested, review count does not matter.
      if (approver.changeRequestAuthors.isNotEmpty) {
        approved = false;
        approvedMessage =
            'This PR has not met approval requirements for merging. Changes were requested by ${approver.changeRequestAuthors}, please make the needed changes and resubmit this PR.\n'
            'You have project association $authorAssociation and need ${approver.remainingReviews} more review(s) in order to merge this PR.\n';
      } else {
        // No changes were requested.
        approvedMessage = approved
            ? 'This PR has met approval requirements for merging.\n'
            : 'This PR has not met approval requirements for merging. You have project association $authorAssociation and need ${approver.remainingReviews} more review(s) in order to merge this PR.\n';
      }

      message = approved ? approvedMessage : '$approvedMessage\n${Config.pullRequestApprovalRequirementsMessage}';
    }

    return ValidationResult(approved, Action.REMOVE_LABEL, message);
  }
}

class Approver {
  Approver(
    this.repositoryConfiguration,
    this.githubService,
    this.author,
    this.reviews,
  );

  final RepositoryConfiguration repositoryConfiguration;
  final GithubService githubService;
  final String? author;
  final List<ReviewNode> reviews;

  bool _approved = false;
  int _remainingReviews = 2;
  final Set<String?> _approvers = <String?>{};
  final Set<String?> _changeRequestAuthors = <String?>{};
  final Set<String?> _reviewAuthors = <String?>{};

  bool get approved => _approved;

  int get remainingReviews => _remainingReviews;

  Set<String?> get approvers => _approvers;

  Set<String?> get changeRequestAuthors => _changeRequestAuthors;

  /// Parses the restApi response reviews.
  ///
  /// If author is a MEMBER or OWNER then it only requires a single review from
  /// another MEMBER or OWNER. If the author is not a MEMBER or OWNER then it
  /// requires two reviews from MEMBERs or OWNERS.
  ///
  /// If there are any CHANGES_REQUESTED reviews, checks if the same author has
  /// subsequently APPROVED.  From testing, dismissing a review means it won't
  /// show up in this list since it will have a status of DISMISSED and we only
  /// ask for CHANGES_REQUESTED or APPROVED - however, adding a new review does
  /// not automatically dismiss the previous one.
  Future<void> computeApproval() async {
    //TODO remove the COLLABORATOR config from here when done testing.
    // const Set<String> allowedReviewers = <String>{ORG_MEMBER, ORG_OWNER, ORG_COLLABORATOR};
    // final bool authorIsMember = allowedReviewers.contains(authorAssociation);

    // team might be more than one in the future.
    final bool authorIsMember = await githubService.isMember(repositoryConfiguration.approvalGroup, author!);

    // Author counts as 1 review so we need only 1 more.
    if (authorIsMember) {
      _remainingReviews--;
      _approvers.add(author);
    }

    final int targetReviewCount = _remainingReviews;

    for (ReviewNode review in reviews.reversed) {
      if (review.author!.login == author) {
        log.info('Author cannot review own pull request.');
        continue;
      }

      // Ignore reviews from non-members/owners.
      if (!await githubService.isMember(
        repositoryConfiguration.approvalGroup,
        review.author!.login!,
      )) {
        continue;
      }

      // Reviews come back in order of creation.
      final String? state = review.state;
      final String? authorLogin = review.author!.login;
      // For some reason github will allow a reviewer to provide multiple
      // reviews and will keep them all so the same person can provide two
      // reviews and bypass the two review rule. We make an _approvers
      // contains check to make sure this does not happen.
      if (state == APPROVED_STATE && !_reviewAuthors.contains(authorLogin)) {
        _approvers.add(authorLogin);
        if (_remainingReviews > 0) {
          _remainingReviews--;
        }
      } else if (state == CHANGES_REQUESTED_STATE && !_reviewAuthors.contains(authorLogin)) {
        _changeRequestAuthors.add(authorLogin);
        if (_remainingReviews < targetReviewCount) {
          _remainingReviews++;
        }
      }

      _reviewAuthors.add(authorLogin);
    }

    _approved = (_approvers.length > 1) && _changeRequestAuthors.isEmpty;
  }
}
