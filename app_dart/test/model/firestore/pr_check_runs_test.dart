// Copyright 2024 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:cocoon_integration_test/testing.dart';
import 'package:cocoon_server_test/test_logging.dart';
import 'package:cocoon_service/src/model/common/firestore_extensions.dart';
import 'package:cocoon_service/src/model/firestore/pr_check_runs.dart';
import 'package:github/github.dart';
import 'package:googleapis/firestore/v1.dart';
import 'package:test/test.dart';

void main() {
  useTestLoggerPerTest();

  late FakeFirestoreService firestoreService;

  setUp(() {
    firestoreService = FakeFirestoreService();
  });

  group('initializeDocument', () {
    final runs = <CheckRun>[
      generateCheckRun(1, name: 'check 1'),
      generateCheckRun(2, name: 'check 2'),
    ];
    final pr = generatePullRequest(
      id: 11252024,
      repo: 'fluax',
      headSha: '1234abc',
    );

    test('creates a document with the correct fields', () async {
      await PrCheckRuns.initializeDocument(
        firestoreService: firestoreService,
        pullRequest: pr,
        checks: runs,
      );

      expect(
        firestoreService,
        existsInStorage(PrCheckRuns.metadata, [
          isPrCheckRun
              .hasPullRequest(
                isA<PullRequest>().having(
                  (r) => json.encode(r.toJson()),
                  'toJson()',
                  json.encode(pr.toJson()),
                ),
              )
              .hasSlug(pr.head!.repo!.slug())
              .hasSha(pr.head!.sha)
              .hasCheckRuns({'check 1': '1', 'check 2': '2'}),
        ]),
      );
    });
  });

  test('query for checkrun', () async {
    firestoreService.putDocument(
      Document(
        fields: {
          PrCheckRuns.kPullRequestField: Value(
            stringValue: json.encode(generatePullRequest(id: 1234).toJson()),
          ),
          'testing tesing': '1'.toValue(),
        },
        name: firestoreService.resolveDocumentName(
          PrCheckRuns.kCollectionId,
          '1234',
        ),
      ),
    );

    final pr = await PrCheckRuns.findPullRequestFor(
      firestoreService,
      1,
      'testing tesing',
    );

    expect(pr.id, 1234);
  });

  group('updatePullRequestForSha', () {
    test('updates pullRequest for the same PR', () async {
      final pr1 = generatePullRequest(id: 1234, number: 5678, headSha: 'abc');
      await PrCheckRuns.initializeDocument(
        firestoreService: firestoreService,
        pullRequest: pr1,
        checks: [],
      );

      final pr1Updated = generatePullRequest(
        id: 1234,
        number: 5678,
        headSha: 'abc',
        labels: [IssueLabel(name: 'CICD')],
      );
      final updated = await PrCheckRuns.updatePullRequestForSha(
        firestoreService,
        'abc',
        pr1Updated,
      );

      expect(updated, isTrue);

      final result = await PrCheckRuns.findPullRequestForSha(
        firestoreService,
        'abc',
      );
      expect(result!.number, 5678);
      expect(result.labels!.map((l) => l.name), ['CICD']);
    });

    test('does not overwrite a different PR with the same sha', () async {
      final pr1 = generatePullRequest(id: 1234, number: 5678, headSha: 'abc');
      await PrCheckRuns.initializeDocument(
        firestoreService: firestoreService,
        pullRequest: pr1,
        checks: [generateCheckRun(42, name: 'guard')],
      );

      final pr2 = generatePullRequest(id: 4321, number: 9999, headSha: 'abc');
      final updated = await PrCheckRuns.updatePullRequestForSha(
        firestoreService,
        'abc',
        pr2,
      );

      expect(updated, isFalse);

      final result = await PrCheckRuns.findPullRequestFor(
        firestoreService,
        42,
        'guard',
      );
      expect(result.number, 5678);
    });

    test('does not overwrite the same PR number in a different repo', () async {
      final pr1 = generatePullRequest(number: 5678, headSha: 'abc');
      await PrCheckRuns.initializeDocument(
        firestoreService: firestoreService,
        pullRequest: pr1,
        checks: [],
      );

      final pr2 = generatePullRequest(
        number: 5678,
        headSha: 'abc',
        repo: 'packages',
      );
      final updated = await PrCheckRuns.updatePullRequestForSha(
        firestoreService,
        'abc',
        pr2,
      );

      expect(updated, isFalse);
    });

    test('returns false when no document exists', () async {
      final updated = await PrCheckRuns.updatePullRequestForSha(
        firestoreService,
        'abc',
        generatePullRequest(headSha: 'abc'),
      );
      expect(updated, isFalse);
    });
  });

  // Regression test for https://github.com/flutter/flutter/issues/166014.
  test('deserializes issue labels', () async {
    final fullPullRequest = generatePullRequest(id: 1233).toJson();
    fullPullRequest['labels'] = [
      IssueLabel(name: 'override: foo').toJson(),
      IssueLabel(name: 'override: bar').toJson(),
    ];

    firestoreService.putDocument(
      Document(
        fields: {
          PrCheckRuns.kPullRequestField: Value(
            stringValue: json.encode(fullPullRequest),
          ),
          'check-run': '1234'.toValue(),
        },
        name: firestoreService.resolveDocumentName(
          PrCheckRuns.kCollectionId,
          '1234',
        ),
      ),
    );

    final prCheckRun = await PrCheckRuns.findPullRequestFor(
      firestoreService,
      1234,
      'check-run',
    );
    expect(prCheckRun.labels, [
      isA<IssueLabel>().having((l) => l.name, 'name', 'override: foo'),
      isA<IssueLabel>().having((l) => l.name, 'name', 'override: bar'),
    ]);
  });
}
