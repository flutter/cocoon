// Copyright 2022 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:auto_submit/model/auto_submit_query_result.dart';
import 'package:auto_submit/validations/validation.dart';
import 'package:github/github.dart' as github;

import '../service/log.dart';

/// Validates that a PR has been approved in accordance with the code review
/// guidelines.
class Approval extends Validation {
  Approval({
    required super.config,
  });

  @override
  /// Implements the code review approval logic.
  Future<ValidationResult> validate(QueryResult result, github.PullRequest messagePullRequest) async {
    final PullRequest pullRequest = result.repository!.pullRequest!;
    final String authorAssociation = pullRequest.authorAssociation!;
    final String? author = pullRequest.author!.login;
    final List<ReviewNode> reviews = pullRequest.reviews!.nodes!;

    bool approved = false;
    String message = '';
    if (config.rollerAccounts.contains(author)) {
      approved = true;
      log.info('PR approved by roller account: $author');
      return ValidationResult(approved, Action.REMOVE_LABEL, '');
    } else {
      final Approver approver = Approver(author, authorAssociation, reviews);
      approver.computeApproval();
      approved = approver.approved;
      log.info('PR approved $approved, approvers: ${approver.approvers}, remaining approvals: ${approver.remainingReviews}, request authors: ${approver.changeRequestAuthors}');
      final String appvd = approved ?
        'This PR has met approval requirements for merging.' :
        'This PR has not met approval requirements for merging. You have project association $authorAssociation and need ${approver.remainingReviews} move reviews in order to merge this PR.';
      

      message = '$appvd\n' 
        '- You need at least one approved review if you are already '
        'a MEMBER or two member reviews if you are not a MEMBER before re-applying the '
        'autosubmit label. __Reviewers__: If you left a comment approving, please use '
        'the "approve" review action instead.';
    }

    return ValidationResult(approved, Action.REMOVE_LABEL, message);
  }

  

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
  ///
  ///
  /// Returns false if no approved reviews or any oustanding change request
  /// reviews.
  ///
  /// Returns true if at least one approved review and no outstanding change
  /// request reviews.
  // bool _checkApproval(
  //   String? author,
  //   String? authorAssociation,
  //   List<ReviewNode> reviewNodes,
  // ) {
    // final Set<String?> changeRequestAuthors = <String?>{};
    // const Set<String> allowedReviewers = <String>{ORG_MEMBER, ORG_OWNER};
    // final Set<String?> approvers = <String?>{};
    // // Author counts as 1 review so we need only 1 more.
    // if (allowedReviewers.contains(authorAssociation)) {
    //   approvers.add(author);
    // }
    // for (ReviewNode review in reviewNodes) {
    //   // Ignore reviews from non-members/owners.
    //   if (!allowedReviewers.contains(review.authorAssociation)) {
    //     continue;
    //   }
    //   // Reviews come back in order of creation.
    //   final String? state = review.state;
    //   final String? authorLogin = review.author!.login;
    //   if (state == APPROVED_STATE) {
    //     approvers.add(authorLogin);
    //     changeRequestAuthors.remove(authorLogin);
    //   } else if (state == CHANGES_REQUESTED_STATE) {
    //     changeRequestAuthors.add(authorLogin);
    //   }
    // }
    // final bool approved = (approvers.length > 1) && changeRequestAuthors.isEmpty;
  //   final Approver approver = Approver(author, authorAssociation, reviewNodes);
  //   approver.computeApproval();
  //   final bool approved = approver.approved;
  //   final int remaining = approver.remainingReviews;
  //   final Set<String?> approvers = approver.approvers;
  //   final Set<String?> changeRequestAuthors = approver.changeRequestAuthors;

  //   log.info('PR approved $approved, approvers: $approvers, remaining approvals: $remaining, request authors: $changeRequestAuthors');
  //   return approved;
  // }
}

/// If the original author is a MEMBER/OWNER they count as 1 towards the
/// requirements and thus need only a single review from a MEMBER/OWNER. If 
/// the author is not a MEMBER/OWNER they need two reviews from a 
/// MEMBER/OWNER.

// what I have access to: 
  // Author
  // AuthorAssociation
  // List<reviewNodes>

// what I want to provide:
  // approved?
  // how many remaining reviews?

class Approver {
  Approver(this.author, this.authorAssociation, this.reviews);

  final String? author;
  final String? authorAssociation;
  final List<ReviewNode> reviews;

  bool _approved = false;
  int _remainingReviews = 2;
  final Set<String?> _approvers = <String?>{};
  final Set<String?> _changeRequestAuthors = <String?>{};

  bool get approved => _approved;

  int get remainingReviews => _remainingReviews;

  Set<String?> get approvers => _approvers;

  Set<String?> get changeRequestAuthors => _changeRequestAuthors;

  void computeApproval() {
    const Set<String> allowedReviewers = <String>{ORG_MEMBER, ORG_OWNER};
    // Author counts as 1 review so we need only 1 more.
    if (allowedReviewers.contains(authorAssociation)) {
      _approvers.add(author);
    }
    for (ReviewNode review in reviews) {
      // Ignore reviews from non-members/owners.
      if (!allowedReviewers.contains(review.authorAssociation)) {
        _remainingReviews--;
        continue;
      }

      // Reviews come back in order of creation.
      final String? state = review.state;
      final String? authorLogin = review.author!.login;
      if (state == APPROVED_STATE) {
        _approvers.add(authorLogin);
        _remainingReviews--;
        _changeRequestAuthors.remove(authorLogin);
      } else if (state == CHANGES_REQUESTED_STATE) {
        _changeRequestAuthors.add(authorLogin);
      }
    }
    
    _approved = (_approvers.length > 1) && _changeRequestAuthors.isEmpty;
  }
}
