// Copyright 2024 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_service/src/service/logging.dart';
import 'package:github/github.dart';

import '../../service/firestore.dart';
import 'package:googleapis/firestore/v1.dart' hide Status;

/// Representation of the current work scheduled for a given stage of monorepo check runs.
///
/// 'Staging' is the breaking up of the CI tasks such that some are performed before others.
/// This is required so that engine build artifacts can be made available to any tests that
/// depend on them.
///
/// This document layout is currently:
///  /projects/flutter-dashboard/databases/cocoon/ciStaging/
///     document: <owner>_<repo>_<sha>_<stage>
///       total: int >= 0
///       remaining: int >= 0
///       [*fields]: string {scheduled, success, failure, skipped}
class CiStaging extends Document {
  /// Firestore collection for the staging documents.
  static const kCollectionId = 'ciStaging';
  static const kRemainingField = 'remaining';
  static const kTotalField = 'total';
  static const kFailedField = 'failed_count';
  static const kCheckRunGuardField = 'check_run_guard';

  static const kScheduledValue = 'scheduled';
  static final kSuccessValue = CheckRunConclusion.success.value!;
  static final kFailureValue = CheckRunConclusion.failure.value!;

  static String documentIdFor({required RepositorySlug slug, required String sha, required CiStage stage}) =>
      '${slug.owner}_${slug.name}_${sha}_$stage';

  /// Returns a firebase documentName used in [fromFirestore].
  static String documentNameFor({required RepositorySlug slug, required String sha, required CiStage stage}) {
    // Document names cannot cannot have '/' in the document id.
    final docId = documentIdFor(slug: slug, sha: sha, stage: stage);
    return '$kDocumentParent/$kCollectionId/$docId';
  }

  /// Lookup [Commit] from Firestore.
  ///
  /// Use [documentNameFor] to get the correct [documentName]
  static Future<CiStaging> fromFirestore({
    required FirestoreService firestoreService,
    required String documentName,
  }) async {
    final Document document = await firestoreService.getDocument(documentName);
    return CiStaging.fromDocument(ciStagingDocument: document);
  }

  /// Create [CiStaging] from a Commit Document.
  static CiStaging fromDocument({
    required Document ciStagingDocument,
  }) {
    return CiStaging()
      ..fields = ciStagingDocument.fields!
      ..name = ciStagingDocument.name!;
  }

  /// The remaining number of checks in this staging.
  int get remaining => int.parse(fields![kRemainingField]!.integerValue!);

  /// The total number of checks in this staging.
  int get total => int.parse(fields![kTotalField]!.integerValue!);

  /// The total number of failing checks.
  int get failed => int.parse(fields![kFailedField]!.integerValue!);

  /// The check_run to complete when this stage is closed.
  String get checkRunGuard => fields![kCheckRunGuardField]!.stringValue!;

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
    required String conclusion,
  }) async {
    final logCrumb = 'markConclusion(${slug.owner}_${slug.name}_${sha}_$stage, $checkRun, $conclusion)';

    // Marking needs to happen while in a transaction to ensure `remaining` is
    // updated correctly. For that to happen correctly; we need to perform a
    // read of the document in the transaction as well. So start the transaction
    // first thing.
    final docRes = await firestoreService.documentResource();
    final transactionResponse = await docRes.beginTransaction(
      BeginTransactionRequest(
        options: TransactionOptions(
          readWrite: ReadWrite(),
        ),
      ),
      kDatabase,
    );
    final transaction = transactionResponse.transaction;
    if (transaction == null) {
      throw '$logCrumb: transaction was null when updating $conclusion';
    }

    var remaining = -1;
    var failed = -1;
    bool valid = false;
    String? checkRunGuard;

    late final Document doc;

    // transaction block
    try {
      // First: read the fields we want to change.
      final documentName = documentNameFor(
        slug: slug,
        stage: stage,
        sha: sha,
      );
      doc = await docRes.get(
        documentName,
        mask_fieldPaths: [kRemainingField, checkRun, kCheckRunGuardField, kFailedField],
        transaction: transaction,
      );

      final fields = doc.fields;
      if (fields == null) {
        throw '$logCrumb: missing fields for $transaction / $doc';
      }

      // Fields and remaining _must_ be present.
      final docRemaining = int.tryParse(fields[kRemainingField]?.integerValue ?? '');
      if (docRemaining == null) {
        throw '$logCrumb: missing field "$kRemainingField" for $transaction / ${doc.fields}';
      }
      remaining = docRemaining;

      final maybeFailed = int.tryParse(fields[kFailedField]?.integerValue ?? '');
      if (maybeFailed == null) {
        throw '$logCrumb: missing field "$kFailedField" for $transaction / ${doc.fields}';
      }
      failed = maybeFailed;

      // We will have check_runs scheduled after the engine was built successfully, so missing the checkRun field
      // is an OK response to have. All fields should have been written at creation time.
      final recordedConclusion = fields[checkRun]?.stringValue;
      if (recordedConclusion == null) {
        log.info('$logCrumb: $checkRun not present in doc for $transaction / $doc');
        await docRes.rollback(RollbackRequest(transaction: transaction), kDatabase);
        return (valid: false, remaining: remaining, checkRunGuard: null, failed: failed);
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
      if (recordedConclusion == kScheduledValue && conclusion != kScheduledValue) {
        // Guard against going negative and log enough info so we can debug.
        if (remaining == 0) {
          throw '$logCrumb: field "$kRemainingField" is already zero for $transaction / ${doc.fields}';
        }
        remaining = remaining - 1;
        valid = true;
      }

      // Only rollback the "failed" counter if this is a successful test run,
      // i.e. the test failed, the user requested a rerun, and now it passes.
      if (recordedConclusion == kFailureValue && conclusion == kSuccessValue) {
        log.info('$logCrumb: conclusion flipped to positive - assuming test was re-run');
        if (failed == 0) {
          throw '$logCrumb: field "$kFailedField" is already zero for $transaction / ${doc.fields}';
        }
        valid = true;
        failed = failed - 1;
      }

      // Only increment the "failed" counter if the new conclusion flips from positive or neutral to failure.
      if ((recordedConclusion == kScheduledValue || recordedConclusion == kSuccessValue) &&
          conclusion == kFailureValue) {
        log.info('$logCrumb: test failed');
        if (failed == 0) {
          throw '$logCrumb: field "$kFailedField" is already zero for $transaction / ${doc.fields}';
        }
        valid = true;
        failed = failed + 1;
      }

      // Record the json string of the check_run to complete.
      checkRunGuard = fields[kCheckRunGuardField]?.stringValue;

      // All checks pass. "valid" is only set to true if there was a change in either the remaining or failed count.
      log.info('$logCrumb: setting remaining to $remaining, failed to $failed, and changing $recordedConclusion');
      fields[checkRun] = Value(stringValue: conclusion);
      fields[kRemainingField] = Value(integerValue: '$remaining');
      fields[kFailedField] = Value(integerValue: '$failed');
    } on DetailedApiRequestError catch (e) {
      if (e.status == 404) {
        // An attempt to read a document not in firestore should not be retried.
        log.info('$logCrumb: staging document not found for $transaction');
        await docRes.rollback(RollbackRequest(transaction: transaction), kDatabase);
        return (valid: false, remaining: -1, checkRunGuard: null, failed: failed);
      }
      // All other errors should bubble up and be retried.
      await docRes.rollback(RollbackRequest(transaction: transaction), kDatabase);
      rethrow;
    } catch (e) {
      // All other errors should bubble up and be retried.
      await docRes.rollback(RollbackRequest(transaction: transaction), kDatabase);
      rethrow;
    }

    // Commit this write firebase and if no one else was writing at the same time, return success.
    // If this commit fails, that means someone else modified firestore and the caller should try again.
    // We do not need to rollback the transaction; firebase documentation says a failed commit takes care of that.
    final commitRequest = CommitRequest(transaction: transaction, writes: documentsToWrites([doc], exists: true));
    final response = await docRes.commit(commitRequest, kDatabase);
    log.info('$logCrumb: results = ${response.writeResults?.map((e) => e.toJson())}');
    return (valid: valid, remaining: remaining, checkRunGuard: checkRunGuard, failed: failed);
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
    final logCrumb = 'initializeDocument(${slug.owner}_${slug.name}_${sha}_$stage, ${tasks.length} tasks)';

    final fields = <String, Value>{
      kTotalField: Value(integerValue: '${tasks.length}'),
      kRemainingField: Value(integerValue: '${tasks.length}'),
      kFailedField: Value(integerValue: '0'),
      kCheckRunGuardField: Value(stringValue: checkRunGuard),
      for (final task in tasks) task: Value(stringValue: kScheduledValue),
    };

    final document = Document(fields: fields);

    try {
      // Calling createDocument multiple times for the same documentId will return a 409 - ALREADY_EXISTS error;
      // this is good because it means we don't have to do any transactions.
      // curl -X POST -H "Content-Type: application/json" -H "Authorization: Bearer <TOKEN>" "https://firestore.googleapis.com/v1beta1/projects/flutter-dashboard/databases/cocoon/documents/ciStaging?documentId=foo_bar_baz" -d '{"fields": {"test": {"stringValue": "baz"}}}'
      final databasesDocumentsResource = await firestoreService.documentResource();
      final newDoc = await databasesDocumentsResource.createDocument(
        document,
        kDocumentParent,
        kCollectionId,
        documentId: documentIdFor(slug: slug, sha: sha, stage: stage),
      );
      log.info('$logCrumb: document created');
      return newDoc;
    } catch (e) {
      log.warning('$logCrumb: failed to create document: $e');
      rethrow;
    }
  }
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

/// Results from attempting to mark a staging task as completed.
///
/// See: [CiStaging.markConclusion]
typedef StagingConclusion = ({bool valid, int remaining, String? checkRunGuard, int failed});
