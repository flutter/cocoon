// Copyright 2026 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:cocoon_server/logging.dart';
import 'package:github/github.dart';
import 'package:meta/meta.dart';

import '../../model/firestore/want_lgtm_state.dart';
import '../../service/config.dart';
import '../../service/firestore.dart';
import 'want_lgtm_check_writer.dart';
import 'want_lgtm_evaluator.dart';
import 'want_lgtm_graphql.dart';
import 'want_lgtm_models.dart';
import 'want_lgtm_parser.dart';

/// Result returned from [WantLgtmReconciler.reconcilePullRequest].
@immutable
sealed class WantLgtmReconcileResult {
  const WantLgtmReconcileResult();
}

/// The pull request review state was successfully reconciled and updated.
final class WantLgtmReconcileSuccess extends WantLgtmReconcileResult {
  const WantLgtmReconcileSuccess({required this.verdict, required this.state});

  final WantLgtmVerdict verdict;
  final WantLgtmState state;
}

/// Reconciliation was skipped (e.g. rollout flag disabled or PR closed).
final class WantLgtmReconcileSkipped extends WantLgtmReconcileResult {
  const WantLgtmReconcileSkipped({required this.reason});

  final String reason;
}

/// Orchestrates atomic, race-free reconciliation of WANT_LGTM check runs on pull requests.
interface class WantLgtmReconciler {
  WantLgtmReconciler({
    required Config config,
    required WantLgtmGraphQLClient graphQLClient,
    required WantLgtmCheckWriter checkWriter,
    required FirestoreService firestoreService,
  }) : _config = config,
       _graphQLClient = graphQLClient,
       _checkWriter = checkWriter,
       _firestoreService = firestoreService;

  final Config _config;
  final WantLgtmGraphQLClient _graphQLClient;
  final WantLgtmCheckWriter _checkWriter;
  final FirestoreService _firestoreService;

  final Map<String, Future<void>> _locks = <String, Future<void>>{};

  /// Serializes operations on the same pull request within this process.
  @visibleForTesting
  Future<T> withLock<T>(
    RepositorySlug slug,
    int prNumber,
    Future<T> Function() action,
  ) async {
    final key = '${slug.fullName}/$prNumber';
    final current = _locks[key] ?? Future<void>.value();
    final completer = Completer<void>();
    _locks[key] = completer.future;
    try {
      await current;
      return await action();
    } finally {
      completer.complete();
      if (identical(_locks[key], completer.future)) {
        unawaited(_locks.remove(key));
      }
    }
  }

  /// Reconciles the WANT_LGTM check run for a pull request.
  Future<WantLgtmReconcileResult> reconcilePullRequest(
    RepositorySlug slug,
    int prNumber, {
    PullRequest? pullRequest,
    String? triggerReason,
  }) async {
    return withLock(slug, prNumber, () async {
      final isEnabled = _config.flags.wantLgtm.isEnabledForRepo(slug);

      final existingState = await WantLgtmState.fromFirestoreOrNull(
        firestoreService: _firestoreService,
        slug: slug,
        pr: prNumber,
      );

      if (!isEnabled) {
        return _reconcileDisabled(slug, prNumber, existingState);
      }

      if (pullRequest != null) {
        final fastPathResult = await _tryFastPath(
          slug,
          prNumber,
          pullRequest,
          existingState,
        );
        if (fastPathResult != null) {
          return fastPathResult;
        }
      }

      return _reconcileSnapshot(slug, prNumber, existingState);
    });
  }

  Future<WantLgtmReconcileResult> _reconcileDisabled(
    RepositorySlug slug,
    int prNumber,
    WantLgtmState? existingState,
  ) async {
    if (existingState != null &&
        existingState.checkRunStatus == 'in_progress') {
      log.info(
        'WANT_LGTM disabled for $slug. Waiving open check run on #$prNumber',
      );
      final state = await _checkWriter.writeRolledBackCheckRun(
        slug: slug,
        prNumber: prNumber,
        checkRunId: existingState.checkRunId,
        headSha: existingState.headSha,
        existingState: existingState,
      );
      return WantLgtmReconcileSuccess(
        verdict: const WantLgtmSatisfied(
          approvedBy: [],
          latestApprovalAt: null,
          title: 'WANT_LGTM: waived (feature rolled back)',
          summary:
              'WANT_LGTM rollout flag is disabled for this repository. Check run waived.',
        ),
        state: state,
      );
    }
    return const WantLgtmReconcileSkipped(reason: 'Rollout flag disabled');
  }

  Future<WantLgtmReconcileResult?> _tryFastPath(
    RepositorySlug slug,
    int prNumber,
    PullRequest pullRequest,
    WantLgtmState? existingState,
  ) async {
    if (pullRequest.state == 'closed') {
      return _handleClosedPr(
        slug,
        prNumber,
        pullRequest.head?.sha,
        existingState,
      );
    }

    final authorLogin = pullRequest.user?.login ?? '';
    final directive = parseWantLgtmDirective(
      pullRequest.body,
      authorLogin: authorLogin,
    );

    if (directive is InvalidWantLgtmDirective) {
      log.info(
        'WANT_LGTM invalid directive on $slug #$prNumber; writing failure without GraphQL',
      );
      final verdict = evaluateWantLgtm(
        directive: directive,
        snapshot: WantLgtmGraphQLSnapshot.empty(
          headRefOid: pullRequest.head?.sha ?? '',
          authorLogin: authorLogin,
        ),
        rollerAccounts: _config.rollerAccounts,
      );
      final state = await _checkWriter.writePrVerdict(
        slug: slug,
        prNumber: prNumber,
        headSha: pullRequest.head?.sha ?? '',
        verdict: verdict,
        existingState: existingState,
      );
      return WantLgtmReconcileSuccess(verdict: verdict, state: state);
    }

    if (directive is NoWantLgtmDirective) {
      return _handleDirectiveRemoved(slug, prNumber, existingState);
    }

    return null;
  }

  Future<WantLgtmReconcileResult> _handleDirectiveRemoved(
    RepositorySlug slug,
    int prNumber,
    WantLgtmState? existingState,
  ) async {
    if (existingState != null) {
      log.info(
        'WANT_LGTM directive removed on $slug #$prNumber; waiving check run to neutral',
      );
      final state = await _checkWriter.writeWaivedCheckRun(
        slug: slug,
        prNumber: prNumber,
        checkRunId: existingState.checkRunId,
        headSha: existingState.headSha,
        reason: 'directive removed',
        existingState: existingState,
      );
      return WantLgtmReconcileSuccess(
        verdict: const WantLgtmSatisfied(
          approvedBy: [],
          latestApprovalAt: null,
          title: 'WANT_LGTM: waived (directive removed)',
          summary: 'WANT_LGTM directive was removed.',
        ),
        state: state,
      );
    }
    return const WantLgtmReconcileSkipped(
      reason: 'No WANT_LGTM directive declared',
    );
  }

  Future<WantLgtmReconcileResult> _reconcileSnapshot(
    RepositorySlug slug,
    int prNumber,
    WantLgtmState? existingState,
  ) async {
    final snapshot = await _graphQLClient.fetchSnapshot(slug, prNumber);

    if (snapshot.prState == 'CLOSED' || snapshot.prState == 'MERGED') {
      return _handleClosedPr(
        slug,
        prNumber,
        snapshot.headRefOid,
        existingState,
      );
    }

    final directive = parseWantLgtmDirective(
      snapshot.body,
      authorLogin: snapshot.authorLogin,
    );

    if (directive is NoWantLgtmDirective) {
      return _handleDirectiveRemoved(slug, prNumber, existingState);
    }

    final verdict = evaluateWantLgtm(
      directive: directive,
      snapshot: snapshot,
      rollerAccounts: _config.rollerAccounts,
    );

    final directiveStr = switch (directive) {
      ValidWantLgtmDirective(:final canonicalStorageValue) =>
        canonicalStorageValue,
      _ => null,
    };

    log.info(
      'WANT_LGTM evaluated for $slug #$prNumber: verdict=${verdict.runtimeType}, '
      'queries=${snapshot.queryCount}, title="${verdict.title}"',
    );

    final state = await _checkWriter.writePrVerdict(
      slug: slug,
      prNumber: prNumber,
      headSha: snapshot.headRefOid,
      verdict: verdict,
      existingState: existingState,
      directive: directiveStr,
    );

    return WantLgtmReconcileSuccess(verdict: verdict, state: state);
  }

  Future<WantLgtmReconcileResult> _handleClosedPr(
    RepositorySlug slug,
    int prNumber,
    String? headSha,
    WantLgtmState? existingState,
  ) async {
    if (existingState != null &&
        existingState.checkRunStatus == 'in_progress') {
      log.info(
        'PR $slug #$prNumber closed/merged; waiving open WANT_LGTM check run to neutral',
      );
      final state = await _checkWriter.writeWaivedCheckRun(
        slug: slug,
        prNumber: prNumber,
        checkRunId: existingState.checkRunId,
        headSha: headSha ?? existingState.headSha,
        reason: 'PR closed',
        existingState: existingState,
      );
      return WantLgtmReconcileSuccess(
        verdict: const WantLgtmSatisfied(
          approvedBy: [],
          latestApprovalAt: null,
          title: 'WANT_LGTM: waived (PR closed)',
          summary: 'Pull request was closed or merged.',
        ),
        state: state,
      );
    }
    return const WantLgtmReconcileSkipped(reason: 'PR is closed or merged');
  }

  /// Automatically waives the WANT_LGTM check run for a merge group commit.
  Future<CheckRun> reconcileMergeGroup({
    required RepositorySlug slug,
    required int prNumber,
    required String mergeGroupSha,
  }) async {
    return _checkWriter.writeMergeGroupVerdict(
      slug: slug,
      prNumber: prNumber,
      mergeGroupSha: mergeGroupSha,
    );
  }
}
