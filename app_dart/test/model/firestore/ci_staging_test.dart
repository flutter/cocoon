// Copyright 2024 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_server_test/test_logging.dart';
import 'package:cocoon_service/src/model/firestore/ci_staging.dart';
import 'package:cocoon_service/src/service/firestore.dart';
import 'package:github/github.dart';
import 'package:googleapis/firestore/v1.dart';
import 'package:test/test.dart';

import '../../src/service/fake_firestore_service.dart';

void main() {
  useTestLoggerPerTest();

  late FakeFirestoreService firestoreService;

  setUp(() {
    firestoreService = FakeFirestoreService();
  });

  test('documentNameFor produces expected keys', () {
    expect(
      CiStaging.documentNameFor(
        slug: RepositorySlug('code', 'fu'),
        sha: '12345',
        stage: CiStage.fusionTests,
      ),
      '$kDocumentParent/ciStaging/code_fu_12345_fusion',
    );
  });

  test('fromFirestore', () async {
    firestoreService.putDocument(
      Document(
        createTime: '1234',
        name: CiStaging.documentNameFor(
          slug: RepositorySlug('flutter', 'flutter'),
          sha: '12345',
          stage: CiStage.fusionEngineBuild,
        ),
        fields: {
          CiStaging.kRemainingField: 1.toValue(),
          CiStaging.kTotalField: 3.toValue(),
          'Linux build_test': 'scheduled'.toValue(),
          'MacOS build_test': 'success'.toValue(),
          'Failed build_test': 'failure'.toValue(),
        },
      ),
    );

    final ciStaging = await CiStaging.fromFirestore(
      firestoreService: firestoreService,
      documentName: CiStaging.documentNameFor(
        slug: RepositorySlug('flutter', 'flutter'),
        sha: '12345',
        stage: CiStage.fusionEngineBuild,
      ),
    );

    // Read the fields from the document name instead of the object.
    // TODO(matanlurey): Move these to fields when we backfill the database.
    // See https://github.com/flutter/flutter/issues/166229.
    expect(ciStaging.slug.fullName, 'flutter/flutter');
    expect(ciStaging.sha, '12345');
    expect(ciStaging.stage, CiStage.fusionEngineBuild);

    expect(ciStaging.remaining, 1);
    expect(ciStaging.total, 3);
  });

  group('markConclusion', () {
    final slug = RepositorySlug('flutter', 'flutter');
    final expectedName = CiStaging.documentNameFor(
      slug: RepositorySlug('flutter', 'flutter'),
      sha: '1234',
      stage: CiStage.fusionEngineBuild,
    );

    setUp(() async {
      await CiStaging.initializeDocument(
        firestoreService: firestoreService,
        slug: slug,
        sha: '1234',
        stage: CiStage.fusionEngineBuild,
        checkRunGuard: 'check-run-guard',
        tasks: ['test'],
      );
    });

    test('bad transaction throws', () async {
      firestoreService.failOnTransactionCommit();
      expect(
        CiStaging.markConclusion(
          firestoreService: firestoreService,
          slug: slug,
          sha: '1234',
          stage: CiStage.fusionEngineBuild,
          checkRun: 'test',
          conclusion: TaskConclusion.unknown,
        ),
        throwsA(isA<DetailedApiRequestError>()),
      );
    });

    test('handles missing fields', () async {
      firestoreService.putDocument(
        Document(
          name: CiStaging.documentNameFor(
            slug: slug,
            sha: '1234',
            stage: CiStage.fusionEngineBuild,
          ),
        ),
      );
      final future = CiStaging.markConclusion(
        firestoreService: firestoreService,
        slug: slug,
        sha: '1234',
        stage: CiStage.fusionEngineBuild,
        checkRun: 'test',
        conclusion: TaskConclusion.unknown,
      );

      await expectLater(future, throwsA(isA<String>()));
    });

    test('handles missing check_runs', () async {
      firestoreService.putDocument(
        Document(
          name: expectedName,
          fields: {
            CiStaging.kRemainingField: 1.toValue(),
            CiStaging.kTotalField: 3.toValue(),
            CiStaging.kFailedField: 0.toValue(),
            CiStaging.kCheckRunGuardField: '{}'.toValue(),
            'Linux build_test': Value(
              stringValue: TaskConclusion.scheduled.name,
            ),
            'MacOS build_test': TaskConclusion.success.name.toValue(),
            'Failed build_test': Value(
              stringValue: TaskConclusion.failure.name,
            ),
          },
        ),
      );

      final future = CiStaging.markConclusion(
        firestoreService: firestoreService,
        slug: slug,
        sha: '1234',
        stage: CiStage.fusionEngineBuild,
        checkRun: 'test',
        conclusion: TaskConclusion.unknown,
      );

      final result = await future;
      expect(
        result,
        const StagingConclusion(
          remaining: 1,
          result: StagingConclusionResult.missing,
          failed: 0,
          checkRunGuard: null,
          summary: 'Check run "test" not present in engine CI stage',
          details: 'Change flutter_flutter_1234',
        ),
      );
    });

    test('handles transaction failures', () async {
      firestoreService.putDocument(
        Document(
          name: expectedName,
          fields: {
            CiStaging.kTotalField: 1.toValue(),
            CiStaging.kRemainingField: 1.toValue(),
            CiStaging.kFailedField: 0.toValue(),
            CiStaging.kCheckRunGuardField: '{}'.toValue(),
            'Linux build_test': Value(
              stringValue: TaskConclusion.scheduled.name,
            ),
          },
        ),
      );
      firestoreService.failOnTransactionCommit();

      final future = CiStaging.markConclusion(
        firestoreService: firestoreService,
        slug: slug,
        sha: '1234',
        stage: CiStage.fusionEngineBuild,
        checkRun: 'Linux build_test',
        conclusion: TaskConclusion.unknown,
      );

      await expectLater(future, throwsA(isA<DetailedApiRequestError>()));
    });

    test('handles writing updating', () async {
      firestoreService.putDocument(
        Document(
          name: expectedName,
          fields: {
            CiStaging.kRemainingField: 1.toValue(),
            CiStaging.kFailedField: 0.toValue(),
            CiStaging.kTotalField: 1.toValue(),
            CiStaging.kCheckRunGuardField: '{}'.toValue(),
            'Linux build_test': Value(
              stringValue: TaskConclusion.scheduled.name,
            ),
          },
        ),
      );

      final future = CiStaging.markConclusion(
        firestoreService: firestoreService,
        slug: slug,
        sha: '1234',
        stage: CiStage.fusionEngineBuild,
        checkRun: 'Linux build_test',
        conclusion: TaskConclusion.unknown,
      );

      final result = await future;
      expect(
        result,
        const StagingConclusion(
          remaining: 0,
          result: StagingConclusionResult.ok,
          failed: 0,
          checkRunGuard: '{}',
          summary: 'All tests passed',
          details: '''
For CI stage engine:
  Total check runs scheduled: 1
  Pending: 0
  Failed: 0
''',
        ),
      );
    });

    test('handles previously completed check_runs', () async {
      firestoreService.putDocument(
        Document(
          name: expectedName,
          fields: {
            CiStaging.kRemainingField: 1.toValue(),
            CiStaging.kFailedField: 0.toValue(),
            CiStaging.kTotalField: 1.toValue(),
            CiStaging.kCheckRunGuardField: '{}'.toValue(),
            'MacOS build_test': TaskConclusion.success.name.toValue(),
          },
        ),
      );

      final future = CiStaging.markConclusion(
        firestoreService: firestoreService,
        slug: slug,
        sha: '1234',
        stage: CiStage.fusionEngineBuild,
        checkRun: 'MacOS build_test',
        conclusion: TaskConclusion.unknown,
      );

      final result = await future;
      expect(
        result,
        const StagingConclusion(
          remaining: 1,
          result: StagingConclusionResult.internalError,
          failed: 0,
          checkRunGuard: '{}',
          summary: 'Not a valid state transition for MacOS build_test',
          details:
              'Attempted to transition the state of check run MacOS build_test from "success" to "unknown".',
        ),
      );
    });

    test('handles a test flip-flop after re-running', () async {
      firestoreService.putDocument(
        Document(
          name: expectedName,
          fields: {
            CiStaging.kRemainingField: 1.toValue(),
            CiStaging.kFailedField: 1.toValue(),
            CiStaging.kTotalField: 1.toValue(),
            CiStaging.kCheckRunGuardField: '{}'.toValue(),
            'MacOS build_test': TaskConclusion.failure.name.toValue(),
          },
        ),
      );

      final future = CiStaging.markConclusion(
        firestoreService: firestoreService,
        slug: slug,
        sha: '1234',
        stage: CiStage.fusionEngineBuild,
        checkRun: 'MacOS build_test',
        conclusion: TaskConclusion.success,
      );

      final result = await future;
      // Remaining == 1 because our test was already concluded.
      expect(
        result,
        const StagingConclusion(
          remaining: 1,
          result: StagingConclusionResult.ok,
          failed: 0,
          checkRunGuard: '{}',
          summary: 'All tests passed',
          details: '''
For CI stage engine:
  Total check runs scheduled: 1
  Pending: 1
  Failed: 0
''',
        ),
      );
    });

    test('ignored repeat failures', () async {
      firestoreService.putDocument(
        Document(
          name: expectedName,
          fields: {
            CiStaging.kRemainingField: 1.toValue(),
            CiStaging.kFailedField: 1.toValue(),
            CiStaging.kTotalField: 1.toValue(),
            CiStaging.kCheckRunGuardField: '{}'.toValue(),
            'MacOS build_test': TaskConclusion.failure.name.toValue(),
          },
        ),
      );

      final future = CiStaging.markConclusion(
        firestoreService: firestoreService,
        slug: slug,
        sha: '1234',
        stage: CiStage.fusionEngineBuild,
        checkRun: 'MacOS build_test',
        conclusion: TaskConclusion.failure,
      );

      final result = await future;
      expect(
        result,
        const StagingConclusion(
          remaining: 1,
          result: StagingConclusionResult.internalError,
          failed: 1,
          checkRunGuard: '{}',
          summary: 'Not a valid state transition for MacOS build_test',
          details:
              'Attempted to transition the state of check run MacOS build_test from "failure" to "failure".',
        ),
      );
    });

    test('handles success to failure case', () async {
      firestoreService.putDocument(
        Document(
          name: expectedName,
          fields: {
            CiStaging.kRemainingField: 1.toValue(),
            CiStaging.kFailedField: 0.toValue(),
            CiStaging.kTotalField: 1.toValue(),
            CiStaging.kCheckRunGuardField: '{}'.toValue(),
            'MacOS build_test': TaskConclusion.success.name.toValue(),
          },
        ),
      );

      final future = CiStaging.markConclusion(
        firestoreService: firestoreService,
        slug: slug,
        sha: '1234',
        stage: CiStage.fusionEngineBuild,
        checkRun: 'MacOS build_test',
        conclusion: TaskConclusion.failure,
      );

      final result = await future;
      expect(
        result,
        const StagingConclusion(
          remaining: 1,
          result: StagingConclusionResult.ok,
          failed: 1,
          checkRunGuard: '{}',
          summary: 'All tests passed',
          details: '''
For CI stage engine:
  Total check runs scheduled: 1
  Pending: 1
  Failed: 1
''',
        ),
      );
    });
  });

  group('initializeDocument', () {
    final slug = RepositorySlug('flutter', 'flutter');
    final tasks = <String>['task1', 'task2'];
    const checkRunGuard = '{"id": "check_run_id"}';
    const sha = '1234abc';
    const stage = CiStage.fusionTests;

    test('creates a document with the correct fields', () async {
      final createdDoc = await CiStaging.initializeDocument(
        firestoreService: firestoreService,
        slug: slug,
        sha: sha,
        stage: stage,
        tasks: tasks,
        checkRunGuard: checkRunGuard,
      );
      expect(
        createdDoc.name,
        CiStaging.documentNameFor(slug: slug, sha: sha, stage: stage),
      );

      expect(
        firestoreService,
        existsInStorage(CiStaging.metadata, [
          isCiStaging
              .hasTotal(tasks.length)
              .hasRemaining(tasks.length)
              .hasFailed(0)
              .hasCheckRunGuard(checkRunGuard)
              .hasSlug(slug)
              .hasSha(sha)
              .hasStage(stage)
              .hasCheckRuns({
                for (final t in tasks) t: TaskConclusion.scheduled,
              }),
        ]),
      );
    });

    test('throws error if document creation fails', () async {
      firestoreService.failOnWriteCollection(CiStaging.metadata.collectionId);

      expect(
        CiStaging.initializeDocument(
          firestoreService: firestoreService,
          slug: slug,
          sha: sha,
          stage: stage,
          tasks: tasks,
          checkRunGuard: checkRunGuard,
        ),
        throwsA(isA<Exception>()),
      );
    });
  });
}
