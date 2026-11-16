// Copyright 2026 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_server_test/test_logging.dart';
import 'package:cocoon_service/src/service/want_lgtm/want_lgtm_evaluator.dart';
import 'package:cocoon_service/src/service/want_lgtm/want_lgtm_models.dart';
import 'package:test/test.dart';

void main() {
  useTestLoggerPerTest();

  final rollerAccounts = {'skia-flutter-autoroll', 'engine-flutter-autoroll'};

  WantLgtmGraphQLSnapshot makeSnapshot({
    String authorLogin = 'author',
    Set<String> openReviewRequestLogins = const {},
    List<WantLgtmReviewRecord> reviews = const [],
    List<WantLgtmTimelineEvent> timelineEvents = const [],
  }) {
    return WantLgtmGraphQLSnapshot(
      prState: 'OPEN',
      body: 'PR body',
      headRefOid: 'abcdef123456',
      authorLogin: authorLogin,
      openReviewRequestLogins: openReviewRequestLogins,
      reviews: reviews,
      timelineEvents: timelineEvents,
      queryCount: 1,
    );
  }

  group('evaluateWantLgtm - RFC 610.0001 Section 3.3 Truth Table', () {
    test('Row 1: alice,bob | alice APPROVED -> pending (Waiting on bob)', () {
      const directive = ValidWantLgtmDirective(
        requiresAll: false,
        explicitLogins: ['alice', 'bob'],
      );
      final snapshot = makeSnapshot(
        reviews: [
          WantLgtmReviewRecord(
            authorLogin: 'alice',
            state: WantLgtmReviewState.approved,
            submittedAt: DateTime.utc(2026, 1, 1, 10, 0),
          ),
        ],
      );

      final verdict = evaluateWantLgtm(
        directive: directive,
        snapshot: snapshot,
        rollerAccounts: rollerAccounts,
      );

      expect(verdict, isA<WantLgtmPending>());
      final pending = verdict as WantLgtmPending;
      expect(pending.waitingOn, ['bob']);
      expect(pending.changesRequestedBy, isEmpty);
      expect(pending.title, 'Waiting on bob');
    });

    test(
      'Row 2: alice | alice APPROVED, then CHANGES_REQUESTED -> pending (alice requested changes)',
      () {
        const directive = ValidWantLgtmDirective(
          requiresAll: false,
          explicitLogins: ['alice'],
        );
        final snapshot = makeSnapshot(
          reviews: [
            WantLgtmReviewRecord(
              authorLogin: 'alice',
              state: WantLgtmReviewState.approved,
              submittedAt: DateTime.utc(2026, 1, 1, 10, 0),
            ),
            WantLgtmReviewRecord(
              authorLogin: 'alice',
              state: WantLgtmReviewState.changesRequested,
              submittedAt: DateTime.utc(2026, 1, 1, 11, 0),
            ),
          ],
        );

        final verdict = evaluateWantLgtm(
          directive: directive,
          snapshot: snapshot,
          rollerAccounts: rollerAccounts,
        );

        expect(verdict, isA<WantLgtmPending>());
        final pending = verdict as WantLgtmPending;
        expect(pending.changesRequestedBy, ['alice']);
        expect(pending.title, 'alice requested changes');
      },
    );

    test('Row 3: alice | alice APPROVED, then COMMENTED -> satisfied', () {
      const directive = ValidWantLgtmDirective(
        requiresAll: false,
        explicitLogins: ['alice'],
      );
      // Non-comment reviews are stored in snapshot; comments are not in reviews list.
      final snapshot = makeSnapshot(
        reviews: [
          WantLgtmReviewRecord(
            authorLogin: 'alice',
            state: WantLgtmReviewState.approved,
            submittedAt: DateTime.utc(2026, 1, 1, 10, 0),
          ),
        ],
      );

      final verdict = evaluateWantLgtm(
        directive: directive,
        snapshot: snapshot,
        rollerAccounts: rollerAccounts,
      );

      expect(verdict, isA<WantLgtmSatisfied>());
      final satisfied = verdict as WantLgtmSatisfied;
      expect(satisfied.approvedBy, ['alice']);
      expect(satisfied.latestApprovalAt, DateTime.utc(2026, 1, 1, 10, 0));
      expect(satisfied.title, 'Approved by alice');
    });

    test(
      'Row 4: alice | alice APPROVED, then re-requested -> pending (Waiting on alice)',
      () {
        const directive = ValidWantLgtmDirective(
          requiresAll: false,
          explicitLogins: ['alice'],
        );
        final snapshot = makeSnapshot(
          reviews: [
            WantLgtmReviewRecord(
              authorLogin: 'alice',
              state: WantLgtmReviewState.approved,
              submittedAt: DateTime.utc(2026, 1, 1, 10, 0),
            ),
          ],
          timelineEvents: [
            WantLgtmTimelineEvent(
              reviewerLogin: 'alice',
              action: TimelineReviewAction.requested,
              createdAt: DateTime.utc(2026, 1, 1, 11, 0),
            ),
          ],
        );

        final verdict = evaluateWantLgtm(
          directive: directive,
          snapshot: snapshot,
          rollerAccounts: rollerAccounts,
        );

        expect(verdict, isA<WantLgtmPending>());
        final pending = verdict as WantLgtmPending;
        expect(pending.waitingOn, ['alice']);
        expect(pending.title, 'Waiting on alice');
      },
    );

    test(
      'Row 5: alice | alice never requested, drive-by APPROVED -> satisfied',
      () {
        const directive = ValidWantLgtmDirective(
          requiresAll: false,
          explicitLogins: ['alice'],
        );
        final snapshot = makeSnapshot(
          reviews: [
            WantLgtmReviewRecord(
              authorLogin: 'alice',
              state: WantLgtmReviewState.approved,
              submittedAt: DateTime.utc(2026, 1, 1, 10, 0),
            ),
          ],
        );

        final verdict = evaluateWantLgtm(
          directive: directive,
          snapshot: snapshot,
          rollerAccounts: rollerAccounts,
        );

        expect(verdict, isA<WantLgtmSatisfied>());
        final satisfied = verdict as WantLgtmSatisfied;
        expect(satisfied.approvedBy, ['alice']);
        expect(satisfied.title, 'Approved by alice');
      },
    );

    test(
      'Row 6: all | alice & bob requested; alice APPROVED; bob COMMENTED -> pending (Waiting on bob)',
      () {
        const directive = ValidWantLgtmDirective(
          requiresAll: true,
          explicitLogins: [],
        );
        // When bob commented, GitHub dropped him from open requests, but timeline records his request.
        final snapshot = makeSnapshot(
          openReviewRequestLogins: {},
          reviews: [
            WantLgtmReviewRecord(
              authorLogin: 'alice',
              state: WantLgtmReviewState.approved,
              submittedAt: DateTime.utc(2026, 1, 1, 10, 0),
            ),
          ],
          timelineEvents: [
            WantLgtmTimelineEvent(
              reviewerLogin: 'alice',
              action: TimelineReviewAction.requested,
              createdAt: DateTime.utc(2026, 1, 1, 9, 0),
            ),
            WantLgtmTimelineEvent(
              reviewerLogin: 'bob',
              action: TimelineReviewAction.requested,
              createdAt: DateTime.utc(2026, 1, 1, 9, 1),
            ),
          ],
        );

        final verdict = evaluateWantLgtm(
          directive: directive,
          snapshot: snapshot,
          rollerAccounts: rollerAccounts,
        );

        expect(verdict, isA<WantLgtmPending>());
        final pending = verdict as WantLgtmPending;
        expect(pending.waitingOn, ['bob']);
        expect(pending.title, 'Waiting on bob');
      },
    );

    test(
      'Row 7: all | alice requested then removed; bob requested & APPROVED -> satisfied',
      () {
        const directive = ValidWantLgtmDirective(
          requiresAll: true,
          explicitLogins: [],
        );
        final snapshot = makeSnapshot(
          openReviewRequestLogins: {},
          reviews: [
            WantLgtmReviewRecord(
              authorLogin: 'bob',
              state: WantLgtmReviewState.approved,
              submittedAt: DateTime.utc(2026, 1, 1, 10, 0),
            ),
          ],
          timelineEvents: [
            WantLgtmTimelineEvent(
              reviewerLogin: 'alice',
              action: TimelineReviewAction.requested,
              createdAt: DateTime.utc(2026, 1, 1, 9, 0),
            ),
            WantLgtmTimelineEvent(
              reviewerLogin: 'bob',
              action: TimelineReviewAction.requested,
              createdAt: DateTime.utc(2026, 1, 1, 9, 5),
            ),
            WantLgtmTimelineEvent(
              reviewerLogin: 'alice',
              action: TimelineReviewAction.removed,
              createdAt: DateTime.utc(2026, 1, 1, 9, 10),
            ),
          ],
        );

        final verdict = evaluateWantLgtm(
          directive: directive,
          snapshot: snapshot,
          rollerAccounts: rollerAccounts,
        );

        expect(verdict, isA<WantLgtmSatisfied>());
        final satisfied = verdict as WantLgtmSatisfied;
        expect(satisfied.approvedBy, ['bob']);
        expect(satisfied.title, 'Approved by bob');
      },
    );

    test(
      'Row 8: all | no reviewers requested -> pending (No reviewers requested)',
      () {
        const directive = ValidWantLgtmDirective(
          requiresAll: true,
          explicitLogins: [],
        );
        final snapshot = makeSnapshot(
          openReviewRequestLogins: {},
          reviews: [],
          timelineEvents: [],
        );

        final verdict = evaluateWantLgtm(
          directive: directive,
          snapshot: snapshot,
          rollerAccounts: rollerAccounts,
        );

        expect(verdict, isA<WantLgtmPending>());
        final pending = verdict as WantLgtmPending;
        expect(pending.title, 'No reviewers requested');
        expect(pending.waitingOn, isEmpty);
        expect(pending.changesRequestedBy, isEmpty);
      },
    );

    test(
      'Row 9: all,carol | no sidebar reviewers requested; carol APPROVED -> satisfied',
      () {
        const directive = ValidWantLgtmDirective(
          requiresAll: true,
          explicitLogins: ['carol'],
        );
        final snapshot = makeSnapshot(
          openReviewRequestLogins: {},
          reviews: [
            WantLgtmReviewRecord(
              authorLogin: 'carol',
              state: WantLgtmReviewState.approved,
              submittedAt: DateTime.utc(2026, 1, 1, 10, 0),
            ),
          ],
          timelineEvents: [],
        );

        final verdict = evaluateWantLgtm(
          directive: directive,
          snapshot: snapshot,
          rollerAccounts: rollerAccounts,
        );

        expect(verdict, isA<WantLgtmSatisfied>());
        final satisfied = verdict as WantLgtmSatisfied;
        expect(satisfied.approvedBy, ['carol']);
        expect(satisfied.title, 'Approved by carol');
      },
    );

    test('Row 10: invalid directive returns WantLgtmInvalid', () {
      const directive = InvalidWantLgtmDirective(
        invalidTokens: ['@flutter/engine'],
      );
      final snapshot = makeSnapshot();

      final verdict = evaluateWantLgtm(
        directive: directive,
        snapshot: snapshot,
        rollerAccounts: rollerAccounts,
      );

      expect(verdict, isA<WantLgtmInvalid>());
      final invalid = verdict as WantLgtmInvalid;
      expect(invalid.invalidTokens, ['@flutter/engine']);
      expect(invalid.title, contains('Invalid WANT_LGTM directive'));
    });
  });

  group('evaluateWantLgtm - Special cases and exclusions', () {
    test('excludes PR author and roller accounts from all cohort', () {
      const directive = ValidWantLgtmDirective(
        requiresAll: true,
        explicitLogins: [],
      );
      final snapshot = makeSnapshot(
        authorLogin: 'pr-author',
        openReviewRequestLogins: {'pr-author', 'skia-flutter-autoroll'},
        reviews: [
          WantLgtmReviewRecord(
            authorLogin: 'alice',
            state: WantLgtmReviewState.approved,
            submittedAt: DateTime.utc(2026, 1, 1, 10, 0),
          ),
        ],
        timelineEvents: [
          WantLgtmTimelineEvent(
            reviewerLogin: 'alice',
            action: TimelineReviewAction.requested,
            createdAt: DateTime.utc(2026, 1, 1, 9, 0),
          ),
          WantLgtmTimelineEvent(
            reviewerLogin: 'pr-author',
            action: TimelineReviewAction.requested,
            createdAt: DateTime.utc(2026, 1, 1, 9, 0),
          ),
          WantLgtmTimelineEvent(
            reviewerLogin: 'skia-flutter-autoroll',
            action: TimelineReviewAction.requested,
            createdAt: DateTime.utc(2026, 1, 1, 9, 0),
          ),
        ],
      );

      final verdict = evaluateWantLgtm(
        directive: directive,
        snapshot: snapshot,
        rollerAccounts: rollerAccounts,
      );

      expect(verdict, isA<WantLgtmSatisfied>());
      expect((verdict as WantLgtmSatisfied).approvedBy, ['alice']);
    });

    test(
      'enforces strict unremovedRequestAt.isAfter(latestApprovalAt) for re-requests',
      () {
        const directive = ValidWantLgtmDirective(
          requiresAll: false,
          explicitLogins: ['alice'],
        );
        final tApproval = DateTime.utc(2026, 1, 1, 12, 0, 0);

        // Re-request at tApproval (same second as initial request/approval) does not invalidate approval.
        final sameSecondSnapshot = makeSnapshot(
          reviews: [
            WantLgtmReviewRecord(
              authorLogin: 'alice',
              state: WantLgtmReviewState.approved,
              submittedAt: tApproval,
            ),
          ],
          timelineEvents: [
            WantLgtmTimelineEvent(
              reviewerLogin: 'alice',
              action: TimelineReviewAction.requested,
              createdAt: tApproval,
            ),
          ],
        );

        final sameSecondVerdict = evaluateWantLgtm(
          directive: directive,
          snapshot: sameSecondSnapshot,
          rollerAccounts: rollerAccounts,
        );
        expect(sameSecondVerdict, isA<WantLgtmSatisfied>());

        // Re-request at tApproval + 1s is strictly after approval, so alice is waiting.
        final afterSnapshot = makeSnapshot(
          reviews: [
            WantLgtmReviewRecord(
              authorLogin: 'alice',
              state: WantLgtmReviewState.approved,
              submittedAt: tApproval,
            ),
          ],
          timelineEvents: [
            WantLgtmTimelineEvent(
              reviewerLogin: 'alice',
              action: TimelineReviewAction.requested,
              createdAt: tApproval.add(const Duration(seconds: 1)),
            ),
          ],
        );

        final afterVerdict = evaluateWantLgtm(
          directive: directive,
          snapshot: afterSnapshot,
          rollerAccounts: rollerAccounts,
        );
        expect(afterVerdict, isA<WantLgtmPending>());
        expect((afterVerdict as WantLgtmPending).waitingOn, ['alice']);
      },
    );

    test(
      'caps titles at <= 255 characters when many reviewers are pending',
      () {
        final manyLogins = List.generate(40, (i) => 'reviewer$i');
        final directive = ValidWantLgtmDirective(
          requiresAll: false,
          explicitLogins: manyLogins,
        );
        final snapshot = makeSnapshot();

        final verdict = evaluateWantLgtm(
          directive: directive,
          snapshot: snapshot,
          rollerAccounts: rollerAccounts,
        );

        expect(verdict, isA<WantLgtmPending>());
        expect(verdict.title.length, lessThanOrEqualTo(255));
        expect(verdict.title.endsWith('...'), isTrue);
      },
    );

    test('NoWantLgtmDirective returns satisfied', () {
      const directive = NoWantLgtmDirective();
      final snapshot = makeSnapshot();

      final verdict = evaluateWantLgtm(
        directive: directive,
        snapshot: snapshot,
        rollerAccounts: rollerAccounts,
      );

      expect(verdict, isA<WantLgtmSatisfied>());
      expect((verdict as WantLgtmSatisfied).approvedBy, isEmpty);
    });
  });
}
