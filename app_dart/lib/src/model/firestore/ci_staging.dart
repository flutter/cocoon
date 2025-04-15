// Copyright 2024 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// @docImport 'task.dart';
library;

import 'package:cocoon_server/logging.dart';
import 'package:collection/collection.dart';
import 'package:github/github.dart';
import 'package:googleapis/firestore/v1.dart' hide Status;
import 'package:meta/meta.dart';
import 'package:path/path.dart' as p;

import '../../service/firestore.dart';
import 'base.dart';

final class CiStagingId extends AppDocumentId<CiStaging> {
  CiStagingId({
    required this.owner,
    required this.repo,
    required this.sha,
    required this.stage,
  });

  /// The repository owner.
  final String owner;

  /// The repository name.
  final String repo;

  /// The commit SHA.
  final String sha;

  /// The stage of the CI process.
  final CiStage stage;

  @override
  String get documentId => [owner, repo, sha, stage].join('_');

  @override
  AppDocumentMetadata<CiStaging> get runtimeMetadata => CiStaging.metadata;
}

/// Representation of the current work scheduled for a given stage of monorepo check runs.
///
/// 'Staging' is the breaking up of the CI tasks such that some are performed before others.
/// This is required so that engine build artifacts can be made available to any tests that
/// depend on them.
///
/// This document layout is currently:
/// ```
///  /projects/flutter-dashboard/databases/cocoon/ciStaging/
///     document: <this.slug.owner>_<this.slug.repo>_<this.sha>_<this.stage>
///       total: int >= 0
///       remaining: int >= 0
///       [*fields]: string {scheduled, success, failure, skipped}
/// ```
final class CiStaging extends AppDocument<CiStaging> {
  /// Firestore collection for the staging documents.
  static const _collectionId = 'ciStaging';

  static const kRemainingField = 'remaining';
  static const kTotalField = 'total';
  static const kFailedField = 'failed_count';
  static const kCheckRunGuardField = 'check_run_guard';

  @visibleForTesting
  static const fieldRepoFullPath = 'repository';

  @visibleForTesting
  static const fieldCommitSha = 'commit_sha';

  @visibleForTesting
  static const fieldStage = 'stage';

  static AppDocumentId<CiStaging> documentIdFor({
    required RepositorySlug slug,
    required String sha,
    required CiStage stage,
  }) => CiStagingId(owner: slug.owner, repo: slug.name, sha: sha, stage: stage);

  @override
  AppDocumentMetadata<CiStaging> get runtimeMetadata => metadata;

  /// Description of the document in Firestore.
  static final metadata = AppDocumentMetadata<CiStaging>(
    collectionId: _collectionId,
    fromDocument: CiStaging.fromDocument,
  );

  /// Returns a firebase documentName used in [fromFirestore].
  static String documentNameFor({
    required RepositorySlug slug,
    required String sha,
    required CiStage stage,
  }) {
    // Document names cannot cannot have '/' in the document id.
    final docId = documentIdFor(slug: slug, sha: sha, stage: stage);
    return '$kDocumentParent/$_collectionId/${docId.documentId}';
  }

  /// Lookup [Commit] from Firestore.
  ///
  /// Use [documentNameFor] to get the correct [documentName]
  static Future<CiStaging> fromFirestore({
    required FirestoreService firestoreService,
    required String documentName,
  }) async {
    final document = await firestoreService.getDocument(documentName);
    return CiStaging.fromDocument(document);
  }

  /// Create [CiStaging] from a Commit Document.
  CiStaging.fromDocument(Document other) {
    this
      ..name = other.name
      ..fields = {...?other.fields}
      ..createTime = other.createTime
      ..updateTime = other.updateTime;
  }

  /// The repository that this stage is recorded for.
  RepositorySlug get slug {
    // TODO(matanlurey): Simplify this when existing documents are backfilled.
    if (fields[fieldRepoFullPath]?.stringValue case final repoFullPath?) {
      return RepositorySlug.full(repoFullPath);
    }

    // Read it from the document name.
    final [owner, repo, _, _] = p.posix.basename(name!).split('_');
    return RepositorySlug(owner, repo);
  }

  /// Which commit this stage is recorded for.
  String get sha {
    // TODO(matanlurey): Simplify this when existing documents are backfilled.
    if (fields[fieldCommitSha]?.stringValue case final sha?) {
      return sha;
    }

    // Read it from the document name.
    final [_, _, sha, _] = p.posix.basename(name!).split('_');
    return sha;
  }

  /// The stage of the CI process.
  CiStage? get stage {
    // TODO(matanlurey): Simplify this when existing documents are backfilled.
    if (fields[fieldStage]?.stringValue case final stageName?) {
      return CiStage.values.firstWhereOrNull((e) => e.name == stageName);
    }

    // Read it from the document name.
    final [_, _, _, stageName] = p.posix.basename(name!).split('_');
    return CiStage.values.firstWhereOrNull((e) => e.name == stageName);
  }

  /// The remaining number of checks in this staging.
  int get remaining => int.parse(fields[kRemainingField]!.integerValue!);

  /// The total number of checks in this staging.
  int get total => int.parse(fields[kTotalField]!.integerValue!);

  /// The total number of failing checks.
  int get failed => int.parse(fields[kFailedField]!.integerValue!);

  /// The check_run to complete when this stage is closed.
  String get checkRunGuard => fields[kCheckRunGuardField]!.stringValue!;

  static const keysOfImport = [
    kRemainingField,
    kTotalField,
    kFailedField,
    kCheckRunGuardField,
    fieldRepoFullPath,
    fieldCommitSha,
    fieldStage,
  ];

  /// The recorded check-runs, a map of "test_name": "check_run id".
  Map<String, TaskConclusion> get checkRuns {
    return {
      for (final MapEntry(:key, :value) in fields.entries)
        if (!keysOfImport.contains(key))
          key: TaskConclusion.fromName(value.stringValue),
    };
  }

  /// Mark a [checkRun] for a given [stage] with [conclusion].
  ///
  /// Returns a [StagingConclusion] record or throws. If the check_run was
  /// both valid and recorded successfully, the record's `remaining` value
  /// signals how many more tests are running. Returns the record (valid: false)
  /// otherwise.
  static Future<StagingConclusion> markConclusion({
    required FirestoreService firestoreService,
    required RepositorySlug slug,
    required String sha,
    required CiStage stage,
    required String checkRun,
    required TaskConclusion conclusion,
  }) async {
    final changeCrumb = '${slug.owner}_${slug.name}_$sha';
    final logCrumb =
        'markConclusion(${changeCrumb}_$stage, $checkRun, $conclusion)';

    // Marking needs to happen while in a transaction to ensure `remaining` is
    // updated correctly. For that to happen correctly; we need to perform a
    // read of the document in the transaction as well. So start the transaction
    // first thing.
    final transaction = await firestoreService.beginTransaction();

    var remaining = -1;
    var failed = -1;
    var total = -1;
    var valid = false;
    String? checkRunGuard;
    TaskConclusion? recordedConclusion;

    late final Document doc;

    // transaction block
    try {
      // First: read the fields we want to change.
      final documentName = documentNameFor(slug: slug, stage: stage, sha: sha);
      doc = await firestoreService.getDocument(
        documentName,
        transaction: transaction,
      );

      final fields = doc.fields;
      if (fields == null) {
        throw '$logCrumb: missing fields for $transaction / $doc';
      }

      // Fields and remaining _must_ be present.
      final docRemaining = int.tryParse(
        fields[kRemainingField]?.integerValue ?? '',
      );
      if (docRemaining == null) {
        throw '$logCrumb: missing field "$kRemainingField" for $transaction / ${doc.fields}';
      }
      remaining = docRemaining;

      final maybeFailed = int.tryParse(
        fields[kFailedField]?.integerValue ?? '',
      );
      if (maybeFailed == null) {
        throw '$logCrumb: missing field "$kFailedField" for $transaction / ${doc.fields}';
      }
      failed = maybeFailed;

      final maybeTotal = int.tryParse(fields[kTotalField]?.integerValue ?? '');
      if (maybeTotal == null) {
        throw '$logCrumb: missing field "$kTotalField" for $transaction / ${doc.fields}';
      }
      total = maybeTotal;

      // We will have check_runs scheduled after the engine was built successfully, so missing the checkRun field
      // is an OK response to have. All fields should have been written at creation time.
      if (fields[checkRun]?.stringValue case final name?) {
        recordedConclusion = TaskConclusion.fromName(name);
      }
      if (recordedConclusion == null) {
        log.info(
          '$logCrumb: $checkRun not present in doc for $transaction / $doc',
        );
        await firestoreService.rollback(transaction);
        return StagingConclusion(
          result: StagingConclusionResult.missing,
          remaining: remaining,
          checkRunGuard: null,
          failed: failed,
          summary: 'Check run "$checkRun" not present in $stage CI stage',
          details: 'Change $changeCrumb',
        );
      }

      // GitHub sends us 3 "action" messages for check_runs: created, completed, or rerequested.
      //   - We are responsible for the "created" messages.
      //   - The user is responsible for "rerequested"
      //   - LUCI is responsible for the completed.
      // Completed messages are either success / failure.
      // "remaining" should only go down if the previous state was scheduled - this is the first state
      // that is written by the scheduler.
      // "failed_count" can go up or down depending on:
      //   recordedConclusion == failure && conclusion == success: down (-1)
      //   recordedConclusion != failure && conclusion == failure: up (+1)
      // So if the test existed and either remaining or failed_count is changed; the response is valid.
      if (recordedConclusion == TaskConclusion.scheduled &&
          conclusion != TaskConclusion.scheduled) {
        // Guard against going negative and log enough info so we can debug.
        if (remaining == 0) {
          throw '$logCrumb: field "$kRemainingField" is already zero for $transaction / ${doc.fields}';
        }
        remaining = remaining - 1;
        valid = true;
      }

      // Only rollback the "failed" counter if this is a successful test run,
      // i.e. the test failed, the user requested a rerun, and now it passes.
      if (recordedConclusion == TaskConclusion.failure &&
          conclusion == TaskConclusion.success) {
        log.info(
          '$logCrumb: conclusion flipped to positive - assuming test was re-run',
        );
        if (failed == 0) {
          throw '$logCrumb: field "$kFailedField" is already zero for $transaction / ${doc.fields}';
        }
        valid = true;
        failed = failed - 1;
      }

      // Only increment the "failed" counter if the new conclusion flips from positive or neutral to failure.
      if ((recordedConclusion == TaskConclusion.scheduled ||
              recordedConclusion == TaskConclusion.success) &&
          conclusion == TaskConclusion.failure) {
        log.info('$logCrumb: test failed');
        valid = true;
        failed = failed + 1;
      }

      // Record the json string of the check_run to complete.
      checkRunGuard = fields[kCheckRunGuardField]?.stringValue;

      // All checks pass. "valid" is only set to true if there was a change in either the remaining or failed count.
      log.info(
        '$logCrumb: setting remaining to $remaining, failed to $failed, and changing $recordedConclusion',
      );
      fields[checkRun] = conclusion.name.toValue();
      fields[kRemainingField] = remaining.toValue();
      fields[kFailedField] = failed.toValue();
    } on DetailedApiRequestError catch (e, stack) {
      if (e.status == 404) {
        // An attempt to read a document not in firestore should not be retried.
        log.info('$logCrumb: staging document not found for $transaction');
        await firestoreService.rollback(transaction);
        return StagingConclusion(
          result: StagingConclusionResult.internalError,
          remaining: -1,
          checkRunGuard: null,
          failed: failed,
          summary: 'Internal server error',
          details: '''
Staging document not found for CI stage "$stage" for $changeCrumb. Got 404 from
Firestore.

Error:
${e.toString()}
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
    final response = await firestoreService.commit(
      transaction,
      documentsToWrites([doc], exists: true),
    );
    log.info(
      '$logCrumb: results = ${response.writeResults?.map((e) => e.toJson())}',
    );
    return StagingConclusion(
      result:
          valid
              ? StagingConclusionResult.ok
              : StagingConclusionResult.internalError,
      remaining: remaining,
      checkRunGuard: checkRunGuard,
      failed: failed,
      summary:
          valid
              ? 'All tests passed'
              : 'Not a valid state transition for $checkRun',
      details:
          valid
              ? '''
For CI stage $stage:
  Total check runs scheduled: $total
  Pending: $remaining
  Failed: $failed
'''
              : ''
                  'Attempted to transition the state of check run $checkRun '
                  'from "${recordedConclusion.name}" to "${conclusion.name}".',
    );
  }

  /// Initializes a new document for the given [tasks] in Firestore so that stage-tracking can succeed.
  ///
  /// The list of tasks will be written as fields of a document with additional fields for tracking the total
  /// number of tasks, remaining count. It is required to include [checkRunGuard] as a json encoded [CheckRun] as this
  /// will be used to unlock any check runs blocking progress.
  ///
  /// Returns the created document or throws an error.
  static Future<Document> initializeDocument({
    required FirestoreService firestoreService,
    required RepositorySlug slug,
    required String sha,
    required CiStage stage,
    required List<String> tasks,
    required String checkRunGuard,
  }) async {
    final logCrumb =
        'initializeDocument(${slug.owner}_${slug.name}_${sha}_$stage, ${tasks.length} tasks)';

    final fields = <String, Value>{
      kTotalField: tasks.length.toValue(),
      kRemainingField: tasks.length.toValue(),
      kFailedField: 0.toValue(),
      kCheckRunGuardField: checkRunGuard.toValue(),
      fieldRepoFullPath: slug.fullName.toValue(),
      fieldCommitSha: sha.toValue(),
      fieldStage: stage.name.toValue(),
      for (final task in tasks) task: TaskConclusion.scheduled.name.toValue(),
    };

    final document = Document(fields: fields);

    try {
      // Calling createDocument multiple times for the same documentId will return a 409 - ALREADY_EXISTS error;
      // this is good because it means we don't have to do any transactions.
      // curl -X POST -H "Content-Type: application/json" -H "Authorization: Bearer <TOKEN>" "https://firestore.googleapis.com/v1beta1/projects/flutter-dashboard/databases/cocoon/documents/ciStaging?documentId=foo_bar_baz" -d '{"fields": {"test": {"stringValue": "baz"}}}'
      final newDoc = await firestoreService.createDocument(
        document,
        collectionId: _collectionId,
        documentId:
            documentIdFor(
              slug: slug,
              sha: sha,
              stage: stage, //
            ).documentId,
      );
      log.info('$logCrumb: document created');
      return newDoc;
    } catch (e) {
      log.warn('$logCrumb: failed to create document', e);
      rethrow;
    }
  }
}

/// Represents the conclusion of a [Task] within a [CiStaging] document.
enum TaskConclusion {
  /// An unknown task conclusion.
  unknown,

  /// A task is scheduled to run.
  scheduled,

  /// A task was completed as a success.
  success,

  /// A task was completed as a failure.
  failure;

  /// Returns a [TaskConclusion] from a [name].
  factory TaskConclusion.fromName(String? name) {
    for (final value in TaskConclusion.values) {
      if (value.name == name) {
        return value;
      }
    }
    return TaskConclusion.unknown;
  }

  /// Whether the task is completed or not.
  bool get isComplete => this != scheduled;

  /// Whether the task is a success or not.
  bool get isSuccess => this == success;
}

/// Well-defined stages in the build infrastructure.
enum CiStage implements Comparable<CiStage> {
  /// Build engine artifacts
  fusionEngineBuild('engine'),

  /// All non-engine artifact tests (engine & framework)
  fusionTests('fusion');

  const CiStage(this.name);

  final String name;

  @override
  int compareTo(CiStage other) => index - other.index;

  @override
  String toString() => name;
}

/// Explains what happened when attempting to mark the conclusion of a check run
/// using [CiStaging.markConclusion].
enum StagingConclusionResult {
  /// Check run update recorded successfully in the respective CI stage.
  ///
  /// It is OK to evaluate returned results for stage completeness.
  ok,

  /// The check run is not in the specified CI stage.
  ///
  /// Perhaps it's from a different CI stage.
  missing,

  /// An unexpected error happened, and the results of the conclusion are
  /// undefined.
  ///
  /// Examples of situations that can lead to this result:
  ///
  /// * The Firestore document is missing.
  /// * The contents of the Firestore document are inconsistent.
  /// * An unexpected error happend while trying to read from/write to Firestore.
  ///
  /// When this happens, it's best to stop the current transaction, report the
  /// error to the logs, and have someone investigate the issue.
  internalError,
}

/// Results from attempting to mark a staging task as completed.
///
/// See: [CiStaging.markConclusion]
class StagingConclusion {
  final StagingConclusionResult result;
  final int remaining;
  final String? checkRunGuard;
  final int failed;
  final String summary;
  final String details;

  const StagingConclusion({
    required this.result,
    required this.remaining,
    required this.checkRunGuard,
    required this.failed,
    required this.summary,
    required this.details,
  });

  bool get isOk => result == StagingConclusionResult.ok;

  bool get isPending => isOk && remaining > 0;

  bool get isFailed => isOk && !isPending && failed > 0;

  bool get isComplete => isOk && !isPending && !isFailed;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StagingConclusion &&
          other.result == result &&
          other.remaining == remaining &&
          other.checkRunGuard == checkRunGuard &&
          other.failed == failed &&
          other.summary == summary &&
          other.details == details);

  @override
  int get hashCode => Object.hashAll([
    result,
    remaining,
    checkRunGuard,
    failed,
    summary,
    details,
  ]);

  @override
  String toString() =>
      'StagingConclusion("$result", "$remaining", "$checkRunGuard", "$failed", "$summary", "$details")';
}
