// Copyright 2024 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_service/src/model/firestore/ci_staging.dart';
import 'package:cocoon_service/src/service/firestore.dart';
import 'package:github/github.dart';
import 'package:googleapis/firestore/v1.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import '../../src/utilities/mocks.dart';

void main() {
  group('CiStaging', () {
    late MockFirestoreService firestoreService;

    setUp(() {
      firestoreService = MockFirestoreService();
    });

    test('documentNameFor produces expected keys', () {
      expect(
        CiStaging.documentNameFor(slug: RepositorySlug('code', 'fu'), sha: '12345', stage: 'coconut'),
        '$kDocumentParent/ciStaging/code_fu_12345_coconut',
      );
    });

    test('fromFirestore', () async {
      when(firestoreService.getDocument(any)).thenAnswer(
        (_) async => Document(
          createTime: '1234',
          name: CiStaging.documentNameFor(
            slug: RepositorySlug('flutter', 'flaux'),
            sha: '12345',
            stage: 'engine',
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

      final future = CiStaging.fromFirestore(
        firestoreService: firestoreService,
        documentName: CiStaging.documentNameFor(
          slug: RepositorySlug('flutter', 'flaux'),
          sha: '12345',
          stage: 'engine',
        ),
      );
      expect(future, completes);
      final doc = await future;
      expect(doc.remaining, 1);
      expect(doc.total, 3);
      verify(
        firestoreService.getDocument(
          CiStaging.documentNameFor(
            slug: RepositorySlug('flutter', 'flaux'),
            sha: '12345',
            stage: 'engine',
          ),
        ),
      ).called(1);
    });

    group('markConclusion', () {
      const kTransaction = 'a-totally-real-transaction-string';
      final slug = RepositorySlug('flutter', 'flaux');

      late MockProjectsDatabasesDocumentsResource docRes;

      final expectedName = CiStaging.documentNameFor(
        slug: RepositorySlug('flutter', 'flaux'),
        sha: '1234',
        stage: 'engine',
      );

      setUp(() {
        docRes = MockProjectsDatabasesDocumentsResource();
        when(docRes.rollback(captureAny, captureAny)).thenAnswer((_) async => Empty());
        when(firestoreService.documentResource()).thenAnswer((_) async => docRes);
      });

      test('bad transaction throws', () async {
        when(docRes.beginTransaction(any, any)).thenAnswer((_) async => BeginTransactionResponse());
        expect(
          CiStaging.markConclusion(
            firestoreService: firestoreService,
            slug: slug,
            sha: '1234',
            stage: 'engine',
            checkRun: 'test',
            conclusion: 'mulligan',
          ),
          throwsA(isA<String>()),
        );
      });

      test('handles missing fields', () async {
        when(docRes.beginTransaction(any, any, $fields: argThat(isNull, named: r'$fields'))).thenAnswer((_) async {
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
          stage: 'engine',
          checkRun: 'test',
          conclusion: 'mulligan',
        );

        await expectLater(future, throwsA(isA<String>()));
        verify(
          docRes.get(
            expectedName,
            mask_fieldPaths: [CiStaging.kRemainingField, 'test', CiStaging.kCheckRunGuardField, CiStaging.kFailedField],
            transaction: argThat(equals(kTransaction), named: 'transaction'),
          ),
        ).called(1);
        verify(docRes.rollback(argThat(predicate((RollbackRequest t) => t.transaction == kTransaction)), kDatabase))
            .called(1);
        verify(
          docRes.beginTransaction(
            argThat(predicate((BeginTransactionRequest t) => t.options!.readWrite != null)),
            kDatabase,
          ),
        ).called(1);
      });

      test('handles missing check_runs', () async {
        when(docRes.beginTransaction(any, any, $fields: argThat(isNull, named: r'$fields'))).thenAnswer((_) async {
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
              'Linux build_test': Value(stringValue: CiStaging.kScheduledValue),
              'MacOS build_test': Value(stringValue: CiStaging.kSuccessValue),
              'Failed build_test': Value(stringValue: CiStaging.kFailureValue),
            },
          ),
        );

        final future = CiStaging.markConclusion(
          firestoreService: firestoreService,
          slug: slug,
          sha: '1234',
          stage: 'engine',
          checkRun: 'test',
          conclusion: 'mulligan',
        );

        final result = await future;
        expect(result, (remaining: 1, valid: false, failed: 0, checkRunGuard: null));
        verify(docRes.rollback(argThat(predicate((RollbackRequest t) => t.transaction == kTransaction)), kDatabase))
            .called(1);
      });

      test('handles transaction failures', () async {
        when(docRes.beginTransaction(any, any, $fields: argThat(isNull, named: r'$fields'))).thenAnswer((_) async {
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
              CiStaging.kCheckRunGuardField: Value(stringValue: '{}'),
              'Linux build_test': Value(stringValue: CiStaging.kScheduledValue),
            },
          ),
        );

        when(docRes.commit(any, kDatabase)).thenAnswer((_) async => Future.error('commit failure'));

        final future = CiStaging.markConclusion(
          firestoreService: firestoreService,
          slug: slug,
          sha: '1234',
          stage: 'engine',
          checkRun: 'Linux build_test',
          conclusion: 'mulligan',
        );

        await expectLater(future, throwsA(isA<String>()));
        verify(
          docRes.commit(
            argThat(
              predicate((CommitRequest t) {
                return t.transaction == kTransaction &&
                    t.writes!.length == 1 &&
                    t.writes!.first.update!.fields!.length == 4 &&
                    t.writes!.first.update!.fields!['Linux build_test']!.stringValue == 'mulligan' &&
                    t.writes!.first.update!.fields![CiStaging.kRemainingField]!.integerValue == '0';
              }),
            ),
            kDatabase,
          ),
        ).called(1);
        verifyNever(docRes.rollback(any, kDatabase));
      });

      test('handles writing updating', () async {
        when(docRes.beginTransaction(any, any, $fields: argThat(isNull, named: r'$fields'))).thenAnswer((_) async {
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
              CiStaging.kCheckRunGuardField: Value(stringValue: '{}'),
              'Linux build_test': Value(stringValue: CiStaging.kScheduledValue),
            },
          ),
        );

        when(docRes.commit(any, kDatabase)).thenAnswer((_) async => CommitResponse());

        final future = CiStaging.markConclusion(
          firestoreService: firestoreService,
          slug: slug,
          sha: '1234',
          stage: 'engine',
          checkRun: 'Linux build_test',
          conclusion: 'mulligan',
        );

        final result = await future;
        expect(result, (remaining: 0, valid: true, failed: 0, checkRunGuard: '{}'));
        verify(
          docRes.commit(
            argThat(
              predicate((CommitRequest t) {
                return t.transaction == kTransaction &&
                    t.writes!.length == 1 &&
                    t.writes!.first.update!.fields!.length == 4 &&
                    t.writes!.first.update!.fields!['Linux build_test']!.stringValue == 'mulligan' &&
                    t.writes!.first.update!.fields![CiStaging.kRemainingField]!.integerValue == '0';
              }),
            ),
            kDatabase,
          ),
        ).called(1);
        verifyNever(docRes.rollback(any, kDatabase));
      });

      test('handles previously completed check_runs', () async {
        when(docRes.beginTransaction(any, any, $fields: argThat(isNull, named: r'$fields'))).thenAnswer((_) async {
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
              CiStaging.kCheckRunGuardField: Value(stringValue: '{}'),
              'MacOS build_test': Value(stringValue: CiStaging.kSuccessValue),
            },
          ),
        );

        when(docRes.commit(any, kDatabase)).thenAnswer((_) async => CommitResponse());

        final future = CiStaging.markConclusion(
          firestoreService: firestoreService,
          slug: slug,
          sha: '1234',
          stage: 'engine',
          checkRun: 'MacOS build_test',
          conclusion: 'mulligan',
        );

        final result = await future;
        expect(result, (remaining: 1, valid: false, failed: 0, checkRunGuard: '{}'));
        verify(
          docRes.commit(
            argThat(
              predicate((CommitRequest t) {
                return t.transaction == kTransaction &&
                    t.writes!.length == 1 &&
                    t.writes!.first.update!.fields!.length == 4 &&
                    t.writes!.first.update!.fields!['MacOS build_test']!.stringValue == 'mulligan' &&
                    t.writes!.first.update!.fields![CiStaging.kRemainingField]!.integerValue == '1';
              }),
            ),
            kDatabase,
          ),
        ).called(1);
        verifyNever(docRes.rollback(any, kDatabase));
      });

      test('handles a test flip-flop after re-running', () async {
        when(docRes.beginTransaction(any, any, $fields: argThat(isNull, named: r'$fields'))).thenAnswer((_) async {
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
              CiStaging.kCheckRunGuardField: Value(stringValue: '{}'),
              'MacOS build_test': Value(stringValue: CiStaging.kFailureValue),
            },
          ),
        );

        when(docRes.commit(any, kDatabase)).thenAnswer((_) async => CommitResponse());

        final future = CiStaging.markConclusion(
          firestoreService: firestoreService,
          slug: slug,
          sha: '1234',
          stage: 'engine',
          checkRun: 'MacOS build_test',
          conclusion: CiStaging.kSuccessValue,
        );

        final result = await future;
        // Remaining == 1 because our test was already concluded.
        expect(result, (remaining: 1, valid: true, failed: 0, checkRunGuard: '{}'));
        verify(
          docRes.commit(
            argThat(
              predicate((CommitRequest t) {
                return t.transaction == kTransaction &&
                    t.writes!.length == 1 &&
                    t.writes!.first.update!.fields!.length == 4 &&
                    t.writes!.first.update!.fields!['MacOS build_test']!.stringValue == CiStaging.kSuccessValue &&
                    t.writes!.first.update!.fields![CiStaging.kRemainingField]!.integerValue == '1' &&
                    t.writes!.first.update!.fields![CiStaging.kFailedField]!.integerValue == '0';
              }),
            ),
            kDatabase,
          ),
        ).called(1);
        verifyNever(docRes.rollback(any, kDatabase));
      });

      test('ignored repeat failures', () async {
        when(docRes.beginTransaction(any, any, $fields: argThat(isNull, named: r'$fields'))).thenAnswer((_) async {
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
              CiStaging.kCheckRunGuardField: Value(stringValue: '{}'),
              'MacOS build_test': Value(stringValue: CiStaging.kFailureValue),
            },
          ),
        );

        when(docRes.commit(any, kDatabase)).thenAnswer((_) async => CommitResponse());

        final future = CiStaging.markConclusion(
          firestoreService: firestoreService,
          slug: slug,
          sha: '1234',
          stage: 'engine',
          checkRun: 'MacOS build_test',
          conclusion: CiStaging.kFailureValue,
        );

        final result = await future;
        expect(result, (remaining: 1, valid: false, failed: 1, checkRunGuard: '{}'));
        verify(
          docRes.commit(
            argThat(
              predicate((CommitRequest t) {
                return t.transaction == kTransaction &&
                    t.writes!.length == 1 &&
                    t.writes!.first.update!.fields!.length == 4 &&
                    t.writes!.first.update!.fields!['MacOS build_test']!.stringValue == CiStaging.kFailureValue &&
                    t.writes!.first.update!.fields![CiStaging.kRemainingField]!.integerValue == '1' &&
                    t.writes!.first.update!.fields![CiStaging.kFailedField]!.integerValue == '1';
              }),
            ),
            kDatabase,
          ),
        ).called(1);
        verifyNever(docRes.rollback(any, kDatabase));
      });

      test('handles success to failure case', () async {
        when(docRes.beginTransaction(any, any, $fields: argThat(isNull, named: r'$fields'))).thenAnswer((_) async {
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
              CiStaging.kCheckRunGuardField: Value(stringValue: '{}'),
              'MacOS build_test': Value(stringValue: CiStaging.kSuccessValue),
            },
          ),
        );

        when(docRes.commit(any, kDatabase)).thenAnswer((_) async => CommitResponse());

        final future = CiStaging.markConclusion(
          firestoreService: firestoreService,
          slug: slug,
          sha: '1234',
          stage: 'engine',
          checkRun: 'MacOS build_test',
          conclusion: CiStaging.kFailureValue,
        );

        final result = await future;
        expect(result, (remaining: 1, valid: true, failed: 2, checkRunGuard: '{}'));
        verify(
          docRes.commit(
            argThat(
              predicate((CommitRequest t) {
                return t.transaction == kTransaction &&
                    t.writes!.length == 1 &&
                    t.writes!.first.update!.fields!.length == 4 &&
                    t.writes!.first.update!.fields!['MacOS build_test']!.stringValue == CiStaging.kFailureValue &&
                    t.writes!.first.update!.fields![CiStaging.kRemainingField]!.integerValue == '1' &&
                    t.writes!.first.update!.fields![CiStaging.kFailedField]!.integerValue == '2';
              }),
            ),
            kDatabase,
          ),
        ).called(1);
        verifyNever(docRes.rollback(any, kDatabase));
      });
    });

    group('initializeDocument', () {
      final slug = RepositorySlug('flutter', 'flaux');
      final tasks = <String>['task1', 'task2'];
      const checkRunGuard = '{"id": "check_run_id"}';
      const sha = '1234abc';
      const stage = 'unit_test';

      late MockProjectsDatabasesDocumentsResource docRes;

      setUp(() {
        docRes = MockProjectsDatabasesDocumentsResource();
        when(firestoreService.documentResource()).thenAnswer((_) async => docRes);
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
          final Document document = inv.positionalArguments[0] as Document;
          final String collectionId = inv.positionalArguments[2] as String;
          final String documentId = inv.namedArguments[#documentId] as String;

          // Check the fields of the document
          expect(document.fields, isNotNull);
          expect(document.fields![CiStaging.kTotalField]!.integerValue, tasks.length.toString());
          expect(document.fields![CiStaging.kRemainingField]!.integerValue, tasks.length.toString());
          expect(document.fields![CiStaging.kFailedField]!.integerValue, '0');
          expect(document.fields![CiStaging.kCheckRunGuardField]!.stringValue, checkRunGuard);

          for (final task in tasks) {
            expect(document.fields![task]!.stringValue, CiStaging.kScheduledValue);
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
        expect(createdDoc.name, CiStaging.documentNameFor(slug: slug, sha: sha, stage: stage));
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
  });
}
