// Copyright 2026 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_integration_test/testing.dart';
import 'package:cocoon_server_test/test_logging.dart';
import 'package:cocoon_service/src/model/firestore/want_lgtm_state.dart';
import 'package:cocoon_service/src/service/config.dart';
import 'package:cocoon_service/src/service/flags/dynamic_config.dart';
import 'package:cocoon_service/src/service/flags/want_lgtm_flags.dart';
import 'package:cocoon_service/src/service/want_lgtm/want_lgtm_check_writer.dart';
import 'package:cocoon_service/src/service/want_lgtm/want_lgtm_graphql.dart';
import 'package:cocoon_service/src/service/want_lgtm/want_lgtm_models.dart';
import 'package:cocoon_service/src/service/want_lgtm/want_lgtm_reconciler.dart';
import 'package:github/github.dart' as github;
import 'package:github/github.dart';
import 'package:graphql/client.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

void main() {
  useTestLoggerPerTest();

  late FakeConfig config;
  late MockGithubChecksUtil mockGithubChecksUtil;
  late FakeFirestoreService firestoreService;
  late FakeGraphQLClient fakeGraphQLClient;
  late WantLgtmGraphQLClient graphQLClient;
  late WantLgtmCheckWriter checkWriter;
  late WantLgtmReconciler reconciler;

  setUp(() {
    config = FakeConfig();
    mockGithubChecksUtil = MockGithubChecksUtil();
    firestoreService = FakeFirestoreService();
    fakeGraphQLClient = FakeGraphQLClient();
    graphQLClient = WantLgtmGraphQLClient(fakeGraphQLClient);
    checkWriter = WantLgtmCheckWriter(
      config: config,
      githubChecksUtil: mockGithubChecksUtil,
      firestoreService: firestoreService,
    );
    reconciler = WantLgtmReconciler(
      config: config,
      graphQLClient: graphQLClient,
      checkWriter: checkWriter,
      firestoreService: firestoreService,
    );

    // Default: enabled for flutter/flutter
    config.rollerAccountsValue = const <String>{
      'engine-flutter-autoroll',
      'skia-flutter-autoroll',
    };
    config.dynamicConfig = DynamicConfig(
      wantLgtm: WantLgtmFlags(
        enabled: true,
        useForAllRepos: false,
        enabledRepos: ['flutter/flutter'],
      ),
    );
  });

  Map<String, Object?> createSnapshotResponse({
    String state = 'OPEN',
    String body = 'WANT_LGTM=alice',
    String headRefOid = 'sha_head_123',
    String authorLogin = 'author1',
    List<Map<String, Object?>> reviewRequests = const [],
    List<Map<String, Object?>> reviews = const [],
    List<Map<String, Object?>> timelineItems = const [],
  }) => {
    'repository': {
      'pullRequest': {
        'state': state,
        'body': body,
        'headRefOid': headRefOid,
        'author': {'login': authorLogin},
        'reviewRequests': {
          'pageInfo': {'hasNextPage': false, 'endCursor': null},
          'nodes': reviewRequests,
        },
        'reviews': {
          'pageInfo': {'hasNextPage': false, 'endCursor': null},
          'nodes': reviews,
        },
        'timelineItems': {
          'pageInfo': {'hasNextPage': false, 'endCursor': null},
          'nodes': timelineItems,
        },
      },
    },
  };

  group('WantLgtmReconciler', () {
    final slug = RepositorySlug('flutter', 'flutter');
    const prNumber = 123;
    const headSha = 'head_sha_123';

    test('skips when rollout flag is disabled and no existing state', () async {
      config.dynamicConfig = DynamicConfig(
        wantLgtm: WantLgtmFlags(
          enabled: false,
          useForAllRepos: false,
          enabledRepos: [],
        ),
      );

      final result = await reconciler.reconcilePullRequest(slug, prNumber);
      expect(result, isA<WantLgtmReconcileSkipped>());
      expect(
        (result as WantLgtmReconcileSkipped).reason,
        'Rollout flag disabled',
      );
    });

    test('waives active check run when rollout flag is disabled', () async {
      config.dynamicConfig = DynamicConfig(
        wantLgtm: WantLgtmFlags(enabled: false),
      );
      final existingState = WantLgtmState.initialize(
        slug: slug,
        pr: prNumber,
        headSha: 'head_sha',
        checkRunId: 888,
        checkRunStatus: 'in_progress',
        checkRunTitle: 'Waiting on alice',
      );
      firestoreService.putDocument(existingState);

      when(
        mockGithubChecksUtil.updateCheckRun(
          any,
          any,
          any,
          status: anyNamed('status'),
          conclusion: anyNamed('conclusion'),
          detailsUrl: anyNamed('detailsUrl'),
          output: anyNamed('output'),
        ),
      ).thenAnswer((_) async {});

      final result = await reconciler.reconcilePullRequest(slug, prNumber);
      expect(result, isA<WantLgtmReconcileSuccess>());
      final success = result as WantLgtmReconcileSuccess;
      expect(success.verdict, isA<WantLgtmSatisfied>());
      expect(success.verdict.title, 'WANT_LGTM: waived (feature disabled)');
      expect(success.state.checkRunStatus, 'completed');
      expect(success.state.checkRunConclusion, 'neutral');
      expect(
        success.state.checkRunTitle,
        'WANT_LGTM: waived (feature disabled)',
      );
    });

    test('skips closed or merged pull requests', () async {
      fakeGraphQLClient.queryResultForOptions = (QueryOptions options) {
        return createFakeQueryResult(
          data: createSnapshotResponse(state: 'CLOSED'),
        );
      };

      final result = await reconciler.reconcilePullRequest(slug, prNumber);
      expect(result, isA<WantLgtmReconcileSkipped>());
      expect(
        (result as WantLgtmReconcileSkipped).reason,
        'PR is closed or merged',
      );
    });

    test('evaluates valid directive and writes pending verdict', () async {
      fakeGraphQLClient.queryResultForOptions = (QueryOptions options) {
        return createFakeQueryResult(
          data: createSnapshotResponse(
            body: 'WANT_LGTM=alice,bob',
            reviewRequests: [
              {
                'requestedReviewer': {'login': 'bob'},
              },
            ],
            reviews: [
              {
                'author': {'login': 'alice'},
                'state': 'APPROVED',
                'submittedAt': '2026-11-06T10:00:00Z',
              },
            ],
          ),
        );
      };

      when(
        mockGithubChecksUtil.createCheckRun(
          any,
          any,
          any,
          any,
          output: anyNamed('output'),
          conclusion: anyNamed('conclusion'),
          status: anyNamed('status'),
          detailsUrl: anyNamed('detailsUrl'),
        ),
      ).thenAnswer((_) async => WantLgtmCheckWriter.checkRunWithId(555001));

      final result = await reconciler.reconcilePullRequest(slug, prNumber);
      expect(result, isA<WantLgtmReconcileSuccess>());
      final success = result as WantLgtmReconcileSuccess;
      expect(success.verdict, isA<WantLgtmPending>());
      expect(success.verdict.title, 'Waiting on bob');
      expect(success.state.checkRunStatus, 'in_progress');
      expect(success.state.directive, 'alice,bob');
    });

    test(
      'short-circuits when PR has no directive and no Firestore state',
      () async {
        fakeGraphQLClient.queryResultForOptions = (QueryOptions options) {
          return createFakeQueryResult(
            data: createSnapshotResponse(
              body: 'Just a normal PR with no directive',
            ),
          );
        };

        final result = await reconciler.reconcilePullRequest(slug, prNumber);
        expect(result, isA<WantLgtmReconcileSkipped>());
        expect(
          (result as WantLgtmReconcileSkipped).reason,
          contains('No WANT_LGTM directive declared'),
        );

        verifyNever(
          mockGithubChecksUtil.createCheckRun(
            any,
            any,
            any,
            any,
            output: anyNamed('output'),
            conclusion: anyNamed('conclusion'),
            status: anyNamed('status'),
            detailsUrl: anyNamed('detailsUrl'),
          ),
        );
      },
    );

    test('waives check run to neutral when directive is removed', () async {
      final existingState = WantLgtmState.initialize(
        slug: slug,
        pr: prNumber,
        headSha: headSha,
        checkRunId: 555009,
        checkRunStatus: 'in_progress',
        checkRunTitle: 'Waiting on alice',
        directive: 'alice',
      );
      firestoreService.putDocument(existingState);

      fakeGraphQLClient.queryResultForOptions = (QueryOptions options) {
        return createFakeQueryResult(
          data: createSnapshotResponse(body: 'Directive was removed by author'),
        );
      };

      when(
        mockGithubChecksUtil.updateCheckRun(
          any,
          any,
          any,
          output: anyNamed('output'),
          conclusion: anyNamed('conclusion'),
          status: anyNamed('status'),
          detailsUrl: anyNamed('detailsUrl'),
        ),
      ).thenAnswer((_) async {});

      final result = await reconciler.reconcilePullRequest(slug, prNumber);
      expect(result, isA<WantLgtmReconcileSuccess>());
      final success = result as WantLgtmReconcileSuccess;
      expect(success.verdict.title, 'WANT_LGTM: waived (directive removed)');
      expect(success.state.checkRunStatus, 'completed');
      expect(success.state.checkRunConclusion, 'neutral');
      expect(success.state.directive, isNull);

      verify(
        mockGithubChecksUtil.updateCheckRun(
          config,
          slug,
          argThat(isA<github.CheckRun>().having((c) => c.id, 'id', 555009)),
          output: anyNamed('output'),
          conclusion: github.CheckRunConclusion.neutral,
          status: github.CheckRunStatus.completed,
          detailsUrl: 'https://github.com/flutter/flutter/pull/123',
        ),
      ).called(1);

      // Reconciling a second time when already completed/neutral skips GitHub PATCH.
      final secondResult = await reconciler.reconcilePullRequest(
        slug,
        prNumber,
      );
      expect(secondResult, isA<WantLgtmReconcileSuccess>());
      verifyNoMoreInteractions(mockGithubChecksUtil);
    });

    test(
      'waives check run to neutral when PR is closed while in_progress',
      () async {
        final existingState = WantLgtmState.initialize(
          slug: slug,
          pr: prNumber,
          headSha: headSha,
          checkRunId: 555010,
          checkRunStatus: 'in_progress',
          checkRunTitle: 'Waiting on alice',
          directive: 'alice',
        );
        firestoreService.putDocument(existingState);

        fakeGraphQLClient.queryResultForOptions = (QueryOptions options) {
          return createFakeQueryResult(
            data: createSnapshotResponse(
              state: 'CLOSED',
              body: 'WANT_LGTM=alice',
            ),
          );
        };

        when(
          mockGithubChecksUtil.updateCheckRun(
            any,
            any,
            any,
            output: anyNamed('output'),
            conclusion: anyNamed('conclusion'),
            status: anyNamed('status'),
            detailsUrl: anyNamed('detailsUrl'),
          ),
        ).thenAnswer((_) async {});

        final result = await reconciler.reconcilePullRequest(slug, prNumber);
        expect(result, isA<WantLgtmReconcileSuccess>());
        final success = result as WantLgtmReconcileSuccess;
        expect(success.verdict.title, 'WANT_LGTM: waived (PR closed)');
        expect(success.state.checkRunStatus, 'completed');
        expect(success.state.checkRunConclusion, 'neutral');

        verify(
          mockGithubChecksUtil.updateCheckRun(
            config,
            slug,
            argThat(isA<github.CheckRun>().having((c) => c.id, 'id', 555010)),
            output: anyNamed('output'),
            conclusion: github.CheckRunConclusion.neutral,
            status: github.CheckRunStatus.completed,
            detailsUrl: 'https://github.com/flutter/flutter/pull/123',
          ),
        ).called(1);
      },
    );

    test(
      'reconcileMergeGroup creates waived check run on merge commit',
      () async {
        when(
          mockGithubChecksUtil.createCheckRun(
            any,
            any,
            any,
            any,
            output: anyNamed('output'),
            conclusion: anyNamed('conclusion'),
            status: anyNamed('status'),
            detailsUrl: anyNamed('detailsUrl'),
          ),
        ).thenAnswer((_) async => WantLgtmCheckWriter.checkRunWithId(555003));

        final checkRun = await reconciler.reconcileMergeGroup(
          slug: slug,
          prNumber: prNumber,
          mergeGroupSha: 'merge_group_commit_sha',
        );

        expect(checkRun.id, 555003);
        verify(
          mockGithubChecksUtil.createCheckRun(
            config,
            slug,
            'merge_group_commit_sha',
            Config.kWantLgtmCheckName,
            status: github.CheckRunStatus.completed,
            conclusion: github.CheckRunConclusion.neutral,
            detailsUrl: 'https://github.com/flutter/flutter/pull/123',
            output: anyNamed('output'),
          ),
        ).called(1);
      },
    );
  });
}
