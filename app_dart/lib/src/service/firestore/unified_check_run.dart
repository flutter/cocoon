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
import 'package:meta/meta.dart';

import '../../model/common/failed_presubmit_jobs.dart';
import '../../model/common/presubmit_guard_conclusion.dart';
import '../../model/common/presubmit_job_state.dart';
import '../../model/firestore/base.dart';
import '../../model/firestore/ci_staging.dart';
import '../../model/firestore/presubmit_guard.dart';
import '../../model/firestore/presubmit_job.dart';
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
    @visibleForTesting DateTime Function() utcNow = DateTime.timestamp,
  }) async {
    if (checkRun != null &&
        pullRequest != null &&
        config.flags.isUnifiedCheckRunFlowEnabledForUser(
          pullRequest.user!.login!,
        )) {
      // Create the UnifiedCheckRun and UnifiedCheckRunBuilds.
      log.info(
        'Storing UnifiedCheckRun data for ${slug.fullName}#${pullRequest.number} as it enabled for user ${pullRequest.user!.login}.',
      );
      // We store the creation time of the guard since there might be several
      // guards for the same PR created and each new one created after previous
      // was succeeded so we are interested in a state of the latest one.
      final creationTime = utcNow().microsecondsSinceEpoch;
      final guard = PresubmitGuard(
        checkRun: checkRun,
        commitSha: sha,
        slug: slug,
        pullRequestId: pullRequest.number!,
        stage: stage,
        creationTime: creationTime,
        author: pullRequest.user!.login!,
        remainingBuilds: tasks.length,
        failedBuilds: 0,
        builds: {for (final task in tasks) task: TaskStatus.waitingForBackfill},
      );
      final jobs = [
        for (final task in tasks)
          PresubmitJob.init(
            buildName: task,
            checkRunId: checkRun.id!,
            creationTime: creationTime,
          ),
      ];
      await firestoreService.writeViaTransaction(
        documentsToWrites([...jobs, guard], exists: false),
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

  static Future<FailedJobsForRerun?> reInitializeFailedJobs({
    required FirestoreService firestoreService,
    required RepositorySlug slug,
    required int pullRequestId,
    required int checkRunId,
    @visibleForTesting DateTime Function() utcNow = DateTime.timestamp,
  }) async {
    final logCrumb =
        'reInitializeFailedJobs(${slug.fullName}, $pullRequestId, $checkRunId)';

    log.info('$logCrumb Re-Running failed jobs.');
    final transaction = await firestoreService.beginTransaction();

    // New guard created only if previous is succeeded so failed jobs might be
    // only in latest guard.
    final guard = await getLatestPresubmitGuardForCheckRun(
      firestoreService: firestoreService,
      slug: slug,
      pullRequestId: pullRequestId,
      checkRunId: checkRunId,
      transaction: transaction,
    );

    if (guard == null) {
      return null;
    }

    // Copy the failed build names to a local variable to avoid losing the
    // failed build names after resetting the failed guard.builds.
    final creationTime = utcNow().microsecondsSinceEpoch;
    final failedBuildNames = guard.failedBuildNames;
    if (failedBuildNames.isNotEmpty) {
      guard.failedBuilds = 0;
      guard.remainingBuilds = failedBuildNames.length;
      final builds = guard.builds;
      for (final buildName in failedBuildNames) {
        builds[buildName] = TaskStatus.waitingForBackfill;
      }
      guard.builds = builds;
      final jobs = [
        for (final buildName in failedBuildNames)
          PresubmitJob.init(
            buildName: buildName,
            checkRunId: checkRunId,
            creationTime: creationTime,
            attemptNumber:
                ((await getLatestPresubmitJob(
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
          documentsToWrites([...jobs, guard]),
        );
        log.info(
          '$logCrumb: results = ${response.writeResults?.map((e) => e.toJson())}',
        );
        return FailedJobsForRerun(
          checkRunGuard: guard.checkRun,
          checkNames: failedBuildNames,
          stage: guard.stage,
        );
      } catch (e) {
        log.info('$logCrumb: failed to update presubmit job', e);
        rethrow;
      }
    }
    return null;
  }

  /// Returns _all_ jobs running against the specified github [checkRunId].
  static Future<List<PresubmitJob>> queryAllPresubmitJobsForGuard({
    required FirestoreService firestoreService,
    required int checkRunId,
    TaskStatus? status,
    String? buildName,
    Transaction? transaction,
  }) async {
    return await _queryPresubmitJobs(
      firestoreService: firestoreService,
      checkRunId: checkRunId,
      buildName: buildName,
      status: status,
      transaction: transaction,
    );
  }

  /// Returns job for the specified github [checkRunId] and
  /// [buildName] and [attemptNumber].
  static Future<PresubmitJob?> queryPresubmitJob({
    required FirestoreService firestoreService,
    required int checkRunId,
    required String buildName,
    required int attemptNumber,
    Transaction? transaction,
  }) async {
    return (await _queryPresubmitJobs(
      firestoreService: firestoreService,
      checkRunId: checkRunId,
      buildName: buildName,
      status: null,
      attemptNumber: attemptNumber,
      transaction: transaction,
    )).firstOrNull;
  }

  /// Returns the latest [PresubmitJob] for the specified github [checkRunId] and
  /// [buildName].
  static Future<PresubmitJob?> getLatestPresubmitJob({
    required FirestoreService firestoreService,
    required int checkRunId,
    required String buildName,
    Transaction? transaction,
  }) async {
    return (await _queryPresubmitJobs(
      firestoreService: firestoreService,
      checkRunId: checkRunId,
      buildName: buildName,
      status: null,
      transaction: transaction,
      limit: 1,
    )).firstOrNull;
  }

  /// Returns the latest [PresubmitGuard] for the specified github [checkRunId].
  static Future<PresubmitGuard?> getLatestPresubmitGuardForCheckRun({
    required FirestoreService firestoreService,
    required RepositorySlug slug,
    required int pullRequestId,
    required int checkRunId,
    Transaction? transaction,
  }) async {
    return (await _queryPresubmitGuards(
      firestoreService: firestoreService,
      checkRunId: checkRunId,
      transaction: transaction,
      limit: 1,
    )).firstOrNull;
  }

  /// Queries for [PresubmitGuard] records by [slug] and [commitSha].
  static Future<List<PresubmitGuard>> getPresubmitGuardsForCommitSha({
    required FirestoreService firestoreService,
    required RepositorySlug slug,
    required String commitSha,
  }) async {
    return await _queryPresubmitGuards(
      firestoreService: firestoreService,
      slug: slug,
      commitSha: commitSha,
    );
  }

  /// Queries for [PresubmitGuard] records by [slug] and [pullRequestId].
  static Future<List<PresubmitGuard>> getPresubmitGuardsForPullRequest({
    required FirestoreService firestoreService,
    required RepositorySlug slug,
    required int pullRequestId,
  }) async {
    return await _queryPresubmitGuards(
      firestoreService: firestoreService,
      slug: slug,
      pullRequestId: pullRequestId,
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
      '${PresubmitGuard.fieldSlug} =': ?slug?.fullName,
      '${PresubmitGuard.fieldPullRequestId} =': ?pullRequestId,
      '${PresubmitGuard.fieldCheckRunId} =': ?checkRunId,
      '${PresubmitGuard.fieldStage} =': ?stage?.name,
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

  /// Returns detailed information for a specific presubmit job identified by
  /// [checkRunId] and [buildName].
  ///
  /// The results are ordered by attempt number descending.
  static Future<List<PresubmitJob>> getPresubmitJobDetails({
    required FirestoreService firestoreService,
    required int checkRunId,
    required String buildName,
  }) async {
    return await _queryPresubmitJobs(
      firestoreService: firestoreService,
      checkRunId: checkRunId,
      buildName: buildName,
    );
  }

  static Future<List<PresubmitJob>> _queryPresubmitJobs({
    required FirestoreService firestoreService,
    required int checkRunId,
    String? buildName,
    TaskStatus? status,
    Transaction? transaction,
    int? attemptNumber,
    // By default order by attempt number descending.
    Map<String, String>? orderMap = const {
      PresubmitJob.fieldAttemptNumber: kQueryOrderDescending,
    },
    int? limit,
  }) async {
    final filterMap = {
      '${PresubmitJob.fieldCheckRunId} =': checkRunId,
      '${PresubmitJob.fieldBuildName} =': ?buildName,
      '${PresubmitJob.fieldStatus} =': ?status?.value,
      '${PresubmitJob.fieldAttemptNumber} =': ?attemptNumber,
    };
    final documents = await firestoreService.query(
      PresubmitJob.collectionId,
      filterMap,
      limit: limit,
      orderMap: orderMap,
      transaction: transaction,
    );
    return [...documents.map(PresubmitJob.fromDocument)];
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
    required PresubmitJobState state,
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
    late final PresubmitJob presubmitJob;
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
          remaining: presubmitGuard.remainingBuilds,
          checkRunGuard: presubmitGuard.checkRunJson,
          failed: presubmitGuard.failedBuilds,
          summary:
              'Job run "${state.buildName}" not present in ${guardId.stage} CI stage',
          details: 'Change $changeCrumb',
        );
      }

      final checkDocName = PresubmitJob.documentNameFor(
        checkRunId: guardId.checkRunId,
        buildName: state.buildName,
        attemptNumber: state.attemptNumber,
      );
      final presubmitJobDocument = await firestoreService.getDocument(
        checkDocName,
        transaction: transaction,
      );
      presubmitJob = PresubmitJob.fromDocument(presubmitJobDocument);

      remaining = presubmitGuard.remainingBuilds;
      failed = presubmitGuard.failedBuilds;
      final builds = presubmitGuard.builds;
      var status = builds[state.buildName]!;

      // If build is waiting for backfill, that means its initiated by github
      // or re-run. So no processing needed, we should only update appropriate
      // jobs with that [TaskStatus]
      if (state.status == TaskStatus.waitingForBackfill) {
        status = state.status;
        valid = true;
        // If build is in progress, we should update apropriate jobs with start
        // time and their status to that [TaskStatus] only if the build is not
        // completed.
      } else if (state.status == TaskStatus.inProgress) {
        presubmitJob.startTime = state.startTime!;
        // If the build is not completed, update the status.
        if (!status.isBuildCompleted) {
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

        // All jobs pass. "valid" is only set to true if there was a change in either the remaining or failed count.
        log.info(
          '$logCrumb: setting remaining to $remaining, failed to $failed',
        );
        presubmitGuard.remainingBuilds = remaining;
        presubmitGuard.failedBuilds = failed;
        presubmitJob.endTime = state.endTime!;
        presubmitJob.summary = state.summary;
        presubmitJob.buildNumber = state.buildNumber;
      }
      builds[state.buildName] = status;
      presubmitGuard.builds = builds;
      presubmitJob.status = status;
    } on DetailedApiRequestError catch (e, stack) {
      if (e.status == 404) {
        // An attempt to read a document not in firestore should not be retried.
        log.info(
          '$logCrumb: ${PresubmitJob.collectionId} document not found for $transaction',
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
${PresubmitJob.collectionId} document not found for stage "${guardId.stage}" for $changeCrumb. Got 404 from Firestore.
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
        documentsToWrites([presubmitGuard, presubmitJob], exists: true),
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
            : 'Attempted to set the state of job run ${state.buildName} '
                  'to "${state.status.name}".',
      );
    } catch (e) {
      log.info('$logCrumb: failed to update presubmit job', e);
      rethrow;
    }
  }
}
