// Copyright 2026 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_integration_test/testing.dart';
import 'package:cocoon_server_test/test_logging.dart';
import 'package:cocoon_service/src/model/firestore/want_lgtm_state.dart';
import 'package:cocoon_service/src/service/firestore.dart';
import 'package:github/github.dart';
import 'package:test/test.dart';

void main() {
  useTestLoggerPerTest();

  late FakeFirestoreService firestoreService;

  setUp(() {
    firestoreService = FakeFirestoreService();
  });

  group('WantLgtmStateId', () {
    test('produces space-delimited documentId (Option C)', () {
      final id = WantLgtmStateId(
        slug: RepositorySlug('flutter', 'flutter'),
        pr: 12345,
      );
      expect(id.documentId, 'flutter flutter 12345');
    });

    test('reconstructs from valid document ID', () {
      final id = WantLgtmStateId.fromDocumentId('flutter engine 67890');
      expect(id.slug, RepositorySlug('flutter', 'engine'));
      expect(id.pr, 67890);
      expect(id.documentId, 'flutter engine 67890');
    });

    test('throws FormatException on invalid document ID format', () {
      for (final invalid in [
        'invalid_id',
        'flutter flutter 1 2',
        'flutter  123',
        '  123',
        'flutter engine abc',
        'flutter engine 0',
        'flutter engine -5',
      ]) {
        expect(
          () => WantLgtmStateId.fromDocumentId(invalid),
          throwsA(
            isA<FormatException>().having(
              (e) => e.message,
              'message',
              contains('Invalid WantLgtmState document ID:'),
            ),
          ),
        );
      }
    });

    test('equality and hashCode match for identical identifiers', () {
      final id1 = WantLgtmStateId(
        slug: RepositorySlug('flutter', 'flutter'),
        pr: 100,
      );
      final id2 = WantLgtmStateId(
        slug: RepositorySlug('flutter', 'flutter'),
        pr: 100,
      );
      expect(id1, equals(id2));
      expect(id1.hashCode, equals(id2.hashCode));
    });
  });

  group('WantLgtmState', () {
    test('documentNameFor produces expected resource path', () {
      final docName = WantLgtmState.documentNameFor(
        slug: RepositorySlug('flutter', 'cocoon'),
        pr: 42,
      );
      expect(docName, '$kDocumentParent/wantLgtmStates/flutter cocoon 42');
    });

    test('initializes and reads all fields accurately', () {
      final now = DateTime.utc(2026, 11, 6, 12, 0, 0);
      final state = WantLgtmState.initialize(
        slug: RepositorySlug('flutter', 'flutter'),
        pr: 100,
        headSha: 'abc123def456',
        checkRunId: 987654321,
        checkRunStatus: 'in_progress',
        checkRunTitle: 'Waiting on alice',
        checkRunConclusion: null,
        directive: 'alice, bob',
        updatedAt: now,
      );

      expect(state.slug, RepositorySlug('flutter', 'flutter'));
      expect(state.slugOwner, 'flutter');
      expect(state.slugName, 'flutter');
      expect(state.pr, 100);
      expect(state.headSha, 'abc123def456');
      expect(state.checkRunId, 987654321);
      expect(state.checkRunStatus, 'in_progress');
      expect(state.checkRunConclusion, isNull);
      expect(state.checkRunTitle, 'Waiting on alice');
      expect(state.directive, 'alice, bob');
      expect(state.updatedAt, now);
    });

    test('getters and setters mutate document fields', () {
      final state = WantLgtmState();
      state.slug = RepositorySlug('flutter', 'packages');
      state.pr = 555;
      state.headSha = 'sha999';
      state.checkRunId = 111;
      state.checkRunStatus = 'completed';
      state.checkRunConclusion = 'success';
      state.checkRunTitle = 'All reviewers approved';
      state.directive = 'all';

      final updatedTime = DateTime.utc(2026, 11, 6, 13, 0, 0);
      state.updatedAt = updatedTime;

      expect(state.slugOwner, 'flutter');
      expect(state.slugName, 'packages');
      expect(state.pr, 555);
      expect(state.headSha, 'sha999');
      expect(state.checkRunId, 111);
      expect(state.checkRunStatus, 'completed');
      expect(state.checkRunConclusion, 'success');
      expect(state.checkRunTitle, 'All reviewers approved');
      expect(state.directive, 'all');
      expect(state.updatedAt, updatedTime);

      // Nullable fields removal
      state.directive = null;
      state.checkRunConclusion = null;
      state.updatedAt = null;

      expect(state.directive, isNull);
      expect(state.checkRunConclusion, isNull);
      expect(state.updatedAt, isNull);
    });

    test('toWrite returns a valid Firestore Write operation', () {
      final state = WantLgtmState.initialize(
        slug: RepositorySlug('flutter', 'flutter'),
        pr: 100,
        headSha: 'abc',
        checkRunId: 1,
        checkRunStatus: 'completed',
        checkRunTitle: 'WANT_LGTM: satisfied',
      );

      final write = state.toWrite(exists: false);
      expect(write.update, isNotNull);
      expect(write.currentDocument?.exists, isFalse);
    });

    test('fromFirestoreOrNull finds document or returns null', () async {
      final slug = RepositorySlug('flutter', 'flutter');
      final pr = 42;

      final missing = await WantLgtmState.fromFirestoreOrNull(
        firestoreService: firestoreService,
        slug: slug,
        pr: pr,
      );
      expect(missing, isNull);

      final state = WantLgtmState.initialize(
        slug: slug,
        pr: pr,
        headSha: 'abc',
        checkRunId: 10,
        checkRunStatus: 'in_progress',
        checkRunTitle: 'Waiting on bob',
      );
      firestoreService.putDocument(state);

      final found = await WantLgtmState.fromFirestoreOrNull(
        firestoreService: firestoreService,
        slug: slug,
        pr: pr,
      );
      expect(found, isNotNull);
      expect(found!.pr, 42);
      expect(found.checkRunId, 10);
    });

    test('findByCheckRunId finds matching record', () async {
      final state = WantLgtmState.initialize(
        slug: RepositorySlug('flutter', 'flutter'),
        pr: 77,
        headSha: 'def456',
        checkRunId: 123456,
        checkRunStatus: 'in_progress',
        checkRunTitle: 'Waiting on carol',
      );
      firestoreService.putDocument(state);

      final found = await WantLgtmState.findByCheckRunId(
        firestoreService: firestoreService,
        checkRunId: 123456,
      );
      expect(found, isNotNull);
      expect(found!.pr, 77);

      final notFound = await WantLgtmState.findByCheckRunId(
        firestoreService: firestoreService,
        checkRunId: 999999,
      );
      expect(notFound, isNull);
    });

    test('queryInProgress returns in_progress check runs', () async {
      final active = WantLgtmState.initialize(
        slug: RepositorySlug('flutter', 'flutter'),
        pr: 1,
        headSha: 'sha1',
        checkRunId: 101,
        checkRunStatus: 'in_progress',
        checkRunTitle: 'Waiting on alice',
      );
      final completed = WantLgtmState.initialize(
        slug: RepositorySlug('flutter', 'flutter'),
        pr: 2,
        headSha: 'sha2',
        checkRunId: 102,
        checkRunStatus: 'completed',
        checkRunTitle: 'WANT_LGTM: satisfied',
      );

      firestoreService.putDocument(active);
      firestoreService.putDocument(completed);

      final inProgressList = await WantLgtmState.queryInProgress(
        firestoreService: firestoreService,
      );
      expect(inProgressList.length, 1);
      expect(inProgressList.first.pr, 1);
    });

    test(
      'queryInProgress excludes enabled repository slugs via not-in',
      () async {
        firestoreService.putDocuments([
          WantLgtmState.initialize(
            slug: RepositorySlug('flutter', 'flutter'),
            pr: 1,
            headSha: 'sha1',
            checkRunId: 101,
            checkRunStatus: 'in_progress',
            checkRunTitle: 'Waiting on alice',
          ),
          WantLgtmState.initialize(
            slug: RepositorySlug('flutter', 'cocoon'),
            pr: 2,
            headSha: 'sha2',
            checkRunId: 102,
            checkRunStatus: 'in_progress',
            checkRunTitle: 'Waiting on bob',
          ),
        ]);

        final inProgressList = await WantLgtmState.queryInProgress(
          firestoreService: firestoreService,
          excludedSlugs: const <String>['flutter/cocoon'],
        );
        expect(inProgressList, hasLength(1));
        expect(
          inProgressList.single.slug,
          RepositorySlug('flutter', 'flutter'),
        );
      },
    );
  });
}
