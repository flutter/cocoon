// Copyright 2025 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// @docImport 'unified_check_run.dart';
library;

import 'package:cocoon_common/task_status.dart';
import 'package:cocoon_server/logging.dart';
import 'package:collection/collection.dart';
import 'package:github/github.dart';
import 'package:googleapis/firestore/v1.dart' hide Status;

import '../../model/common/failed_presubmit_checks.dart';
import '../../model/common/presubmit_check_state.dart';
import '../../model/common/presubmit_guard_conclusion.dart';
import '../../model/firestore/base.dart';
import '../../model/firestore/ci_staging.dart';
import '../../model/firestore/presubmit_check.dart';
import '../../model/firestore/presubmit_guard.dart';
import '../config.dart';
import '../firestore.dart';

final class UnifiedCheckRun {
  static Future<void> initializeCiStagingDocument({
    required FirestoreService firestoreService,
    required RepositorySlug slug,
    required String sha,
    required CiStage stage,
    required List<String> tasks,
    required Config config,
    PullRequest? pullRequest,
    CheckRun? checkRun,
  }) async {
    if (checkRun != null &&
        pullRequest != null &&
        config.flags.isUnifiedCheckRunFlowEnabledForUser(
          pullRequest.user!.login!,
        )) {
      log.info(
        'Storing UnifiedCheckRun data for ${slug.fullName}#${pullRequest.number} as it enabled for user ${pullRequest.user!.login}.',
      );
      // Create the UnifiedCheckRun and UnifiedCheckRunBuilds.
      final guard = PresubmitGuard(
        checkRun: checkRun,
        commitSha: sha,
        slug: slug,
        pullRequestId: pullRequest.number!,
        stage: stage,
        creationTime: pullRequest.createdAt!.microsecondsSinceEpoch,
        author: pullRequest.user!.login!,
        remainingBuilds: tasks.length,
        failedBuilds: 0,
        builds: {for (final task in tasks) task: TaskStatus.waitingForBackfill},
      );
      final checks = [
        for (final task in tasks)
          PresubmitCheck.init(
            buildName: task,
            checkRunId: checkRun.id!,
            creationTime: pullRequest.createdAt!.microsecondsSinceEpoch,
          ),
      ];
      await firestoreService.writeViaTransaction(
        documentsToWrites([...checks, guard], exists: false),
      );
    } else {
      // Initialize the CiStaging document.
      await CiStaging.initializeDocument(
        firestoreService: firestoreService,
        slug: slug,
        sha: sha,
        stage: stage,
        tasks: tasks,
        checkRunGuard: checkRun != null ? '$checkRun' : '',
      );
    }
  }

  static Future<FailedChecksForRerun?> reInitializeFailedChecks({
    required FirestoreService firestoreService,
    required RepositorySlug slug,
    required int pullRequestId,
    required int checkRunId,
  }) async {
    final logCrumb =
        'reInitializeFailedChecks(${slug.fullName}, $pullRequestId, $checkRunId)';

    log.info('$logCrumb Re-Running failed checks.');
    final transaction = await firestoreService.beginTransaction();

    final guards = await getPresubmitGuardsForCheckRun(
      firestoreService: firestoreService,
      slug: slug,
      pullRequestId: pullRequestId,
      checkRunId: checkRunId,
      transaction: transaction,
    );

    for (final guard in guards) {
      // Copy the failed build names to a local variable to avoid losing the
      // failed build names after resetting the failed guard.builds.
      final failedBuildNames = guard.failedBuildNames;
      if (failedBuildNames.isNotEmpty) {
        guard.failedBuilds = 0;
        guard.remainingBuilds = failedBuildNames.length;
        final builds = guard.builds;
        for (final buildName in failedBuildNames) {
          builds[buildName] = TaskStatus.waitingForBackfill;
        }
        guard.builds = builds;
        final checks = [
          for (final buildName in failedBuildNames)
            PresubmitCheck.init(
              buildName: buildName,
              checkRunId: checkRunId,
              creationTime: DateTime.now().toUtc().microsecondsSinceEpoch,
              attemptNumber:
                  ((await getLatestPresubmitCheck(
                        firestoreService: firestoreService,
                        checkRunId: checkRunId,
                        buildName: buildName,
                        transaction: transaction,
                      ))?.attemptNumber ??
                      0) +
                  1, // Increment the latest attempt number.
            ),
        ];
        try {
          final response = await firestoreService.commit(
            transaction,
            documentsToWrites([...checks, guard]),
          );
          log.info(
            '$logCrumb: results = ${response.writeResults?.map((e) => e.toJson())}',
          );
          return FailedChecksForRerun(
            checkRunGuard: guard.checkRun,
            checkNames: failedBuildNames,
            stage: guard.stage,
          );
        } catch (e) {
          log.info('$logCrumb: failed to update presubmit check', e);
          rethrow;
        }
      }
    }
    return null;
  }

  /// Returns _all_ checks running against the specified github [checkRunId].
  static Future<List<PresubmitCheck>> queryAllPresubmitChecksForGuard({
    required FirestoreService firestoreService,
    required int checkRunId,
    TaskStatus? status,
    String? buildName,
    Transaction? transaction,
  }) async {
    return await _queryPresubmitChecks(
      firestoreService: firestoreService,
      checkRunId: checkRunId,
      buildName: buildName,
      status: status,
      transaction: transaction,
    );
  }

  /// Returns check for the specified github [checkRunId] and
  /// [buildName] and [attemptNumber].
  static Future<PresubmitCheck?> queryPresubmitCheck({
    required FirestoreService firestoreService,
    required int checkRunId,
    required String buildName,
    required int attemptNumber,
    Transaction? transaction,
  }) async {
    return (await _queryPresubmitChecks(
      firestoreService: firestoreService,
      checkRunId: checkRunId,
      buildName: buildName,
      status: null,
      attemptNumber: attemptNumber,
      transaction: transaction,
    )).firstOrNull;
  }

  /// Returns the latest check for the specified github [checkRunId] and
  /// [buildName].
  static Future<PresubmitCheck?> getLatestPresubmitCheck({
    required FirestoreService firestoreService,
    required int checkRunId,
    required String buildName,
    Transaction? transaction,
  }) async {
    return (await _queryPresubmitChecks(
      firestoreService: firestoreService,
      checkRunId: checkRunId,
      buildName: buildName,
      status: null,
      transaction: transaction,
      limit: 1,
    )).firstOrNull;
  }

  /// Returns [PresubmitGuard]s for the specified github [checkRunId].
  static Future<List<PresubmitGuard>> getPresubmitGuardsForCheckRun({
    required FirestoreService firestoreService,
    required RepositorySlug slug,
    required int pullRequestId,
    required int checkRunId,
    Transaction? transaction,
  }) async {
    return await _queryPresubmitGuards(
      firestoreService: firestoreService,
      checkRunId: checkRunId,
      transaction: transaction,
      orderMap: const {PresubmitGuard.fieldStage: kQueryOrderAscending},
    );
  }

  static Future<List<PresubmitGuard>> _queryPresubmitGuards({
    required FirestoreService firestoreService,
    Transaction? transaction,
    int? checkRunId,
    String? commitSha,
    RepositorySlug? slug,
    int? pullRequestId,
    CiStage? stage,
    int? creationTime,
    String? author,
    Map<String, String>? orderMap = const {
      PresubmitGuard.fieldCreationTime: kQueryOrderDescending,
    },
    int? limit,
  }) async {
    final filterMap = {
      '${PresubmitGuard.fieldSlug} =': ?slug,
      '${PresubmitGuard.fieldPullRequestId} =': ?pullRequestId,
      '${PresubmitGuard.fieldCheckRunId} =': ?checkRunId,
      '${PresubmitGuard.fieldStage} =': ?stage,
      '${PresubmitGuard.fieldCreationTime} =': ?creationTime,
      '${PresubmitGuard.fieldAuthor} =': ?author,
      '${PresubmitGuard.fieldCommitSha} =': ?commitSha,
    };
    final documents = await firestoreService.query(
      PresubmitGuard.collectionId,
      filterMap,
      transaction: transaction,
      limit: limit,
      orderMap: orderMap,
    );
    return [...documents.map(PresubmitGuard.fromDocument)];
  }

  static Future<List<PresubmitCheck>> _queryPresubmitChecks({
    required FirestoreService firestoreService,
    required int checkRunId,
    String? buildName,
    TaskStatus? status,
    Transaction? transaction,
    int? attemptNumber,
    // By default order by attempt number descending to get the latest check first.
    Map<String, String>? orderMap = const {
      PresubmitCheck.fieldAttemptNumber: kQueryOrderDescending,
    },
    int? limit,
  }) async {
    final filterMap = {
      '${PresubmitCheck.fieldCheckRunId} =': checkRunId,
      '${PresubmitCheck.fieldBuildName} =': ?buildName,
      '${PresubmitCheck.fieldStatus} =': ?status?.value,
      '${PresubmitCheck.fieldAttemptNumber} =': ?attemptNumber,
    };
    final documents = await firestoreService.query(
      PresubmitCheck.collectionId,
      filterMap,
      limit: limit,
      orderMap: orderMap,
      transaction: transaction,
    );
    return [...documents.map(PresubmitCheck.fromDocument)];
  }

  /// Mark a [buildName] for a given [stage] with [conclusion].
  ///
  /// Returns a [PresubmitGuardConclusion] record or throws. If the check_run was
  /// both valid and recorded successfully, the record's `remaining` value
  /// signals how many more tests are running. Returns the record (valid: false)
  /// otherwise.
  static Future<PresubmitGuardConclusion> markConclusion({
    required FirestoreService firestoreService,
    required PresubmitGuardId guardId,
    required PresubmitCheckState state,
  }) async {
    final changeCrumb =
        '${guardId.slug.owner}_${guardId.slug.name}_${guardId.pullRequestId}_${guardId.checkRunId}';
    final logCrumb =
        'markConclusion(${changeCrumb}_${guardId.stage}, ${state.buildName}, ${state.status}, ${state.attemptNumber})';

    // Marking needs to happen while in a transaction to ensure `remaining` is
    // updated correctly. For that to happen correctly; we need to perform a
    // read of the document in the transaction as well. So start the transaction
    // first thing.
    final transaction = await firestoreService.beginTransaction();

    var remaining = -1;
    var failed = -1;
    var valid = false;

    late final PresubmitGuard presubmitGuard;
    late final PresubmitCheck presubmitCheck;
    // transaction block
    try {
      // First: read the fields we want to change.
      final presubmitGuardDocumentName = PresubmitGuard.documentNameFor(
        slug: guardId.slug,
        pullRequestId: guardId.pullRequestId,
        checkRunId: guardId.checkRunId,
        stage: guardId.stage,
      );
      final presubmitGuardDocument = await firestoreService.getDocument(
        presubmitGuardDocumentName,
        transaction: transaction,
      );
      presubmitGuard = PresubmitGuard.fromDocument(presubmitGuardDocument);

      // Check if the build is present in the guard before trying to load it.
      if (presubmitGuard.builds[state.buildName] == null) {
        log.info(
          '$logCrumb: ${state.buildName} with attemptNumber ${state.attemptNumber} not present for $transaction / ${presubmitGuardDocument.fields}',
        );
        await firestoreService.rollback(transaction);
        return PresubmitGuardConclusion(
          result: PresubmitGuardConclusionResult.missing,
          remaining: presubmitGuard.remainingBuilds!,
          checkRunGuard: presubmitGuard.checkRunJson,
          failed: presubmitGuard.failedBuilds!,
          summary:
              'Check run "${state.buildName}" not present in ${guardId.stage} CI stage',
          details: 'Change $changeCrumb',
        );
      }

      final checkDocName = PresubmitCheck.documentNameFor(
        checkRunId: guardId.checkRunId,
        buildName: state.buildName,
        attemptNumber: state.attemptNumber,
      );
      final presubmitCheckDocument = await firestoreService.getDocument(
        checkDocName,
        transaction: transaction,
      );
      presubmitCheck = PresubmitCheck.fromDocument(presubmitCheckDocument);

      remaining = presubmitGuard.remainingBuilds!;
      failed = presubmitGuard.failedBuilds!;
      final builds = presubmitGuard.builds;
      var status = builds[state.buildName]!;

      // If build is waiting for backfill, that means its initiated by github
      // or re-run. So no processing needed, we should only update appropriate
      // checks with that [TaskStatus]
      if (state.status == TaskStatus.waitingForBackfill) {
        status = state.status;
        valid = true;
        // If build is in progress, we should update apropriate checks with start
        // time and their status to that [TaskStatus] only if the build is not
        // completed.
      } else if (state.status == TaskStatus.inProgress) {
        presubmitCheck.startTime = state.startTime!;
        // If the build is not completed, update the status.
        if (!status!.isBuildCompleted) {
          status = state.status;
        }
        valid = true;
      } else {
        // "remaining" should go down if build is succeeded or failed.
        // "failed_count" can go up or down depending on:
        //   attemptNumber > 1 && buildSuccessed: down (-1)
        //   attemptNumber = 1 && buildFailed: up (+1)
        // So if the test existed and either remaining or failed_count is changed;
        // the response is valid.
        status = state.status;
        if (status.isBuildCompleted) {
          // Guard against going negative and log enough info so we can debug.
          if (remaining == 0) {
            throw '$logCrumb: field "${PresubmitGuard.fieldRemainingBuilds}" is already zero for $transaction / ${presubmitGuardDocument.fields}';
          }
          remaining = remaining - 1;
        }

        if (status.isBuildSuccessed) {
          // Only rollback the "failed" counter if this is a successful test run,
          // i.e. the test failed, the user requested a rerun, and now it passes.
          if (state.attemptNumber > 1) {
            log.info(
              '$logCrumb: conclusion flipped to positive - assuming test was re-run',
            );
            if (failed == 0) {
              throw '$logCrumb: field "${PresubmitGuard.fieldFailedBuilds}" is already zero for $transaction / ${presubmitGuardDocument.fields}';
            }
            failed = failed - 1;
          }
          valid = true;
        }

        // Only increment the "failed" counter if the conclusion failed for the first attempt.
        if (status.isBuildFailed) {
          if (state.attemptNumber == 1) {
            log.info('$logCrumb: test failed');
            failed = failed + 1;
          }
          valid = true;
        }

        // All checks pass. "valid" is only set to true if there was a change in either the remaining or failed count.
        log.info(
          '$logCrumb: setting remaining to $remaining, failed to $failed',
        );
        presubmitGuard.remainingBuilds = remaining;
        presubmitGuard.failedBuilds = failed;
        presubmitCheck.endTime = state.endTime!;
        presubmitCheck.summary = state.summary;
      }
      builds[state.buildName] = status;
      presubmitGuard.builds = builds;
      presubmitCheck.status = status;
    } on DetailedApiRequestError catch (e, stack) {
      if (e.status == 404) {
        // An attempt to read a document not in firestore should not be retried.
        log.info(
          '$logCrumb: ${PresubmitCheck.collectionId} document not found for $transaction',
        );
        await firestoreService.rollback(transaction);
        return PresubmitGuardConclusion(
          result: PresubmitGuardConclusionResult.internalError,
          remaining: -1,
          checkRunGuard: null,
          failed: failed,
          summary: 'Internal server error',
          details:
              '''
${PresubmitCheck.collectionId} document not found for stage "${guardId.stage}" for $changeCrumb. Got 404 from Firestore.
Error: ${e.toString()}
$stack
''',
        );
      }
      // All other errors should bubble up and be retried.
      await firestoreService.rollback(transaction);
      rethrow;
    } catch (e) {
      // All other errors should bubble up and be retried.
      await firestoreService.rollback(transaction);
      rethrow;
    }
    // Commit this write firebase and if no one else was writing at the same time, return success.
    // If this commit fails, that means someone else modified firestore and the caller should try again.
    // We do not need to rollback the transaction; firebase documentation says a failed commit takes care of that.
    try {
      final response = await firestoreService.commit(
        transaction,
        documentsToWrites([presubmitGuard, presubmitCheck], exists: true),
      );
      log.info(
        '$logCrumb: results = ${response.writeResults?.map((e) => e.toJson())}',
      );
      return PresubmitGuardConclusion(
        result: valid
            ? PresubmitGuardConclusionResult.ok
            : PresubmitGuardConclusionResult.internalError,
        remaining: remaining,
        checkRunGuard: presubmitGuard.checkRunJson,
        failed: failed,
        summary: valid
            ? 'Successfully updated presubmit guard status'
            : 'Not a valid state transition for ${state.buildName}',
        details: valid
            ? '''
For CI stage ${guardId.stage}:
  Pending: $remaining
  Failed: $failed
'''
            : 'Attempted to set the state of check run ${state.buildName} '
                  'to "${state.status.name}".',
      );
    } catch (e) {
      log.error('$logCrumb: failed to update presubmit check', e);
      rethrow;
    }
  }
}
