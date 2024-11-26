// Copyright 2024 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:cocoon_service/src/model/firestore/pr_check_runs.dart';
import 'package:cocoon_service/src/service/firestore.dart';
import 'package:github/github.dart';
import 'package:googleapis/firestore/v1.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import '../../src/utilities/entity_generators.dart';
import '../../src/utilities/mocks.dart';

void main() {
  group('PrCheckRuns', () {
    late MockFirestoreService firestoreService;

    setUp(() {
      firestoreService = MockFirestoreService();
    });

    group('initializeDocument', () {
      final runs = <CheckRun>[
        generateCheckRun(1, name: 'check 1'),
        generateCheckRun(2, name: 'check 2'),
      ];
      final pr = generatePullRequest(id: 11252024, repo: 'fluax', sha: '1234abc');

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
          return Document(name: '$kDocumentParent/${PrCheckRuns.kCollectionId}/867-5309');
        });

        await PrCheckRuns.initializeDocument(
          firestoreService: firestoreService,
          pullRequest: pr,
          checks: runs,
        );
        final result = verify(
          docRes.createDocument(
            captureAny,
            captureAny,
            captureAny,
            documentId: anyNamed('documentId'),
          ),
        );
        expect(result.callCount, 1);
        final captured = result.captured;
        final Document document = captured[0] as Document;
        final String parent = captured[1] as String;
        final String collectionId = captured[2] as String;
        expect(parent, kDocumentParent);
        expect(collectionId, PrCheckRuns.kCollectionId);
        expect(document.fields![PrCheckRuns.kPullRequestField]!.stringValue, json.encode(pr.toJson()));
        expect(document.fields![PrCheckRuns.kSlugField]!.stringValue, json.encode(pr.head!.repo!.slug().toJson()));
        expect(document.fields![PrCheckRuns.kShaField]!.stringValue, pr.head!.sha);
        expect(document.fields!['check 1']!.stringValue, '1');
        expect(document.fields!['check 2']!.stringValue, '2');
      });
    });

    test('query for checkrun', () async {
      when(firestoreService.query(any, any)).thenAnswer(
        (_) async => [
          Document(
            fields: {
              PrCheckRuns.kPullRequestField: Value(stringValue: json.encode(generatePullRequest(id: 1234).toJson())),
            },
            name: 'pr1234',
          ),
        ],
      );
      final pr = await PrCheckRuns.findDocumentFor(firestoreService, generateCheckRun(1, name: 'testing tesing'));

      final captured = verify(firestoreService.query(PrCheckRuns.kCollectionId, captureAny)).captured;
      expect(captured, [
        {
          'testing tesing =': '1',
        },
      ]);
      expect(pr.id, 1234);
    });
  });
}
