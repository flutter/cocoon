// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_service/cocoon_service.dart';
import 'package:cocoon_service/src/request_handlers/check_for_waiting_pull_requests_queries.dart';
import 'package:cocoon_service/src/service/logging.dart';
import 'package:github/github.dart';

import 'package:graphql/client.dart';
import 'package:logging/logging.dart';
import 'package:meta/meta.dart';
import 'package:test/test.dart';

import '../src/datastore/fake_config.dart';
import '../src/request_handling/api_request_handler_tester.dart';
import '../src/request_handling/fake_authentication.dart';
import '../src/request_handling/fake_http.dart';
import '../src/service/fake_graphql_client.dart';

const String base64LabelId = 'base_64_label_id';
const String oid = 'deadbeef';
const String title = 'some_title';

Map<String, dynamic> getMergePullRequestVariables(String number) {
  return <String, dynamic>{
    'id': number,
    'oid': oid,
    'title': '$title (#$number)',
  };
}

void main() {
  group('repos are processed independently', () {
    late CheckForWaitingPullRequests handler;
    late ApiRequestHandlerTester tester;
    FakeHttpRequest request;
    late FakeGraphQLClient githubGraphQLClient;
    FakeGraphQLClient cirrusGraphQLClient;
    FakeConfig config;
    FakeClientContext clientContext;
    FakeAuthenticationProvider auth;
    final List<PullRequestHelper> flutterRepoPRs = <PullRequestHelper>[];
    final List<dynamic> statuses = <dynamic>[];
    String? branch;

    setUp(() {
      request = FakeHttpRequest();

      clientContext = FakeClientContext();
      auth = FakeAuthenticationProvider(clientContext: clientContext);
      githubGraphQLClient = FakeGraphQLClient();
      cirrusGraphQLClient = FakeGraphQLClient();
      config = FakeConfig(
        rollerAccountsValue: <String>{},
        githubGraphQLClient: githubGraphQLClient,
        cirrusGraphQLClient: cirrusGraphQLClient,
      );
      flutterRepoPRs.clear();
      statuses.clear();
      cirrusGraphQLClient.mutateResultForOptions =
          (MutationOptions options) => QueryResult(source: QueryResultSource.network);
      cirrusGraphQLClient.queryResultForOptions = (QueryOptions options) {
        return createCirrusQueryResult(statuses, branch);
      };
      tester = ApiRequestHandlerTester(request: request);
      config.waitingForTreeToGoGreenLabelNameValue = 'waiting for tree to go green';

      handler = CheckForWaitingPullRequests(
        config,
        auth,
      );
    });

    test('Continue with other repos if one fails', () async {
      flutterRepoPRs.add(PullRequestHelper());

      githubGraphQLClient.mutateResultForOptions =
          (MutationOptions options) => QueryResult(source: QueryResultSource.network);
      int errorIndex = 0;
      githubGraphQLClient.queryResultForOptions = (QueryOptions options) {
        if (errorIndex == 0) {
          errorIndex++;
          return QueryResult(
            exception: OperationException(graphqlErrors: <GraphQLError>[const GraphQLError(message: 'error')]),
            source: QueryResultSource.network,
          );
        }
        return createQueryResult(flutterRepoPRs);
      };
      final List<LogRecord> records = <LogRecord>[];
      log.onRecord.listen((LogRecord record) => records.add(record));
      await tester.get(handler);
      final List<LogRecord> errorLogs = records.where((LogRecord logLine) => logLine.level == Level.SEVERE).toList();
      expect(errorLogs.length, 1);
      expect(
          errorLogs.first.message, contains('OperationException(linkException: null, graphqlErrors: [GraphQLError('));
    });
  });
  group('check for waiting pull requests', () {
    late CheckForWaitingPullRequests handler;

    FakeHttpRequest request;
    late FakeConfig config;
    FakeClientContext clientContext;
    FakeAuthenticationProvider auth;
    late FakeGraphQLClient githubGraphQLClient;
    FakeGraphQLClient cirrusGraphQLClient;

    late ApiRequestHandlerTester tester;

    final List<PullRequestHelper> cocoonRepoPRs = <PullRequestHelper>[];
    final List<PullRequestHelper> flutterRepoPRs = <PullRequestHelper>[];
    final List<PullRequestHelper> engineRepoPRs = <PullRequestHelper>[];
    final List<PullRequestHelper> packageRepoPRs = <PullRequestHelper>[];
    final List<PullRequestHelper> pluginRepoPRs = <PullRequestHelper>[];
    List<dynamic> statuses = <dynamic>[];
    String? branch;

    setUp(() {
      request = FakeHttpRequest();
      clientContext = FakeClientContext();
      auth = FakeAuthenticationProvider(clientContext: clientContext);
      githubGraphQLClient = FakeGraphQLClient();
      cirrusGraphQLClient = FakeGraphQLClient();
      config = FakeConfig(
        rollerAccountsValue: <String>{},
        cirrusGraphQLClient: cirrusGraphQLClient,
        githubGraphQLClient: githubGraphQLClient,
      );
      config.overrideTreeStatusLabelValue = 'warning: land on red to fix tree breakage';
      flutterRepoPRs.clear();
      engineRepoPRs.clear();
      pluginRepoPRs.clear();
      statuses.clear();
      PullRequestHelper._counter = 0;

      cirrusGraphQLClient.mutateResultForOptions =
          (MutationOptions options) => QueryResult(source: QueryResultSource.network);
      cirrusGraphQLClient.queryResultForOptions = (QueryOptions options) {
        return createCirrusQueryResult(statuses, branch);
      };

      githubGraphQLClient.mutateResultForOptions =
          (MutationOptions options) => QueryResult(source: QueryResultSource.network);

      githubGraphQLClient.queryResultForOptions = (QueryOptions options) {
        expect(options.variables['sOwner'], 'flutter');
        expect(options.variables['sLabelName'], config.waitingForTreeToGoGreenLabelNameValue);

        final String? repoName = options.variables['sName'] as String?;
        if (repoName == 'flutter') {
          return createQueryResult(flutterRepoPRs);
        } else if (repoName == 'engine') {
          return createQueryResult(engineRepoPRs);
        } else if (repoName == 'cocoon') {
          return createQueryResult(cocoonRepoPRs);
        } else if (repoName == 'packages') {
          return createQueryResult(packageRepoPRs);
        } else if (repoName == 'plugins') {
          return createQueryResult(pluginRepoPRs);
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
              'sName': 'cocoon',
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
              'sName': 'packages',
              'sLabelName': config.waitingForTreeToGoGreenLabelNameValue,
            },
          ),
          QueryOptions(
            document: labeledPullRequestsWithReviewsQuery,
            fetchPolicy: FetchPolicy.noCache,
            variables: <String, dynamic>{
              'sOwner': 'flutter',
              'sName': 'plugins',
              'sLabelName': config.waitingForTreeToGoGreenLabelNameValue,
            },
          ),
        ],
      );
    }

    test('Errors can be logged', () async {
      flutterRepoPRs.add(PullRequestHelper());
      final List<GraphQLError> errors = <GraphQLError>[
        const GraphQLError(message: 'message'),
      ];
      final OperationException exception = OperationException(graphqlErrors: errors);
      githubGraphQLClient.mutateResultForOptions = (_) => QueryResult(
            exception: exception,
            source: QueryResultSource.network,
          );
      final List<LogRecord> records = <LogRecord>[];
      log.onRecord.listen((LogRecord record) => records.add(record));
      await tester.get(handler);
      final List<LogRecord> errorLogs = records.where((LogRecord record) => record.level == Level.SEVERE).toList();
      expect(errorLogs.length, errors.length);
      expect(errorLogs.first.message, exception.toString());
    });

    test('Merges unapproved PR from autoroller', () async {
      config.rollerAccountsValue = <String>{'engine-roller', 'skia-roller'};
      flutterRepoPRs.add(PullRequestHelper(author: 'engine-roller', reviews: const <PullRequestReviewHelper>[]));
      engineRepoPRs.add(PullRequestHelper(author: 'skia-roller', reviews: const <PullRequestReviewHelper>[]));

      await tester.get(handler);

      _verifyQueries();

      githubGraphQLClient.verifyMutations(
        <MutationOptions>[
          MutationOptions(
            document: mergePullRequestMutation,
            variables: getMergePullRequestVariables(engineRepoPRs.first.id),
          ),
          MutationOptions(
            document: mergePullRequestMutation,
            variables: getMergePullRequestVariables(flutterRepoPRs.first.id),
          ),
        ],
      );
    });

    test('Does not merge PR with in progress tests', () async {
      statuses = <dynamic>[
        <String, String>{'id': '1', 'status': 'EXECUTING', 'name': 'test1'},
        <String, String>{'id': '2', 'status': 'COMPLETED', 'name': 'test2'}
      ];
      branch = 'pull/0';

      flutterRepoPRs.add(PullRequestHelper());

      await tester.get(handler);

      _verifyQueries();
      githubGraphQLClient.verifyMutations(<MutationOptions>[]);
    });

    test('Does not merge PR with in progress checks', () async {
      branch = 'pull/0';
      final PullRequestHelper prInProgress = PullRequestHelper(
        lastCommitCheckRuns: const <CheckRunHelper>[
          CheckRunHelper.windowsInProgress,
        ],
      );
      flutterRepoPRs.add(prInProgress);
      await tester.get(handler);
      _verifyQueries();
      githubGraphQLClient.verifyMutations(<MutationOptions>[]);
    });

    test('Does not merge PR with queued checks', () async {
      branch = 'pull/0';
      final PullRequestHelper prQueued = PullRequestHelper(
        lastCommitCheckRuns: const <CheckRunHelper>[
          CheckRunHelper.macQueued,
        ],
      );
      flutterRepoPRs.add(prQueued);
      await tester.get(handler);
      _verifyQueries();
      githubGraphQLClient.verifyMutations(<MutationOptions>[]);
    });

    test('Does not merge PR with requested checks', () async {
      branch = 'pull/0';
      final PullRequestHelper prRequested = PullRequestHelper(
        lastCommitCheckRuns: const <CheckRunHelper>[
          CheckRunHelper.linuxRequested,
        ],
      );
      flutterRepoPRs.add(prRequested);
      await tester.get(handler);
      _verifyQueries();
      githubGraphQLClient.verifyMutations(<MutationOptions>[]);
    });

    test('Does not merge PR with failed status', () async {
      branch = 'pull/0';
      final PullRequestHelper prRequested = PullRequestHelper(
        lastCommitCheckRuns: const <CheckRunHelper>[
          CheckRunHelper.linuxRequested,
        ],
        lastCommitStatuses: const <StatusHelper>[
          StatusHelper.flutterBuildFailure,
        ],
      );
      flutterRepoPRs.add(prRequested);
      await tester.get(handler);
      _verifyQueries();
      githubGraphQLClient.verifyMutations(<MutationOptions>[]);
    });

    test('Merges PR with failed tree status if override tree status label is provided', () async {
      branch = 'pull/0';
      final PullRequestHelper prRequested = PullRequestHelper(
        lastCommitCheckRuns: const <CheckRunHelper>[
          CheckRunHelper.luciCompletedSuccess,
        ],
        lastCommitStatuses: const <StatusHelper>[
          StatusHelper.flutterBuildFailure,
        ],
        labels: <dynamic>[
          <String, dynamic>{'name': 'warning: land on red to fix tree breakage'}
        ],
      );
      flutterRepoPRs.add(prRequested);
      await tester.get(handler);
      _verifyQueries();
      githubGraphQLClient.verifyMutations(<MutationOptions>[
        MutationOptions(document: mergePullRequestMutation, variables: <String, dynamic>{
          'id': flutterRepoPRs.first.id,
          'oid': oid,
          'title': 'some_title (#0)',
        }),
      ]);
    });

    test('Merges PR with check that is successful but still considered running', () async {
      branch = 'pull/0';
      final PullRequestHelper prRequested = PullRequestHelper(
        lastCommitCheckRuns: const <CheckRunHelper>[
          CheckRunHelper.linuxCompletedRunning,
        ],
        lastCommitStatuses: const <StatusHelper>[
          StatusHelper.flutterBuildSuccess,
        ],
      );
      flutterRepoPRs.add(prRequested);
      await tester.get(handler);
      _verifyQueries();
      githubGraphQLClient.verifyMutations(<MutationOptions>[
        MutationOptions(document: mergePullRequestMutation, variables: <String, dynamic>{
          'id': flutterRepoPRs.first.id,
          'oid': oid,
          'title': 'some_title (#0)',
        }),
      ]);
    });

    test('Does not merge PR with failed checks', () async {
      branch = 'pull/0';
      final PullRequestHelper prRequested = PullRequestHelper(
        lastCommitCheckRuns: const <CheckRunHelper>[
          CheckRunHelper.luciCompletedFailure,
          CheckRunHelper.luciCompletedSuccess,
        ],
        lastCommitStatuses: const <StatusHelper>[
          StatusHelper.flutterBuildSuccess,
        ],
      );
      flutterRepoPRs.add(prRequested);
      await tester.get(handler);
      _verifyQueries();
      githubGraphQLClient.verifyMutations(<MutationOptions>[
        MutationOptions(
          document: removeLabelMutation,
          variables: <String, dynamic>{
            'id': flutterRepoPRs.first.id,
            'labelId': base64LabelId,
            'sBody': '''
This pull request is not suitable for automatic merging in its current state.

- The status or check suite [Linux](https://Linux) has failed. Please fix the issues identified (or deflake) before re-applying this label.
''',
          },
        ),
      ]);
    });

    test('Does not fail with null checks', () async {
      branch = 'pull/0';
      final PullRequestHelper prRequested = PullRequestHelper(
        lastCommitCheckRuns: const <CheckRunHelper>[],
        lastCommitStatuses: const <StatusHelper>[
          StatusHelper.flutterBuildFailure,
        ],
      );
      prRequested.lastCommitCheckRuns = null;
      flutterRepoPRs.add(prRequested);
      await tester.get(handler);
      _verifyQueries();
      githubGraphQLClient.verifyMutations(<MutationOptions>[
        MutationOptions(
          document: removeLabelMutation,
          variables: <String, dynamic>{
            'id': flutterRepoPRs.first.id,
            'labelId': base64LabelId,
            'sBody': '''
This pull request is not suitable for automatic merging in its current state.

- This commit has no checks. Please check that ci.yaml validation has started and there are multiple checks. If not, try uploading an empty commit.
''',
          },
        ),
      ]);
    });

    test('Empty validations do not merge', () async {
      branch = 'pull/0';
      final PullRequestHelper prRequested = PullRequestHelper(
        lastCommitCheckRuns: const <CheckRunHelper>[],
        lastCommitStatuses: const <StatusHelper>[],
      );
      flutterRepoPRs.add(prRequested);
      await tester.get(handler);
      _verifyQueries();
      githubGraphQLClient.verifyMutations(<MutationOptions>[
        MutationOptions(
          document: removeLabelMutation,
          variables: <String, dynamic>{
            'id': flutterRepoPRs.first.id,
            'labelId': base64LabelId,
            'sBody': '''
This pull request is not suitable for automatic merging in its current state.

- The status or check suite [tree status luci-flutter](https://flutter-dashboard.appspot.com/#/build) has failed. Please fix the issues identified (or deflake) before re-applying this label.
- This commit has no checks. Please check that ci.yaml validation has started and there are multiple checks. If not, try uploading an empty commit.
''',
          },
        ),
      ]);
    });

    test('Merge PR with successful checks on repo without tree status', () async {
      branch = 'pull/0';
      final PullRequestHelper prRequested = PullRequestHelper(
        repo: 'cocoon',
        lastCommitCheckRuns: const <CheckRunHelper>[
          CheckRunHelper.luciCompletedSuccess,
        ],
        lastCommitStatuses: const <StatusHelper>[],
      );
      prRequested.lastCommitStatuses = null;
      flutterRepoPRs.add(prRequested);
      await tester.get(handler);
      _verifyQueries();
      githubGraphQLClient.verifyMutations(<MutationOptions>[
        MutationOptions(
          document: mergePullRequestMutation,
          variables: getMergePullRequestVariables(flutterRepoPRs.first.id),
        ),
      ]);
    });

    test('Merge PR with successful status and checks', () async {
      branch = 'pull/0';
      final PullRequestHelper prRequested = PullRequestHelper(
        lastCommitCheckRuns: const <CheckRunHelper>[
          CheckRunHelper.luciCompletedSuccess,
        ],
        lastCommitStatuses: const <StatusHelper>[
          StatusHelper.flutterBuildSuccess,
        ],
      );
      flutterRepoPRs.add(prRequested);
      await tester.get(handler);
      _verifyQueries();
      githubGraphQLClient.verifyMutations(<MutationOptions>[
        MutationOptions(
          document: mergePullRequestMutation,
          variables: getMergePullRequestVariables(flutterRepoPRs.first.id),
        ),
      ]);
    });

    test('Ignores cirrus tasks statuses when no matched branch', () async {
      statuses = <dynamic>[
        <String, String>{'id': '1', 'status': 'EXECUTING', 'name': 'test1'},
        <String, String>{'id': '2', 'status': 'COMPLETED', 'name': 'test2'}
      ];
      branch = 'flutter-0.0-candidate.0';

      flutterRepoPRs.add(PullRequestHelper());

      await tester.get(handler);

      _verifyQueries();

      githubGraphQLClient.verifyMutations(
        <MutationOptions>[
          MutationOptions(
            document: mergePullRequestMutation,
            variables: getMergePullRequestVariables(flutterRepoPRs[0].id),
          ),
        ],
      );
    });

    test('Merge PR with complated tests', () async {
      statuses = <dynamic>[
        <String, String>{'id': '1', 'status': 'SKIPPED', 'name': 'test1'},
        <String, String>{'id': '2', 'status': 'COMPLETED', 'name': 'test2'}
      ];
      branch = 'pull/0';

      flutterRepoPRs.add(PullRequestHelper());

      await tester.get(handler);

      _verifyQueries();

      githubGraphQLClient.verifyMutations(
        <MutationOptions>[
          MutationOptions(
            document: mergePullRequestMutation,
            variables: getMergePullRequestVariables(flutterRepoPRs[0].id),
          ),
        ],
      );
    });

    test('Does not merge PR with failed tests', () async {
      statuses = <dynamic>[
        <String, String>{'id': '1', 'status': 'FAILED', 'name': 'test1'},
        <String, String>{'id': '2', 'status': 'COMPLETED', 'name': 'test2'}
      ];
      branch = 'pull/0';

      flutterRepoPRs.add(PullRequestHelper());

      await tester.get(handler);

      _verifyQueries();

      githubGraphQLClient.verifyMutations(
        <MutationOptions>[
          MutationOptions(
            document: removeLabelMutation,
            variables: <String, dynamic>{
              'id': flutterRepoPRs[0].id,
              'labelId': base64LabelId,
              'sBody': '''
This pull request is not suitable for automatic merging in its current state.

- The status or check suite [test1](https://cirrus-ci.com/task/1) has failed. Please fix the issues identified (or deflake) before re-applying this label.
''',
            },
          ),
        ],
      );
    });

    test('Does not merge unapproved PR from a hacker', () async {
      config.rollerAccountsValue = <String>{'engine-roller', 'skia-roller'};
      flutterRepoPRs.add(PullRequestHelper(author: 'engine-roller-hacker', reviews: const <PullRequestReviewHelper>[]));
      engineRepoPRs.add(PullRequestHelper(author: 'skia-roller-hacker', reviews: const <PullRequestReviewHelper>[]));

      await tester.get(handler);

      _verifyQueries();

      githubGraphQLClient.verifyMutations(
        <MutationOptions>[
          MutationOptions(
            document: removeLabelMutation,
            variables: <String, dynamic>{
              'id': engineRepoPRs.first.id,
              'sBody': '''This pull request is not suitable for automatic merging in its current state.

- Please get at least one approved review before re-applying this label. __Reviewers__: If you left a comment approving, please use the "approve" review action instead.
''',
              'labelId': base64LabelId,
            },
          ),
          MutationOptions(
            document: removeLabelMutation,
            variables: <String, dynamic>{
              'id': flutterRepoPRs.first.id,
              'sBody': '''This pull request is not suitable for automatic merging in its current state.

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
            variables: getMergePullRequestVariables(engineRepoPRs.first.id),
          ),
          MutationOptions(
            document: mergePullRequestMutation,
            variables: getMergePullRequestVariables(flutterRepoPRs[0].id),
          ),
          MutationOptions(
            document: mergePullRequestMutation,
            variables: getMergePullRequestVariables(flutterRepoPRs[1].id),
          ),
        ],
      );
    });

    test('Merges 1st and 3rd PR, 2nd failed', () async {
      flutterRepoPRs.add(PullRequestHelper());
      flutterRepoPRs.add(PullRequestHelper(author: 'engine-roller-hacker', reviews: const <PullRequestReviewHelper>[]));

      flutterRepoPRs.add(PullRequestHelper());
      engineRepoPRs.add(PullRequestHelper());

      await tester.get(handler);

      _verifyQueries();

      githubGraphQLClient.verifyMutations(
        <MutationOptions>[
          MutationOptions(
            document: mergePullRequestMutation,
            variables: getMergePullRequestVariables(engineRepoPRs.first.id),
          ),
          MutationOptions(
            document: mergePullRequestMutation,
            variables: getMergePullRequestVariables(flutterRepoPRs[0].id),
          ),
          MutationOptions(
            document: removeLabelMutation,
            variables: <String, dynamic>{
              'id': flutterRepoPRs[1].id,
              'sBody': '''This pull request is not suitable for automatic merging in its current state.

- Please get at least one approved review before re-applying this label. __Reviewers__: If you left a comment approving, please use the "approve" review action instead.
''',
              'labelId': base64LabelId,
            },
          ),
          MutationOptions(
            document: mergePullRequestMutation,
            variables: getMergePullRequestVariables(flutterRepoPRs[2].id),
          ),
        ],
      );
    });

    test('Ignores PRs that are too new', () async {
      flutterRepoPRs.add(PullRequestHelper(dateTime: DateTime.now().add(const Duration(minutes: -50)))); // too new
      flutterRepoPRs.add(PullRequestHelper(dateTime: DateTime.now().add(const Duration(minutes: -70)))); // ok
      engineRepoPRs.add(PullRequestHelper()); // default is two hours for this ctor.

      await tester.get(handler);

      _verifyQueries();

      githubGraphQLClient.verifyMutations(
        <MutationOptions>[
          MutationOptions(
            document: mergePullRequestMutation,
            variables: getMergePullRequestVariables(engineRepoPRs.first.id),
          ),
          MutationOptions(
            document: mergePullRequestMutation,
            variables: getMergePullRequestVariables(flutterRepoPRs.last.id),
          ),
        ],
      );
    });

    test('Unlabels red PRs', () async {
      statuses = <dynamic>[
        <String, String>{'id': '1', 'status': 'FAILED', 'name': 'test1'},
        <String, String>{'id': '2', 'status': 'COMPLETED', 'name': 'test2'}
      ];
      branch = 'pull/0';
      final PullRequestHelper prRed = PullRequestHelper(
        lastCommitStatuses: const <StatusHelper>[
          StatusHelper.flutterBuildSuccess,
          StatusHelper.otherStatusFailure,
        ],
      );
      flutterRepoPRs.add(prRed);

      await tester.get(handler);
      _verifyQueries();
      githubGraphQLClient.verifyMutations(<MutationOptions>[
        MutationOptions(
          document: removeLabelMutation,
          variables: <String, dynamic>{
            'id': prRed.id,
            'sBody': '''This pull request is not suitable for automatic merging in its current state.

- The status or check suite [other status](https://other status) has failed. Please fix the issues identified (or deflake) before re-applying this label.
- The status or check suite [test1](https://cirrus-ci.com/task/1) has failed. Please fix the issues identified (or deflake) before re-applying this label.
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
            variables: getMergePullRequestVariables(prChangedReview.id),
          ),
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
      final PullRequestHelper prNonMemberChangeRequestWithMemberApprove = PullRequestHelper(
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
              'sBody': '''This pull request is not suitable for automatic merging in its current state.

- Please get at least one approved review before re-applying this label. __Reviewers__: If you left a comment approving, please use the "approve" review action instead.
''',
              'labelId': base64LabelId,
            },
          ),
          MutationOptions(
            document: removeLabelMutation,
            variables: <String, dynamic>{
              'id': prNonMemberChangeRequest.id,
              'sBody': '''This pull request is not suitable for automatic merging in its current state.

- Please get at least one approved review before re-applying this label. __Reviewers__: If you left a comment approving, please use the "approve" review action instead.
''',
              'labelId': base64LabelId,
            },
          ),
          MutationOptions(
            document: mergePullRequestMutation,
            variables: getMergePullRequestVariables(prNonMemberChangeRequestWithMemberApprove.id),
          ),
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
        lastCommitStatuses: const <StatusHelper>[StatusHelper.flutterBuildFailure],
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
              'sBody': '''This pull request is not suitable for automatic merging in its current state.

- This pull request has changes requested by @change_please. Please resolve those before re-applying the label.
''',
              'labelId': base64LabelId,
            },
          ),
          MutationOptions(
            document: removeLabelMutation,
            variables: <String, dynamic>{
              'id': prOneGoodOneBadReview.id,
              'sBody': '''This pull request is not suitable for automatic merging in its current state.

- This pull request has changes requested by @change_please. Please resolve those before re-applying the label.
''',
              'labelId': base64LabelId,
            },
          ),
          MutationOptions(
            document: removeLabelMutation,
            variables: <String, dynamic>{
              'id': prNoReviews.id,
              'sBody': '''This pull request is not suitable for automatic merging in its current state.

- Please get at least one approved review before re-applying this label. __Reviewers__: If you left a comment approving, please use the "approve" review action instead.
''',
              'labelId': base64LabelId,
            },
          ),
          MutationOptions(
            document: removeLabelMutation,
            variables: <String, dynamic>{
              'id': prEverythingWrong.id,
              'sBody': '''This pull request is not suitable for automatic merging in its current state.

- This pull request has changes requested by @change_please. Please resolve those before re-applying the label.
''',
              'labelId': base64LabelId,
            },
          ),
        ],
      );
    });
  });
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
    required this.authorName,
    required this.state,
    required this.memberType,
  });

  final String authorName;
  final ReviewState state;
  final MemberType memberType;
}

@immutable
class StatusHelper {
  const StatusHelper(this.name, this.state);

  static const StatusHelper cirrusSuccess = StatusHelper('Cirrus CI', 'SUCCESS');
  static const StatusHelper cirrusFailure = StatusHelper('Cirrus CI', 'FAILURE');
  static const StatusHelper flutterBuildSuccess = StatusHelper('luci-flutter', 'SUCCESS');
  static const StatusHelper flutterBuildFailure = StatusHelper('luci-flutter', 'FAILURE');
  static const StatusHelper otherStatusFailure = StatusHelper('other status', 'FAILURE');
  static const StatusHelper luciEngineBuildSuccess = StatusHelper('luci-engine', 'SUCCESS');
  static const StatusHelper luciEngineBuildFailure = StatusHelper('luci-engine', 'FAILURE');

  final String name;
  final String state;
}

@immutable
class CheckRunHelper {
  const CheckRunHelper(this.name, this.status, this.conclusion);

  static const CheckRunHelper luciCompletedSuccess = CheckRunHelper('Linux', 'COMPLETED', 'SUCCESS');
  static const CheckRunHelper luciCompletedFailure = CheckRunHelper('Linux', 'COMPLETED', 'FAILURE');
  static const CheckRunHelper luciCompletedNeutral = CheckRunHelper('Linux', 'COMPLETED', 'NEUTRAL');
  static const CheckRunHelper luciCompletedSkipped = CheckRunHelper('Linux', 'COMPLETED', 'SKIPPED');
  static const CheckRunHelper luciCompletedStale = CheckRunHelper('Linux', 'COMPLETED', 'STALE');
  static const CheckRunHelper luciCompletedTimedout = CheckRunHelper('Linux', 'COMPLETED', 'TIMED_OUT');
  static const CheckRunHelper windowsInProgress = CheckRunHelper('Windows', 'IN_PROGRESS', '');
  static const CheckRunHelper macQueued = CheckRunHelper('Mac', 'QUEUED', '');
  static const CheckRunHelper linuxRequested = CheckRunHelper('Linux', 'REQUESTED', '');
  // See https://github.com/flutter/flutter/issues/91908
  static const CheckRunHelper linuxCompletedRunning = CheckRunHelper('Linux', 'IN PROGRESS', 'SUCCESS');

  final String name;
  final String status;
  final String conclusion;
}

class PullRequestHelper {
  PullRequestHelper({
    this.author = 'some_rando',
    this.repo = 'flutter',
    this.title = 'some_title',
    this.reviews = const <PullRequestReviewHelper>[
      PullRequestReviewHelper(authorName: 'member', state: ReviewState.APPROVED, memberType: MemberType.MEMBER)
    ],
    this.lastCommitHash = oid,
    this.lastCommitStatuses = const <StatusHelper>[StatusHelper.flutterBuildSuccess],
    this.lastCommitCheckRuns = const <CheckRunHelper>[CheckRunHelper.luciCompletedSuccess],
    this.dateTime,
    this.labels = const <dynamic>[],
  }) : _count = _counter++;

  static int _counter = 0;

  final int _count;
  String get id => _count.toString();

  final String repo;
  final String author;
  final String title;
  final List<PullRequestReviewHelper> reviews;
  final String lastCommitHash;
  List<StatusHelper>? lastCommitStatuses;
  List<CheckRunHelper>? lastCommitCheckRuns;
  final DateTime? dateTime;
  List<dynamic> labels;

  RepositorySlug get slug => RepositorySlug('flutter', repo);

  Map<String, dynamic> toEntry() {
    return <String, dynamic>{
      'author': <String, dynamic>{'login': author},
      'id': id,
      'baseRepository': <String, dynamic>{
        'nameWithOwner': slug.fullName,
      },
      'number': _count,
      'title': title,
      'reviews': <String, dynamic>{
        'nodes': reviews.map((PullRequestReviewHelper review) {
          return <String, dynamic>{
            'author': <String, dynamic>{'login': review.authorName},
            'authorAssociation': review.memberType.toString().replaceFirst('MemberType.', ''),
            'state': review.state.toString().replaceFirst('ReviewState.', ''),
          };
        }).toList(),
      },
      'commits': <String, dynamic>{
        'nodes': <dynamic>[
          <String, dynamic>{
            'commit': <String, dynamic>{
              'oid': lastCommitHash,
              'pushedDate': (dateTime ?? DateTime.now().add(const Duration(hours: -2))).toUtc().toIso8601String(),
              'status': <String, dynamic>{
                'contexts': lastCommitStatuses != null
                    ? lastCommitStatuses!.map((StatusHelper status) {
                        return <String, dynamic>{
                          'context': status.name,
                          'state': status.state,
                          'targetUrl': 'https://${status.name}',
                        };
                      }).toList()
                    : <dynamic>[]
              },
              'checkSuites': <String, dynamic>{
                'nodes': lastCommitCheckRuns != null
                    ? <dynamic>[
                        <String, dynamic>{
                          'checkRuns': <String, dynamic>{
                            'nodes': lastCommitCheckRuns!.map((CheckRunHelper status) {
                              return <String, dynamic>{
                                'name': status.name,
                                'status': status.status,
                                'conclusion': status.conclusion,
                                'detailsUrl': 'https://${status.name}',
                              };
                            }).toList(),
                          }
                        }
                      ]
                    : <dynamic>[]
              },
            },
          },
        ],
      },
      'labels': <String, dynamic>{
        'nodes': labels,
      },
    };
  }
}

QueryResult createQueryResult(List<PullRequestHelper> pullRequests) {
  return QueryResult(
    data: <String, dynamic>{
      'repository': <String, dynamic>{
        'labels': <String, dynamic>{
          'nodes': <dynamic>[
            <String, dynamic>{
              'id': base64LabelId,
              'pullRequests': <String, dynamic>{
                'nodes': pullRequests
                    .map<Map<String, dynamic>>(
                      (PullRequestHelper pullRequest) => pullRequest.toEntry(),
                    )
                    .toList(),
              },
            },
          ],
        },
      },
    },
    source: QueryResultSource.network,
  );
}

QueryResult createCirrusQueryResult(List<dynamic> statuses, String? branch) {
  if (statuses.isEmpty) {
    return QueryResult(source: QueryResultSource.network);
  }
  return QueryResult(
    data: <String, dynamic>{
      'searchBuilds': <dynamic>[
        <String, dynamic>{
          'id': '1',
          'branch': branch,
          'latestGroupTasks': statuses.map<Map<String, dynamic>>((dynamic status) {
            return <String, dynamic>{
              'id': status['id'],
              'name': status['name'],
              'status': status['status'],
            };
          }).toList(),
        }
      ],
    },
    source: QueryResultSource.network,
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
