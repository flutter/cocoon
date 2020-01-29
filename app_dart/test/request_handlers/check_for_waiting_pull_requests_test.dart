// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_service/cocoon_service.dart';
import 'package:cocoon_service/src/request_handlers/check_for_waiting_pull_requests_queries.dart';

import 'package:graphql/client.dart';
import 'package:graphql/src/core/observable_query.dart';
import 'package:graphql/src/link/fetch_result.dart';
import 'package:graphql/src/link/operation.dart';
import 'package:meta/meta.dart';
import 'package:test/test.dart';

import '../src/datastore/fake_cocoon_config.dart';
import '../src/request_handling/api_request_handler_tester.dart';
import '../src/request_handling/fake_authentication.dart';
import '../src/request_handling/fake_http.dart';
import '../src/request_handling/fake_logging.dart';

const String base64LabelId = 'base_64_label_id';
const String oid = 'deadbeef';

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
      config = FakeConfig(rollerAccountsValue: <String>{});
      clientContext = FakeClientContext();
      auth = FakeAuthenticationProvider(clientContext: clientContext);
      log = FakeLogging();
      githubGraphQLClient = FakeGraphQLClient();
      flutterRepoPRs.clear();
      engineRepoPRs.clear();
      PullRequestHelper._counter = 0;

      githubGraphQLClient._mutateResultForOptions =
          (MutationOptions options) => QueryResult();

      githubGraphQLClient._queryResultForOptions = (QueryOptions options) {
        expect(options.variables['sOwner'], 'flutter');
        expect(options.variables['sLabelName'],
            config.waitingForTreeToGoGreenLabelNameValue);

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
      config.waitingForTreeToGoGreenLabelNameValue =
          'waiting for tree to go green';
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

    test('Errors can be logged', () async {
      flutterRepoPRs.add(PullRequestHelper());
      final List<GraphQLError> errors = <GraphQLError>[
        GraphQLError(raw: <String, String>{}, message: 'message'),
      ];
      githubGraphQLClient._mutateResultForOptions =
          (_) => QueryResult(errors: errors);

      await tester.get(handler);
      expect(log.records.length, errors.length);
      for (int i = 0; i < errors.length; i++) {
        expect(log.records[i].message, errors[i].toString());
      }
    });

    test('Merges unapproved PR from autoroller', () async {
      config.rollerAccountsValue = <String>{'engine-roller', 'skia-roller'};
      flutterRepoPRs.add(PullRequestHelper(
          author: 'engine-roller', reviews: const <PullRequestReviewHelper>[]));
      engineRepoPRs.add(PullRequestHelper(
          author: 'skia-roller', reviews: const <PullRequestReviewHelper>[]));

      await tester.get(handler);

      _verifyQueries();

      githubGraphQLClient.verifyMutations(
        <MutationOptions>[
          MutationOptions(
            document: mergePullRequestMutation,
            variables: <String, dynamic>{
              'id': flutterRepoPRs.first.id,
              'oid': oid,
            },
          ),
          MutationOptions(
            document: mergePullRequestMutation,
            variables: <String, dynamic>{
              'id': engineRepoPRs.first.id,
              'oid': oid,
            },
          ),
        ],
      );
    });

    test('Does not merge PR with in progress tests', () async {
      flutterRepoPRs.add(PullRequestHelper(
        lastCommitStatuses: const <StatusHelper>[
          StatusHelper('Linux Host', 'PENDING')
        ],
      ));

      await tester.get(handler);

      _verifyQueries();

      githubGraphQLClient.verifyMutations(<MutationOptions>[]);
    });

    test('Does not merge unapproved PR from a hacker', () async {
      config.rollerAccountsValue = <String>{'engine-roller', 'skia-roller'};
      flutterRepoPRs.add(PullRequestHelper(
          author: 'engine-roller-hacker',
          reviews: const <PullRequestReviewHelper>[]));
      engineRepoPRs.add(PullRequestHelper(
          author: 'skia-roller-hacker',
          reviews: const <PullRequestReviewHelper>[]));

      await tester.get(handler);

      _verifyQueries();

      githubGraphQLClient.verifyMutations(
        <MutationOptions>[
          MutationOptions(
            document: removeLabelMutation,
            variables: <String, dynamic>{
              'id': flutterRepoPRs.first.id,
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
              'id': engineRepoPRs.first.id,
              'sBody':
                  '''This pull request is not suitable for automatic merging in its current state.

- Please get at least one approved review before re-applying this label. __Reviewers__: If you left a comment approving, please use the "approve" review action instead.
''',
              'labelId': base64LabelId,
            },
          ),
        ],
      );
    });

    test('Merges first 2 PRs in list, all successful', () async {
      flutterRepoPRs.add(PullRequestHelper());
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
              'id': flutterRepoPRs[0].id,
              'oid': oid,
            },
          ),
          MutationOptions(
            document: mergePullRequestMutation,
            variables: <String, dynamic>{
              'id': flutterRepoPRs[1].id,
              'oid': oid,
            },
          ),
          MutationOptions(
            document: mergePullRequestMutation,
            variables: <String, dynamic>{
              'id': engineRepoPRs.first.id,
              'oid': oid,
            },
          ),
        ],
      );
    });

    test('Merges 1st and 3rd PR, 2nd failed', () async {
      flutterRepoPRs.add(PullRequestHelper());
      flutterRepoPRs.add(PullRequestHelper(
          lastCommitStatuses: const <StatusHelper>[
            StatusHelper.cirrusFailure
          ])); // not merged
      flutterRepoPRs.add(PullRequestHelper());
      engineRepoPRs.add(PullRequestHelper());

      await tester.get(handler);

      _verifyQueries();

      githubGraphQLClient.verifyMutations(
        <MutationOptions>[
          MutationOptions(
            document: mergePullRequestMutation,
            variables: <String, dynamic>{
              'id': flutterRepoPRs[0].id,
              'oid': oid,
            },
          ),
          MutationOptions(
            document: removeLabelMutation,
            variables: <String, dynamic>{
              'id': flutterRepoPRs[1].id,
              'labelId': base64LabelId,
              'sBody': '''
This pull request is not suitable for automatic merging in its current state.

- The status or check suite Cirrus CI has failed. Please fix the issues identified (or deflake) before re-applying this label.
''',
            },
          ),
          MutationOptions(
            document: mergePullRequestMutation,
            variables: <String, dynamic>{
              'id': flutterRepoPRs[2].id,
              'oid': oid,
            },
          ),
          MutationOptions(
            document: mergePullRequestMutation,
            variables: <String, dynamic>{
              'id': engineRepoPRs.first.id,
              'oid': oid,
            },
          ),
        ],
      );
    });

    test('Ignores PRs that are too new', () async {
      flutterRepoPRs.add(PullRequestHelper(
          dateTime:
              DateTime.now().add(const Duration(minutes: -50)))); // too new
      flutterRepoPRs.add(PullRequestHelper(
          dateTime: DateTime.now().add(const Duration(minutes: -70)))); // ok
      engineRepoPRs
          .add(PullRequestHelper()); // default is two hours for this ctor.

      await tester.get(handler);

      _verifyQueries();

      githubGraphQLClient.verifyMutations(
        <MutationOptions>[
          MutationOptions(
            document: mergePullRequestMutation,
            variables: <String, dynamic>{
              'id': flutterRepoPRs.last.id,
              'oid': oid,
            },
          ),
          MutationOptions(
            document: mergePullRequestMutation,
            variables: <String, dynamic>{
              'id': engineRepoPRs.first.id,
              'oid': oid,
            },
          ),
        ],
      );
    });

    test('Unlabels red PRs', () async {
      final PullRequestHelper prRed = PullRequestHelper(
        lastCommitStatuses: const <StatusHelper>[
          StatusHelper.flutterBuildSuccess,
          StatusHelper.otherStatusFailure,
        ],
        lastCommitCheckRuns: const <StatusHelper>[
          StatusHelper.cirrusFailure,
        ],
      );
      final PullRequestHelper prRedButChecksOk = PullRequestHelper(
        lastCommitStatuses: const <StatusHelper>[
          StatusHelper.flutterBuildFailure,
          StatusHelper.otherStatusFailure,
        ],
        lastCommitCheckRuns: const <StatusHelper>[
          StatusHelper.cirrusSuccess,
        ],
      );
      final PullRequestHelper prRedButStatusOk = PullRequestHelper(
        lastCommitStatuses: const <StatusHelper>[
          StatusHelper.flutterBuildSuccess,
        ],
        lastCommitCheckRuns: const <StatusHelper>[
          StatusHelper.cirrusFailure,
        ],
      );

      flutterRepoPRs.add(prRed);
      flutterRepoPRs.add(prRedButChecksOk);
      flutterRepoPRs.add(prRedButStatusOk);

      await tester.get(handler);
      _verifyQueries();
      githubGraphQLClient.verifyMutations(<MutationOptions>[
        MutationOptions(
          document: removeLabelMutation,
          variables: <String, dynamic>{
            'id': prRed.id,
            'sBody':
                '''This pull request is not suitable for automatic merging in its current state.

- The status or check suite other status has failed. Please fix the issues identified (or deflake) before re-applying this label.
- The status or check suite Cirrus CI has failed. Please fix the issues identified (or deflake) before re-applying this label.
''',
            'labelId': base64LabelId,
          },
        ),
        MutationOptions(
          document: removeLabelMutation,
          variables: <String, dynamic>{
            'id': prRedButChecksOk.id,
            'sBody':
                '''This pull request is not suitable for automatic merging in its current state.

- The status or check suite other status has failed. Please fix the issues identified (or deflake) before re-applying this label.
''',
            'labelId': base64LabelId,
          },
        ),
        MutationOptions(
          document: removeLabelMutation,
          variables: <String, dynamic>{
            'id': prRedButStatusOk.id,
            'sBody':
                '''This pull request is not suitable for automatic merging in its current state.

- The status or check suite Cirrus CI has failed. Please fix the issues identified (or deflake) before re-applying this label.
''',
            'labelId': base64LabelId,
          },
        ),
      ]);
    });

    test('Allows member to change review', () async {
      final PullRequestHelper prChangedReview = PullRequestHelper(
        reviews: const <PullRequestReviewHelper>[
          changePleaseChange,
          changePleaseApprove,
        ],
      );

      flutterRepoPRs.add(prChangedReview);
      await tester.get(handler);

      _verifyQueries();

      githubGraphQLClient.verifyMutations(
        <MutationOptions>[
          MutationOptions(
              document: mergePullRequestMutation,
              variables: <String, dynamic>{
                'id': prChangedReview.id,
                'oid': oid,
              }),
        ],
      );
    });

    test('Ignores non-member/owner reviews', () async {
      final PullRequestHelper prNonMemberApprove = PullRequestHelper(
        reviews: const <PullRequestReviewHelper>[
          nonMemberApprove,
        ],
      );
      final PullRequestHelper prNonMemberChangeRequest = PullRequestHelper(
        reviews: const <PullRequestReviewHelper>[
          nonMemberChangeRequest,
        ],
      );
      final PullRequestHelper prNonMemberChangeRequestWithMemberApprove =
          PullRequestHelper(
        reviews: const <PullRequestReviewHelper>[
          ownerApprove,
          nonMemberChangeRequest,
        ],
      );

      // Ignored approval from non-member
      flutterRepoPRs.add(prNonMemberApprove);
      // Ignored change reuqest from non-member (but still no approval from member)
      flutterRepoPRs.add(prNonMemberChangeRequest);
      // Ignored change request from non-member with approval from owner/member.
      flutterRepoPRs.add(prNonMemberChangeRequestWithMemberApprove);

      await tester.get(handler);

      _verifyQueries();

      githubGraphQLClient.verifyMutations(
        <MutationOptions>[
          MutationOptions(
            document: removeLabelMutation,
            variables: <String, dynamic>{
              'id': prNonMemberApprove.id,
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
              'id': prNonMemberChangeRequest.id,
              'sBody':
                  '''This pull request is not suitable for automatic merging in its current state.

- Please get at least one approved review before re-applying this label. __Reviewers__: If you left a comment approving, please use the "approve" review action instead.
''',
              'labelId': base64LabelId,
            },
          ),
          MutationOptions(
              document: mergePullRequestMutation,
              variables: <String, dynamic>{
                'id': prNonMemberChangeRequestWithMemberApprove.id,
                'oid': oid,
              }),
        ],
      );
    });

    test('Remove labels', () async {
      final PullRequestHelper prOneBadReview = PullRequestHelper(
        reviews: const <PullRequestReviewHelper>[
          changePleaseChange,
        ],
      );
      final PullRequestHelper prOneGoodOneBadReview = PullRequestHelper(
        reviews: const <PullRequestReviewHelper>[
          memberApprove,
          changePleaseChange,
        ],
      );
      final PullRequestHelper prNoReviews = PullRequestHelper(
        reviews: const <PullRequestReviewHelper>[],
      );
      final PullRequestHelper prEverythingWrong = PullRequestHelper(
        lastCommitStatuses: const <StatusHelper>[
          StatusHelper.flutterBuildFailure
        ],
        lastCommitCheckRuns: const <StatusHelper>[StatusHelper.cirrusFailure],
        reviews: const <PullRequestReviewHelper>[changePleaseChange],
      );

      flutterRepoPRs.add(prOneBadReview);
      flutterRepoPRs.add(prOneGoodOneBadReview);
      flutterRepoPRs.add(prNoReviews);
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

- This pull request has changes requested by @change_please. Please resolve those before re-applying the label.
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

- This pull request has changes requested by @change_please. Please resolve those before re-applying the label.
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
              'id': prEverythingWrong.id,
              'sBody':
                  '''This pull request is not suitable for automatic merging in its current state.

- This pull request has changes requested by @change_please. Please resolve those before re-applying the label.
- The status or check suite Cirrus CI has failed. Please fix the issues identified (or deflake) before re-applying this label.
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

  void verify(List<BaseOptions> expected, List<BaseOptions> actual) {
    expect(actual.length, expected.length);
    for (int i = 0; i < actual.length; i++) {
      /// [BaseOptions.toKey] serializes all of the relevant parts of the query
      /// or mutation for us, except the fetch policy.
      expect(actual[i].toKey(), expected[i].toKey());
      expect(actual[i].fetchPolicy, expected[i].fetchPolicy);
    }
  }

  void verifyQueries(List<QueryOptions> expected) => verify(expected, queries);

  void verifyMutations(List<MutationOptions> expected) =>
      verify(expected, mutations);
}

enum ReviewState {
  APPROVED,
  CHANGES_REQUESTED,
}

enum MemberType {
  OWNER,
  MEMBER,
  OTHER,
}

@immutable
class PullRequestReviewHelper {
  const PullRequestReviewHelper({
    @required this.authorName,
    @required this.state,
    @required this.memberType,
  });

  final String authorName;
  final ReviewState state;
  final MemberType memberType;
}

@immutable
class StatusHelper {
  const StatusHelper(this.name, this.state);

  static const StatusHelper cirrusSuccess =
      StatusHelper('Cirrus CI', 'SUCCESS');
  static const StatusHelper cirrusFailure =
      StatusHelper('Cirrus CI', 'FAILURE');
  static const StatusHelper flutterBuildSuccess =
      StatusHelper('flutter-build', 'SUCCESS');
  static const StatusHelper flutterBuildFailure =
      StatusHelper('flutter-build', 'FAILURE');
  static const StatusHelper otherStatusFailure =
      StatusHelper('other status', 'FAILURE');
  static const StatusHelper luciEngineBuildSuccess =
      StatusHelper('luci-engine', 'SUCCESS');
  static const StatusHelper luciEngineBuildFailure =
      StatusHelper('luci-engine', 'FAILURE');

  final String name;
  final String state;
}

@immutable
class PullRequestHelper {
  PullRequestHelper({
    this.author = 'some_rando',
    this.reviews = const <PullRequestReviewHelper>[
      PullRequestReviewHelper(
          authorName: 'member',
          state: ReviewState.APPROVED,
          memberType: MemberType.MEMBER)
    ],
    this.lastCommitHash = oid,
    this.lastCommitStatuses = const <StatusHelper>[
      StatusHelper.flutterBuildSuccess
    ],
    this.lastCommitCheckRuns = const <StatusHelper>[StatusHelper.cirrusSuccess],
    this.dateTime,
  }) : _count = _counter++;

  static int _counter = 0;

  final int _count;
  String get id => _count.toString();

  final String author;
  final List<PullRequestReviewHelper> reviews;
  final String lastCommitHash;
  final List<StatusHelper> lastCommitStatuses;
  final List<StatusHelper> lastCommitCheckRuns;
  final DateTime dateTime;

  Map<String, dynamic> toEntry() {
    return <String, dynamic>{
      'author': <String, dynamic>{'login': author},
      'id': id,
      'number': id.hashCode,
      'reviews': <String, dynamic>{
        'nodes': reviews.map((PullRequestReviewHelper review) {
          return <String, dynamic>{
            'author': <String, dynamic>{'login': review.authorName},
            'authorAssociation':
                review.memberType.toString().replaceFirst('MemberType.', ''),
            'state': review.state.toString().replaceFirst('ReviewState.', ''),
          };
        }).toList(),
      },
      'commits': <String, dynamic>{
        'nodes': <dynamic>[
          <String, dynamic>{
            'commit': <String, dynamic>{
              'oid': lastCommitHash,
              'pushedDate':
                  (dateTime ?? DateTime.now().add(const Duration(hours: -2)))
                      .toUtc()
                      .toIso8601String(),
              'status': <String, dynamic>{
                'contexts': lastCommitStatuses.map((StatusHelper status) {
                  return <String, dynamic>{
                    'context': status.name,
                    'state': status.state,
                  };
                }).toList(),
              },
              'checkSuites': <String, dynamic>{
                'nodes': lastCommitCheckRuns.map((StatusHelper status) {
                  return <String, dynamic>{
                    'app': <String, dynamic>{'name': status.name},
                    'conclusion': status.state,
                  };
                }).toList(),
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

const PullRequestReviewHelper ownerApprove = PullRequestReviewHelper(
  authorName: 'owner',
  memberType: MemberType.OWNER,
  state: ReviewState.APPROVED,
);
const PullRequestReviewHelper changePleaseChange = PullRequestReviewHelper(
  authorName: 'change_please',
  memberType: MemberType.MEMBER,
  state: ReviewState.CHANGES_REQUESTED,
);
const PullRequestReviewHelper changePleaseApprove = PullRequestReviewHelper(
  authorName: 'change_please',
  memberType: MemberType.MEMBER,
  state: ReviewState.APPROVED,
);
const PullRequestReviewHelper memberApprove = PullRequestReviewHelper(
  authorName: 'member',
  memberType: MemberType.MEMBER,
  state: ReviewState.APPROVED,
);
const PullRequestReviewHelper nonMemberApprove = PullRequestReviewHelper(
  authorName: 'random_person',
  memberType: MemberType.OTHER,
  state: ReviewState.APPROVED,
);
const PullRequestReviewHelper nonMemberChangeRequest = PullRequestReviewHelper(
  authorName: 'random_person',
  memberType: MemberType.OTHER,
  state: ReviewState.CHANGES_REQUESTED,
);
