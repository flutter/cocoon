// Copyright 2025 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_common/task_status.dart';
import 'package:cocoon_integration_test/testing.dart';
import 'package:cocoon_server_test/test_logging.dart';
import 'package:cocoon_service/src/model/common/presubmit_guard_conclusion.dart';
import 'package:cocoon_service/src/model/common/presubmit_job_state.dart';
import 'package:cocoon_service/src/model/firestore/base.dart';
import 'package:cocoon_service/src/model/firestore/presubmit_guard.dart';
import 'package:cocoon_service/src/model/firestore/presubmit_job.dart';
import 'package:cocoon_service/src/service/firestore.dart';
import 'package:cocoon_service/src/service/firestore/unified_check_run.dart';
import 'package:cocoon_service/src/service/flags/dynamic_config.dart';
import 'package:github/github.dart';
import 'package:googleapis/firestore/v1.dart';
import 'package:test/test.dart';

void main() {
  useTestLoggerPerTest();

  late FakeConfig config;
  late FakeFirestoreService firestoreService;

  setUp(() {
    config = FakeConfig();
    firestoreService = FakeFirestoreService();
  });

  group('UnifiedCheckRun', () {
    final slug = RepositorySlug('flutter', 'flutter');
    final checkRun = CheckRun.fromJson({
      'id': 123,
      'name': 'check_run',
      'head_sha': 'context_sha',
      'started_at': DateTime.now().toIso8601String(),
      'check_suite': {'id': 456},
    });
    final pullRequest = generatePullRequest(
      id: 789,
      authorLogin: 'dash',
      number: 1,
    );
    const sha = 'sha';

    group('initializeCiStagingDocument', () {
      test('creates PresubmitGuard and Checks when enabled for user', () async {
        config.dynamicConfig = DynamicConfig.fromJson({
          'unifiedCheckRunFlow': {
            'useForUsers': ['dash'],
          },
        });

        await UnifiedCheckRun.initializeCiStagingDocument(
          firestoreService: firestoreService,
          slug: slug,
          sha: sha,
          stage: CiStage.fusionEngineBuild,
          tasks: ['linux', 'mac'],
          config: config,
          pullRequest: pullRequest,
          checkRun: checkRun,
        );

        final guardId = PresubmitGuard.documentIdFor(
          slug: slug,
          prNum: 1,
          checkRunId: 123,
          stage: CiStage.fusionEngineBuild,
        );
        final guardDoc = await firestoreService.getDocument(
          'projects/flutter-dashboard/databases/cocoon/documents/presubmit_guards/${guardId.documentId}',
        );
        expect(guardDoc.name, endsWith(guardId.documentId));

        final checkId = PresubmitJob.documentIdFor(
          slug: slug,
          checkRunId: 123,
          jobName: 'linux',
          attemptNumber: 1,
        );
        final checkDoc = await firestoreService.getDocument(
          'projects/flutter-dashboard/databases/cocoon/documents/presubmit_jobs/${checkId.documentId}',
        );
        expect(checkDoc.name, endsWith(checkId.documentId));
      });

      test('initializes CiStagingDocument when NOT enabled for user', () async {
        config.dynamicConfig = DynamicConfig.fromJson({
          'unifiedCheckRunFlow': {'useForUsers': <String>[]},
        });

        await UnifiedCheckRun.initializeCiStagingDocument(
          firestoreService: firestoreService,
          slug: slug,
          sha: sha,
          stage: CiStage.fusionEngineBuild,
          tasks: ['linux', 'mac'],
          config: config,
          pullRequest: pullRequest,
          checkRun: checkRun,
        );

        // Verify PresubmitGuard is NOT created
        final guardId = PresubmitGuard.documentIdFor(
          slug: slug,
          prNum: 1,
          checkRunId: 123,
          stage: CiStage.fusionEngineBuild,
        );
        expect(
          () => firestoreService.getDocument(
            'projects/flutter-dashboard/databases/cocoon/documents/presubmit_guards/${guardId.documentId}',
          ),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('markConclusion', () {
      late PresubmitGuardId guardId;

      setUp(() async {
        guardId = PresubmitGuardId(
          slug: slug,
          prNum: 1,
          checkRunId: 123,
          stage: CiStage.fusionEngineBuild,
        );

        // Initialize documents
        final guard = PresubmitGuard(
          checkRun: checkRun,
          headSha: sha,
          slug: slug,
          prNum: 1,
          stage: CiStage.fusionEngineBuild,
          creationTime: 1000,
          author: 'dash',
          jobs: {
            for (final task in ['linux', 'mac'])
              task: TaskStatus.waitingForBackfill,
          },
          remainingJobs: 2,
          failedJobs: 0,
        );

        final check1 = PresubmitJob.init(
          slug: slug,
          jobName: 'linux',
          checkRunId: guardId.checkRunId,
          creationTime: 1000,
        );
        final check2 = PresubmitJob.init(
          slug: slug,
          jobName: 'mac',
          checkRunId: guardId.checkRunId,
          creationTime: 1000,
        );

        await firestoreService.writeViaTransaction(
          documentsToWrites([
            Document(name: guard.name, fields: guard.fields),
            Document(name: check1.name, fields: check1.fields),
            Document(name: check2.name, fields: check2.fields),
          ], exists: false),
        );
      });

      test('updates check status and remaining count on success', () async {
        final state = const PresubmitJobState(
          jobName: 'linux',
          status: TaskStatus.succeeded,
          attemptNumber: 1,
          startTime: 2000,
          endTime: 3000,
          buildNumber: 456,
        );

        final result = await UnifiedCheckRun.markConclusion(
          firestoreService: firestoreService,
          guardId: guardId,
          state: state,
        );

        expect(result.result, PresubmitGuardConclusionResult.ok);
        expect(result.remaining, 1);
        expect(result.failed, 0);

        final checkDoc = await PresubmitJob.fromFirestore(
          firestoreService,
          PresubmitJobId(
            slug: slug,
            checkRunId: 123,
            jobName: 'linux',
            attemptNumber: 1,
          ),
        );
        expect(checkDoc.status, TaskStatus.succeeded);
        expect(checkDoc.endTime, 3000);
        expect(checkDoc.buildNumber, 456);
      });

      test(
        'update all check status to succeeded lead to complete guard',
        () async {
          final result1 = await UnifiedCheckRun.markConclusion(
            firestoreService: firestoreService,
            guardId: guardId,
            state: const PresubmitJobState(
              jobName: 'linux',
              status: TaskStatus.succeeded,
              attemptNumber: 1,
              startTime: 2000,
              endTime: 3000,
            ),
          );

          expect(result1.remaining, 1);
          expect(result1.failed, 0);
          expect(result1.isOk, true);
          expect(result1.isComplete, false);
          expect(result1.isPending, true);

          final result2 = await UnifiedCheckRun.markConclusion(
            firestoreService: firestoreService,
            guardId: guardId,
            state: const PresubmitJobState(
              jobName: 'mac',
              status: TaskStatus.succeeded,
              attemptNumber: 1,
              startTime: 2000,
              endTime: 3000,
            ),
          );

          expect(result2.remaining, 0);
          expect(result2.failed, 0);
          expect(result2.isOk, true);
          expect(result2.isComplete, true);
          expect(result2.isPending, false);

          final checkDoc = await PresubmitJob.fromFirestore(
            firestoreService,
            PresubmitJobId(
              slug: slug,
              checkRunId: 123,
              jobName: 'linux',
              attemptNumber: 1,
            ),
          );
          expect(checkDoc.status, TaskStatus.succeeded);
          expect(checkDoc.endTime, 3000);
        },
      );

      test('updates check status and failed count on failure', () async {
        final state = const PresubmitJobState(
          jobName: 'linux',
          status: TaskStatus.failed,
          attemptNumber: 1,
          startTime: 2000,
          endTime: 3000,
        );

        final result = await UnifiedCheckRun.markConclusion(
          firestoreService: firestoreService,
          guardId: guardId,
          state: state,
        );

        expect(result.result, PresubmitGuardConclusionResult.ok);
        expect(result.remaining, 1);
        expect(result.failed, 1);
      });

      test('handles missing check gracefully', () async {
        final state = const PresubmitJobState(
          jobName: 'windows', // Missing
          status: TaskStatus.succeeded,
          attemptNumber: 1,
        );

        final result = await UnifiedCheckRun.markConclusion(
          firestoreService: firestoreService,
          guardId: guardId,
          state: state,
        );

        expect(result.result, PresubmitGuardConclusionResult.missing);
      });
      test('updates check status and build number on inProgress', () async {
        final state = const PresubmitJobState(
          jobName: 'linux',
          status: TaskStatus.inProgress,
          attemptNumber: 1,
          startTime: 2000,
          buildNumber: 456,
        );

        final result = await UnifiedCheckRun.markConclusion(
          firestoreService: firestoreService,
          guardId: guardId,
          state: state,
        );

        expect(result.result, PresubmitGuardConclusionResult.ok);

        final checkDoc = await PresubmitJob.fromFirestore(
          firestoreService,
          PresubmitJobId(
            slug: slug,
            checkRunId: 123,
            jobName: 'linux',
            attemptNumber: 1,
          ),
        );
        expect(checkDoc.status, TaskStatus.inProgress);
        expect(checkDoc.startTime, 2000);
        expect(checkDoc.buildNumber, 456);
      });
    });
    group('reInitializeFailedChecks', () {
      late PresubmitGuardId fusionGuardId;

      setUp(() async {
        fusionGuardId = PresubmitGuardId(
          slug: slug,
          prNum: 1,
          checkRunId: 123,
          stage: CiStage.fusionTests,
        );

        // Initialize documents
        final guard = PresubmitGuard(
          checkRun: checkRun,
          headSha: sha,
          slug: slug,
          prNum: 1,
          stage: CiStage.fusionTests,
          creationTime: 1000,
          author: 'dash',
          jobs: {'linux': TaskStatus.failed, 'mac': TaskStatus.succeeded},
          remainingJobs: 0,
          failedJobs: 1,
        );

        final check1 = PresubmitJob(
          slug: slug,
          jobName: 'linux',
          checkRunId: fusionGuardId.checkRunId,
          creationTime: 1000,
          status: TaskStatus.failed,
          attemptNumber: 1,
        );

        final check2 = PresubmitJob(
          slug: slug,
          jobName: 'mac',
          checkRunId: fusionGuardId.checkRunId,
          creationTime: 1000,
          status: TaskStatus.succeeded,
          attemptNumber: 1,
        );

        await firestoreService.writeViaTransaction(
          documentsToWrites([
            Document(name: guard.name, fields: guard.fields),
            Document(name: check1.name, fields: check1.fields),
            Document(name: check2.name, fields: check2.fields),
          ], exists: false),
        );
      });

      test('updates fusion failed checks and remaining count', () async {
        final result = await UnifiedCheckRun.reInitializeFailedJobs(
          firestoreService: firestoreService,
          slug: slug,
          prNum: pullRequest.number!,
          guardCheckRunId: 123,
        );
        expect(result, isNotNull);
        expect(result!.jobRetries, containsPair('linux', 2));
        expect(result.jobRetries.keys, isNot(contains('mac')));
        expect(result.stage, CiStage.fusionTests);

        final guardDoc = await firestoreService.getDocument(
          'projects/flutter-dashboard/databases/cocoon/documents/presubmit_guards/${fusionGuardId.documentId}',
        );
        final guard = PresubmitGuard.fromDocument(guardDoc);

        expect(guard.failedJobs, 0);
        expect(guard.remainingJobs, 1);
        expect(guard.jobs['linux'], TaskStatus.waitingForBackfill);
        expect(guard.jobs['mac'], TaskStatus.succeeded);

        // Verify new check document created with incremented attempt number
        final checkDoc = await PresubmitJob.fromFirestore(
          firestoreService,
          PresubmitJobId(
            slug: slug,
            checkRunId: 123,
            jobName: 'linux',
            attemptNumber: 2,
          ),
        );
        expect(checkDoc.status, TaskStatus.waitingForBackfill);
        expect(checkDoc.attemptNumber, 2);
      });

      test('properly handle if engine and fusion guards are present', () async {
        final engineGuardId = PresubmitGuardId(
          slug: slug,
          prNum: 1,
          checkRunId: 123,
          stage: CiStage.fusionEngineBuild,
        );

        // Initialize documents
        final guard = PresubmitGuard(
          checkRun: checkRun,
          headSha: sha,
          slug: slug,
          prNum: 1,
          stage: CiStage.fusionEngineBuild,
          creationTime: 1000,
          author: 'dash',
          jobs: {'win': TaskStatus.succeeded, 'ios': TaskStatus.succeeded},
          remainingJobs: 0,
          failedJobs: 0,
        );

        final check1 = PresubmitJob(
          slug: slug,
          jobName: 'win',
          checkRunId: engineGuardId.checkRunId,
          creationTime: 1000,
          status: TaskStatus.succeeded,
          attemptNumber: 1,
        );

        final check2 = PresubmitJob(
          slug: slug,
          jobName: 'ios',
          checkRunId: engineGuardId.checkRunId,
          creationTime: 1000,
          status: TaskStatus.succeeded,
          attemptNumber: 1,
        );

        await firestoreService.writeViaTransaction(
          documentsToWrites([
            Document(name: guard.name, fields: guard.fields),
            Document(name: check1.name, fields: check1.fields),
            Document(name: check2.name, fields: check2.fields),
          ], exists: false),
        );

        final result = await UnifiedCheckRun.reInitializeFailedJobs(
          firestoreService: firestoreService,
          slug: slug,
          prNum: pullRequest.number!,
          guardCheckRunId: 123,
        );
        expect(result, isNotNull);
        expect(result!.jobRetries, containsPair('linux', 2));
        expect(result.jobRetries.keys, isNot(contains('mac')));
        expect(result.stage, CiStage.fusionTests);

        final guardDoc = await firestoreService.getDocument(
          'projects/flutter-dashboard/databases/cocoon/documents/presubmit_guards/${fusionGuardId.documentId}',
        );
        final restartedGuard = PresubmitGuard.fromDocument(guardDoc);

        expect(restartedGuard.failedJobs, 0);
        expect(restartedGuard.remainingJobs, 1);
        expect(restartedGuard.jobs['linux'], TaskStatus.waitingForBackfill);
        expect(restartedGuard.jobs['mac'], TaskStatus.succeeded);

        // Verify new check document created with incremented attempt number
        final checkDoc = await PresubmitJob.fromFirestore(
          firestoreService,
          PresubmitJobId(
            slug: slug,
            checkRunId: 123,
            jobName: 'linux',
            attemptNumber: 2,
          ),
        );
        expect(checkDoc.status, TaskStatus.waitingForBackfill);
        expect(checkDoc.attemptNumber, 2);
      });

      test('returns null when no failed checks', () async {
        // Update setup to have no failed checks
        var guardDoc = await firestoreService.getDocument(
          'projects/flutter-dashboard/databases/cocoon/documents/presubmit_guards/${fusionGuardId.documentId}',
        );
        final guard = PresubmitGuard.fromDocument(guardDoc);
        final builds = guard.jobs;
        builds['linux'] = TaskStatus.succeeded;
        guard.jobs = builds;
        guard.failedJobs = 0;
        await firestoreService.writeViaTransaction(
          documentsToWrites([guard], exists: true),
        );

        final result = await UnifiedCheckRun.reInitializeFailedJobs(
          firestoreService: firestoreService,
          slug: slug,
          prNum: pullRequest.number!,
          guardCheckRunId: 123,
        );
        expect(result, isNull);

        guardDoc = await firestoreService.getDocument(
          'projects/flutter-dashboard/databases/cocoon/documents/presubmit_guards/${fusionGuardId.documentId}',
        );
        final updatedGuard = PresubmitGuard.fromDocument(guardDoc);
        // Should remain unchanged
        expect(updatedGuard.failedJobs, 0);
        expect(updatedGuard.remainingJobs, 0);
      });
    });

    test('getLatestPresubmitGuardForCheckRun returns latest guard', () async {
      final sha = 'sha';
      final slug = RepositorySlug('flutter', 'flutter');
      final checkRun = CheckRun.fromJson(const {
        'id': 123,
        'name': 'check_run',
        'started_at': '2020-05-12T00:00:00.000Z',
        'check_suite': {'id': 456},
      });

      final guard1 = PresubmitGuard(
        checkRun: checkRun,
        headSha: sha,
        slug: slug,
        prNum: 1,
        stage: CiStage.fusionEngineBuild,
        creationTime: 1000,
        author: 'dash',
        remainingJobs: 1,
        failedJobs: 0,
        jobs: {'linux': TaskStatus.succeeded},
      );

      final guard2 = PresubmitGuard(
        checkRun: checkRun,
        headSha: sha,
        slug: slug,
        prNum: 1,
        stage: CiStage.fusionTests,
        creationTime: 2000,
        author: 'dash',
        remainingJobs: 1,
        failedJobs: 0,
        jobs: {'mac': TaskStatus.succeeded},
      );

      await firestoreService.writeViaTransaction(
        documentsToWrites([
          Document(name: guard2.name, fields: guard2.fields),
          Document(name: guard1.name, fields: guard1.fields),
        ], exists: false),
      );

      final guard = await UnifiedCheckRun.getLatestPresubmitGuardForCheckRun(
        firestoreService: firestoreService,
        slug: slug,
        prNum: 1,
        checkRunId: 123,
      );

      expect(guard, isNotNull);
      expect(guard!.stage, CiStage.fusionTests);
      expect(guard.checkRunId, 123);
    });

    test(
      'getLatestPresubmitGuardByPullRequestNum returns latest guard',
      () async {
        final guard1 = generatePresubmitGuard(
          checkRun: generateCheckRun(1),
          headSha: 'abc',
          prNum: 5678,
          creationTime: 1000,
        );
        final guard2 = generatePresubmitGuard(
          checkRun: generateCheckRun(2),
          headSha: 'abc',
          prNum: 5678,
          creationTime: 2000,
        );

        firestoreService.putDocument(guard1);
        firestoreService.putDocument(guard2);

        final result = await UnifiedCheckRun.getLatestPresubmitGuardForPrNum(
          firestoreService: firestoreService,
          slug: slug,
          prNum: 5678,
        );
        expect(result!.checkRunId, 2);
      },
    );

    test('getPresubmitJobDetails returns all attempts sorted', () async {
      final check1 = PresubmitJob(
        slug: slug,
        checkRunId: 1234,
        jobName: 'linux_test',
        status: TaskStatus.succeeded,
        attemptNumber: 1,
        creationTime: 100,
        startTime: 110,
        endTime: 120,
        summary: 'attempt 1',
      );
      final check2 = PresubmitJob(
        slug: slug,
        checkRunId: 1234,
        jobName: 'linux_test',
        status: TaskStatus.failed,
        attemptNumber: 2,
        creationTime: 200,
        startTime: 210,
        endTime: 220,
        summary: 'attempt 2',
      );
      await firestoreService.writeViaTransaction(
        documentsToWrites([check1, check2], exists: false),
      );

      final attempts = await UnifiedCheckRun.getPresubmitJobDetails(
        firestoreService: firestoreService,
        checkRunId: 1234,
        jobName: 'linux_test',
      );

      expect(attempts.length, 2);
      expect(attempts[0].attemptNumber, 2);
      expect(attempts[0].summary, 'attempt 2');
      expect(attempts[1].attemptNumber, 1);
      expect(attempts[1].summary, 'attempt 1');
    });
  });
}
