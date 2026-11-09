// Copyright 2026 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:github/github.dart';
import 'package:gql/language.dart' as lang;
import 'package:graphql/client.dart';

import 'want_lgtm_models.dart';

/// Exception thrown when a GraphQL operation fails or returns invalid data.
final class WantLgtmGraphQLException implements Exception {
  const WantLgtmGraphQLException(this.message);
  final String message;

  @override
  String toString() => 'WantLgtmGraphQLException: $message';
}

/// Client for fetching complete, race-free PR review snapshots via GitHub GraphQL.
final class WantLgtmGraphQLClient {
  const WantLgtmGraphQLClient(this._client);

  final GraphQLClient _client;

  /// Fetches a [WantLgtmGraphQLSnapshot] for the given pull request.
  Future<WantLgtmGraphQLSnapshot> fetchSnapshot(
    RepositorySlug slug,
    int prNumber,
  ) async {
    var queryCount = 0;
    final initialData = await _execute(_kInitialQuery, <String, Object?>{
      'owner': slug.owner,
      'name': slug.name,
      'number': prNumber,
    });
    queryCount++;

    final pr = _extractPr(initialData, slug, prNumber);
    final openRequests = <String>{};
    final reviews = <WantLgtmReviewRecord>[];
    final timelineEvents = <WantLgtmTimelineEvent>[];

    final requestsConn = pr['reviewRequests'] as Map<String, Object?>?;
    if (requestsConn != null) {
      _parseReviewRequests(requestsConn, openRequests);
      queryCount += await _paginateConnection(
        slug: slug,
        prNumber: prNumber,
        query: _kReviewRequestsPageQuery,
        connectionKey: 'reviewRequests',
        initialConn: requestsConn,
        onPage: (conn) => _parseReviewRequests(conn, openRequests),
      );
    }

    final reviewsConn = pr['reviews'] as Map<String, Object?>?;
    if (reviewsConn != null) {
      _parseReviews(reviewsConn, reviews);
      queryCount += await _paginateConnection(
        slug: slug,
        prNumber: prNumber,
        query: _kReviewsPageQuery,
        connectionKey: 'reviews',
        initialConn: reviewsConn,
        onPage: (conn) => _parseReviews(conn, reviews),
      );
    }

    final timelineConn = pr['timelineItems'] as Map<String, Object?>?;
    if (timelineConn != null) {
      _parseTimeline(timelineConn, timelineEvents);
      queryCount += await _paginateConnection(
        slug: slug,
        prNumber: prNumber,
        query: _kTimelinePageQuery,
        connectionKey: 'timelineItems',
        initialConn: timelineConn,
        onPage: (conn) => _parseTimeline(conn, timelineEvents),
      );
    }

    final author = pr['author'] as Map<String, Object?>?;
    final authorLogin = (author?['login'] as String? ?? '')
        .trim()
        .toLowerCase();

    return WantLgtmGraphQLSnapshot(
      prState: (pr['state'] as String? ?? 'OPEN').toUpperCase(),
      body: pr['body'] as String? ?? '',
      headRefOid: pr['headRefOid'] as String? ?? '',
      authorLogin: authorLogin,
      openReviewRequestLogins: openRequests,
      reviews: reviews,
      timelineEvents: timelineEvents,
      queryCount: queryCount,
    );
  }

  Future<int> _paginateConnection({
    required RepositorySlug slug,
    required int prNumber,
    required String query,
    required String connectionKey,
    required Map<String, Object?> initialConn,
    required void Function(Map<String, Object?> conn) onPage,
  }) async {
    var count = 0;
    var (hasNext, cursor) = _extractPageInfo(initialConn);
    while (hasNext && cursor != null) {
      final data = await _execute(query, <String, Object?>{
        'owner': slug.owner,
        'name': slug.name,
        'number': prNumber,
        'cursor': cursor,
      });
      count++;
      final pr = _extractPr(data, slug, prNumber);
      final conn = pr[connectionKey] as Map<String, Object?>?;
      if (conn == null) {
        break;
      }
      onPage(conn);
      (hasNext, cursor) = _extractPageInfo(conn);
    }
    return count;
  }

  Future<Map<String, Object?>> _execute(
    String query,
    Map<String, Object?> variables,
  ) async {
    final result = await _client.query(
      QueryOptions(
        document: lang.parseString(query),
        fetchPolicy: FetchPolicy.noCache,
        variables: variables,
      ),
    );
    if (result.hasException) {
      throw WantLgtmGraphQLException(result.exception.toString());
    }
    final data = result.data;
    if (data == null) {
      throw const WantLgtmGraphQLException('GraphQL response data was null');
    }
    return data;
  }

  static Map<String, Object?> _extractPr(
    Map<String, Object?> data,
    RepositorySlug slug,
    int prNumber,
  ) {
    final repo = data['repository'] as Map<String, Object?>?;
    final pr = repo?['pullRequest'] as Map<String, Object?>?;
    if (pr == null) {
      throw WantLgtmGraphQLException(
        'Pull request ${slug.fullName} #$prNumber not found',
      );
    }
    return pr;
  }

  static (bool, String?) _extractPageInfo(Map<String, Object?> connection) {
    final pageInfo = connection['pageInfo'] as Map<String, Object?>?;
    final hasNext = pageInfo?['hasNextPage'] as bool? ?? false;
    final endCursor = pageInfo?['endCursor'] as String?;
    return (hasNext, endCursor);
  }

  static void _parseReviewRequests(
    Map<String, Object?> connection,
    Set<String> openRequests,
  ) {
    final nodes = connection['nodes'] as List<Object?>? ?? const [];
    for (final node in nodes.whereType<Map<String, Object?>>()) {
      final reviewer = node['requestedReviewer'] as Map<String, Object?>?;
      final login = (reviewer?['login'] as String?)?.trim().toLowerCase();
      if (login != null && login.isNotEmpty) {
        openRequests.add(login);
      }
    }
  }

  static void _parseReviews(
    Map<String, Object?> connection,
    List<WantLgtmReviewRecord> reviews,
  ) {
    final nodes = connection['nodes'] as List<Object?>? ?? const [];
    for (final node in nodes.whereType<Map<String, Object?>>()) {
      final author = node['author'] as Map<String, Object?>?;
      final login = (author?['login'] as String?)?.trim().toLowerCase();
      final stateStr = node['state'] as String?;
      final submittedAtStr = node['submittedAt'] as String?;
      final state = switch (stateStr) {
        'APPROVED' => WantLgtmReviewState.approved,
        'CHANGES_REQUESTED' => WantLgtmReviewState.changesRequested,
        'DISMISSED' => WantLgtmReviewState.dismissed,
        _ => null,
      };
      if (login != null && state != null) {
        final submittedAt = submittedAtStr != null
            ? DateTime.tryParse(submittedAtStr)?.toUtc()
            : null;
        reviews.add(
          WantLgtmReviewRecord(
            authorLogin: login,
            state: state,
            submittedAt: submittedAt,
          ),
        );
      }
    }
  }

  static void _parseTimeline(
    Map<String, Object?> connection,
    List<WantLgtmTimelineEvent> events,
  ) {
    final nodes = connection['nodes'] as List<Object?>? ?? const [];
    for (final node in nodes.whereType<Map<String, Object?>>()) {
      final type = node['__typename'] as String?;
      final action = switch (type) {
        'ReviewRequestedEvent' => TimelineReviewAction.requested,
        'ReviewRequestRemovedEvent' => TimelineReviewAction.removed,
        _ => null,
      };
      final reviewer = node['requestedReviewer'] as Map<String, Object?>?;
      final login = (reviewer?['login'] as String?)?.trim().toLowerCase();
      final createdAtStr = node['createdAt'] as String?;
      if (action != null && login != null && login.isNotEmpty) {
        final createdAt = createdAtStr != null
            ? DateTime.tryParse(createdAtStr)?.toUtc()
            : null;
        events.add(
          WantLgtmTimelineEvent(
            reviewerLogin: login,
            action: action,
            createdAt: createdAt,
          ),
        );
      }
    }
  }
}

const String _kInitialQuery = r'''
query WantLgtmInitialSnapshot($owner: String!, $name: String!, $number: Int!) {
  repository(owner: $owner, name: $name) {
    pullRequest(number: $number) {
      state
      body
      headRefOid
      author {
        login
      }
      reviewRequests(first: 100) {
        pageInfo {
          hasNextPage
          endCursor
        }
        nodes {
          requestedReviewer {
            ... on User {
              login
            }
          }
        }
      }
      reviews(first: 100, states: [APPROVED, CHANGES_REQUESTED, DISMISSED]) {
        pageInfo {
          hasNextPage
          endCursor
        }
        nodes {
          author {
            login
          }
          state
          submittedAt
        }
      }
      timelineItems(first: 100, itemTypes: [REVIEW_REQUESTED_EVENT, REVIEW_REQUEST_REMOVED_EVENT]) {
        pageInfo {
          hasNextPage
          endCursor
        }
        nodes {
          __typename
          ... on ReviewRequestedEvent {
            createdAt
            requestedReviewer {
              ... on User {
                login
              }
            }
          }
          ... on ReviewRequestRemovedEvent {
            createdAt
            requestedReviewer {
              ... on User {
                login
              }
            }
          }
        }
      }
    }
  }
}
''';

const String _kReviewRequestsPageQuery = r'''
query WantLgtmReviewRequestsPage($owner: String!, $name: String!, $number: Int!, $cursor: String!) {
  repository(owner: $owner, name: $name) {
    pullRequest(number: $number) {
      reviewRequests(first: 100, after: $cursor) {
        pageInfo {
          hasNextPage
          endCursor
        }
        nodes {
          requestedReviewer {
            ... on User {
              login
            }
          }
        }
      }
    }
  }
}
''';

const String _kReviewsPageQuery = r'''
query WantLgtmReviewsPage($owner: String!, $name: String!, $number: Int!, $cursor: String!) {
  repository(owner: $owner, name: $name) {
    pullRequest(number: $number) {
      reviews(first: 100, after: $cursor, states: [APPROVED, CHANGES_REQUESTED, DISMISSED]) {
        pageInfo {
          hasNextPage
          endCursor
        }
        nodes {
          author {
            login
          }
          state
          submittedAt
        }
      }
    }
  }
}
''';

const String _kTimelinePageQuery = r'''
query WantLgtmTimelinePage($owner: String!, $name: String!, $number: Int!, $cursor: String!) {
  repository(owner: $owner, name: $name) {
    pullRequest(number: $number) {
      timelineItems(first: 100, after: $cursor, itemTypes: [REVIEW_REQUESTED_EVENT, REVIEW_REQUEST_REMOVED_EVENT]) {
        pageInfo {
          hasNextPage
          endCursor
        }
        nodes {
          __typename
          ... on ReviewRequestedEvent {
            createdAt
            requestedReviewer {
              ... on User {
                login
              }
            }
          }
          ... on ReviewRequestRemovedEvent {
            createdAt
            requestedReviewer {
              ... on User {
                login
              }
            }
          }
        }
      }
    }
  }
}
''';
