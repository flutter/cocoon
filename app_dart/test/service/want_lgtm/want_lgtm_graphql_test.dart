// Copyright 2026 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_integration_test/testing.dart';
import 'package:cocoon_server_test/test_logging.dart';
import 'package:cocoon_service/src/service/want_lgtm/want_lgtm_graphql.dart';
import 'package:cocoon_service/src/service/want_lgtm/want_lgtm_models.dart';
import 'package:github/github.dart';
import 'package:graphql/client.dart';
import 'package:test/test.dart';

void main() {
  useTestLoggerPerTest();

  late FakeGraphQLClient fakeClient;
  late WantLgtmGraphQLClient client;

  setUp(() {
    fakeClient = FakeGraphQLClient();
    client = WantLgtmGraphQLClient(fakeClient);
  });

  Map<String, Object?> createPrNode({
    String state = 'OPEN',
    String body = 'WANT_LGTM=alice',
    String headRefOid = 'abc123',
    String? authorLogin = 'author1',
    List<Map<String, Object?>> reviewRequests = const [],
    bool reviewRequestsHasNext = false,
    String? reviewRequestsCursor,
    List<Map<String, Object?>> reviews = const [],
    bool reviewsHasNext = false,
    String? reviewsCursor,
    List<Map<String, Object?>> timelineItems = const [],
    bool timelineHasNext = false,
    String? timelineCursor,
  }) {
    return {
      'repository': {
        'pullRequest': {
          'state': state,
          'body': body,
          'headRefOid': headRefOid,
          'author': authorLogin != null ? {'login': authorLogin} : null,
          'reviewRequests': {
            'pageInfo': {
              'hasNextPage': reviewRequestsHasNext,
              'endCursor': reviewRequestsCursor,
            },
            'nodes': reviewRequests,
          },
          'reviews': {
            'pageInfo': {
              'hasNextPage': reviewsHasNext,
              'endCursor': reviewsCursor,
            },
            'nodes': reviews,
          },
          'timelineItems': {
            'pageInfo': {
              'hasNextPage': timelineHasNext,
              'endCursor': timelineCursor,
            },
            'nodes': timelineItems,
          },
        },
      },
    };
  }

  test(
    'successfully fetches and parses complete PR review snapshot in single query',
    () async {
      final slug = RepositorySlug('flutter', 'flutter');
      const prNumber = 42;

      fakeClient.queryResultForOptions = (QueryOptions options) {
        return createFakeQueryResult(
          data: createPrNode(
            state: 'OPEN',
            body: 'Fixes bug\\nWANT_LGTM=alice,bob',
            headRefOid: 'def456',
            authorLogin: 'prAuthor',
            reviewRequests: [
              {
                'requestedReviewer': {'login': 'alice'},
              },
              {
                'requestedReviewer': {'login': 'bob'},
              },
              {
                'requestedReviewer': {
                  '__typename': 'Team',
                  'name': 'engine-team',
                },
              },
            ],
            reviews: [
              {
                'author': {'login': 'alice'},
                'state': 'APPROVED',
                'submittedAt': '2026-11-06T10:00:00Z',
              },
              {
                'author': {'login': 'carol'},
                'state': 'CHANGES_REQUESTED',
                'submittedAt': '2026-11-06T10:30:00Z',
              },
              {
                'author': {'login': 'dave'},
                'state': 'DISMISSED',
                'submittedAt': '2026-11-06T11:00:00Z',
              },
              {
                'author': {'login': 'eve'},
                'state': 'COMMENTED',
                'submittedAt': '2026-11-06T11:15:00Z',
              },
            ],
            timelineItems: [
              {
                '__typename': 'ReviewRequestedEvent',
                'createdAt': '2026-11-06T09:00:00Z',
                'requestedReviewer': {'login': 'alice'},
              },
              {
                '__typename': 'ReviewRequestRemovedEvent',
                'createdAt': '2026-11-06T09:30:00Z',
                'requestedReviewer': {'login': 'bob'},
              },
            ],
          ),
        );
      };

      final snapshot = await client.fetchSnapshot(slug, prNumber);

      expect(snapshot.prState, 'OPEN');
      expect(snapshot.body, 'Fixes bug\\nWANT_LGTM=alice,bob');
      expect(snapshot.headRefOid, 'def456');
      expect(snapshot.authorLogin, 'prauthor');
      expect(snapshot.queryCount, 1);

      expect(snapshot.openReviewRequestLogins, containsAll(['alice', 'bob']));
      expect(snapshot.openReviewRequestLogins.length, 2);

      expect(snapshot.reviews.length, 3); // COMMENTED is excluded
      expect(snapshot.reviews[0].authorLogin, 'alice');
      expect(snapshot.reviews[0].state, WantLgtmReviewState.approved);
      expect(
        snapshot.reviews[0].submittedAt,
        DateTime.utc(2026, 11, 6, 10, 0, 0),
      );
      expect(snapshot.reviews[1].authorLogin, 'carol');
      expect(snapshot.reviews[1].state, WantLgtmReviewState.changesRequested);
      expect(snapshot.reviews[2].authorLogin, 'dave');
      expect(snapshot.reviews[2].state, WantLgtmReviewState.dismissed);

      expect(snapshot.timelineEvents.length, 2);
      expect(snapshot.timelineEvents[0].reviewerLogin, 'alice');
      expect(snapshot.timelineEvents[0].action, TimelineReviewAction.requested);
      expect(snapshot.timelineEvents[1].reviewerLogin, 'bob');
      expect(snapshot.timelineEvents[1].action, TimelineReviewAction.removed);
    },
  );

  test(
    'paginates reviewRequests, reviews, and timelineItems when hasNextPage is true',
    () async {
      final slug = RepositorySlug('flutter', 'engine');
      const prNumber = 100;

      fakeClient.queryResultForOptions = (QueryOptions options) {
        final cursor = options.variables['cursor'] as String?;
        if (cursor == null) {
          return createFakeQueryResult(
            data: createPrNode(
              reviewRequests: [
                {
                  'requestedReviewer': {'login': 'user1'},
                },
              ],
              reviewRequestsHasNext: true,
              reviewRequestsCursor: 'cursor_rr_1',
              reviews: [
                {
                  'author': {'login': 'user1'},
                  'state': 'APPROVED',
                  'submittedAt': '2026-11-06T10:00:00Z',
                },
              ],
              reviewsHasNext: true,
              reviewsCursor: 'cursor_rev_1',
              timelineItems: [
                {
                  '__typename': 'ReviewRequestedEvent',
                  'createdAt': '2026-11-06T09:00:00Z',
                  'requestedReviewer': {'login': 'user1'},
                },
              ],
              timelineHasNext: true,
              timelineCursor: 'cursor_time_1',
            ),
          );
        } else if (cursor == 'cursor_rr_1') {
          return createFakeQueryResult(
            data: createPrNode(
              reviewRequests: [
                {
                  'requestedReviewer': {'login': 'user2'},
                },
              ],
              reviewRequestsHasNext: false,
            ),
          );
        } else if (cursor == 'cursor_rev_1') {
          return createFakeQueryResult(
            data: createPrNode(
              reviews: [
                {
                  'author': {'login': 'user2'},
                  'state': 'APPROVED',
                  'submittedAt': '2026-11-06T11:00:00Z',
                },
              ],
              reviewsHasNext: false,
            ),
          );
        } else if (cursor == 'cursor_time_1') {
          return createFakeQueryResult(
            data: createPrNode(
              timelineItems: [
                {
                  '__typename': 'ReviewRequestedEvent',
                  'createdAt': '2026-11-06T09:30:00Z',
                  'requestedReviewer': {'login': 'user2'},
                },
              ],
              timelineHasNext: false,
            ),
          );
        }
        return createFakeQueryResult(data: createPrNode());
      };

      final snapshot = await client.fetchSnapshot(slug, prNumber);

      expect(snapshot.queryCount, 4); // 1 initial + 3 paginated
      expect(snapshot.openReviewRequestLogins, containsAll(['user1', 'user2']));
      expect(snapshot.reviews.length, 2);
      expect(
        snapshot.reviews.map((r) => r.authorLogin),
        containsAll(['user1', 'user2']),
      );
      expect(snapshot.timelineEvents.length, 2);
      expect(
        snapshot.timelineEvents.map((t) => t.reviewerLogin),
        containsAll(['user1', 'user2']),
      );
    },
  );

  test(
    'throws WantLgtmGraphQLException when pull request is not found',
    () async {
      final slug = RepositorySlug('flutter', 'flutter');
      fakeClient.queryResultForOptions = (QueryOptions options) {
        return createFakeQueryResult(
          data: {
            'repository': {'pullRequest': null},
          },
        );
      };

      expect(
        () => client.fetchSnapshot(slug, 999),
        throwsA(isA<WantLgtmGraphQLException>()),
      );
    },
  );

  test(
    'throws WantLgtmGraphQLException when GraphQL result has exception',
    () async {
      final slug = RepositorySlug('flutter', 'flutter');
      fakeClient.queryResultForOptions = (QueryOptions options) {
        return createFakeQueryResult(
          exception: OperationException(
            graphqlErrors: [const GraphQLError(message: 'Rate limit exceeded')],
          ),
        );
      };

      expect(
        () => client.fetchSnapshot(slug, 123),
        throwsA(isA<WantLgtmGraphQLException>()),
      );
    },
  );

  test('handles null author and null timestamps cleanly', () async {
    final slug = RepositorySlug('flutter', 'flutter');
    fakeClient.queryResultForOptions = (QueryOptions options) {
      return createFakeQueryResult(
        data: createPrNode(
          authorLogin: null,
          reviews: [
            {
              'author': {'login': 'ghost'},
              'state': 'APPROVED',
              'submittedAt': null,
            },
          ],
          timelineItems: [
            {
              '__typename': 'ReviewRequestedEvent',
              'createdAt': null,
              'requestedReviewer': {'login': 'ghost'},
            },
          ],
        ),
      );
    };

    final snapshot = await client.fetchSnapshot(slug, 1);
    expect(snapshot.authorLogin, '');
    expect(snapshot.reviews.first.submittedAt, isNull);
    expect(snapshot.timelineEvents.first.createdAt, isNull);
  });
}
