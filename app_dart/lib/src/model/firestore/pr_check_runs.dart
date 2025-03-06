// Copyright 2024 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:cocoon_server/logging.dart';
import 'package:github/github.dart';
import 'package:googleapis/firestore/v1.dart' hide Status;

import '../../service/firestore.dart';

/// Pairs the GitHub PR with the check runs associated with it.
///
/// The current webhook for check_runs does not include the PR. To reduce quota
/// on GitHub, we need to be able to look up PRs based on check_run ids. Each
/// document will be a collection of check_runs scheduled for a PR / sha.
///
/// The PR / SHA combo is not unique:
///   - PR's will have multiple runs and we want this document to represent a
///     snapshot.
///   - SHAs can exist in multiple PRs.
///
/// Instead of generating some unique key (e.g. check_run+slug) and creating a
/// large amount of documents, we will rely on querying the fields.
///
/// This document layout is currently:
/// ```
///  /projects/flutter-dashboard/databases/cocoon/prCheckRuns/
///     document: <firebase unique id>
///       pullRequest: json string
///       slug: json string
///       sha: string
///       [*fields]: "test_name": "check_run id"
/// ```
class PrCheckRuns extends Document {
  static const kCollectionId = 'prCheckRuns';
  static const kPullRequestField = 'pull_request';
  static const kSlugField = 'slug';
  static const kShaField = 'sha';

  /// Create [PrCheckRuns] from a Commit Document.
  static PrCheckRuns fromDocument(Document prCheckRunsDoc) {
    return PrCheckRuns()
      ..fields = prCheckRunsDoc.fields!
      ..name = prCheckRunsDoc.name!;
  }

  /// The json string of the pullrequest belonging to this document.
  PullRequest get pullRequest => PullRequest.fromJson(
    json.decode(fields![kPullRequestField]!.stringValue!),
  );

  /// The head sha at the time this document was created for testing.
  String get sha => fields![kShaField]!.stringValue!;

  RepositorySlug get slug =>
      RepositorySlug.fromJson(json.decode(fields![kSlugField]!.stringValue!));

  /// Initializes a new document for the list of check_runs in Firestore so we can find it later.
  ///
  /// The list of tasks will be written as fields of a document with additional fields for tracking the total
  /// number of tasks, remaining count. It is required to include [checkRunGuard] as a json encoded [CheckRun] as this
  /// will be used to unlock any check runs blocking progress.
  ///
  /// Returns the created document or throws an error.
  static Future<Document> initializeDocument({
    required FirestoreService firestoreService,
    required PullRequest pullRequest,
    required List<CheckRun> checks,
  }) async {
    final logCrumb =
        'initializeDocument(${pullRequest.head!.repo!.slug().fullName}/${pullRequest.number}, ${checks.length} check runs)';

    final fields = <String, Value>{
      kPullRequestField: Value(stringValue: json.encode(pullRequest.toJson())),
      kSlugField: Value(
        stringValue: json.encode(pullRequest.head!.repo!.slug().toJson()),
      ),
      kShaField: Value(stringValue: pullRequest.head!.sha!),
      for (final run in checks) run.name!: Value(stringValue: '${run.id}'),
    };

    final document = Document(fields: fields);

    try {
      // Calling createDocument multiple times for the same documentId will return a 409 - ALREADY_EXISTS error;
      // this is good because it means we don't have to do any transactions.
      // curl -X POST -H "Content-Type: application/json" -H "Authorization: Bearer <TOKEN>" "https://firestore.googleapis.com/v1beta1/projects/flutter-dashboard/databases/cocoon/documents/prCheckRuns" -d '{"fields": {"test": {"stringValue": "baz"}}}'
      final databasesDocumentsResource =
          await firestoreService.documentResource();
      final newDoc = await databasesDocumentsResource.createDocument(
        document,
        kDocumentParent,
        kCollectionId,
      );
      log.info('$logCrumb: document created');
      return newDoc;
    } catch (e) {
      log.warning('$logCrumb: failed to create document: $e');
      rethrow;
    }
  }

  /// Retrieve the [PullRequest] for a given [checkRun] or throw an error.
  static Future<PullRequest> findPullRequestFor(
    FirestoreService firestoreService,
    int checkRunId,
    String checkRunName,
  ) async {
    final filterMap = <String, Object>{'$checkRunName =': '$checkRunId'};
    log.info('findDocumentFor($filterMap): finding prCheckRuns document');
    final docs = await firestoreService.query(kCollectionId, filterMap);
    log.info('findDocumentFor($filterMap): found: $docs');
    return PrCheckRuns.fromDocument(docs.first).pullRequest;
  }

  /// Retrieve the [PullRequest] for a given [sha] or throw an error.
  static Future<PullRequest?> findPullRequestForSha(
    FirestoreService firestoreService,
    String sha,
  ) async {
    final filterMap = <String, Object>{'sha =': sha};
    log.info('findPullRequestForSha($filterMap): finding prCheckRuns document');
    final docs = await firestoreService.query(kCollectionId, filterMap);
    log.info('findPullRequestForSha($filterMap): found: $docs');
    if (docs.isEmpty) return null;
    return PrCheckRuns.fromDocument(docs.first).pullRequest;
  }
}
