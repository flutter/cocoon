// Copyright 2026 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_server_test/test_logging.dart';
import 'package:cocoon_service/src/service/want_lgtm/want_lgtm_models.dart';
import 'package:test/test.dart';

void main() {
  useTestLoggerPerTest();

  group('Domain records and directives', () {
    test('WantLgtmReviewRecord equality and string representation', () {
      final now = DateTime.utc(2026, 11, 6, 12);
      final r1 = WantLgtmReviewRecord(
        authorLogin: 'alice',
        state: WantLgtmReviewState.approved,
        submittedAt: now,
      );
      final r2 = WantLgtmReviewRecord(
        authorLogin: 'alice',
        state: WantLgtmReviewState.approved,
        submittedAt: now,
      );
      final r3 = WantLgtmReviewRecord(
        authorLogin: 'bob',
        state: WantLgtmReviewState.changesRequested,
        submittedAt: now,
      );

      expect(r1, equals(r2));
      expect(r1.hashCode, equals(r2.hashCode));
      expect(r1, isNot(equals(r3)));
      expect(r1.toString(), contains('WantLgtmReviewRecord'));
    });

    test('WantLgtmTimelineEvent equality and string representation', () {
      final now = DateTime.utc(2026, 11, 6, 12);
      final e1 = WantLgtmTimelineEvent(
        reviewerLogin: 'alice',
        action: TimelineReviewAction.requested,
        createdAt: now,
      );
      final e2 = WantLgtmTimelineEvent(
        reviewerLogin: 'alice',
        action: TimelineReviewAction.requested,
        createdAt: now,
      );
      final e3 = WantLgtmTimelineEvent(
        reviewerLogin: 'bob',
        action: TimelineReviewAction.removed,
        createdAt: now,
      );

      expect(e1, equals(e2));
      expect(e1.hashCode, equals(e2.hashCode));
      expect(e1, isNot(equals(e3)));
      expect(e1.toString(), contains('WantLgtmTimelineEvent'));
    });

    test('ValidWantLgtmDirective equality and canonicalStorageValue', () {
      const d1 = ValidWantLgtmDirective(
        requiresAll: true,
        explicitLogins: ['alice', 'bob'],
      );
      const d2 = ValidWantLgtmDirective(
        requiresAll: true,
        explicitLogins: ['alice', 'bob'],
      );
      const d3 = ValidWantLgtmDirective(
        requiresAll: false,
        explicitLogins: ['alice', 'bob'],
      );
      const dAllOnly = ValidWantLgtmDirective(
        requiresAll: true,
        explicitLogins: [],
      );

      expect(d1, equals(d2));
      expect(d1.hashCode, equals(d2.hashCode));
      expect(d1, isNot(equals(d3)));
      expect(d1.canonicalStorageValue, equals('all,alice,bob'));
      expect(dAllOnly.canonicalStorageValue, equals('all'));
      expect(d3.canonicalStorageValue, equals('alice,bob'));
      expect(d1.toString(), contains('ValidWantLgtmDirective'));
    });

    test('NoWantLgtmDirective equality and string representation', () {
      const n1 = NoWantLgtmDirective();
      const n2 = NoWantLgtmDirective();

      expect(n1, equals(n2));
      expect(n1.hashCode, equals(n2.hashCode));
      expect(n1.toString(), equals('NoWantLgtmDirective()'));
    });

    test('InvalidWantLgtmDirective equality and string representation', () {
      const inv1 = InvalidWantLgtmDirective(invalidTokens: ['bad/user']);
      const inv2 = InvalidWantLgtmDirective(invalidTokens: ['bad/user']);
      const inv3 = InvalidWantLgtmDirective(invalidTokens: ['other']);

      expect(inv1, equals(inv2));
      expect(inv1.hashCode, equals(inv2.hashCode));
      expect(inv1, isNot(equals(inv3)));
      expect(inv1.toString(), contains('InvalidWantLgtmDirective'));
    });
  });

  group('WantLgtmVerdict models', () {
    test('WantLgtmSatisfied equality and string representation', () {
      final now = DateTime.utc(2026, 11, 6, 12);
      final s1 = WantLgtmSatisfied(
        approvedBy: ['alice'],
        latestApprovalAt: now,
        title: 'Title',
        summary: 'Summary',
      );
      final s2 = WantLgtmSatisfied(
        approvedBy: ['alice'],
        latestApprovalAt: now,
        title: 'Title',
        summary: 'Summary',
      );
      final s3 = WantLgtmSatisfied(
        approvedBy: ['bob'],
        latestApprovalAt: now,
        title: 'Title',
        summary: 'Summary',
      );

      expect(s1, equals(s2));
      expect(s1.hashCode, equals(s2.hashCode));
      expect(s1, isNot(equals(s3)));
      expect(s1.toString(), contains('WantLgtmSatisfied'));
    });

    test('WantLgtmPending equality and string representation', () {
      const p1 = WantLgtmPending(
        waitingOn: ['alice'],
        changesRequestedBy: ['bob'],
        title: 'Title',
        summary: 'Summary',
      );
      const p2 = WantLgtmPending(
        waitingOn: ['alice'],
        changesRequestedBy: ['bob'],
        title: 'Title',
        summary: 'Summary',
      );
      const p3 = WantLgtmPending(
        waitingOn: ['carol'],
        changesRequestedBy: [],
        title: 'Title',
        summary: 'Summary',
      );

      expect(p1, equals(p2));
      expect(p1.hashCode, equals(p2.hashCode));
      expect(p1, isNot(equals(p3)));
      expect(p1.toString(), contains('WantLgtmPending'));
    });

    test('WantLgtmInvalid equality and string representation', () {
      const i1 = WantLgtmInvalid(
        invalidTokens: ['bad/user'],
        title: 'Title',
        summary: 'Summary',
      );
      const i2 = WantLgtmInvalid(
        invalidTokens: ['bad/user'],
        title: 'Title',
        summary: 'Summary',
      );
      const i3 = WantLgtmInvalid(
        invalidTokens: ['another'],
        title: 'Title',
        summary: 'Summary',
      );

      expect(i1, equals(i2));
      expect(i1.hashCode, equals(i2.hashCode));
      expect(i1, isNot(equals(i3)));
      expect(i1.toString(), contains('WantLgtmInvalid'));
    });
  });
}
