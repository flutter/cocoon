import 'package:cocoon_service/src/service/logging.dart';
import 'package:github/github.dart';

import '../../service/firestore.dart';
import 'package:googleapis/firestore/v1.dart' hide Status;

/// Representaion the current work scheduled for a given stage of monorepo check runs.
///
/// Staging is required so that engine build artifacts can be made available to any tests that
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
  static const kEngineStage = 'engine';
  static const kDefaultTaskStatus = 'scheduled';

  /// Returns a firebase documentName used in [fromFirestore].
  static String documentNameFor({required RepositorySlug slug, required String sha, required String stage}) {
    // Document names cannot cannot have '/' in the document id.
    final docId = '${slug.owner}_${slug.name}_${sha}_$stage';
    return '$kDocumentParent/ciStaging/$docId';
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
  int? get remaining => int.tryParse(fields![kRemainingField]!.integerValue ?? '');

  /// The total number of checks in this staging.
  int? get total => int.tryParse(fields![kTotalField]!.integerValue ?? '');

  /// Mark a [checkRun] for a given [stage] with [conclusion].
  ///
  /// Returns a [StagingConclusion] record or throws. If the check_run was
  /// both valid and recorded successfully, the record's `remaining` value
  /// signals how many more tests are running. Returns the record (valid: false)
  /// otherwise.
  static Future<StagingConclusion> markConclusion({
    required FirestoreService firestoreService,
    // required String documentNameString,
    required RepositorySlug slug,
    required String sha,
    required String stage,
    required String checkRun,
    required String conclusion,
  }) async {
    final logCrumb = 'markConclusion(${slug.owner}_${slug.name}_${sha}_$stage, $checkRun, $conclusion)';

    // Marking needs to happen while in a transaction to ensure `remaining` is
    // updated correctly. For that to happen correctly; we need to as perform a
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
      log.warning('$logCrumb: transaction was null');
      throw '$logCrumb: transaction was null';
    }

    var newRemaining = -1;

    late final Document doc;

    // transaction block
    try {
      // First: read the fields we want to change.
      final documentPath = documentNameFor(sha: sha, slug: slug, stage: stage);
      doc = await docRes.get(documentPath, mask_fieldPaths: [kRemainingField, checkRun], transaction: transaction);

      // Fields and remaining _must_ be present.
      if (doc.fields == null ||
          doc.fields![kRemainingField] == null ||
          doc.fields![kRemainingField]!.integerValue == null) {
        log.warning('$logCrumb: missing field for $transaction / ${doc.fields}');
        throw '$logCrumb missing fields';
      }

      final remaining = int.parse(doc.fields![kRemainingField]!.integerValue!);
      newRemaining = remaining - 1;
      // We will have check_runs scheduled after the engine was built successfully, so missing the checkRun field
      // is an OK response to have. All fields should have been written at creation time.
      if (doc.fields?[checkRun] == null || doc.fields?[checkRun]!.stringValue == null) {
        log.info('$logCrumb: $checkRun not present in doc; remaining=$remaining');
        await docRes.rollback(RollbackRequest(transaction: transaction), kDatabase);
        return (valid: false, remaining: remaining);
      }

      // Now we can modify the document the change in the conculsion
      if (kDefaultTaskStatus == doc.fields![checkRun]!.stringValue) {
        log.info('$logCrumb: setting remaining to $newRemaining and changing ${doc.fields![checkRun]!.stringValue}');
        doc.fields![checkRun] = Value(stringValue: conclusion);
        doc.fields![kRemainingField] = Value(integerValue: '$newRemaining');
      } else {
        log.warning("$logCrumb: '$conclusion' already recorded? ${doc.fields![checkRun]!.stringValue}");
        throw "$logCrumb: '$conclusion' already recorded? ${doc.fields![checkRun]!.stringValue}";
      }
    } catch (e) {
      await docRes.rollback(RollbackRequest(transaction: transaction), kDatabase);
      rethrow;
    }

    // Commit this write firebase and if no one else was writing at the same time, return success.
    // If this commit fails, that means someone else modified firestore and the caller should try again.
    // We do not need to rollback the transaction; firebase documentation says a failed commit takes care of that.
    final CommitRequest commitRequest =
        CommitRequest(transaction: transaction, writes: documentsToWrites([doc], exists: true));

    final response = await docRes.commit(commitRequest, kDatabase);
    log.info('$logCrumb: results = ${response.writeResults?.map((e) => e.toJson())}');

    return (valid: true, remaining: newRemaining);
  }
}

/// Results from attempting to mark a staging task as completed.
///
/// See: [CiStaging.markConclusion]
typedef StagingConclusion = ({bool valid, int remaining});
