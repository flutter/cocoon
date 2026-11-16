// Copyright 2026 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'want_lgtm_models.dart';

const int _kMaxTitleLength = 255;

String _clampTitleLength(String title) {
  if (title.length <= _kMaxTitleLength) {
    return title;
  }
  return '${title.substring(0, _kMaxTitleLength - 3)}...';
}

/// Evaluates a PR's review status against a parsed `WANT_LGTM=` directive.
WantLgtmVerdict evaluateWantLgtm({
  required ParsedWantLgtmDirective directive,
  required WantLgtmGraphQLSnapshot snapshot,
  required Set<String> rollerAccounts,
}) {
  return switch (directive) {
    NoWantLgtmDirective() => const WantLgtmSatisfied(
      approvedBy: [],
      latestApprovalAt: null,
      title: 'WANT_LGTM satisfied',
      summary: 'No WANT_LGTM directive specified.',
    ),
    InvalidWantLgtmDirective(:final invalidTokens) => WantLgtmInvalid(
      invalidTokens: invalidTokens,
      title: _clampTitleLength(
        'Invalid WANT_LGTM directive: ${invalidTokens.join(', ')}',
      ),
      summary:
          'The following tokens in WANT_LGTM= are invalid GitHub logins: '
          '${invalidTokens.join(', ')}. Note that GitHub teams (@org/team) are not supported.',
    ),
    ValidWantLgtmDirective(:final requiresAll, :final explicitLogins) =>
      _evaluateValidDirective(
        requiresAll: requiresAll,
        explicitLogins: explicitLogins,
        snapshot: snapshot,
        rollerAccounts: rollerAccounts,
      ),
  };
}

/// Computes the cohort of reviewers requested via GitHub sidebar / timeline.
Set<String> _resolveAllCohort(
  WantLgtmGraphQLSnapshot snapshot,
  Set<String> rollerAccounts,
) {
  final normalizedAuthor = snapshot.authorLogin.trim().toLowerCase();
  final normalizedRollers = <String>{
    for (final s in rollerAccounts) s.trim().toLowerCase(),
  };

  final timelineRequested = <String>{};
  for (final event in snapshot.timelineEvents) {
    final login = event.reviewerLogin.toLowerCase();
    switch (event.action) {
      case TimelineReviewAction.requested:
        timelineRequested.add(login);
      case TimelineReviewAction.removed:
        timelineRequested.remove(login);
    }
  }

  return <String>{
    for (final s in snapshot.openReviewRequestLogins) s.toLowerCase(),
    ...timelineRequested,
  }..removeWhere(
    (login) => login == normalizedAuthor || normalizedRollers.contains(login),
  );
}

/// Evaluates review status across all required users.
({
  List<String> approvedBy,
  List<String> waitingOn,
  List<String> changesRequestedBy,
  DateTime? latestApprovalAt,
})
_evaluateUsers(Set<String> requiredUsers, WantLgtmGraphQLSnapshot snapshot) {
  final approvedBy = <String>[];
  final waitingOn = <String>[];
  final changesRequestedBy = <String>[];
  DateTime? latestApprovalAt;

  final sortedUsers = requiredUsers.toList()..sort();
  for (final user in sortedUsers) {
    final status = _determineUserReviewStatus(user, snapshot);
    switch (status) {
      case _UserReviewStatus.approved:
        approvedBy.add(user);
        final userApprovalAt = _findLatestApprovalTime(user, snapshot.reviews);
        if (userApprovalAt != null) {
          if (latestApprovalAt == null ||
              userApprovalAt.isAfter(latestApprovalAt)) {
            latestApprovalAt = userApprovalAt;
          }
        }
      case _UserReviewStatus.changesRequested:
        changesRequestedBy.add(user);
      case _UserReviewStatus.waiting:
        waitingOn.add(user);
    }
  }

  return (
    approvedBy: approvedBy,
    waitingOn: waitingOn,
    changesRequestedBy: changesRequestedBy,
    latestApprovalAt: latestApprovalAt,
  );
}

/// Builds the final verdict from categorized reviewer groups.
WantLgtmVerdict _buildVerdict({
  required List<String> approvedBy,
  required List<String> waitingOn,
  required List<String> changesRequestedBy,
  required DateTime? latestApprovalAt,
}) {
  if (changesRequestedBy.isNotEmpty || waitingOn.isNotEmpty) {
    final title = changesRequestedBy.isNotEmpty
        ? '${changesRequestedBy.join(', ')} requested changes'
        : 'Waiting on ${waitingOn.join(', ')}';

    final summaryBuffer = StringBuffer('### WANT_LGTM Pending\n\n');
    if (changesRequestedBy.isNotEmpty) {
      summaryBuffer.writeln(
        '- **Changes requested by**: ${changesRequestedBy.join(', ')}',
      );
    }
    if (waitingOn.isNotEmpty) {
      summaryBuffer.writeln('- **Waiting on**: ${waitingOn.join(', ')}');
    }
    if (approvedBy.isNotEmpty) {
      summaryBuffer.writeln('- **Approved by**: ${approvedBy.join(', ')}');
    }

    return WantLgtmPending(
      waitingOn: waitingOn,
      changesRequestedBy: changesRequestedBy,
      title: _clampTitleLength(title),
      summary: summaryBuffer.toString().trim(),
    );
  }

  return WantLgtmSatisfied(
    approvedBy: approvedBy,
    latestApprovalAt: latestApprovalAt,
    title: _clampTitleLength('Approved by ${approvedBy.join(', ')}'),
    summary: 'All required reviewers have approved: ${approvedBy.join(', ')}',
  );
}

WantLgtmVerdict _evaluateValidDirective({
  required bool requiresAll,
  required List<String> explicitLogins,
  required WantLgtmGraphQLSnapshot snapshot,
  required Set<String> rollerAccounts,
}) {
  final requiredUsers = <String>{
    for (final s in explicitLogins) s.toLowerCase(),
  };

  if (requiresAll) {
    requiredUsers.addAll(_resolveAllCohort(snapshot, rollerAccounts));
    if (requiredUsers.isEmpty) {
      return const WantLgtmPending(
        waitingOn: [],
        changesRequestedBy: [],
        title: 'No reviewers requested',
        summary: 'No reviewers have been requested on GitHub.',
      );
    }
  }

  final (:approvedBy, :waitingOn, :changesRequestedBy, :latestApprovalAt) =
      _evaluateUsers(requiredUsers, snapshot);

  return _buildVerdict(
    approvedBy: approvedBy,
    waitingOn: waitingOn,
    changesRequestedBy: changesRequestedBy,
    latestApprovalAt: latestApprovalAt,
  );
}

enum _UserReviewStatus { approved, changesRequested, waiting }

DateTime? _findLatestApprovalTime(
  String user,
  List<WantLgtmReviewRecord> reviews,
) {
  for (var i = reviews.length - 1; i >= 0; i--) {
    final review = reviews[i];
    if (review.authorLogin.toLowerCase() == user &&
        review.state == WantLgtmReviewState.approved) {
      return review.submittedAt;
    }
  }
  return null;
}

WantLgtmReviewRecord? _findLatestReview(
  String user,
  List<WantLgtmReviewRecord> reviews,
) {
  for (var i = reviews.length - 1; i >= 0; i--) {
    final review = reviews[i];
    if (review.authorLogin.toLowerCase() == user) {
      return review;
    }
  }
  return null;
}

({bool isRequested, DateTime? requestedAt}) _findUnremovedTimelineRequest(
  String user,
  List<WantLgtmTimelineEvent> timelineEvents,
) {
  var isRequested = false;
  DateTime? latestRequestTime;

  for (final event in timelineEvents) {
    if (event.reviewerLogin.toLowerCase() != user) {
      continue;
    }
    switch (event.action) {
      case TimelineReviewAction.requested:
        isRequested = true;
        latestRequestTime = event.createdAt;
      case TimelineReviewAction.removed:
        isRequested = false;
        latestRequestTime = null;
    }
  }

  return (isRequested: isRequested, requestedAt: latestRequestTime);
}

_UserReviewStatus _determineUserReviewStatus(
  String user,
  WantLgtmGraphQLSnapshot snapshot,
) {
  if (snapshot.openReviewRequestLogins.any(
    (login) => login.toLowerCase() == user,
  )) {
    return _UserReviewStatus.waiting;
  }

  final latestReview = _findLatestReview(user, snapshot.reviews);
  if (latestReview == null ||
      latestReview.state == WantLgtmReviewState.dismissed) {
    return _UserReviewStatus.waiting;
  }

  final (:isRequested, :requestedAt) = _findUnremovedTimelineRequest(
    user,
    snapshot.timelineEvents,
  );
  if (isRequested) {
    final reviewTime = latestReview.submittedAt;
    if (reviewTime == null ||
        requestedAt == null ||
        requestedAt.isAfter(reviewTime)) {
      return _UserReviewStatus.waiting;
    }
  }

  if (latestReview.state == WantLgtmReviewState.changesRequested) {
    return _UserReviewStatus.changesRequested;
  }

  return _UserReviewStatus.approved;
}
