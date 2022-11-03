// Copyright 2022 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:auto_submit/model/auto_submit_query_result.dart';
import 'package:auto_submit/validations/validation.dart';
import 'package:github/github.dart' as github;

import '../service/log.dart';

/// Validates the PR does not have any pending change requests.
class ChangeRequested extends Validation {
  ChangeRequested({
    required super.config,
  });

  @override

  /// Implements the change request validation.
  Future<ValidationResult> validate(QueryResult result, github.PullRequest messagePullRequest) async {
    final PullRequest pullRequest = result.repository!.pullRequest!;
    final String authorAssociation = pullRequest.authorAssociation!;
    final String? author = pullRequest.author!.login;
    final List<ReviewNode> reviews = pullRequest.reviews!.nodes!;
    const Set<String> allowedReviewers = <String>{ORG_MEMBER, ORG_OWNER};
    final Set<String?> approvers = <String?>{};
    final Set<String?> changeRequestAuthors = <String?>{};

    if (allowedReviewers.contains(authorAssociation)) {
      approvers.add(author);
    }

    if (config.rollerAccounts.contains(author)) {
      // If the PR was created by an autoroller just pass the validation.
      return ValidationResult(true, Action.REMOVE_LABEL, '');
    }

    for (ReviewNode review in reviews) {
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
    final bool changesRequested = (approvers.length > 1) && changeRequestAuthors.isEmpty;

    final StringBuffer buffer = StringBuffer();
    for (String? author in changeRequestAuthors) {
      buffer.writeln('- This pull request has changes requested by @$author. Please '
          'resolve those before re-applying the label.');
    }
    return ValidationResult(changesRequested, Action.REMOVE_LABEL, buffer.toString());
  }
}
