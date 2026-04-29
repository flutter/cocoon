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
      // Create the presubmit_guard and associated presubmit_job documents.
      log.info(
        'Storing UnifiedCheckRun data for ${slug.fullName}#${pullRequest.number} as it enabled for user ${pullRequest.user!.login}.',
      );
      // We store the creation time of the guard since there might be several
      // guards for the same PR created and each new one created after previous
      // was succeeded so we are interested in a state of the latest one.
      final creationTime = utcNow().millisecondsSinceEpoch;
      final guard = PresubmitGuard(
        checkRun: checkRun,
        headSha: sha,
        slug: slug,
        prNum: pullRequest.number!,
        stage: stage,
        creationTime: creationTime,
        author: pullRequest.user!.login!,
        remainingJobs: tasks.length,
        failedJobs: 0,
        jobs: {for (final task in tasks) task: TaskStatus.waitingForBackfill},
      );
      final jobs = [
        for (final task in tasks)
          PresubmitJob.init(
            slug: slug,
            jobName: task,
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

  /// Re-initializes all failed jobs for the specified [guardCheckRunId].
  static Future<FailedJobsForRerun?> reInitializeFailedJobs({
    required FirestoreService firestoreService,
    required RepositorySlug slug,
    required int prNum,
    required int guardCheckRunId,
    @visibleForTesting DateTime Function() utcNow = DateTime.timestamp,
  }) async {
    final guard = await getLatestPresubmitGuardForCheckRun(
      firestoreService: firestoreService,
      slug: slug,
      prNum: prNum,
      checkRunId: guardCheckRunId,
    );

    if (guard == null) {
      return null;
    }

    final logCrumb =
        'reInitializeFailedChecks(${slug.fullName}, $prNum, $guardCheckRunId)';

    log.info('$logCrumb Re-Running failed checks.');
    final transaction = await firestoreService.beginTransaction();

    // New guard created only if previous is succeeded so failed checks might be
    // only in latest guard.
    final latestGuard = await getLatestPresubmitGuardForCheckRun(
      firestoreService: firestoreService,
      slug: slug,
      prNum: prNum,
      checkRunId: guardCheckRunId,
      transaction: transaction,
    );

    if (latestGuard == null) {
      await firestoreService.rollback(transaction);
      return null;
    }

    final creationTime = utcNow().millisecondsSinceEpoch;
    final failedJobNames = latestGuard.failedJobNames;
    if (failedJobNames.isNotEmpty) {
      latestGuard.failedJobs = 0;
      latestGuard.remainingJobs = failedJobNames.length;
      final jobs = latestGuard.jobs;
      for (final jobName in failedJobNames) {
        jobs[jobName] = TaskStatus.waitingForBackfill;
      }
      latestGuard.jobs = jobs;
      final checks = <PresubmitJob>[];
      final checkRetries = <String, int>{};
      for (final jobName in failedJobNames) {
        final latestCheck = await getLatestPresubmitJob(
          firestoreService: firestoreService,
          checkRunId: guardCheckRunId,
          jobName: jobName,
          transaction: transaction,
        );
        checkRetries[jobName] = (latestCheck?.attemptNumber ?? 0) + 1;
        checks.add(
          PresubmitJob.init(
            slug: slug,
            jobName: jobName,
            checkRunId: guardCheckRunId,
            creationTime: creationTime,
            attemptNumber: (latestCheck?.attemptNumber ?? 0) + 1,
          ),
        );
      }
      try {
        final response = await firestoreService.commit(
          transaction,
          documentsToWrites([...checks, latestGuard]),
        );
        log.info(
          '$logCrumb: results = ${response.writeResults?.map((e) => e.toJson())}',
        );
        return FailedJobsForRerun(
          checkRunGuard: latestGuard.checkRun,
          jobRetries: checkRetries,
          stage: latestGuard.stage,
        );
      } catch (e) {
        log.info('$logCrumb: failed to update presubmit job', e);
        rethrow;
      }
    }
    await firestoreService.rollback(transaction);
    return null;
  }

  /// Re-initializes a specific failed check for the specified [guardCheckRunId] and [jobName].
  static Future<FailedJobsForRerun?> reInitializeFailedJob({
    required FirestoreService firestoreService,
    required RepositorySlug slug,
    required int prNum,
    required int guardCheckRunId,
    required String jobName,
    @visibleForTesting DateTime Function() utcNow = DateTime.timestamp,
  }) async {
    final logCrumb =
        'reInitializeFailedJob(${slug.fullName}, $prNum, $guardCheckRunId, $jobName)';

    log.info('$logCrumb Re-Running failed job.');
    final transaction = await firestoreService.beginTransaction();

    final guard = await getLatestPresubmitGuardForCheckRun(
      firestoreService: firestoreService,
      slug: slug,
      prNum: prNum,
      checkRunId: guardCheckRunId,
      transaction: transaction,
    );

    if (guard == null || !guard.jobs.containsKey(jobName)) {
      await firestoreService.rollback(transaction);
      return null;
    }

    final creationTime = utcNow().millisecondsSinceEpoch;
    final jobs = guard.jobs;
    final currentStatus = jobs[jobName]!;

    // If job is failed we increment remain jobs and decrement failed.
    // If job succeeded re-run is not possible but if some how they manage to
    // request re-run we have to only increment remaining jobs.
    // If job is still in progress re-run is not possible but if some how they
    // manage to request re-run we should not touch any counters.
    if (currentStatus.isComplete) {
      guard.remainingJobs += 1;
      if (currentStatus.isFailure && guard.failedJobs > 0) {
        guard.failedJobs -= 1;
      }
    }

    jobs[jobName] = TaskStatus.waitingForBackfill;
    guard.jobs = jobs;

    final latestCheck = await getLatestPresubmitJob(
      firestoreService: firestoreService,
      checkRunId: guardCheckRunId,
      jobName: jobName,
      transaction: transaction,
    );

    final check = PresubmitJob.init(
      slug: slug,
      jobName: jobName,
      checkRunId: guardCheckRunId,
      creationTime: creationTime,
      attemptNumber: (latestCheck?.attemptNumber ?? 0) + 1,
    );

    try {
      final response = await firestoreService.commit(
        transaction,
        documentsToWrites([check, guard]),
      );
      log.info(
        '$logCrumb: results = ${response.writeResults?.map((e) => e.toJson())}',
      );
      return FailedJobsForRerun(
        checkRunGuard: guard.checkRun,
        jobRetries: {jobName: (latestCheck?.attemptNumber ?? 0) + 1},
        stage: guard.stage,
      );
    } catch (e) {
      log.info('$logCrumb: failed to update presubmit job', e);
      rethrow;
    }
  }

  /// Returns _all_ jobs running against the specified github [checkRunId].
  static Future<List<PresubmitJob>> queryAllPresubmitJobsForGuard({
    required FirestoreService firestoreService,
    required int checkRunId,
    TaskStatus? status,
    String? jobName,
    Transaction? transaction,
  }) async {
    return await _queryPresubmitJobs(
      firestoreService: firestoreService,
      checkRunId: checkRunId,
      jobName: jobName,
      status: status,
      transaction: transaction,
    );
  }

  /// Returns check for the specified github [checkRunId] and
  /// [jobName] and [attemptNumber].
  static Future<PresubmitJob?> queryPresubmitJob({
    required FirestoreService firestoreService,
    required int checkRunId,
    required String jobName,
    required int attemptNumber,
    Transaction? transaction,
  }) async {
    return (await _queryPresubmitJobs(
      firestoreService: firestoreService,
      checkRunId: checkRunId,
      jobName: jobName,
      status: null,
      attemptNumber: attemptNumber,
      transaction: transaction,
    )).firstOrNull;
  }

  /// Returns the latest [PresubmitJob] for the specified github [checkRunId] and
  /// [jobName].
  static Future<PresubmitJob?> getLatestPresubmitJob({
    required FirestoreService firestoreService,
    required int checkRunId,
    required String jobName,
    Transaction? transaction,
  }) async {
    return (await _queryPresubmitJobs(
      firestoreService: firestoreService,
      checkRunId: checkRunId,
      jobName: jobName,
      status: null,
      transaction: transaction,
      limit: 1,
    )).firstOrNull;
  }

  /// Returns the latest [PresubmitGuard] for the specified github [checkRunId].
  static Future<PresubmitGuard?> getLatestPresubmitGuardForCheckRun({
    required FirestoreService firestoreService,
    required RepositorySlug slug,
    required int prNum,
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

  /// Returns the latest failed [PresubmitJob] for the specified github [checkRunId].
  static Future<List<PresubmitJob>> getLatestFailedJobs({
    required FirestoreService firestoreService,
    required int checkRunId,
  }) async {
    final filterMap = <String, Object>{
      PresubmitJob.fieldCheckRunId: checkRunId,
    };
    final docs = await firestoreService.query(
      PresubmitJob.collectionId,
      filterMap,
    );
    final allChecks = docs.map(PresubmitJob.fromDocument).toList();

    // Group by jobName and find the latest attempt.
    final latestChecks = <String, PresubmitJob>{};
    for (final check in allChecks) {
      final currentLatest = latestChecks[check.jobName];
      if (currentLatest == null ||
          check.attemptNumber > currentLatest.attemptNumber) {
        latestChecks[check.jobName] = check;
      }
    }

    return latestChecks.values
        .where((check) => check.status.isFailure)
        .toList();
  }

  /// Returns the latest [PresubmitGuard] for the specified github [checkRunId].
  static Future<PresubmitGuard?> getLatestPresubmitGuardForCheckRunId({
    required FirestoreService firestoreService,
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

  /// Returns the latest [PresubmitGuard] for the specified [slug] and [prNum].
  static Future<PresubmitGuard?> getLatestPresubmitGuardForPrNum({
    required FirestoreService firestoreService,
    required RepositorySlug slug,
    required int prNum,
    Transaction? transaction,
  }) async {
    return (await _queryPresubmitGuards(
      firestoreService: firestoreService,
      slug: slug,
      prNum: prNum,
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

  /// Queries for [PresubmitGuard] records by [slug] and [prNum].
  static Future<List<PresubmitGuard>> getPresubmitGuardsForPullRequest({
    required FirestoreService firestoreService,
    required RepositorySlug slug,
    required int prNum,
  }) async {
    return await _queryPresubmitGuards(
      firestoreService: firestoreService,
      slug: slug,
      prNum: prNum,
    );
  }

  static Future<List<PresubmitGuard>> _queryPresubmitGuards({
    required FirestoreService firestoreService,
    Transaction? transaction,
    int? checkRunId,
    String? commitSha,
    RepositorySlug? slug,
    int? prNum,
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
      '${PresubmitGuard.fieldPrNum} =': ?prNum,
      '${PresubmitGuard.fieldCheckRunId} =': ?checkRunId,
      '${PresubmitGuard.fieldStage} =': ?stage?.name,
      '${PresubmitGuard.fieldCreationTime} =': ?creationTime,
      '${PresubmitGuard.fieldAuthor} =': ?author,
      '${PresubmitGuard.fieldHeadSha} =': ?commitSha,
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
  /// [checkRunId] and [jobName].
  ///
  /// The results are ordered by attempt number descending.
  static Future<List<PresubmitJob>> getPresubmitJobDetails({
    required FirestoreService firestoreService,
    required int checkRunId,
    required String jobName,
    RepositorySlug? slug,
  }) async {
    return await _queryPresubmitJobs(
      firestoreService: firestoreService,
      checkRunId: checkRunId,
      jobName: jobName,
      slug: slug,
    );
  }

  static Future<List<PresubmitJob>> _queryPresubmitJobs({
    required FirestoreService firestoreService,
    required int checkRunId,
    RepositorySlug? slug,
    String? jobName,
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
      '${PresubmitJob.fieldSlug} =': ?slug?.fullName,
      '${PresubmitJob.fieldCheckRunId} =': checkRunId,
      '${PresubmitJob.fieldJobName} =': ?jobName,
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

  /// Mark a [jobName] for a given [stage] with [conclusion].
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
        '${guardId.slug.owner}_${guardId.slug.name}_${guardId.prNum}_${guardId.checkRunId}';
    final logCrumb =
        'markConclusion(${changeCrumb}_${guardId.stage}, ${state.jobName}, ${state.status}, ${state.attemptNumber})';

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
        prNum: guardId.prNum,
        checkRunId: guardId.checkRunId,
        stage: guardId.stage,
      );
      final presubmitGuardDocument = await firestoreService.getDocument(
        presubmitGuardDocumentName,
        transaction: transaction,
      );
      presubmitGuard = PresubmitGuard.fromDocument(presubmitGuardDocument);

      // Check if the build is present in the guard before trying to load it.
      if (presubmitGuard.jobs[state.jobName] == null) {
        log.info(
          '$logCrumb: ${state.jobName} with attemptNumber ${state.attemptNumber} not present for $transaction / ${presubmitGuardDocument.fields}',
        );
        await firestoreService.rollback(transaction);
        return PresubmitGuardConclusion(
          result: PresubmitGuardConclusionResult.missing,
          remaining: presubmitGuard.remainingJobs,
          checkRunGuard: presubmitGuard.checkRunJson,
          failed: presubmitGuard.failedJobs,
          summary:
              'Check run "${state.jobName}" not present in ${guardId.stage} CI stage',
          details: 'Change $changeCrumb',
        );
      }

      final checkDocName = PresubmitJob.documentNameFor(
        slug: guardId.slug,
        checkRunId: guardId.checkRunId,
        jobName: state.jobName,
        attemptNumber: state.attemptNumber,
      );
      final presubmitJobDocument = await firestoreService.getDocument(
        checkDocName,
        transaction: transaction,
      );
      presubmitJob = PresubmitJob.fromDocument(presubmitJobDocument);

      remaining = presubmitGuard.remainingJobs;
      failed = presubmitGuard.failedJobs;
      final jobs = presubmitGuard.jobs;
      var status = jobs[state.jobName]!;

      // If job is waiting for backfill, that means its initiated by github
      // or re-run. So no processing needed, we should only update appropriate
      // checks with that [TaskStatus]
      if (state.status == TaskStatus.waitingForBackfill) {
        status = state.status;
        valid = true;
        // If job is in progress, we should update apropriate checks with start
        // time and their status to that [TaskStatus] only if the job is not
        // completed.
      } else if (state.status == TaskStatus.inProgress) {
        presubmitJob.startTime = state.startTime!;
        presubmitJob.buildNumber = state.buildNumber;
        presubmitJob.buildId = state.buildId;
        // If the job is not completed, update the status.
        if (!status.isComplete) {
          status = state.status;
        }
        valid = true;
      } else {
        // If job already compleated remaining and failed should not updated.
        if (!status.isComplete) {
          // "remaining" should go down if job is succeeded or failed.
          // "failed_count" can go up or down depending on:
          //   attemptNumber > 1 && jobSuccessed: down (-1)
          //   attemptNumber = 1 && jobFailed: up (+1)
          // So if the test existed and either remaining or failed_count is changed;
          // the response is valid.
          if (state.status.isComplete) {
            // Guard against going negative and log enough info so we can debug.
            if (remaining == 0) {
              throw '$logCrumb: field "${PresubmitGuard.fieldRemainingJobs}" is already zero for $transaction / ${presubmitGuardDocument.fields}';
            }
            remaining -= 1;
            valid = true;
          }

          if (state.status.isFailure) {
            log.info('$logCrumb: test failed');
            failed += 1;
            valid = true;
          }
          status = state.status;
          // All checks pass. "valid" is only set to true if there was a change in either the remaining or failed count.
          log.info(
            '$logCrumb: setting remaining to $remaining, failed to $failed',
          );
          presubmitGuard.remainingJobs = remaining;
          presubmitGuard.failedJobs = failed;
          presubmitJob.endTime = state.endTime!;
          presubmitJob.summary = state.summary;
          presubmitJob.buildNumber = state.buildNumber;
          presubmitJob.buildId = state.buildId;
        } else {
          status = state.status;
          valid = true;
        }
      }
      jobs[state.jobName] = status;
      presubmitGuard.jobs = jobs;
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
            : 'Not a valid state transition for ${state.jobName}',
        details: valid
            ? '''
For CI stage ${guardId.stage}:
  Pending: $remaining
  Failed: $failed
'''
            : 'Attempted to set the state of job ${state.jobName} '
                  'to "${state.status.name}".',
      );
    } catch (e) {
      log.info('$logCrumb: failed to update presubmit job', e);
      rethrow;
    }
  }
}
