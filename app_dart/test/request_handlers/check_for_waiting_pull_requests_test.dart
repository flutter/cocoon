// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_service/cocoon_service.dart';
import 'package:cocoon_service/src/request_handlers/check_for_waiting_pull_requests_queries.dart';

import 'package:graphql/client.dart';
import 'package:graphql/src/core/observable_query.dart';
import 'package:graphql/src/link/fetch_result.dart';
import 'package:graphql/src/link/operation.dart';
import 'package:test/test.dart';

import '../src/datastore/fake_cocoon_config.dart';
import '../src/request_handling/api_request_handler_tester.dart';
import '../src/request_handling/fake_authentication.dart';
import '../src/request_handling/fake_http.dart';
import '../src/request_handling/fake_logging.dart';

const String base64LabelId = 'base_64_label_id';

void main() {
  group('check for waiting pull requests', () {
    CheckForWaitingPullRequests handler;

    FakeHttpRequest request;
    FakeConfig config;
    FakeClientContext clientContext;
    FakeAuthenticationProvider auth;
    FakeLogging log;
    FakeGraphQLClient githubGraphQLClient;

    ApiRequestHandlerTester tester;

    final List<PullRequestHelper> flutterRepoPRs = <PullRequestHelper>[];
    final List<PullRequestHelper> engineRepoPRs = <PullRequestHelper>[];

    setUp(() {
      request = FakeHttpRequest();
      config = FakeConfig();
      clientContext = FakeClientContext();
      auth = FakeAuthenticationProvider(clientContext: clientContext);
      log = FakeLogging();
      githubGraphQLClient = FakeGraphQLClient();
      flutterRepoPRs.clear();
      engineRepoPRs.clear();
      PullRequestHelper._counter = 0;

      githubGraphQLClient._mutateResultForOptions = (MutationOptions options) => QueryResult();

      githubGraphQLClient._queryResultForOptions = (QueryOptions options) {
        expect(options.variables['sOwner'], 'flutter');
        expect(options.variables['sLabelName'], config.waitingForTreeToGoGreenLabelNameValue);

        final String repoName = options.variables['sName'];
        if (repoName == 'flutter') {
          return createQueryResult(flutterRepoPRs);
        } else if (repoName == 'engine') {
          return createQueryResult(engineRepoPRs);
        } else {
          fail('unexpected repo $repoName');
        }
      };

      tester = ApiRequestHandlerTester(request: request);
      config.waitingForTreeToGoGreenLabelNameValue = 'waiting for tree to go green';
      config.githubGraphQLClient = githubGraphQLClient;

      handler = CheckForWaitingPullRequests(
        config,
        auth,
        loggingProvider: () => log,
      );
    });

    void _verifyQueries() {
      githubGraphQLClient.verifyQueries(
        <QueryOptions>[
          QueryOptions(
            document: labeledPullRequestsWithReviewsQuery,
            fetchPolicy: FetchPolicy.noCache,
            variables: <String, dynamic>{
              'sOwner': 'flutter',
              'sName': 'flutter',
              'sLabelName': config.waitingForTreeToGoGreenLabelNameValue,
            },
          ),
          QueryOptions(
            document: labeledPullRequestsWithReviewsQuery,
            fetchPolicy: FetchPolicy.noCache,
            variables: <String, dynamic>{
              'sOwner': 'flutter',
              'sName': 'engine',
              'sLabelName': config.waitingForTreeToGoGreenLabelNameValue,
            },
          ),
        ],
      );
    }

    test('Merges first PR in list, all successful', () async {
      flutterRepoPRs.add(PullRequestHelper());
      flutterRepoPRs.add(PullRequestHelper()); // will be ignored.
      engineRepoPRs.add(PullRequestHelper());

      await tester.get(handler);

      _verifyQueries();

      githubGraphQLClient.verifyMutations(
        <MutationOptions>[
          MutationOptions(
            document: mergePullRequestMutation,
            variables: <String, dynamic>{
              'id': flutterRepoPRs.first.id,
              'oid': 'deadbeef',
            },
          ),
          MutationOptions(
            document: mergePullRequestMutation,
            variables: <String, dynamic>{
              'id': engineRepoPRs.first.id,
              'oid': 'deadbeef',
            },
          ),
        ],
      );
    });

    test('Remove labels', () async {
      final PullRequestHelper prOneBadReview = PullRequestHelper(
        reviewStates: <bool>[false],
      );
      final PullRequestHelper prOneGoodOneBadReview = PullRequestHelper(
        reviewStates: <bool>[true, false],
      );
      final PullRequestHelper prNoReviews = PullRequestHelper(
        reviewStates: <bool>[],
      );
      final PullRequestHelper prMergeConflict = PullRequestHelper(
        mergeable: false,
      );
      final PullRequestHelper prRed = PullRequestHelper(
        lastCommitSuccess: false,
      );
      final PullRequestHelper prEverythingWrong = PullRequestHelper(
        lastCommitSuccess: false,
        mergeable: false,
        reviewStates: <bool>[false],
      );

      flutterRepoPRs.add(prOneBadReview);
      flutterRepoPRs.add(prOneGoodOneBadReview);
      flutterRepoPRs.add(prNoReviews);
      flutterRepoPRs.add(prMergeConflict);
      flutterRepoPRs.add(prRed); // ignored.
      flutterRepoPRs.add(prEverythingWrong);

      await tester.get(handler);

      _verifyQueries();

      githubGraphQLClient.verifyMutations(
        <MutationOptions>[
          MutationOptions(
            document: removeLabelMutation,
            variables: <String, dynamic>{
              'id': prOneBadReview.id,
              'sBody':
                  '''This pull request is not suitable for automatic merging in its current state.

- Please get at least one approved review before re-applying this label. __Reviewers__: If you left a comment approving, please use the "approve" review action instead.
- This pull request has changes requested. Please resolve those before re-applying the label.
''',
              'labelId': base64LabelId,
            },
          ),
          MutationOptions(
            document: removeLabelMutation,
            variables: <String, dynamic>{
              'id': prOneGoodOneBadReview.id,
              'sBody':
                  '''This pull request is not suitable for automatic merging in its current state.

- This pull request has changes requested. Please resolve those before re-applying the label.
''',
              'labelId': base64LabelId,
            },
          ),
          MutationOptions(
            document: removeLabelMutation,
            variables: <String, dynamic>{
              'id': prNoReviews.id,
              'sBody':
                  '''This pull request is not suitable for automatic merging in its current state.

- Please get at least one approved review before re-applying this label. __Reviewers__: If you left a comment approving, please use the "approve" review action instead.
''',
              'labelId': base64LabelId,
            },
          ),
          MutationOptions(
            document: removeLabelMutation,
            variables: <String, dynamic>{
              'id': prMergeConflict.id,
              'sBody':
                  '''This pull request is not suitable for automatic merging in its current state.

- Please resolve merge conflicts before re-applying this label.
''',
              'labelId': base64LabelId,
            },
          ),
          MutationOptions(
            document: removeLabelMutation,
            variables: <String, dynamic>{
              'id': prEverythingWrong.id,
              'sBody':
                  '''This pull request is not suitable for automatic merging in its current state.

- Please resolve merge conflicts before re-applying this label.
- Please get at least one approved review before re-applying this label. __Reviewers__: If you left a comment approving, please use the "approve" review action instead.
- This pull request has changes requested. Please resolve those before re-applying the label.
''',
              'labelId': base64LabelId,
            },
          ),
        ],
      );
    });
  });
}

class FakeGraphQLClient implements GraphQLClient {
  QueryResult Function(MutationOptions) _mutateResultForOptions;
  QueryResult Function(QueryOptions) _queryResultForOptions;

  @override
  QueryManager queryManager;

  @override
  Cache get cache => throw UnimplementedError();

  @override
  Link get link => throw UnimplementedError();

  final List<QueryOptions> queries = <QueryOptions>[];
  final List<MutationOptions> mutations = <MutationOptions>[];

  @override
  Future<QueryResult> mutate(MutationOptions options) async {
    mutations.add(options);
    return _mutateResultForOptions(options);
  }

  @override
  Future<QueryResult> query(QueryOptions options) async {
    queries.add(options);
    return _queryResultForOptions(options);
  }

  @override
  Stream<FetchResult> subscribe(Operation operation) {
    throw UnimplementedError();
  }

  @override
  ObservableQuery watchQuery(WatchQueryOptions options) {
    throw UnimplementedError();
  }

  void verifyQueries(List<QueryOptions> expectedQueries) {
    expect(queries.length, expectedQueries.length);
    for (int i = 0; i < queries.length; i++) {
      expect(queries[i].toKey(), expectedQueries[i].toKey());
      expect(queries[i].fetchPolicy, expectedQueries[i].fetchPolicy);
    }
  }

  void verifyMutations(List<MutationOptions> expectedMutations) {
    expect(mutations.length, expectedMutations.length);
    for (int i = 0; i < mutations.length; i++) {
      expect(mutations[i].toKey(), expectedMutations[i].toKey());
      expect(mutations[i].fetchPolicy, expectedMutations[i].fetchPolicy);
    }
  }
}

class PullRequestHelper {
  PullRequestHelper({
    this.mergeable = true,
    this.reviewStates = const <bool>[true],
    this.lastCommitHash = 'deadbeef',
    this.lastCommitSuccess = true,
  }) : _count = _counter++;

  static int _counter = 0;

  final int _count;
  String get id => _count.toString();

  final bool mergeable;
  final List<bool> reviewStates;
  final String lastCommitHash;
  final bool lastCommitSuccess;

  Map<String, dynamic> toEntry() {
    return <String, dynamic>{
      'id': id,
      'number': id.hashCode,
      'mergeable': mergeable ? 'MERGEABLE' : 'CONFLICT',
      'reviews': <String, dynamic>{
        'nodes': reviewStates.map<Map<String, dynamic>>(
          (bool approved) {
            return <String, dynamic>{
              'state': approved ? 'APPROVED' : 'CHANGES_REQUESTED',
            };
          },
        ).toList(),
      },
      'commits': <String, dynamic>{
        'nodes': <dynamic>[
          <String, dynamic>{
            'commit': <String, dynamic>{
              'oid': lastCommitHash,
              'status': <String, dynamic>{
                'state': lastCommitSuccess ? 'SUCCESS' : 'FAILURE',
              },
            },
          },
        ],
      },
    };
  }
}

QueryResult createQueryResult(List<PullRequestHelper> pullRequests) {
  assert(pullRequests != null);

  return QueryResult(
    data: <String, dynamic>{
      'repository': <String, dynamic>{
        'labels': <String, dynamic>{
          'nodes': <dynamic>[
            <String, dynamic>{
              'id': base64LabelId,
              'pullRequests': <String, dynamic>{
                'nodes': pullRequests.map<Map<String, dynamic>>(
                  (PullRequestHelper pullRequest) => pullRequest.toEntry(),
                ),
              },
            },
          ],
        },
      },
    },
  );
}
