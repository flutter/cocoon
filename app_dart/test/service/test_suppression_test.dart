// Copyright 2026 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_integration_test/testing.dart';
import 'package:cocoon_server_test/test_logging.dart';
import 'package:cocoon_service/cocoon_service.dart';
import 'package:github/github.dart';
import 'package:test/test.dart';

void main() {
  useTestLoggerPerTest();

  group('TestSuppression.canonicalizeIssueUrl', () {
    test('canonicalizes standard GitHub issue URLs', () {
      expect(
        TestSuppression.canonicalizeIssueUrl(
          'https://github.com/flutter/flutter/issues/188740',
        ),
        'https://github.com/flutter/flutter/issues/188740',
      );
    });

    test('strips trailing slashes', () {
      expect(
        TestSuppression.canonicalizeIssueUrl(
          'https://github.com/flutter/flutter/issues/188740/',
        ),
        'https://github.com/flutter/flutter/issues/188740',
      );
      expect(
        TestSuppression.canonicalizeIssueUrl(
          'https://github.com/flutter/flutter/issues/188740///',
        ),
        'https://github.com/flutter/flutter/issues/188740',
      );
    });

    test('strips fragment anchors (e.g. comment links)', () {
      expect(
        TestSuppression.canonicalizeIssueUrl(
          'https://github.com/flutter/flutter/issues/188740#issuecomment-1234567',
        ),
        'https://github.com/flutter/flutter/issues/188740',
      );
    });

    test('strips query parameters', () {
      expect(
        TestSuppression.canonicalizeIssueUrl(
          'https://github.com/flutter/flutter/issues/188740?param=1&q=search',
        ),
        'https://github.com/flutter/flutter/issues/188740',
      );
    });

    test('strips rest path segments (e.g. comments subpath)', () {
      expect(
        TestSuppression.canonicalizeIssueUrl(
          'https://github.com/flutter/flutter/issues/188740/comments',
        ),
        'https://github.com/flutter/flutter/issues/188740',
      );
      expect(
        TestSuppression.canonicalizeIssueUrl(
          'https://github.com/flutter/flutter/issues/188740/comments/123/',
        ),
        'https://github.com/flutter/flutter/issues/188740',
      );
    });

    test('handles combined trailing slashes, queries, and fragments', () {
      expect(
        TestSuppression.canonicalizeIssueUrl(
          'https://github.com/flutter/flutter/issues/188740/comments/?param=1#frag',
        ),
        'https://github.com/flutter/flutter/issues/188740',
      );
    });

    test('trims surrounding whitespace', () {
      expect(
        TestSuppression.canonicalizeIssueUrl(
          '   https://github.com/flutter/flutter/issues/188740   ',
        ),
        'https://github.com/flutter/flutter/issues/188740',
      );
    });

    test('canonicalizes www.github.com issue URLs to github.com', () {
      expect(
        TestSuppression.canonicalizeIssueUrl(
          'https://www.github.com/flutter/flutter/issues/188740',
        ),
        'https://github.com/flutter/flutter/issues/188740',
      );
      expect(
        TestSuppression.canonicalizeIssueUrl(
          'https://www.github.com/flutter/flutter/issues/188740/#issuecomment-123',
        ),
        'https://github.com/flutter/flutter/issues/188740',
      );
    });

    test('returns null for non-GitHub URLs or non-issue links', () {
      expect(
        TestSuppression.canonicalizeIssueUrl('https://example.com/foo/bar/'),
        isNull,
      );
      expect(
        TestSuppression.canonicalizeIssueUrl(
          'https://github.com/flutter/flutter/pull/123/',
        ),
        isNull,
      );
      expect(
        TestSuppression.canonicalizeIssueUrl(
          'https://github.com/flutter/flutter',
        ),
        isNull,
      );
      expect(
        TestSuppression.canonicalizeIssueUrl(
          'https://github.com/flutter/flutter/issues/notanumber',
        ),
        isNull,
      );
      expect(TestSuppression.canonicalizeIssueUrl('   '), isNull);
    });
  });

  group('TestSuppression.updateSuppression validation', () {
    late FakeFirestoreService firestore;
    late CacheService cache;
    late TestSuppression suppressionService;

    setUp(() {
      firestore = FakeFirestoreService();
      cache = CacheService.inMemory();
      suppressionService = TestSuppression(firestore: firestore, cache: cache);
    });

    test('throws ArgumentError if issueLink is null on suppress', () async {
      await expectLater(
        suppressionService.updateSuppression(
          testName: 'Linux test',
          email: 'test@example.com',
          repository: RepositorySlug('flutter', 'flutter'),
          action: SuppressingAction.suppress,
          note: 'Missing URL test',
          issueLink: null,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('does not throw if issueLink is null on unsuppress', () async {
      await expectLater(
        suppressionService.updateSuppression(
          testName: 'Linux test',
          email: 'test@example.com',
          repository: RepositorySlug('flutter', 'flutter'),
          action: SuppressingAction.unsuppress,
          note: 'Unsuppress test',
        ),
        completes,
      );
    });

    test('throws ArgumentError if issueLink is invalid on suppress', () async {
      await expectLater(
        suppressionService.updateSuppression(
          testName: 'Linux test',
          email: 'test@example.com',
          repository: RepositorySlug('flutter', 'flutter'),
          action: SuppressingAction.suppress,
          note: 'Invalid URL test',
          issueLink: 'https://example.com/not-github',
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('canonicalizes www.github.com issueLink on suppress', () async {
      await suppressionService.updateSuppression(
        testName: 'Linux test',
        email: 'test@example.com',
        repository: RepositorySlug('flutter', 'flutter'),
        action: SuppressingAction.suppress,
        note: 'Canonical test',
        issueLink: 'https://www.github.com/flutter/flutter/issues/188740/',
      );

      final latest = await SuppressedTest.getLatest(
        firestore,
        'flutter/flutter',
        'Linux test',
      );
      expect(latest, isNotNull);
      expect(
        latest!.issueLink,
        'https://github.com/flutter/flutter/issues/188740',
      );
    });
  });
}
