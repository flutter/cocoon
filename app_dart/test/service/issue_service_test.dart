// Copyright 2026 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:cocoon_integration_test/testing.dart';
import 'package:cocoon_server_test/test_logging.dart';
import 'package:cocoon_service/cocoon_service.dart';
import 'package:github/github.dart';
import 'package:github/hooks.dart';
import 'package:googleapis/firestore/v1.dart';
import 'package:test/test.dart';

import 'issue_service_test_data.dart';

void main() {
  useTestLoggerPerTest();

  late IssueService issueService;
  late FakeFirestoreService firestore;
  late CacheService cache;
  late TestSuppression suppressionService;

  setUp(() {
    firestore = FakeFirestoreService();
    cache = CacheService.inMemory();
    suppressionService = TestSuppression(firestore: firestore, cache: cache);
    issueService = IssueService(
      firestore: firestore,
      suppressionService: suppressionService,
    );
  });

  group('IssueService', () {
    test(
      'unsuppresses all matching tests when issue is closed (e.g. Linux fu and Linux bar)',
      () async {
        const issueLink = 'https://github.com/flutter/flutter/issues/188740';
        final testDoc1 = SuppressedTest(
          name: 'Linux fu',
          repository: 'flutter/flutter',
          issueLink: issueLink,
          isSuppressed: true,
          createTimestamp: DateTime.utc(2026, 1, 1),
        );
        final testDoc2 = SuppressedTest(
          name: 'Linux bar',
          repository: 'flutter/flutter',
          issueLink: issueLink,
          isSuppressed: true,
          createTimestamp: DateTime.utc(2026, 1, 1),
        );
        await firestore.createDocument(
          testDoc1,
          collectionId: SuppressedTest.kCollectionId,
        );
        await firestore.createDocument(
          testDoc2,
          collectionId: SuppressedTest.kCollectionId,
        );

        final eventJson = issueEventJson(
          action: 'closed',
          htmlUrl: issueLink,
          login: 'ievdokdm',
          number: 188740,
        );
        final event = IssueEvent.fromJson(
          jsonDecode(eventJson) as Map<String, dynamic>,
        );

        await issueService.handleIssueEvent(event);

        final latest1 = await SuppressedTest.getLatest(
          firestore,
          'flutter/flutter',
          'Linux fu',
        );
        expect(latest1, isNotNull);
        expect(latest1!.isSuppressed, isFalse);
        expect(latest1.updates.last['user'], 'ievdokdm');
        expect(
          latest1.updates.last['note'],
          contains('Automatic unsuppression'),
        );

        final latest2 = await SuppressedTest.getLatest(
          firestore,
          'flutter/flutter',
          'Linux bar',
        );
        expect(latest2, isNotNull);
        expect(latest2!.isSuppressed, isFalse);
        expect(latest2.updates.last['user'], 'ievdokdm');
        expect(
          latest2.updates.last['note'],
          contains('Automatic unsuppression'),
        );
      },
    );

    test(
      're-suppresses all matching tests when issue is reopened (e.g. Linux fu and Linux bar)',
      () async {
        const issueLink = 'https://github.com/flutter/flutter/issues/188740';
        final testDoc1 = SuppressedTest(
          name: 'Linux fu',
          repository: 'flutter/flutter',
          issueLink: issueLink,
          isSuppressed: false,
          createTimestamp: DateTime.utc(2026, 1, 1),
        );
        final testDoc2 = SuppressedTest(
          name: 'Linux bar',
          repository: 'flutter/flutter',
          issueLink: issueLink,
          isSuppressed: false,
          createTimestamp: DateTime.utc(2026, 1, 1),
        );
        await firestore.createDocument(
          testDoc1,
          collectionId: SuppressedTest.kCollectionId,
        );
        await firestore.createDocument(
          testDoc2,
          collectionId: SuppressedTest.kCollectionId,
        );

        final eventJson = issueEventJson(
          action: 'reopened',
          htmlUrl: issueLink,
          login: 'ievdokdm',
          number: 188740,
        );
        final event = IssueEvent.fromJson(
          jsonDecode(eventJson) as Map<String, dynamic>,
        );

        await issueService.handleIssueEvent(event);

        final latest1 = await SuppressedTest.getLatest(
          firestore,
          'flutter/flutter',
          'Linux fu',
        );
        expect(latest1, isNotNull);
        expect(latest1!.isSuppressed, isTrue);
        expect(latest1.updates.last['user'], 'ievdokdm');
        expect(
          latest1.updates.last['note'],
          contains('Automatic re-suppression'),
        );

        final latest2 = await SuppressedTest.getLatest(
          firestore,
          'flutter/flutter',
          'Linux bar',
        );
        expect(latest2, isNotNull);
        expect(latest2!.isSuppressed, isTrue);
        expect(latest2.updates.last['user'], 'ievdokdm');
        expect(
          latest2.updates.last['note'],
          contains('Automatic re-suppression'),
        );
      },
    );

    test(
      'does not unsuppress test if latest suppression has different issue link',
      () async {
        const oldIssueLink = 'https://github.com/flutter/flutter/issues/111';
        const newIssueLink = 'https://github.com/flutter/flutter/issues/222';
        final oldDoc = SuppressedTest(
          name: 'Linux test',
          repository: 'flutter/flutter',
          issueLink: oldIssueLink,
          isSuppressed: false,
          createTimestamp: DateTime.utc(2026, 1, 1),
        );
        final newDoc = SuppressedTest(
          name: 'Linux test',
          repository: 'flutter/flutter',
          issueLink: newIssueLink,
          isSuppressed: true,
          createTimestamp: DateTime.utc(2026, 1, 2),
        );
        await firestore.createDocument(
          oldDoc,
          collectionId: SuppressedTest.kCollectionId,
        );
        await firestore.createDocument(
          newDoc,
          collectionId: SuppressedTest.kCollectionId,
        );

        // Event for the OLD issue being closed
        final eventJson = issueEventJson(
          action: 'closed',
          htmlUrl: oldIssueLink,
          number: 111,
        );
        final event = IssueEvent.fromJson(
          jsonDecode(eventJson) as Map<String, dynamic>,
        );

        await issueService.handleIssueEvent(event);

        final latest = await SuppressedTest.getLatest(
          firestore,
          'flutter/flutter',
          'Linux test',
        );
        expect(latest, isNotNull);
        // Remains suppressed under newIssueLink
        expect(latest!.isSuppressed, isTrue);
        expect(latest.issueLink, newIssueLink);
      },
    );

    test('handles legacy documents missing issueLink without crashing', () async {
      final legacyDoc = SuppressedTest.fromDocument(
        Document(
          name:
              'projects/flutter-dashboard/databases/cocoon/documents/suppressed_tests/legacy',
          fields: {
            'name': 'Linux legacy'.toValue(),
            'repository': 'flutter/flutter'.toValue(),
            'isSuppressed': true.toValue(),
            'createTimestamp': DateTime.utc(2026, 1, 1).toValue(),
          },
        ),
      );
      await firestore.createDocument(
        legacyDoc,
        collectionId: SuppressedTest.kCollectionId,
      );

      final eventJson = issueEventJson(
        action: 'closed',
        htmlUrl: 'https://github.com/flutter/flutter/issues/12345',
        number: 12345,
      );
      final event = IssueEvent.fromJson(
        jsonDecode(eventJson) as Map<String, dynamic>,
      );

      // Should complete without null assertion error
      await issueService.handleIssueEvent(event);
    });

    test(
      'defaults sender to github-webhook when sender is missing in event',
      () async {
        const issueLink = 'https://github.com/flutter/flutter/issues/999';
        final testDoc = SuppressedTest(
          name: 'Linux nosender',
          repository: 'flutter/flutter',
          issueLink: issueLink,
          isSuppressed: true,
          createTimestamp: DateTime.utc(2026, 1, 1),
        );
        await firestore.createDocument(
          testDoc,
          collectionId: SuppressedTest.kCollectionId,
        );

        final event = IssueEvent(
          action: 'closed',
          issue: Issue(htmlUrl: issueLink, number: 999),
          sender: null,
        );

        await issueService.handleIssueEvent(event);

        final latest = await SuppressedTest.getLatest(
          firestore,
          'flutter/flutter',
          'Linux nosender',
        );
        expect(latest, isNotNull);
        expect(latest!.isSuppressed, isFalse);
        expect(latest.updates.last['user'], 'github-webhook');
      },
    );

    test(
      'ignores non-closed/non-reopened actions or missing htmlUrl',
      () async {
        final eventJson = issueEventJson(
          action: 'labeled',
          htmlUrl: 'https://github.com/flutter/flutter/issues/123',
          number: 123,
        );
        final event = IssueEvent.fromJson(
          jsonDecode(eventJson) as Map<String, dynamic>,
        );

        await issueService.handleIssueEvent(event);

        final eventWithoutUrl = IssueEvent(action: 'closed', issue: Issue());

        await issueService.handleIssueEvent(eventWithoutUrl);

        final eventWithoutIssue = IssueEvent(action: 'closed', issue: null);

        await issueService.handleIssueEvent(eventWithoutIssue);
      },
    );
  });
}
