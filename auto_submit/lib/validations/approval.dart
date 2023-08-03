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

/// Validates that a PR has been approved in accordance with the flutter code
/// review guidelines.
class Approval extends Validation {
  Approval({
    required super.config,
  });

  @override
  String get name => 'Approval';

  /// Implements the code review approval logic.
  @override
  Future<ValidationResult> validate(QueryResult result, github.PullRequest messagePullRequest) async {
    final PullRequest pullRequest = result.repository!.pullRequest!;
    final String? author = pullRequest.author!.login;
    final List<ReviewNode> reviews = pullRequest.reviews!.nodes!;
    final github.RepositorySlug slug = github.RepositorySlug.full(messagePullRequest.base!.repo!.fullName);

    final RepositoryConfiguration repositoryConfiguration = await config.getRepositoryConfiguration(slug);

    bool approved = false;
    String message = '';
    Action action = Action.REMOVE_LABEL;
    if (repositoryConfiguration.autoApprovalAccounts.contains(author)) {
      log.info('PR ${slug.fullName}/${messagePullRequest.number} approved by roller account: $author');
      return ValidationResult(true, Action.REMOVE_LABEL, '');
    } else {
      final GithubService githubService = await config.createGithubService(slug);
      final bool authorIsFlutterHacker =
          await githubService.isTeamMember(repositoryConfiguration.approvalGroup, author!, slug.owner);
      final Approver approver = Approver(
        slug,
        repositoryConfiguration,
        githubService,
        author,
        reviews,
      );
      await approver.computeApproval();
      approved = approver.approved;

      log.info(
        'PR ${slug.fullName}/${messagePullRequest.number} approved $approved, approvers: ${approver.approvers}, remaining approvals: ${approver.remainingReviews}, request authors: ${approver.changeRequestAuthors}',
      );

      String approvedMessage;
      final String flutterHackerMessage = (authorIsFlutterHacker)
          ? 'You are a member of ${repositoryConfiguration.approvalGroup}'
          : 'You are not a member of ${repositoryConfiguration.approvalGroup}';
      // Changes were requested, review count does not matter.
      if (approver.changeRequestAuthors.isNotEmpty) {
        approved = false;
        approvedMessage =
            'This PR has not met approval requirements for merging. Changes were requested by ${approver.changeRequestAuthors}, please make the needed changes and resubmit this PR.\n'
            '$flutterHackerMessage and need ${approver.remainingReviews} more review(s) in order to merge this PR.\n';
      } else {
        // No changes were requested so check approval count.
        approvedMessage = approved
            ? 'This PR has met approval requirements for merging.\n'
            : 'This PR has not met approval requirements for merging. $flutterHackerMessage and need ${approver.remainingReviews} more review(s) in order to merge this PR.\n';
        if (!approved && authorIsFlutterHacker) {
          // Flutter hackers are aware of the review requirements, and can add
          // the autosubmit label without waiting on review.
          action = Action.IGNORE_TEMPORARILY;
        }
      }

      message = approved ? approvedMessage : '$approvedMessage\n${Config.pullRequestApprovalRequirementsMessage}';
    }

    return ValidationResult(approved, action, message);
  }
}

class Approver {
  Approver(
    this.slug,
    this.repositoryConfiguration,
    this.githubService,
    this.author,
    this.reviews,
  );

  final github.RepositorySlug slug;
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
  /// If author is a of the defined approval group then it only requires a
  /// single review from another approval group member. If the author is not a
  /// member of the approval group then it will require two reviews from members
  /// of the approval group.
  ///
  /// Changes requested will supercede any approvals and the autosubmit bot will
  /// not make any merges until the change requests are fixed.
  Future<void> computeApproval() async {
    _remainingReviews = repositoryConfiguration.approvingReviews;
    // TODO (ricardoamador) team might be more than one in the future.
    final bool authorIsMember =
        await githubService.isTeamMember(repositoryConfiguration.approvalGroup, author!, slug.owner);

    // The author counts as 1 review if they are a member of the approval group
    // so we need only 1 more review from a member of the approval group.
    if (authorIsMember) {
      _remainingReviews--;
      _approvers.add(author);
    }

    final int targetReviewCount = _remainingReviews;

    // Github reviews are returned in chonological order so to avoid the odd
    // case where a user requests changes then approves we parse the reviews in
    // reverse chronological order.
    for (ReviewNode review in reviews.reversed) {
      if (review.author!.login == author) {
        log.info('Author cannot review own pull request.');
        continue;
      }

      // Ignore reviews from non-members/owners.
      if (!await githubService.isTeamMember(
        repositoryConfiguration.approvalGroup,
        review.author!.login!,
        slug.owner,
      )) {
        continue;
      }

      final String? state = review.state;
      final String? authorLogin = review.author!.login;
      // Github keeps all reviews so the same person can provide two reviews and
      // possibly bypass the two review rule. Track the reviewers so we can
      // account for this.
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

    _approved = (_approvers.length > repositoryConfiguration.approvingReviews - 1) && _changeRequestAuthors.isEmpty;
  }
}
