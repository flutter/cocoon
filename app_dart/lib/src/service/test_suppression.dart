import 'package:github/github.dart';
import 'package:googleapis/firestore/v1.dart';
import 'package:meta/meta.dart';

import '../../cocoon_service.dart';
import 'extensions/cache_service_test_suppression.dart'
    show SuppressedTestCache;

enum SuppressingAction {
  suppress('SUPPRESS'),
  unsuppress('UNSUPPRESS');

  const SuppressingAction(this.action);
  final String action;
}

class TestSuppression {
  TestSuppression({
    required FirestoreService firestore,
    required CacheService cache,

    @visibleForTesting DateTime Function() now = DateTime.now,
  }) : _firestore = firestore,
       _now = now,
       _cache = cache;

  final FirestoreService _firestore;
  final DateTime Function() _now;
  final CacheService _cache;

  Future<void> updateSuppression({
    required String testName,
    required String email,
    required RepositorySlug repository,
    required SuppressingAction action,
    required String note,
    String? issueLink,
  }) async {
    // Query for existing suppression - we assume there is at most one document
    // per (repo, name) based on business logic, though the DB constraint might
    // not strictly exist yet without unique index.
    final SuppressedTest? existingSuppression;
    {
      final previous = await SuppressedTest.getLatest(
        _firestore,
        repository.fullName,
        testName,
      );
      if (previous?.isSuppressed == false) {
        // Don't update old, closed tests.
        existingSuppression = null;
      } else {
        existingSuppression = previous;
      }
    }

    final isSuppressed = action == SuppressingAction.suppress;
    final now = _now().toUtc();

    // New or old doc; record an update
    final updateEntry = {
      SuppressedTest.updateFieldUser: email,
      SuppressedTest.updateFieldUpdateTimestamp: now,
      SuppressedTest.updateFieldNote: note,
      SuppressedTest.updateFieldAction: action.action,
    };

    // Update an existing document
    if (existingSuppression != null) {
      final updatedSuppression = SuppressedTest(
        name: testName,
        repository: repository.fullName,
        // issue: today we don't have UI affordance for updating the link.
        issueLink: existingSuppression.issueLink,
        isSuppressed: isSuppressed,
        createTimestamp: existingSuppression.createTimestamp,
        updates: [...existingSuppression.updates, updateEntry],
      )..name = existingSuppression.name; // We need to preserve the ID.

      await _firestore.batchWriteDocuments(
        BatchWriteRequest(
          writes: [
            Write(
              update: updatedSuppression,
              currentDocument: Precondition(exists: true),
            ),
          ],
        ),
        kDatabase,
      );
    } else {
      // Create new document
      if (action == SuppressingAction.unsuppress) {
        // Nothing to unsuppress.
        return;
      }

      final newSuppression = SuppressedTest(
        name: testName,
        repository: repository.fullName,
        issueLink: issueLink ?? 'BUG',
        isSuppressed: true,
        createTimestamp: now,
        updates: [updateEntry],
      );

      await _firestore.createDocument(
        newSuppression,
        collectionId: SuppressedTest.kCollectionId,
      );
    }

    // Update cache now that we've written it
    await _cache.setTestSuppression(
      testName: testName,
      repository: repository,
      isSuppressed: isSuppressed,
    );
  }

  Future<bool> isTestSuppressed({
    required String testName,
    required RepositorySlug repository,
  }) => _cache.isTestSuppressed(
    testName: testName,
    repository: repository,
    firestore: _firestore,
  );

  Future<List<SuppressedTest>> listSuppressedTests({
    required RepositorySlug repository,
  }) => SuppressedTest.getSuppressedTests(_firestore, repository.fullName);
}
