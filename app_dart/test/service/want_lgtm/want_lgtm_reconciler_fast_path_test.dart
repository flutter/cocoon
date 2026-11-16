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

    config.rollerAccountsValue = const <String>{'engine-flutter-autoroll'};
    config.dynamicConfig = DynamicConfig(
      wantLgtm: WantLgtmFlags(
        enabled: true,
        useForAllRepos: false,
        enabledRepos: ['flutter/flutter'],
      ),
    );
  });

  group('WantLgtmReconciler fast-paths', () {
    final slug = github.RepositorySlug('flutter', 'flutter');
    const prNumber = 123;
    const headSha = 'head_sha_123';

    test(
      'closed PR with in_progress state skips without mutating check run',
      () async {
        final existing = WantLgtmState.initialize(
          slug: slug,
          pr: prNumber,
          headSha: headSha,
          checkRunId: 777001,
          checkRunStatus: 'in_progress',
          checkRunTitle: 'Waiting on alice',
          directive: 'alice',
        );
        firestoreService.putDocument(existing);

        final pr = github.PullRequest(
          number: prNumber,
          state: 'closed',
          head: github.PullRequestHead(sha: headSha),
        );

        final result = await reconciler.reconcilePullRequest(
          slug,
          prNumber,
          pullRequest: pr,
        );
        expect(result, isA<WantLgtmReconcileSkipped>());
        final skipped = result as WantLgtmReconcileSkipped;
        expect(skipped.reason, 'PR is closed or merged');
        verifyZeroInteractions(mockGithubChecksUtil);
      },
    );

    test('closed PR without existing state returns skipped', () async {
      final pr = github.PullRequest(number: prNumber, state: 'closed');
      final result = await reconciler.reconcilePullRequest(
        slug,
        prNumber,
        pullRequest: pr,
      );
      expect(result, isA<WantLgtmReconcileSkipped>());
      final skipped = result as WantLgtmReconcileSkipped;
      expect(skipped.reason, 'PR is closed or merged');
    });

    test(
      'invalid directive writes failure check run without GraphQL',
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
        ).thenAnswer((_) async => WantLgtmCheckWriter.checkRunWithId(777002));

        final pr = github.PullRequest(
          number: prNumber,
          state: 'open',
          body: 'WANT_LGTM=bad/user',
          user: github.User(login: 'author1'),
          head: github.PullRequestHead(sha: headSha),
        );

        final result = await reconciler.reconcilePullRequest(
          slug,
          prNumber,
          pullRequest: pr,
        );
        expect(result, isA<WantLgtmReconcileSuccess>());
        final success = result as WantLgtmReconcileSuccess;
        expect(success.verdict, isA<WantLgtmInvalid>());
        expect(success.state.checkRunConclusion, 'failure');
        expect(success.state.checkRunStatus, 'completed');

        verify(
          mockGithubChecksUtil.createCheckRun(
            config,
            slug,
            headSha,
            Config.kWantLgtmCheckName,
            status: github.CheckRunStatus.completed,
            conclusion: github.CheckRunConclusion.failure,
            detailsUrl: anyNamed('detailsUrl'),
            output: anyNamed('output'),
          ),
        ).called(1);
      },
    );

    test('directive removed with existing state waives check run', () async {
      final existing = WantLgtmState.initialize(
        slug: slug,
        pr: prNumber,
        headSha: headSha,
        checkRunId: 777003,
        checkRunStatus: 'in_progress',
        checkRunTitle: 'Waiting on alice',
        directive: 'alice',
      );
      firestoreService.putDocument(existing);

      final pr = github.PullRequest(
        number: prNumber,
        state: 'open',
        body: 'Just a PR description without directive',
        user: github.User(login: 'author1'),
        head: github.PullRequestHead(sha: headSha),
      );

      final result = await reconciler.reconcilePullRequest(
        slug,
        prNumber,
        pullRequest: pr,
      );
      expect(result, isA<WantLgtmReconcileSuccess>());
      final success = result as WantLgtmReconcileSuccess;
      expect(success.verdict.title, 'WANT_LGTM: waived (directive removed)');
      expect(success.state.checkRunConclusion, 'neutral');

      verify(
        mockGithubChecksUtil.updateCheckRun(
          config,
          slug,
          argThat(isA<github.CheckRun>().having((c) => c.id, 'id', 777003)),
          output: anyNamed('output'),
          conclusion: github.CheckRunConclusion.neutral,
          status: github.CheckRunStatus.completed,
          detailsUrl: anyNamed('detailsUrl'),
        ),
      ).called(1);
    });

    test('no directive and no existing state skips', () async {
      final pr = github.PullRequest(
        number: prNumber,
        state: 'open',
        body: 'No directive here',
        user: github.User(login: 'author1'),
        head: github.PullRequestHead(sha: headSha),
      );

      final result = await reconciler.reconcilePullRequest(
        slug,
        prNumber,
        pullRequest: pr,
      );
      expect(result, isA<WantLgtmReconcileSkipped>());
      final skipped = result as WantLgtmReconcileSkipped;
      expect(skipped.reason, 'No WANT_LGTM directive declared');
    });
  });
}
