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
    final bool approved = config.rollerAccounts.contains(author) ||
        _checkApproval(
          author,
          authorAssociation,
          reviews,
        );

    const String message = '- Please get at least one approved review if you are already '
        'a member or two member reviews if you are not a member before re-applying this '
        'label. __Reviewers__: If you left a comment approving, please use '
        'the "approve" review action instead.';
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
  bool _checkApproval(
    String? author,
    String? authorAssociation,
    List<ReviewNode> reviewNodes,
  ) {
    final Set<String?> changeRequestAuthors = <String?>{};
    const Set<String> allowedReviewers = <String>{ORG_MEMBER, ORG_OWNER};
    final Set<String?> approvers = <String?>{};
    if (allowedReviewers.contains(authorAssociation)) {
      approvers.add(author);
    }
    for (ReviewNode review in reviewNodes) {
      // Ignore reviews from non-members/owners.
      if (!allowedReviewers.contains(review.authorAssociation)) {
        continue;
      }
      // Reviews come back in order of creation.
      final String? state = review.state;
      final String? authorLogin = review.author!.login;
      if (state == APPROVED_STATE) {
        approvers.add(authorLogin);
        changeRequestAuthors.remove(authorLogin);
      } else if (state == CHANGES_REQUESTED_STATE) {
        changeRequestAuthors.add(authorLogin);
      }
    }
    final bool approved = (approvers.length > 1) && changeRequestAuthors.isEmpty;
    log.info('PR approved $approved, approvers: $approvers, change request authors: $changeRequestAuthors');
    return (approvers.length > 1) && changeRequestAuthors.isEmpty;
  }
}
