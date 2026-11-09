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
import 'package:cocoon_service/src/service/want_lgtm/want_lgtm_models.dart';
import 'package:github/github.dart' as github;
import 'package:github/github.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

void main() {
  useTestLoggerPerTest();

  late FakeConfig config;
  late MockGithubChecksUtil mockGithubChecksUtil;
  late FakeFirestoreService firestoreService;
  late WantLgtmCheckWriter checkWriter;

  setUp(() {
    config = FakeConfig();
    mockGithubChecksUtil = MockGithubChecksUtil();
    firestoreService = FakeFirestoreService();
    checkWriter = WantLgtmCheckWriter(
      config: config,
      githubChecksUtil: mockGithubChecksUtil,
      firestoreService: firestoreService,
    );
  });

  group('WantLgtmCheckWriter', () {
    final slug = RepositorySlug('flutter', 'flutter');
    const prNumber = 12345;
    const headSha = 'abc123def456';

    test(
      'creates new check run and persists state for WantLgtmSatisfied',
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
        ).thenAnswer((_) async => WantLgtmCheckWriter.checkRunWithId(999001));

        const verdict = WantLgtmSatisfied(
          approvedBy: ['alice'],
          latestApprovalAt: null,
          title: 'WANT_LGTM: satisfied',
          summary: 'All required reviewers approved.',
        );

        final state = await checkWriter.writePrVerdict(
          slug: slug,
          prNumber: prNumber,
          headSha: headSha,
          verdict: verdict,
          directive: 'all',
        );

        expect(state.slug, slug);
        expect(state.pr, prNumber);
        expect(state.headSha, headSha);
        expect(state.checkRunId, 999001);
        expect(state.checkRunStatus, 'completed');
        expect(state.checkRunConclusion, 'success');
        expect(state.checkRunTitle, 'WANT_LGTM: satisfied');
        expect(state.directive, 'all');

        verify(
          mockGithubChecksUtil.createCheckRun(
            config,
            slug,
            headSha,
            Config.kWantLgtmCheckName,
            status: github.CheckRunStatus.completed,
            conclusion: github.CheckRunConclusion.success,
            detailsUrl: 'https://github.com/flutter/flutter/pull/12345',
            output: argThat(
              isA<github.CheckRunOutput>().having(
                (o) => o.title,
                'title',
                'WANT_LGTM: satisfied',
              ),
              named: 'output',
            ),
          ),
        ).called(1);

        final saved = await WantLgtmState.fromFirestoreOrNull(
          firestoreService: firestoreService,
          slug: slug,
          pr: prNumber,
        );
        expect(saved, isNotNull);
        expect(saved!.checkRunId, 999001);
      },
    );

    test(
      'creates in_progress check run with null conclusion for WantLgtmPending',
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
        ).thenAnswer((_) async => WantLgtmCheckWriter.checkRunWithId(999002));

        const verdict = WantLgtmPending(
          waitingOn: ['alice'],
          changesRequestedBy: [],
          title: 'Waiting on alice',
          summary: '- alice: waiting for review',
        );

        final state = await checkWriter.writePrVerdict(
          slug: slug,
          prNumber: prNumber,
          headSha: headSha,
          verdict: verdict,
        );

        expect(state.checkRunStatus, 'in_progress');
        expect(state.checkRunConclusion, isNull);
        expect(state.checkRunTitle, 'Waiting on alice');

        verify(
          mockGithubChecksUtil.createCheckRun(
            config,
            slug,
            headSha,
            Config.kWantLgtmCheckName,
            status: github.CheckRunStatus.inProgress,
            conclusion: argThat(isNull, named: 'conclusion'),
            detailsUrl: 'https://github.com/flutter/flutter/pull/12345',
            output: anyNamed('output'),
          ),
        ).called(1);
      },
    );

    test('creates completed failure check run for WantLgtmInvalid', () async {
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
      ).thenAnswer((_) async => WantLgtmCheckWriter.checkRunWithId(999003));

      const verdict = WantLgtmInvalid(
        invalidTokens: ['@flutter/engine'],
        title: 'WANT_LGTM: invalid syntax',
        summary: 'Invalid reviewer login: @flutter/engine',
      );

      final state = await checkWriter.writePrVerdict(
        slug: slug,
        prNumber: prNumber,
        headSha: headSha,
        verdict: verdict,
      );

      expect(state.checkRunStatus, 'completed');
      expect(state.checkRunConclusion, 'failure');
      expect(state.checkRunTitle, 'WANT_LGTM: invalid syntax');

      verify(
        mockGithubChecksUtil.createCheckRun(
          config,
          slug,
          headSha,
          Config.kWantLgtmCheckName,
          status: github.CheckRunStatus.completed,
          conclusion: github.CheckRunConclusion.failure,
          detailsUrl: 'https://github.com/flutter/flutter/pull/12345',
          output: anyNamed('output'),
        ),
      ).called(1);
    });

    test('updates existing check run when headSha matches', () async {
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

      final existingState = WantLgtmState.initialize(
        slug: slug,
        pr: prNumber,
        headSha: headSha,
        checkRunId: 777111,
        checkRunStatus: 'in_progress',
        checkRunTitle: 'Waiting on bob',
      );
      firestoreService.putDocument(existingState);

      const verdict = WantLgtmSatisfied(
        approvedBy: ['bob'],
        latestApprovalAt: null,
        title: 'WANT_LGTM: satisfied',
        summary: 'bob approved.',
      );

      final state = await checkWriter.writePrVerdict(
        slug: slug,
        prNumber: prNumber,
        headSha: headSha,
        verdict: verdict,
        existingState: existingState,
      );

      expect(state.checkRunId, 777111);
      expect(state.checkRunStatus, 'completed');
      expect(state.checkRunConclusion, 'success');
      expect(state.checkRunTitle, 'WANT_LGTM: satisfied');

      verify(
        mockGithubChecksUtil.updateCheckRun(
          config,
          slug,
          argThat(isA<github.CheckRun>().having((c) => c.id, 'id', 777111)),
          status: github.CheckRunStatus.completed,
          conclusion: github.CheckRunConclusion.success,
          detailsUrl: 'https://github.com/flutter/flutter/pull/12345',
          output: anyNamed('output'),
        ),
      ).called(1);
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
    });

    test('creates new check run when headSha changes', () async {
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
      ).thenAnswer((_) async => WantLgtmCheckWriter.checkRunWithId(888222));

      final existingState = WantLgtmState.initialize(
        slug: slug,
        pr: prNumber,
        headSha: 'old_sha_000',
        checkRunId: 777111,
        checkRunStatus: 'completed',
        checkRunTitle: 'WANT_LGTM: satisfied',
      );

      const verdict = WantLgtmPending(
        waitingOn: ['alice'],
        changesRequestedBy: [],
        title: 'Waiting on alice',
        summary: 'New commit added.',
      );

      final state = await checkWriter.writePrVerdict(
        slug: slug,
        prNumber: prNumber,
        headSha: 'new_sha_999',
        verdict: verdict,
        existingState: existingState,
      );

      expect(state.checkRunId, 888222);
      expect(state.headSha, 'new_sha_999');
      expect(state.checkRunStatus, 'in_progress');

      verify(
        mockGithubChecksUtil.createCheckRun(
          config,
          slug,
          'new_sha_999',
          Config.kWantLgtmCheckName,
          status: github.CheckRunStatus.inProgress,
          conclusion: argThat(isNull, named: 'conclusion'),
          detailsUrl: 'https://github.com/flutter/flutter/pull/12345',
          output: anyNamed('output'),
        ),
      ).called(1);
    });

    test(
      'creates new check run when existingState is completed and verdict is pending (same-SHA reopen)',
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
        ).thenAnswer((_) async => WantLgtmCheckWriter.checkRunWithId(999888));

        final existingState = WantLgtmState.initialize(
          slug: slug,
          pr: prNumber,
          headSha: headSha,
          checkRunId: 777111,
          checkRunStatus: 'completed',
          checkRunConclusion: 'success',
          checkRunTitle: 'WANT_LGTM satisfied',
        );

        const verdict = WantLgtmPending(
          waitingOn: ['alice'],
          changesRequestedBy: [],
          title: 'Waiting on alice',
          summary: 'Alice was re-requested',
        );

        final state = await checkWriter.writePrVerdict(
          slug: slug,
          prNumber: prNumber,
          headSha: headSha,
          verdict: verdict,
          existingState: existingState,
        );

        expect(state.checkRunId, 999888);
        expect(state.checkRunStatus, 'in_progress');
        expect(state.checkRunConclusion, isNull);

        verify(
          mockGithubChecksUtil.createCheckRun(
            config,
            slug,
            headSha,
            Config.kWantLgtmCheckName,
            status: github.CheckRunStatus.inProgress,
            conclusion: argThat(isNull, named: 'conclusion'),
            detailsUrl: 'https://github.com/flutter/flutter/pull/12345',
            output: anyNamed('output'),
          ),
        ).called(1);
        verifyNever(
          mockGithubChecksUtil.updateCheckRun(
            any,
            any,
            any,
            status: anyNamed('status'),
            conclusion: anyNamed('conclusion'),
            detailsUrl: anyNamed('detailsUrl'),
            output: anyNamed('output'),
          ),
        );
      },
    );

    test(
      'suppresses updateCheckRun and save when fields are unchanged',
      () async {
        final existingState = WantLgtmState.initialize(
          slug: slug,
          pr: prNumber,
          headSha: headSha,
          checkRunId: 777111,
          checkRunStatus: 'completed',
          checkRunConclusion: 'success',
          checkRunTitle: 'WANT_LGTM: satisfied',
          directive: 'alice',
        );

        const verdict = WantLgtmSatisfied(
          approvedBy: ['alice'],
          latestApprovalAt: null,
          title: 'WANT_LGTM: satisfied',
          summary: 'alice approved.',
        );

        final state = await checkWriter.writePrVerdict(
          slug: slug,
          prNumber: prNumber,
          headSha: headSha,
          verdict: verdict,
          existingState: existingState,
          directive: 'alice',
        );

        expect(state.checkRunId, 777111);
        verifyNever(
          mockGithubChecksUtil.updateCheckRun(
            any,
            any,
            any,
            status: anyNamed('status'),
            conclusion: anyNamed('conclusion'),
            detailsUrl: anyNamed('detailsUrl'),
            output: anyNamed('output'),
          ),
        );
      },
    );

    test(
      'writeMergeGroupVerdict creates completed neutral check run',
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
        ).thenAnswer((_) async => WantLgtmCheckWriter.checkRunWithId(333444));

        final checkRun = await checkWriter.writeMergeGroupVerdict(
          slug: slug,
          prNumber: prNumber,
          mergeGroupSha: 'merge_sha_123',
        );

        expect(checkRun.id, 333444);
        verify(
          mockGithubChecksUtil.createCheckRun(
            config,
            slug,
            'merge_sha_123',
            Config.kWantLgtmCheckName,
            status: github.CheckRunStatus.completed,
            conclusion: github.CheckRunConclusion.neutral,
            detailsUrl: 'https://github.com/flutter/flutter/pull/12345',
            output: argThat(
              isA<github.CheckRunOutput>().having(
                (o) => o.title,
                'title',
                'WANT_LGTM: satisfied (waived in merge group)',
              ),
              named: 'output',
            ),
          ),
        ).called(1);
      },
    );

    test(
      'writeWaivedCheckRun updates existingState checkRunId, headSha, and clears directive',
      () async {
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

        final existingState = WantLgtmState.initialize(
          slug: slug,
          pr: prNumber,
          headSha: 'old_sha_111',
          checkRunId: 111222,
          checkRunStatus: 'in_progress',
          checkRunTitle: 'Waiting on alice',
          directive: 'alice',
        );
        firestoreService.putDocument(existingState);

        final state = await checkWriter.writeWaivedCheckRun(
          slug: slug,
          prNumber: prNumber,
          checkRunId: 333444,
          headSha: 'new_sha_222',
          reason: 'PR closed',
          existingState: existingState,
        );

        expect(state.checkRunId, 333444);
        expect(state.headSha, 'new_sha_222');
        expect(state.checkRunStatus, 'completed');
        expect(state.checkRunConclusion, 'neutral');
        expect(state.checkRunTitle, 'WANT_LGTM: waived (PR closed)');
        expect(state.directive, isNull);

        final saved = await WantLgtmState.fromFirestoreOrNull(
          firestoreService: firestoreService,
          slug: slug,
          pr: prNumber,
        );
        expect(saved, isNotNull);
        expect(saved!.checkRunId, 333444);
        expect(saved.headSha, 'new_sha_222');
        expect(saved.directive, isNull);
      },
    );

    test(
      'writeRolledBackCheckRun updates existingState checkRunId and headSha',
      () async {
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

        final existingState = WantLgtmState.initialize(
          slug: slug,
          pr: prNumber,
          headSha: 'old_sha_111',
          checkRunId: 111222,
          checkRunStatus: 'in_progress',
          checkRunTitle: 'Waiting on alice',
          directive: 'alice',
        );
        firestoreService.putDocument(existingState);

        final state = await checkWriter.writeRolledBackCheckRun(
          slug: slug,
          prNumber: prNumber,
          checkRunId: 555666,
          headSha: 'new_sha_222',
          existingState: existingState,
        );

        expect(state.checkRunId, 555666);
        expect(state.headSha, 'new_sha_222');
        expect(state.checkRunStatus, 'completed');
        expect(state.checkRunConclusion, 'neutral');
        expect(state.checkRunTitle, 'WANT_LGTM: waived (feature rolled back)');

        final saved = await WantLgtmState.fromFirestoreOrNull(
          firestoreService: firestoreService,
          slug: slug,
          pr: prNumber,
        );
        expect(saved, isNotNull);
        expect(saved!.checkRunId, 555666);
        expect(saved.headSha, 'new_sha_222');
      },
    );

    test(
      'writeRolledBackCheckRun patches check run to completed neutral waived',
      () async {
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

        final state = await checkWriter.writeRolledBackCheckRun(
          slug: slug,
          prNumber: prNumber,
          checkRunId: 555666,
          headSha: headSha,
        );

        expect(state.checkRunStatus, 'completed');
        expect(state.checkRunConclusion, 'neutral');
        expect(state.checkRunTitle, 'WANT_LGTM: waived (feature rolled back)');

        verify(
          mockGithubChecksUtil.updateCheckRun(
            config,
            slug,
            argThat(isA<github.CheckRun>().having((c) => c.id, 'id', 555666)),
            status: github.CheckRunStatus.completed,
            conclusion: github.CheckRunConclusion.neutral,
            detailsUrl: 'https://github.com/flutter/flutter/pull/12345',
            output: anyNamed('output'),
          ),
        ).called(1);
      },
    );

    test(
      'sweepInProgressRuns sweeps in-progress runs on disabled repos as neutral',
      () async {
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

        final doc = WantLgtmState.initialize(
          slug: slug,
          pr: prNumber,
          headSha: headSha,
          checkRunId: 555777,
          checkRunStatus: 'in_progress',
          checkRunTitle: 'Waiting on bob',
        );
        firestoreService.putDocument(doc);

        final count = await checkWriter.sweepInProgressRuns();
        expect(count, 1);

        final updated = await WantLgtmState.fromFirestoreOrNull(
          firestoreService: firestoreService,
          slug: slug,
          pr: prNumber,
        );
        expect(updated?.checkRunStatus, 'completed');
        expect(updated?.checkRunConclusion, 'neutral');
      },
    );

    test(
      'sweepInProgressRuns skips repositories where wantLgtm is still enabled',
      () async {
        config.dynamicConfig = DynamicConfig(
          wantLgtm: WantLgtmFlags(
            enabled: true,
            useForAllRepos: false,
            enabledRepos: ['flutter/cocoon'],
          ),
        );

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

        final cocoonSlug = RepositorySlug('flutter', 'cocoon');
        firestoreService.putDocuments([
          WantLgtmState.initialize(
            slug: cocoonSlug,
            pr: 100,
            headSha: 'sha_cocoon',
            checkRunId: 555888,
            checkRunStatus: 'in_progress',
            checkRunTitle: 'Waiting on alice',
          ),
          WantLgtmState.initialize(
            slug: slug,
            pr: prNumber,
            headSha: headSha,
            checkRunId: 555999,
            checkRunStatus: 'in_progress',
            checkRunTitle: 'Waiting on bob',
          ),
        ]);

        final count = await checkWriter.sweepInProgressRuns();
        expect(count, 1);

        final cocoonState = await WantLgtmState.fromFirestoreOrNull(
          firestoreService: firestoreService,
          slug: cocoonSlug,
          pr: 100,
        );
        expect(cocoonState?.checkRunStatus, 'in_progress');

        final flutterState = await WantLgtmState.fromFirestoreOrNull(
          firestoreService: firestoreService,
          slug: slug,
          pr: prNumber,
        );
        expect(flutterState?.checkRunStatus, 'completed');
        expect(flutterState?.checkRunConclusion, 'neutral');
      },
    );

    test(
      'sweepInProgressRuns supports dryRun without mutating GitHub or Firestore',
      () async {
        firestoreService.putDocument(
          WantLgtmState.initialize(
            slug: slug,
            pr: prNumber,
            headSha: headSha,
            checkRunId: 555777,
            checkRunStatus: 'in_progress',
            checkRunTitle: 'Waiting on bob',
          ),
        );

        final count = await checkWriter.sweepInProgressRuns(dryRun: true);
        expect(count, 1);

        verifyNever(
          mockGithubChecksUtil.updateCheckRun(
            any,
            any,
            any,
            status: anyNamed('status'),
            conclusion: anyNamed('conclusion'),
            detailsUrl: anyNamed('detailsUrl'),
            output: anyNamed('output'),
          ),
        );

        final unchanged = await WantLgtmState.fromFirestoreOrNull(
          firestoreService: firestoreService,
          slug: slug,
          pr: prNumber,
        );
        expect(unchanged?.checkRunStatus, 'in_progress');
      },
    );

    test(
      'sweepInProgressRuns continues sweeping remaining PRs when one fails',
      () async {
        when(
          mockGithubChecksUtil.updateCheckRun(
            any,
            any,
            argThat(isA<github.CheckRun>().having((c) => c.id, 'id', 600001)),
            status: anyNamed('status'),
            conclusion: anyNamed('conclusion'),
            detailsUrl: anyNamed('detailsUrl'),
            output: anyNamed('output'),
          ),
        ).thenThrow(Exception('GitHub 500'));
        when(
          mockGithubChecksUtil.updateCheckRun(
            any,
            any,
            argThat(isA<github.CheckRun>().having((c) => c.id, 'id', 600002)),
            status: anyNamed('status'),
            conclusion: anyNamed('conclusion'),
            detailsUrl: anyNamed('detailsUrl'),
            output: anyNamed('output'),
          ),
        ).thenAnswer((_) async {});

        firestoreService.putDocuments([
          WantLgtmState.initialize(
            slug: slug,
            pr: 1,
            headSha: 'sha_1',
            checkRunId: 600001,
            checkRunStatus: 'in_progress',
            checkRunTitle: 'Waiting on alice',
          ),
          WantLgtmState.initialize(
            slug: slug,
            pr: 2,
            headSha: 'sha_2',
            checkRunId: 600002,
            checkRunStatus: 'in_progress',
            checkRunTitle: 'Waiting on bob',
          ),
        ]);

        final count = await checkWriter.sweepInProgressRuns();
        expect(count, 1);

        final pr1 = await WantLgtmState.fromFirestoreOrNull(
          firestoreService: firestoreService,
          slug: slug,
          pr: 1,
        );
        expect(pr1?.checkRunStatus, 'in_progress');

        final pr2 = await WantLgtmState.fromFirestoreOrNull(
          firestoreService: firestoreService,
          slug: slug,
          pr: 2,
        );
        expect(pr2?.checkRunStatus, 'completed');
        expect(pr2?.checkRunConclusion, 'neutral');
      },
    );
  });
}
