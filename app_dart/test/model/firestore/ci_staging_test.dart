// Copyright 2024 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_server_test/test_logging.dart';
import 'package:cocoon_service/src/model/firestore/ci_staging.dart';
import 'package:cocoon_service/src/service/firestore.dart';
import 'package:github/github.dart';
import 'package:googleapis/firestore/v1.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import '../../src/service/fake_firestore_service.dart';
import '../../src/utilities/mocks.dart';

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
          CiStaging.kRemainingField: Value(integerValue: '1'),
          CiStaging.kTotalField: Value(integerValue: '3'),
          'Linux build_test': Value(stringValue: 'scheduled'),
          'MacOS build_test': Value(stringValue: 'success'),
          'Failed build_test': Value(stringValue: 'failure'),
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
    const kTransaction = 'a-totally-real-transaction-string';
    final slug = RepositorySlug('flutter', 'flutter');

    late MockProjectsDatabasesDocumentsResource docRes;

    final expectedName = CiStaging.documentNameFor(
      slug: RepositorySlug('flutter', 'flutter'),
      sha: '1234',
      stage: CiStage.fusionEngineBuild,
    );

    setUp(() {
      docRes = MockProjectsDatabasesDocumentsResource();
      when(
        // ignore: discarded_futures
        docRes.rollback(captureAny, captureAny),
      ).thenAnswer((_) async => Empty());
      when(
        // ignore: discarded_futures
        firestoreService.mock.documentResource(),
      ).thenAnswer((_) async => docRes);
    });

    test('bad transaction throws', () async {
      when(
        docRes.beginTransaction(any, any),
      ).thenAnswer((_) async => BeginTransactionResponse());
      expect(
        CiStaging.markConclusion(
          firestoreService: firestoreService,
          slug: slug,
          sha: '1234',
          stage: CiStage.fusionEngineBuild,
          checkRun: 'test',
          conclusion: TaskConclusion.unknown,
        ),
        throwsA(isA<String>()),
      );
    });

    test('handles missing fields', () async {
      when(
        docRes.beginTransaction(
          any,
          any,
          $fields: argThat(isNull, named: r'$fields'),
        ),
      ).thenAnswer((_) async {
        return BeginTransactionResponse(transaction: kTransaction);
      });
      when(
        docRes.get(
          any,
          mask_fieldPaths: anyNamed('mask_fieldPaths'),
          transaction: anyNamed('transaction'),
          $fields: argThat(isNull, named: r'$fields'),
          readTime: argThat(isNull, named: 'readTime'),
        ),
      ).thenAnswer((_) async => Document());

      final future = CiStaging.markConclusion(
        firestoreService: firestoreService,
        slug: slug,
        sha: '1234',
        stage: CiStage.fusionEngineBuild,
        checkRun: 'test',
        conclusion: TaskConclusion.unknown,
      );

      await expectLater(future, throwsA(isA<String>()));
      verify(
        docRes.get(
          expectedName,
          mask_fieldPaths: anyNamed('mask_fieldPaths'),
          transaction: argThat(equals(kTransaction), named: 'transaction'),
        ),
      ).called(1);
      verify(
        docRes.rollback(
          argThat(
            predicate((RollbackRequest t) => t.transaction == kTransaction),
          ),
          kDatabase,
        ),
      ).called(1);
      verify(
        docRes.beginTransaction(
          argThat(
            predicate(
              (BeginTransactionRequest t) => t.options!.readWrite != null,
            ),
          ),
          kDatabase,
        ),
      ).called(1);
    });

    test('handles missing check_runs', () async {
      when(
        docRes.beginTransaction(
          any,
          any,
          $fields: argThat(isNull, named: r'$fields'),
        ),
      ).thenAnswer((_) async {
        return BeginTransactionResponse(transaction: kTransaction);
      });
      when(
        docRes.get(
          any,
          mask_fieldPaths: anyNamed('mask_fieldPaths'),
          transaction: anyNamed('transaction'),
          $fields: argThat(isNull, named: r'$fields'),
          readTime: argThat(isNull, named: 'readTime'),
        ),
      ).thenAnswer(
        (_) async => Document(
          name: expectedName,
          fields: {
            CiStaging.kRemainingField: Value(integerValue: '1'),
            CiStaging.kTotalField: Value(integerValue: '3'),
            CiStaging.kFailedField: Value(integerValue: '0'),
            CiStaging.kCheckRunGuardField: Value(stringValue: '{}'),
            'Linux build_test': Value(
              stringValue: TaskConclusion.scheduled.name,
            ),
            'MacOS build_test': Value(stringValue: TaskConclusion.success.name),
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
      verify(
        docRes.rollback(
          argThat(
            predicate((RollbackRequest t) => t.transaction == kTransaction),
          ),
          kDatabase,
        ),
      ).called(1);
    });

    test('handles transaction failures', () async {
      when(
        docRes.beginTransaction(
          any,
          any,
          $fields: argThat(isNull, named: r'$fields'),
        ),
      ).thenAnswer((_) async {
        return BeginTransactionResponse(transaction: kTransaction);
      });
      when(
        docRes.get(
          any,
          mask_fieldPaths: anyNamed('mask_fieldPaths'),
          transaction: anyNamed('transaction'),
          $fields: argThat(isNull, named: r'$fields'),
          readTime: argThat(isNull, named: 'readTime'),
        ),
      ).thenAnswer(
        (_) async => Document(
          name: expectedName,
          fields: {
            CiStaging.kTotalField: Value(integerValue: '1'),
            CiStaging.kRemainingField: Value(integerValue: '1'),
            CiStaging.kFailedField: Value(integerValue: '0'),
            CiStaging.kCheckRunGuardField: Value(stringValue: '{}'),
            'Linux build_test': Value(
              stringValue: TaskConclusion.scheduled.name,
            ),
          },
        ),
      );

      when(
        docRes.commit(any, kDatabase),
      ).thenAnswer((_) async => Future.error('commit failure'));

      final future = CiStaging.markConclusion(
        firestoreService: firestoreService,
        slug: slug,
        sha: '1234',
        stage: CiStage.fusionEngineBuild,
        checkRun: 'Linux build_test',
        conclusion: TaskConclusion.unknown,
      );

      await expectLater(future, throwsA(isA<String>()));
      verify(
        docRes.commit(
          argThat(
            predicate((CommitRequest t) {
              return t.transaction == kTransaction &&
                  t.writes!.length == 1 &&
                  t.writes!.first.update!.fields!.length == 5 &&
                  t
                          .writes!
                          .first
                          .update!
                          .fields!['Linux build_test']!
                          .stringValue ==
                      'unknown' &&
                  t
                          .writes!
                          .first
                          .update!
                          .fields![CiStaging.kRemainingField]!
                          .integerValue ==
                      '0';
            }),
          ),
          kDatabase,
        ),
      ).called(1);
      verifyNever(docRes.rollback(any, kDatabase));
    });

    test('handles writing updating', () async {
      when(
        docRes.beginTransaction(
          any,
          any,
          $fields: argThat(isNull, named: r'$fields'),
        ),
      ).thenAnswer((_) async {
        return BeginTransactionResponse(transaction: kTransaction);
      });
      when(
        docRes.get(
          any,
          mask_fieldPaths: anyNamed('mask_fieldPaths'),
          transaction: anyNamed('transaction'),
          $fields: argThat(isNull, named: r'$fields'),
          readTime: argThat(isNull, named: 'readTime'),
        ),
      ).thenAnswer(
        (_) async => Document(
          name: expectedName,
          fields: {
            CiStaging.kRemainingField: Value(integerValue: '1'),
            CiStaging.kFailedField: Value(integerValue: '0'),
            CiStaging.kTotalField: Value(integerValue: '1'),
            CiStaging.kCheckRunGuardField: Value(stringValue: '{}'),
            'Linux build_test': Value(
              stringValue: TaskConclusion.scheduled.name,
            ),
          },
        ),
      );

      when(
        docRes.commit(any, kDatabase),
      ).thenAnswer((_) async => CommitResponse());

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
      verify(
        docRes.commit(
          argThat(
            predicate((CommitRequest t) {
              return t.transaction == kTransaction &&
                  t.writes!.length == 1 &&
                  t.writes!.first.update!.fields!.length == 5 &&
                  t
                          .writes!
                          .first
                          .update!
                          .fields!['Linux build_test']!
                          .stringValue ==
                      'unknown' &&
                  t
                          .writes!
                          .first
                          .update!
                          .fields![CiStaging.kRemainingField]!
                          .integerValue ==
                      '0';
            }),
          ),
          kDatabase,
        ),
      ).called(1);
      verifyNever(docRes.rollback(any, kDatabase));
    });

    test('handles previously completed check_runs', () async {
      when(
        docRes.beginTransaction(
          any,
          any,
          $fields: argThat(isNull, named: r'$fields'),
        ),
      ).thenAnswer((_) async {
        return BeginTransactionResponse(transaction: kTransaction);
      });
      when(
        docRes.get(
          any,
          mask_fieldPaths: anyNamed('mask_fieldPaths'),
          transaction: anyNamed('transaction'),
          $fields: argThat(isNull, named: r'$fields'),
          readTime: argThat(isNull, named: 'readTime'),
        ),
      ).thenAnswer(
        (_) async => Document(
          name: expectedName,
          fields: {
            CiStaging.kRemainingField: Value(integerValue: '1'),
            CiStaging.kFailedField: Value(integerValue: '0'),
            CiStaging.kTotalField: Value(integerValue: '1'),
            CiStaging.kCheckRunGuardField: Value(stringValue: '{}'),
            'MacOS build_test': Value(stringValue: TaskConclusion.success.name),
          },
        ),
      );

      when(
        docRes.commit(any, kDatabase),
      ).thenAnswer((_) async => CommitResponse());

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
      verify(
        docRes.commit(
          argThat(
            predicate((CommitRequest t) {
              return t.transaction == kTransaction &&
                  t.writes!.length == 1 &&
                  t.writes!.first.update!.fields!.length == 5 &&
                  t
                          .writes!
                          .first
                          .update!
                          .fields!['MacOS build_test']!
                          .stringValue ==
                      'unknown' &&
                  t
                          .writes!
                          .first
                          .update!
                          .fields![CiStaging.kRemainingField]!
                          .integerValue ==
                      '1';
            }),
          ),
          kDatabase,
        ),
      ).called(1);
      verifyNever(docRes.rollback(any, kDatabase));
    });

    test('handles a test flip-flop after re-running', () async {
      when(
        docRes.beginTransaction(
          any,
          any,
          $fields: argThat(isNull, named: r'$fields'),
        ),
      ).thenAnswer((_) async {
        return BeginTransactionResponse(transaction: kTransaction);
      });
      when(
        docRes.get(
          any,
          mask_fieldPaths: anyNamed('mask_fieldPaths'),
          transaction: anyNamed('transaction'),
          $fields: argThat(isNull, named: r'$fields'),
          readTime: argThat(isNull, named: 'readTime'),
        ),
      ).thenAnswer(
        (_) async => Document(
          name: expectedName,
          fields: {
            CiStaging.kRemainingField: Value(integerValue: '1'),
            CiStaging.kFailedField: Value(integerValue: '1'),
            CiStaging.kTotalField: Value(integerValue: '1'),
            CiStaging.kCheckRunGuardField: Value(stringValue: '{}'),
            'MacOS build_test': Value(stringValue: TaskConclusion.failure.name),
          },
        ),
      );

      when(
        docRes.commit(any, kDatabase),
      ).thenAnswer((_) async => CommitResponse());

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
      verify(
        docRes.commit(
          argThat(
            predicate((CommitRequest t) {
              return t.transaction == kTransaction &&
                  t.writes!.length == 1 &&
                  t.writes!.first.update!.fields!.length == 5 &&
                  t
                          .writes!
                          .first
                          .update!
                          .fields!['MacOS build_test']!
                          .stringValue ==
                      TaskConclusion.success.name &&
                  t
                          .writes!
                          .first
                          .update!
                          .fields![CiStaging.kRemainingField]!
                          .integerValue ==
                      '1' &&
                  t
                          .writes!
                          .first
                          .update!
                          .fields![CiStaging.kFailedField]!
                          .integerValue ==
                      '0';
            }),
          ),
          kDatabase,
        ),
      ).called(1);
      verifyNever(docRes.rollback(any, kDatabase));
    });

    test('ignored repeat failures', () async {
      when(
        docRes.beginTransaction(
          any,
          any,
          $fields: argThat(isNull, named: r'$fields'),
        ),
      ).thenAnswer((_) async {
        return BeginTransactionResponse(transaction: kTransaction);
      });
      when(
        docRes.get(
          any,
          mask_fieldPaths: anyNamed('mask_fieldPaths'),
          transaction: anyNamed('transaction'),
          $fields: argThat(isNull, named: r'$fields'),
          readTime: argThat(isNull, named: 'readTime'),
        ),
      ).thenAnswer(
        (_) async => Document(
          name: expectedName,
          fields: {
            CiStaging.kRemainingField: Value(integerValue: '1'),
            CiStaging.kFailedField: Value(integerValue: '1'),
            CiStaging.kTotalField: Value(integerValue: '1'),
            CiStaging.kCheckRunGuardField: Value(stringValue: '{}'),
            'MacOS build_test': Value(stringValue: TaskConclusion.failure.name),
          },
        ),
      );

      when(
        docRes.commit(any, kDatabase),
      ).thenAnswer((_) async => CommitResponse());

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
      verify(
        docRes.commit(
          argThat(
            predicate((CommitRequest t) {
              return t.transaction == kTransaction &&
                  t.writes!.length == 1 &&
                  t.writes!.first.update!.fields!.length == 5 &&
                  t
                          .writes!
                          .first
                          .update!
                          .fields!['MacOS build_test']!
                          .stringValue ==
                      TaskConclusion.failure.name &&
                  t
                          .writes!
                          .first
                          .update!
                          .fields![CiStaging.kRemainingField]!
                          .integerValue ==
                      '1' &&
                  t
                          .writes!
                          .first
                          .update!
                          .fields![CiStaging.kFailedField]!
                          .integerValue ==
                      '1';
            }),
          ),
          kDatabase,
        ),
      ).called(1);
      verifyNever(docRes.rollback(any, kDatabase));
    });

    test('handles success to failure case', () async {
      when(
        docRes.beginTransaction(
          any,
          any,
          $fields: argThat(isNull, named: r'$fields'),
        ),
      ).thenAnswer((_) async {
        return BeginTransactionResponse(transaction: kTransaction);
      });
      when(
        docRes.get(
          any,
          mask_fieldPaths: anyNamed('mask_fieldPaths'),
          transaction: anyNamed('transaction'),
          $fields: argThat(isNull, named: r'$fields'),
          readTime: argThat(isNull, named: 'readTime'),
        ),
      ).thenAnswer(
        (_) async => Document(
          name: expectedName,
          fields: {
            CiStaging.kRemainingField: Value(integerValue: '1'),
            CiStaging.kFailedField: Value(integerValue: '0'),
            CiStaging.kTotalField: Value(integerValue: '1'),
            CiStaging.kCheckRunGuardField: Value(stringValue: '{}'),
            'MacOS build_test': Value(stringValue: TaskConclusion.success.name),
          },
        ),
      );

      when(
        docRes.commit(any, kDatabase),
      ).thenAnswer((_) async => CommitResponse());

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
      verify(
        docRes.commit(
          argThat(
            predicate((CommitRequest t) {
              return t.transaction == kTransaction &&
                  t.writes!.length == 1 &&
                  t.writes!.first.update!.fields!.length == 5 &&
                  t
                          .writes!
                          .first
                          .update!
                          .fields!['MacOS build_test']!
                          .stringValue ==
                      TaskConclusion.failure.name &&
                  t
                          .writes!
                          .first
                          .update!
                          .fields![CiStaging.kRemainingField]!
                          .integerValue ==
                      '1' &&
                  t
                          .writes!
                          .first
                          .update!
                          .fields![CiStaging.kFailedField]!
                          .integerValue ==
                      '1';
            }),
          ),
          kDatabase,
        ),
      ).called(1);
      verifyNever(docRes.rollback(any, kDatabase));
    });
  });

  group('initializeDocument', () {
    final slug = RepositorySlug('flutter', 'flutter');
    final tasks = <String>['task1', 'task2'];
    const checkRunGuard = '{"id": "check_run_id"}';
    const sha = '1234abc';
    const stage = CiStage.fusionTests;

    late MockProjectsDatabasesDocumentsResource docRes;

    setUp(() {
      docRes = MockProjectsDatabasesDocumentsResource();
      when(
        // ignore: discarded_futures
        firestoreService.documentResource(),
      ).thenAnswer((_) async => docRes);
    });

    test('creates a document with the correct fields', () async {
      when(
        docRes.createDocument(
          any,
          any,
          any,
          documentId: anyNamed('documentId'),
          $fields: anyNamed(r'$fields'),
        ),
      ).thenAnswer((Invocation inv) async {
        final document = inv.positionalArguments[0] as Document;
        final collectionId = inv.positionalArguments[2] as String;
        final documentId = inv.namedArguments[#documentId] as String;

        // Check the fields of the document
        expect(document.fields, isNotNull);
        expect(
          document.fields![CiStaging.kTotalField]!.integerValue,
          tasks.length.toString(),
        );
        expect(
          document.fields![CiStaging.kRemainingField]!.integerValue,
          tasks.length.toString(),
        );
        expect(document.fields![CiStaging.kFailedField]!.integerValue, '0');
        expect(
          document.fields![CiStaging.kCheckRunGuardField]!.stringValue,
          checkRunGuard,
        );
        expect(
          document.fields![CiStaging.fieldRepoFullPath]!.stringValue,
          '${slug.owner}/${slug.name}',
        );
        expect(document.fields![CiStaging.fieldCommitSha]!.stringValue, sha);
        expect(document.fields![CiStaging.fieldStage]!.stringValue, stage.name);

        for (final task in tasks) {
          expect(
            document.fields![task]!.stringValue,
            TaskConclusion.scheduled.name,
          );
        }

        return Document(name: '$kDocumentParent/$collectionId/$documentId');
      });

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
      verify(
        docRes.createDocument(
          any,
          any,
          any,
          documentId: anyNamed('documentId'),
        ),
      ).called(1);
    });

    test('throws error if document creation fails', () async {
      when(
        docRes.createDocument(
          any,
          any,
          any,
          documentId: anyNamed('documentId'),
          $fields: anyNamed(r'$fields'),
        ),
      ).thenThrow(Exception('Document creation failed'));

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
