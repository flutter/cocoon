// Copyright 2025 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math';

import 'package:cocoon_common/task_status.dart';
import 'package:cocoon_server_test/test_logging.dart';
import 'package:cocoon_service/src/model/common/presubmit_check_state.dart';
import 'package:cocoon_service/src/model/common/presubmit_guard_conclusion.dart';
import 'package:cocoon_service/src/model/firestore/base.dart';
import 'package:cocoon_service/src/model/firestore/presubmit_check.dart';
import 'package:cocoon_service/src/model/firestore/presubmit_guard.dart';
import 'package:cocoon_service/src/service/firestore.dart';
import 'package:cocoon_service/src/service/firestore/unified_check_run.dart';
import 'package:cocoon_service/src/service/flags/dynamic_config.dart';
import 'package:github/github.dart';
import 'package:googleapis/firestore/v1.dart';
import 'package:test/test.dart';

import '../../src/fake_config.dart';
import '../../src/service/fake_firestore_service.dart';
import '../../src/utilities/entity_generators.dart';

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
          pullRequestId: 1,
          checkRunId: 123,
          stage: CiStage.fusionEngineBuild,
        );
        final guardDoc = await firestoreService.getDocument(
          'projects/flutter-dashboard/databases/cocoon/documents/presubmit_guards/${guardId.documentId}',
        );
        expect(guardDoc.name, endsWith(guardId.documentId));

        final checkId = PresubmitCheck.documentIdFor(
          checkRunId: 123,
          buildName: 'linux',
          attemptNumber: 1,
        );
        final checkDoc = await firestoreService.getDocument(
          'projects/flutter-dashboard/databases/cocoon/documents/presubmit_checks/${checkId.documentId}',
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
          pullRequestId: 1,
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
          pullRequestId: 1,
          checkRunId: 123,
          stage: CiStage.fusionEngineBuild,
        );

        // Initialize documents
        await UnifiedCheckRun.initializePresubmitGuardDocument(
          firestoreService: firestoreService,
          slug: slug,
          pullRequestId: 1,
          checkRun: checkRun,
          stage: CiStage.fusionEngineBuild,
          commitSha: sha,
          creationTime: 1000,
          author: 'dash',
          tasks: ['linux', 'mac'],
        );

        final check1 = PresubmitCheck.init(
          buildName: 'linux',
          checkRunId: 123,
          creationTime: 1000,
        );
        final check2 = PresubmitCheck.init(
          buildName: 'mac',
          checkRunId: 123,
          creationTime: 1000,
        );

        await firestoreService.writeViaTransaction(
          documentsToWrites([
            Document(name: check1.name, fields: check1.fields),
            Document(name: check2.name, fields: check2.fields),
          ], exists: false),
        );
      });

      test('updates check status and remaining count on success', () async {
        final state = const PresubmitCheckState(
          buildName: 'linux',
          status: TaskStatus.succeeded,
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
        expect(result.failed, 0);

        final checkDoc = await PresubmitCheck.fromFirestore(
          firestoreService,
          PresubmitCheckId(
            checkRunId: 123,
            buildName: 'linux',
            attemptNumber: 1,
          ),
        );
        expect(checkDoc.status, TaskStatus.succeeded);
        expect(checkDoc.endTime, 3000);
      });

      test(
        'update all check status to succeeded lead to complete guard',
        () async {
          final result1 = await UnifiedCheckRun.markConclusion(
            firestoreService: firestoreService,
            guardId: guardId,
            state: const PresubmitCheckState(
              buildName: 'linux',
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
            state: const PresubmitCheckState(
              buildName: 'mac',
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

          final checkDoc = await PresubmitCheck.fromFirestore(
            firestoreService,
            PresubmitCheckId(
              checkRunId: 123,
              buildName: 'linux',
              attemptNumber: 1,
            ),
          );
          expect(checkDoc.status, TaskStatus.succeeded);
          expect(checkDoc.endTime, 3000);
        },
      );

      test('updates check status and failed count on failure', () async {
        final state = const PresubmitCheckState(
          buildName: 'linux',
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
        final state = const PresubmitCheckState(
          buildName: 'windows', // Missing
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
    });
  });
}
