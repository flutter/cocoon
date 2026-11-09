// Copyright 2026 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_server/logging.dart';
import 'package:github/github.dart';

import '../../foundation/github_checks_util.dart';
import '../../model/firestore/want_lgtm_state.dart';
import '../../service/config.dart';
import '../../service/firestore.dart';
import 'want_lgtm_models.dart';

/// Translates WANT_LGTM evaluation verdicts into GitHub Check Runs and persists state.
final class WantLgtmCheckWriter {
  const WantLgtmCheckWriter({
    required Config config,
    required GithubChecksUtil githubChecksUtil,
    required FirestoreService firestoreService,
  }) : _config = config,
       _githubChecksUtil = githubChecksUtil,
       _firestoreService = firestoreService;

  final Config _config;
  final GithubChecksUtil _githubChecksUtil;
  final FirestoreService _firestoreService;

  /// Returns the canonical GitHub pull request URL for the check run details link.
  static String? detailsUrlFor(RepositorySlug slug, int prNumber) {
    if (prNumber <= 0) {
      return 'https://github.com/${slug.fullName}';
    }
    return 'https://github.com/${slug.fullName}/pull/$prNumber';
  }

  /// Constructs a minimal [CheckRun] referencing an existing check run by ID.
  static CheckRun checkRunWithId(int checkRunId) {
    return CheckRun.fromJson({
      'id': checkRunId,
      'name': Config.kWantLgtmCheckName,
      'check_suite': const {'id': null},
      // Required by CheckRun.fromJson (non-nullable DateTime); updateCheckRun only reads CheckRun.id.
      'started_at': DateTime.now().toUtc().toIso8601String(),
      'conclusion': null,
    });
  }

  /// Writes a check run verdict for a PR, updating an existing check run if matching
  /// the same head SHA, or creating a new one otherwise.
  Future<WantLgtmState> writePrVerdict({
    required RepositorySlug slug,
    required int prNumber,
    required String headSha,
    required WantLgtmVerdict verdict,
    WantLgtmState? existingState,
    String? directive,
  }) async {
    final (status, conclusion, statusStr, conclusionStr) = switch (verdict) {
      WantLgtmSatisfied() => (
        CheckRunStatus.completed,
        CheckRunConclusion.success,
        'completed',
        'success',
      ),
      WantLgtmPending() => (
        CheckRunStatus.inProgress,
        null,
        'in_progress',
        null,
      ),
      WantLgtmInvalid() => (
        CheckRunStatus.completed,
        CheckRunConclusion.failure,
        'completed',
        'failure',
      ),
    };

    final detailsUrl = detailsUrlFor(slug, prNumber);
    final output = CheckRunOutput(
      title: verdict.title,
      summary: verdict.summary,
    );

    final canUpdateInPlace =
        existingState != null &&
        existingState.headSha == headSha &&
        !(existingState.checkRunStatus == 'completed' &&
            status == CheckRunStatus.inProgress);

    if (canUpdateInPlace) {
      if (existingState.checkRunStatus == statusStr &&
          existingState.checkRunConclusion == conclusionStr &&
          existingState.checkRunTitle == verdict.title &&
          existingState.directive == directive) {
        return existingState;
      }

      await _githubChecksUtil.updateCheckRun(
        _config,
        slug,
        checkRunWithId(existingState.checkRunId),
        status: status,
        conclusion: conclusion,
        detailsUrl: detailsUrl,
        output: output,
      );
      existingState.checkRunStatus = statusStr;
      existingState.checkRunConclusion = conclusionStr;
      existingState.checkRunTitle = verdict.title;
      existingState.directive = directive;
      existingState.updatedAt = DateTime.now().toUtc();
      await existingState.save(_firestoreService);
      return existingState;
    }

    // We cannot update in place when headSha changed or when reopening a
    // terminal (completed) check run; terminal check runs must be re-created.
    final checkRun = await _githubChecksUtil.createCheckRun(
      _config,
      slug,
      headSha,
      Config.kWantLgtmCheckName,
      status: status,
      conclusion: conclusion,
      detailsUrl: detailsUrl,
      output: output,
    );

    final state = WantLgtmState.initialize(
      slug: slug,
      pr: prNumber,
      headSha: headSha,
      checkRunId: checkRun.id!,
      checkRunStatus: statusStr,
      checkRunTitle: verdict.title,
      checkRunConclusion: conclusionStr,
      directive: directive,
      updatedAt: DateTime.now().toUtc(),
    );
    await state.save(_firestoreService);
    return state;
  }

  /// Writes a completed, neutral check run for ephemeral merge queue commits.
  Future<CheckRun> writeMergeGroupVerdict({
    required RepositorySlug slug,
    required int prNumber,
    required String mergeGroupSha,
  }) async {
    const title = 'WANT_LGTM: satisfied (waived in merge group)';
    const summary =
        'WANT_LGTM checks are evaluated on the pull request before entering the merge queue and are waived within the merge group.';
    return _githubChecksUtil.createCheckRun(
      _config,
      slug,
      mergeGroupSha,
      Config.kWantLgtmCheckName,
      status: CheckRunStatus.completed,
      conclusion: CheckRunConclusion.neutral,
      detailsUrl: detailsUrlFor(slug, prNumber),
      output: const CheckRunOutput(title: title, summary: summary),
    );
  }

  /// Updates an active check run to neutral/waived when the directive is removed or PR closed.
  Future<WantLgtmState> writeWaivedCheckRun({
    required RepositorySlug slug,
    required int prNumber,
    required int checkRunId,
    required String headSha,
    required String reason,
    WantLgtmState? existingState,
  }) async {
    final title = 'WANT_LGTM: waived ($reason)';
    final summary = 'WANT_LGTM directive was removed or waived: $reason.';
    await _githubChecksUtil.updateCheckRun(
      _config,
      slug,
      checkRunWithId(checkRunId),
      status: CheckRunStatus.completed,
      conclusion: CheckRunConclusion.neutral,
      detailsUrl: detailsUrlFor(slug, prNumber),
      output: CheckRunOutput(title: title, summary: summary),
    );

    final state =
        existingState ??
        WantLgtmState.initialize(
          slug: slug,
          pr: prNumber,
          headSha: headSha,
          checkRunId: checkRunId,
          checkRunStatus: 'completed',
          checkRunTitle: title,
          checkRunConclusion: 'neutral',
        );
    state.checkRunId = checkRunId;
    state.headSha = headSha;
    state.checkRunStatus = 'completed';
    state.checkRunConclusion = 'neutral';
    state.checkRunTitle = title;
    state.directive = null;
    state.updatedAt = DateTime.now().toUtc();
    await state.save(_firestoreService);
    return state;
  }

  /// Updates an active check run to neutral/waived when the feature is rolled back.
  Future<WantLgtmState> writeRolledBackCheckRun({
    required RepositorySlug slug,
    required int prNumber,
    required int checkRunId,
    required String headSha,
    WantLgtmState? existingState,
  }) async {
    const title = 'WANT_LGTM: waived (feature rolled back)';
    const summary =
        'WANT_LGTM rollout flag is disabled for this repository. Check run waived.';
    await _githubChecksUtil.updateCheckRun(
      _config,
      slug,
      checkRunWithId(checkRunId),
      status: CheckRunStatus.completed,
      conclusion: CheckRunConclusion.neutral,
      detailsUrl: detailsUrlFor(slug, prNumber),
      output: const CheckRunOutput(title: title, summary: summary),
    );

    final state =
        existingState ??
        WantLgtmState.initialize(
          slug: slug,
          pr: prNumber,
          headSha: headSha,
          checkRunId: checkRunId,
          checkRunStatus: 'completed',
          checkRunTitle: title,
          checkRunConclusion: 'neutral',
        );
    state.checkRunId = checkRunId;
    state.headSha = headSha;
    state.checkRunStatus = 'completed';
    state.checkRunConclusion = 'neutral';
    state.checkRunTitle = title;
    state.updatedAt = DateTime.now().toUtc();
    await state.save(_firestoreService);
    return state;
  }

  /// Sweeps in-progress WANT_LGTM states on disabled repositories and waives
  /// them as neutral.
  ///
  /// States belonging to repositories where `flags.wantLgtm` is currently
  /// enabled are skipped so per-repository rollbacks do not disturb active
  /// repositories.
  Future<int> sweepInProgressRuns({
    RepositorySlug? slug,
    bool dryRun = false,
  }) async {
    final states = await WantLgtmState.queryInProgress(
      firestoreService: _firestoreService,
      slug: slug,
    );
    var sweptCount = 0;
    for (final state in states) {
      if (_config.flags.wantLgtm.isEnabledForRepo(state.slug)) {
        continue;
      }
      if (dryRun) {
        sweptCount++;
        continue;
      }
      try {
        await writeRolledBackCheckRun(
          slug: state.slug,
          prNumber: state.pr,
          checkRunId: state.checkRunId,
          headSha: state.headSha,
          existingState: state,
        );
        sweptCount++;
      } catch (e, s) {
        log.error(
          'Failed to sweep WANT_LGTM check run on ${state.slug.fullName}#${state.pr}',
          e,
          s,
        );
      }
    }
    return sweptCount;
  }
}
