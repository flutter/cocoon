// Copyright 2026 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:collection/collection.dart';
import 'package:meta/meta.dart';

/// Sealed hierarchy representing the parsed `WANT_LGTM=` directive in a PR body.
@immutable
sealed class ParsedWantLgtmDirective {
  const ParsedWantLgtmDirective();
}

/// Indicates no `WANT_LGTM=` directive was declared in the PR description.
final class NoWantLgtmDirective extends ParsedWantLgtmDirective {
  const NoWantLgtmDirective();

  @override
  bool operator ==(Object other) => other is NoWantLgtmDirective;

  @override
  int get hashCode => 0;

  @override
  String toString() => 'NoWantLgtmDirective()';
}

/// A syntactically valid `WANT_LGTM=` directive.
final class ValidWantLgtmDirective extends ParsedWantLgtmDirective {
  const ValidWantLgtmDirective({
    required this.requiresAll,
    required this.explicitLogins,
  });

  /// Whether the directive specifies `all`, requiring all sidebar-requested reviewers.
  final bool requiresAll;

  /// Explicit reviewer logins named in the directive, lowercase, '@'-stripped,
  /// author-excluded, and deduplicated.
  final List<String> explicitLogins;

  /// Returns the canonical representation for Firestore storage.
  String get canonicalStorageValue {
    if (requiresAll) {
      return explicitLogins.isEmpty ? 'all' : 'all,${explicitLogins.join(',')}';
    }
    return explicitLogins.join(',');
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is ValidWantLgtmDirective &&
            other.requiresAll == requiresAll &&
            const ListEquality<String>().equals(
              other.explicitLogins,
              explicitLogins,
            ));
  }

  @override
  int get hashCode => Object.hash(requiresAll, Object.hashAll(explicitLogins));

  @override
  String toString() =>
      'ValidWantLgtmDirective(requiresAll: $requiresAll, explicitLogins: $explicitLogins)';
}

/// A syntactically invalid `WANT_LGTM=` directive containing illegal tokens.
final class InvalidWantLgtmDirective extends ParsedWantLgtmDirective {
  const InvalidWantLgtmDirective({required this.invalidTokens});

  /// The invalid tokens encountered (e.g. '@flutter/engine').
  final List<String> invalidTokens;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is InvalidWantLgtmDirective &&
            const ListEquality<String>().equals(
              other.invalidTokens,
              invalidTokens,
            ));
  }

  @override
  int get hashCode => Object.hashAll(invalidTokens);

  @override
  String toString() =>
      'InvalidWantLgtmDirective(invalidTokens: $invalidTokens)';
}

/// Non-comment review states tracked by WANT_LGTM.
enum WantLgtmReviewState { approved, changesRequested, dismissed }

/// Timeline review request actions on a PR.
enum TimelineReviewAction { requested, removed }

/// An immutable record of a review submission on GitHub.
@immutable
final class WantLgtmReviewRecord {
  const WantLgtmReviewRecord({
    required this.authorLogin,
    required this.state,
    required this.submittedAt,
  });

  /// Login of the reviewing user, lowercase.
  final String authorLogin;

  /// Review state (approved, changesRequested, dismissed).
  final WantLgtmReviewState state;

  /// Timestamp when the review was submitted on GitHub.
  final DateTime? submittedAt;

  @override
  bool operator ==(Object other) =>
      other is WantLgtmReviewRecord &&
      other.authorLogin == authorLogin &&
      other.state == state &&
      other.submittedAt == submittedAt;

  @override
  int get hashCode => Object.hash(authorLogin, state, submittedAt);

  @override
  String toString() =>
      'WantLgtmReviewRecord(authorLogin: $authorLogin, state: $state, submittedAt: $submittedAt)';
}

/// An immutable record of a review request or removal timeline event.
@immutable
final class WantLgtmTimelineEvent {
  const WantLgtmTimelineEvent({
    required this.reviewerLogin,
    required this.action,
    required this.createdAt,
  });

  /// Login of the requested reviewer, lowercase.
  final String reviewerLogin;

  /// Action taken (requested or removed).
  final TimelineReviewAction action;

  /// Timestamp when the action occurred on GitHub.
  final DateTime? createdAt;

  @override
  bool operator ==(Object other) =>
      other is WantLgtmTimelineEvent &&
      other.reviewerLogin == reviewerLogin &&
      other.action == action &&
      other.createdAt == createdAt;

  @override
  int get hashCode => Object.hash(reviewerLogin, action, createdAt);

  @override
  String toString() =>
      'WantLgtmTimelineEvent(reviewerLogin: $reviewerLogin, action: $action, createdAt: $createdAt)';
}

/// An immutable snapshot of PR review state queried via GraphQL.
@immutable
final class WantLgtmGraphQLSnapshot {
  const WantLgtmGraphQLSnapshot({
    required this.prState,
    required this.body,
    required this.headRefOid,
    required this.authorLogin,
    required this.openReviewRequestLogins,
    required this.reviews,
    required this.timelineEvents,
    required this.queryCount,
  });

  /// Factory for a minimal empty snapshot when evaluating without GraphQL queries.
  factory WantLgtmGraphQLSnapshot.empty({
    String prState = 'OPEN',
    String body = '',
    String headRefOid = '',
    String authorLogin = '',
  }) => WantLgtmGraphQLSnapshot(
    prState: prState,
    body: body,
    headRefOid: headRefOid,
    authorLogin: authorLogin,
    openReviewRequestLogins: const {},
    reviews: const [],
    timelineEvents: const [],
    queryCount: 0,
  );

  /// State of the PR ('OPEN', 'CLOSED', 'MERGED').
  final String prState;

  /// Full markdown body of the PR.
  final String body;

  /// Commit SHA of the PR head.
  final String headRefOid;

  /// PR author login, lowercase (empty string if author is null/ghost).
  final String authorLogin;

  /// Logins of currently open review requests from `reviewRequests`.
  final Set<String> openReviewRequestLogins;

  /// Reviews in GraphQL connection order.
  final List<WantLgtmReviewRecord> reviews;

  /// Timeline events in GraphQL connection order.
  final List<WantLgtmTimelineEvent> timelineEvents;

  /// Total number of GraphQL query round-trips used to fetch this snapshot.
  final int queryCount;
}

/// Sealed hierarchy representing the verdict of evaluating a PR's review status.
@immutable
sealed class WantLgtmVerdict {
  const WantLgtmVerdict({required this.title, required this.summary});

  /// Check run title (capped at <= 255 chars).
  final String title;

  /// Check run markdown summary.
  final String summary;
}

/// Evaluator verdict when all required reviewers have approved.
final class WantLgtmSatisfied extends WantLgtmVerdict {
  const WantLgtmSatisfied({
    required this.approvedBy,
    required this.latestApprovalAt,
    required super.title,
    required super.summary,
  });

  /// Logins of reviewers who approved.
  final List<String> approvedBy;

  /// Timestamp of the latest approval, used for `approval_to_green_ms` telemetry.
  final DateTime? latestApprovalAt;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is WantLgtmSatisfied &&
            other.title == title &&
            other.summary == summary &&
            other.latestApprovalAt == latestApprovalAt &&
            const ListEquality<String>().equals(other.approvedBy, approvedBy));
  }

  @override
  int get hashCode =>
      Object.hash(title, summary, latestApprovalAt, Object.hashAll(approvedBy));

  @override
  String toString() =>
      'WantLgtmSatisfied(approvedBy: $approvedBy, latestApprovalAt: $latestApprovalAt, title: $title)';
}

/// Evaluator verdict when required reviewers are still waiting or requested changes.
final class WantLgtmPending extends WantLgtmVerdict {
  const WantLgtmPending({
    required this.waitingOn,
    required this.changesRequestedBy,
    required super.title,
    required super.summary,
  });

  /// Logins of required reviewers whose approval is still pending.
  final List<String> waitingOn;

  /// Logins of reviewers who currently have changes requested.
  final List<String> changesRequestedBy;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is WantLgtmPending &&
            other.title == title &&
            other.summary == summary &&
            const ListEquality<String>().equals(other.waitingOn, waitingOn) &&
            const ListEquality<String>().equals(
              other.changesRequestedBy,
              changesRequestedBy,
            ));
  }

  @override
  int get hashCode => Object.hash(
    title,
    summary,
    Object.hashAll(waitingOn),
    Object.hashAll(changesRequestedBy),
  );

  @override
  String toString() =>
      'WantLgtmPending(waitingOn: $waitingOn, changesRequestedBy: $changesRequestedBy, title: $title)';
}

/// Evaluator verdict when the directive syntax is invalid.
final class WantLgtmInvalid extends WantLgtmVerdict {
  const WantLgtmInvalid({
    required this.invalidTokens,
    required super.title,
    required super.summary,
  });

  /// Invalid tokens in the directive.
  final List<String> invalidTokens;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is WantLgtmInvalid &&
            other.title == title &&
            other.summary == summary &&
            const ListEquality<String>().equals(
              other.invalidTokens,
              invalidTokens,
            ));
  }

  @override
  int get hashCode =>
      Object.hash(title, summary, Object.hashAll(invalidTokens));

  @override
  String toString() =>
      'WantLgtmInvalid(invalidTokens: $invalidTokens, title: $title)';
}
