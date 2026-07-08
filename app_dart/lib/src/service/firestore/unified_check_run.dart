// Copyright 2025 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// @docImport 'unified_check_run.dart';
library;

import 'dart:typed_data';

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
import '../../request_handling/pubsub.dart';
import '../cache_service.dart';
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

  /// Calculates the current live job statuses, remaining count, and failed count
  /// for a given [PresubmitGuard].
  static Future<PresubmitGuardJobStatus> getLatestJobStatusesForGuard({
    required FirestoreService firestoreService,
    required PresubmitGuard guard,
    PresubmitJob? overrideJob,
  }) async {
    final allJobs = await queryAllPresubmitJobsForGuard(
      firestoreService: firestoreService,
      checkRunId: guard.checkRunId,
    );

    final latestJobs = <String, PresubmitJob>{};
    for (final job in allJobs) {
      final current = latestJobs[job.jobName];
      if (current == null || job.attemptNumber > current.attemptNumber) {
        latestJobs[job.jobName] = job;
      }
    }

    if (overrideJob != null) {
      latestJobs[overrideJob.jobName] = overrideJob;
    }

    var remaining = 0;
    var failed = 0;
    final jobStatuses = <String, TaskStatus>{};

    for (final jobName in guard.jobs.keys) {
      final job = latestJobs[jobName];
      final status =
          job?.status ?? guard.jobs[jobName] ?? TaskStatus.waitingForBackfill;
      jobStatuses[jobName] = status;
      if (!status.isComplete) {
        remaining++;
      }
      if (status.isFailure) {
        failed++;
      }
    }

    return PresubmitGuardJobStatus(
      remaining: remaining,
      failed: failed,
      jobStatuses: jobStatuses,
      latestJobs: latestJobs,
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

  /// Stores the log analysis result for a [PresubmitJob].
  static Future<void> storeLogAnalysis({
    required FirestoreService firestoreService,
    required PresubmitJob job,
    required String analysis,
  }) async {
    job.logAnalysis = analysis;
    await firestoreService.writeViaTransaction(
      documentsToWrites([job], exists: true),
    );
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
  /// Updates the corresponding [PresubmitJob] document and asynchronously schedules
  /// a debounced [PresubmitGuard] synchronization via PubSub.
  static Future<void> markConclusion({
    required FirestoreService firestoreService,
    required PresubmitGuardId guardId,
    required PresubmitJobState state,
    required CacheService cacheService,
    required PubSub pubsub,
  }) async {
    final changeCrumb =
        '${guardId.slug.owner}_${guardId.slug.name}_${guardId.prNum}_${guardId.checkRunId}';
    final logCrumb =
        'markConclusion(${changeCrumb}_${guardId.stage}, ${state.jobName}, ${state.status}, ${state.attemptNumber})';

    final checkDocName = PresubmitJob.documentNameFor(
      slug: guardId.slug,
      checkRunId: guardId.checkRunId,
      jobName: state.jobName,
      attemptNumber: state.attemptNumber,
    );

    // 1. Update the PresubmitJob document in a transaction.
    final transaction = await firestoreService.beginTransaction();
    var valid = false;
    try {
      final presubmitJobDocument = await firestoreService.getDocument(
        checkDocName,
        transaction: transaction,
      );
      final presubmitJob = PresubmitJob.fromDocument(presubmitJobDocument);

      if (state.status == TaskStatus.waitingForBackfill) {
        presubmitJob.status = state.status;
        valid = true;
      } else if (state.status == TaskStatus.inProgress) {
        presubmitJob.startTime = state.startTime!;
        presubmitJob.buildNumber = state.buildNumber;
        presubmitJob.buildId = state.buildId;
        if (!presubmitJob.status.isComplete) {
          presubmitJob.status = state.status;
        }
        valid = true;
      } else {
        if (!presubmitJob.status.isComplete) {
          presubmitJob.status = state.status;
          presubmitJob.endTime = state.endTime!;
          presubmitJob.summary = state.summary;
          presubmitJob.buildNumber = state.buildNumber;
          presubmitJob.buildId = state.buildId;
          valid = true;
        } else {
          presubmitJob.status = state.status;
          valid = true;
        }
      }

      if (valid) {
        await firestoreService.commit(
          transaction,
          documentsToWrites([presubmitJob], exists: true),
        );
      } else {
        await firestoreService.rollback(transaction);
      }
    } on DetailedApiRequestError catch (e, stack) {
      await firestoreService.rollback(transaction);
      if (e.status == 404) {
        log.info(
          '$logCrumb: ${PresubmitJob.collectionId} document not found for $transaction\n$stack',
        );
        return;
      }
      rethrow;
    } catch (e) {
      await firestoreService.rollback(transaction);
      rethrow;
    }

    if (!valid) {
      log.info('$logCrumb: Not a valid state transition for ${state.jobName}');
      return;
    }

    final presubmitGuardDocumentName = PresubmitGuard.documentNameFor(
      slug: guardId.slug,
      prNum: guardId.prNum,
      checkRunId: guardId.checkRunId,
      stage: guardId.stage,
    );

    // 2. Asynchronously trigger the debounced guard update via pubsub, using
    // setIfNotExists so only the first job to mark the guard dirty publishes.
    final wasSet = await cacheService.setIfNotExists(
      'presubmit_guard_dirty',
      presubmitGuardDocumentName,
      Uint8List.fromList([1]),
      ttl: const Duration(minutes: 15),
    );
    if (wasSet) {
      try {
        await pubsub.publish('presubmit-guard-update', {
          'guard_document_name': presubmitGuardDocumentName,
        });
      } catch (e) {
        log.warn(
          '$logCrumb: Failed to publish presubmit-guard-update via pubsub',
          e,
        );
        await cacheService.purge(
          'presubmit_guard_dirty',
          presubmitGuardDocumentName,
        );
      }
    }
  }

  /// Asynchronously updates a [PresubmitGuard] document based on the live set
  /// of [PresubmitJob] records.
  ///
  /// Used by the debounced PubSub subscription (`presubmit-guard-update`).
  static Future<(PresubmitGuardConclusion, PresubmitGuard)?>
  updatePresubmitGuard({
    required FirestoreService firestoreService,
    required CacheService cacheService,
    required String guardDocumentName,
  }) async {
    // Clear dirty flag right before querying/updating to allow new arrivals to re-debounce.
    await cacheService.purge('presubmit_guard_dirty', guardDocumentName);

    Document latestGuardDoc;
    try {
      latestGuardDoc = await firestoreService.getDocument(guardDocumentName);
    } on DetailedApiRequestError catch (e) {
      if (e.status == 404) {
        log.info(
          'PresubmitGuard $guardDocumentName not found in firestore (404), skipping.',
        );
        return null;
      }
      rethrow;
    }

    final latestGuard = PresubmitGuard.fromDocument(latestGuardDoc);
    final guardStatusInfo = await getLatestJobStatusesForGuard(
      firestoreService: firestoreService,
      guard: latestGuard,
    );

    latestGuard.remainingJobs = guardStatusInfo.remaining;
    latestGuard.failedJobs = guardStatusInfo.failed;

    final jobsMap = latestGuard.jobs;
    for (final jobName in jobsMap.keys) {
      if (guardStatusInfo.latestJobs[jobName] case final job?) {
        jobsMap[jobName] = job.status;
      }
    }
    latestGuard.jobs = jobsMap;

    final response = await firestoreService.writeViaTransaction(
      documentsToWrites([latestGuard], exists: true),
    );
    log.info(
      'updatePresubmitGuard($guardDocumentName): results = ${response.writeResults?.map((e) => e.toJson())}',
    );

    final conclusion = PresubmitGuardConclusion(
      result: PresubmitGuardConclusionResult.ok,
      remaining: guardStatusInfo.remaining,
      checkRunGuard: latestGuard.checkRunJson,
      failed: guardStatusInfo.failed,
      summary: 'Successfully updated presubmit guard status',
      details:
          'For CI stage ${latestGuard.stage}:\n  Pending: ${guardStatusInfo.remaining}\n  Failed: ${guardStatusInfo.failed}\n',
    );
    return (conclusion, latestGuard);
  }
}

/// Holds aggregated job status information for a [PresubmitGuard].
@immutable
final class PresubmitGuardJobStatus {
  const PresubmitGuardJobStatus({
    required this.remaining,
    required this.failed,
    required this.jobStatuses,
    required this.latestJobs,
  });

  final int remaining;
  final int failed;
  final Map<String, TaskStatus> jobStatuses;
  final Map<String, PresubmitJob> latestJobs;
}
