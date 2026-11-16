// Copyright 2026 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:github/github.dart';
import 'package:gql/ast.dart';
import 'package:gql/language.dart' as lang;
import 'package:graphql/client.dart' hide JsonSerializable;
import 'package:json_annotation/json_annotation.dart';

import 'want_lgtm_models.dart';

part 'want_lgtm_graphql.g.dart';

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

  static final DocumentNode _initialQuery = lang.parseString(_kInitialQuery);
  static final DocumentNode _reviewRequestsPageQuery = lang.parseString(
    _kReviewRequestsPageQuery,
  );
  static final DocumentNode _reviewsPageQuery = lang.parseString(
    _kReviewsPageQuery,
  );
  static final DocumentNode _timelinePageQuery = lang.parseString(
    _kTimelinePageQuery,
  );

  final GraphQLClient _client;

  /// Fetches a [WantLgtmGraphQLSnapshot] for the given pull request.
  Future<WantLgtmGraphQLSnapshot> fetchSnapshot(
    RepositorySlug slug,
    int prNumber,
  ) async {
    var queryCount = 1;
    final pr = await _fetchPr(_initialQuery, slug, prNumber);
    final openRequests = <String>{};
    final reviews = <WantLgtmReviewRecord>[];
    final timelineEvents = <WantLgtmTimelineEvent>[];

    queryCount += await _paginateConnection<_GraphQLReviewRequestNode>(
      slug: slug,
      prNumber: prNumber,
      query: _reviewRequestsPageQuery,
      initialConn: pr.reviewRequests,
      selectConn: (nextPr) => nextPr.reviewRequests,
      onNodes: (nodes) => _collectReviewRequests(nodes, openRequests),
    );

    queryCount += await _paginateConnection<_GraphQLReviewNode>(
      slug: slug,
      prNumber: prNumber,
      query: _reviewsPageQuery,
      initialConn: pr.reviews,
      selectConn: (nextPr) => nextPr.reviews,
      onNodes: (nodes) => _collectReviews(nodes, reviews),
    );

    queryCount += await _paginateConnection<_GraphQLTimelineNode>(
      slug: slug,
      prNumber: prNumber,
      query: _timelinePageQuery,
      initialConn: pr.timelineItems,
      selectConn: (nextPr) => nextPr.timelineItems,
      onNodes: (nodes) => _collectTimeline(nodes, timelineEvents),
    );

    return WantLgtmGraphQLSnapshot(
      prState: (pr.state ?? 'OPEN').toUpperCase(),
      body: pr.body ?? '',
      headRefOid: pr.headRefOid ?? '',
      authorLogin: pr.author?.normalizedLogin ?? '',
      openReviewRequestLogins: openRequests,
      reviews: reviews,
      timelineEvents: timelineEvents,
      queryCount: queryCount,
    );
  }

  Future<int> _paginateConnection<T>({
    required RepositorySlug slug,
    required int prNumber,
    required DocumentNode query,
    required _GraphQLConnection<T>? initialConn,
    required _GraphQLConnection<T>? Function(_GraphQLPullRequest pr) selectConn,
    required void Function(List<T?> nodes) onNodes,
  }) async {
    if (initialConn == null) {
      return 0;
    }
    onNodes(initialConn.nodes);
    var count = 0;
    var pageInfo = initialConn.pageInfo;
    while ((pageInfo?.hasNextPage ?? false) && pageInfo?.endCursor != null) {
      final pr = await _fetchPr(
        query,
        slug,
        prNumber,
        cursor: pageInfo!.endCursor,
      );
      count++;
      final nextConn = selectConn(pr);
      if (nextConn == null) {
        break;
      }
      onNodes(nextConn.nodes);
      pageInfo = nextConn.pageInfo;
    }
    return count;
  }

  Future<_GraphQLPullRequest> _fetchPr(
    DocumentNode document,
    RepositorySlug slug,
    int prNumber, {
    String? cursor,
  }) async {
    final data = await _execute(document, <String, Object?>{
      'owner': slug.owner,
      'name': slug.name,
      'number': prNumber,
      'cursor': ?cursor,
    });
    final pr = _GraphQLResponse.fromJson(data).repository?.pullRequest;
    if (pr == null) {
      throw WantLgtmGraphQLException(
        'Pull request ${slug.fullName} #$prNumber not found',
      );
    }
    return pr;
  }

  Future<Map<String, Object?>> _execute(
    DocumentNode document,
    Map<String, Object?> variables,
  ) async {
    final result = await _client.query(
      QueryOptions(
        document: document,
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

  static void _collectReviewRequests(
    List<_GraphQLReviewRequestNode?> nodes,
    Set<String> openRequests,
  ) {
    for (final node in nodes) {
      final login = node?.requestedReviewer?.normalizedLogin;
      if (login != null) {
        openRequests.add(login);
      }
    }
  }

  static void _collectReviews(
    List<_GraphQLReviewNode?> nodes,
    List<WantLgtmReviewRecord> reviews,
  ) {
    for (final node in nodes) {
      final record = node?.toRecord();
      if (record != null) {
        reviews.add(record);
      }
    }
  }

  static void _collectTimeline(
    List<_GraphQLTimelineNode?> nodes,
    List<WantLgtmTimelineEvent> events,
  ) {
    for (final node in nodes) {
      final event = node?.toEvent();
      if (event != null) {
        events.add(event);
      }
    }
  }
}

@JsonSerializable(anyMap: true, createToJson: false)
final class _GraphQLResponse {
  const _GraphQLResponse({this.repository});

  factory _GraphQLResponse.fromJson(Map<String, Object?> json) =>
      _$GraphQLResponseFromJson(json);

  final _GraphQLRepository? repository;
}

@JsonSerializable(anyMap: true, createToJson: false)
final class _GraphQLRepository {
  const _GraphQLRepository({this.pullRequest});

  factory _GraphQLRepository.fromJson(Map<String, Object?> json) =>
      _$GraphQLRepositoryFromJson(json);

  final _GraphQLPullRequest? pullRequest;
}

@JsonSerializable(anyMap: true, createToJson: false)
final class _GraphQLPullRequest {
  const _GraphQLPullRequest({
    this.state,
    this.body,
    this.headRefOid,
    this.author,
    this.reviewRequests,
    this.reviews,
    this.timelineItems,
  });

  factory _GraphQLPullRequest.fromJson(Map<String, Object?> json) =>
      _$GraphQLPullRequestFromJson(json);

  final String? state;
  final String? body;
  final String? headRefOid;
  final _GraphQLActor? author;
  final _GraphQLConnection<_GraphQLReviewRequestNode>? reviewRequests;
  final _GraphQLConnection<_GraphQLReviewNode>? reviews;
  final _GraphQLConnection<_GraphQLTimelineNode>? timelineItems;
}

@JsonSerializable(
  anyMap: true,
  createToJson: false,
  genericArgumentFactories: true,
)
final class _GraphQLConnection<T> {
  const _GraphQLConnection({this.pageInfo, this.nodes = const []});

  factory _GraphQLConnection.fromJson(
    Map<String, Object?> json,
    T Function(Object? json) fromJsonT,
  ) => _$GraphQLConnectionFromJson(json, fromJsonT);

  final _GraphQLPageInfo? pageInfo;
  final List<T?> nodes;
}

@JsonSerializable(anyMap: true, createToJson: false)
final class _GraphQLPageInfo {
  const _GraphQLPageInfo({this.hasNextPage = false, this.endCursor});

  factory _GraphQLPageInfo.fromJson(Map<String, Object?> json) =>
      _$GraphQLPageInfoFromJson(json);

  final bool hasNextPage;
  final String? endCursor;
}

@JsonSerializable(anyMap: true, createToJson: false)
final class _GraphQLActor {
  const _GraphQLActor({this.login});

  factory _GraphQLActor.fromJson(Map<String, Object?> json) =>
      _$GraphQLActorFromJson(json);

  final String? login;

  String? get normalizedLogin {
    final normalized = login?.trim().toLowerCase();
    return (normalized == null || normalized.isEmpty) ? null : normalized;
  }
}

@JsonSerializable(anyMap: true, createToJson: false)
final class _GraphQLReviewRequestNode {
  const _GraphQLReviewRequestNode({this.requestedReviewer});

  factory _GraphQLReviewRequestNode.fromJson(Map<String, Object?> json) =>
      _$GraphQLReviewRequestNodeFromJson(json);

  final _GraphQLActor? requestedReviewer;
}

@JsonSerializable(anyMap: true, createToJson: false)
final class _GraphQLReviewNode {
  const _GraphQLReviewNode({
    this.author,
    @JsonKey(fromJson: _parseReviewState) this.state,
    @JsonKey(fromJson: _tryParseUtcDateTime) this.submittedAt,
  });

  factory _GraphQLReviewNode.fromJson(Map<String, Object?> json) =>
      _$GraphQLReviewNodeFromJson(json);

  final _GraphQLActor? author;
  final WantLgtmReviewState? state;
  final DateTime? submittedAt;

  WantLgtmReviewRecord? toRecord() {
    final login = author?.normalizedLogin;
    final reviewState = state;
    if (login == null || reviewState == null) {
      return null;
    }
    return WantLgtmReviewRecord(
      authorLogin: login,
      state: reviewState,
      submittedAt: submittedAt,
    );
  }
}

@JsonSerializable(anyMap: true, createToJson: false)
final class _GraphQLTimelineNode {
  const _GraphQLTimelineNode({
    @JsonKey(name: '__typename', fromJson: _parseTimelineAction) this.action,
    @JsonKey(fromJson: _tryParseUtcDateTime) this.createdAt,
    this.requestedReviewer,
  });

  factory _GraphQLTimelineNode.fromJson(Map<String, Object?> json) =>
      _$GraphQLTimelineNodeFromJson(json);

  final TimelineReviewAction? action;
  final DateTime? createdAt;
  final _GraphQLActor? requestedReviewer;

  WantLgtmTimelineEvent? toEvent() {
    final timelineAction = action;
    final login = requestedReviewer?.normalizedLogin;
    if (timelineAction == null || login == null) {
      return null;
    }
    return WantLgtmTimelineEvent(
      reviewerLogin: login,
      action: timelineAction,
      createdAt: createdAt,
    );
  }
}

WantLgtmReviewState? _parseReviewState(Object? value) => switch (value) {
  'APPROVED' => WantLgtmReviewState.approved,
  'CHANGES_REQUESTED' => WantLgtmReviewState.changesRequested,
  'DISMISSED' => WantLgtmReviewState.dismissed,
  _ => null,
};

TimelineReviewAction? _parseTimelineAction(Object? value) => switch (value) {
  'ReviewRequestedEvent' => TimelineReviewAction.requested,
  'ReviewRequestRemovedEvent' => TimelineReviewAction.removed,
  _ => null,
};

DateTime? _tryParseUtcDateTime(Object? value) =>
    value is String ? DateTime.tryParse(value)?.toUtc() : null;

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
