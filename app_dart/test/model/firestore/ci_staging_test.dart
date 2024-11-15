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
            mask_fieldPaths: [CiStaging.kRemainingField, 'test'],
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
              'Linux build_test': Value(stringValue: 'scheduled'),
              'MacOS build_test': Value(stringValue: 'success'),
              'Failed build_test': Value(stringValue: 'failure'),
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
        expect(result, (remaining: 1, valid: false));
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
              'Linux build_test': Value(stringValue: 'scheduled'),
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
                    t.writes!.first.update!.fields!.length == 2 &&
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
              'Linux build_test': Value(stringValue: 'scheduled'),
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
        expect(result, (remaining: 0, valid: true));
        verify(
          docRes.commit(
            argThat(
              predicate((CommitRequest t) {
                return t.transaction == kTransaction &&
                    t.writes!.length == 1 &&
                    t.writes!.first.update!.fields!.length == 2 &&
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
              'MacOS build_test': Value(stringValue: 'success'),
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
        expect(result, (remaining: 1, valid: false));
        verify(
          docRes.commit(
            argThat(
              predicate((CommitRequest t) {
                return t.transaction == kTransaction &&
                    t.writes!.length == 1 &&
                    t.writes!.first.update!.fields!.length == 2 &&
                    t.writes!.first.update!.fields!['MacOS build_test']!.stringValue == 'mulligan' &&
                    t.writes!.first.update!.fields![CiStaging.kRemainingField]!.integerValue == '1';
              }),
            ),
            kDatabase,
          ),
        ).called(1);
        verifyNever(docRes.rollback(any, kDatabase));
      });
    });
  });
}
