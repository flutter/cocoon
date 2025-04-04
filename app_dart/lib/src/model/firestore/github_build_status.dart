// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:github/github.dart';
import 'package:googleapis/firestore/v1.dart' hide Status;

import '../../../cocoon_service.dart';
import '../../service/firestore.dart';
import 'base.dart';

const String kGithubBuildStatusCollectionId = 'githubBuildStatuses';
const String kGithubBuildStatusPrNumberField = 'prNumber';
const String kGithubBuildStatusRepositoryField = 'repository';
const String kGithubBuildStatusHeadField = 'head';
const String kGithubBuildStatusStatusField = 'status';
const String kGithubBuildStatusUpdateTimeMillisField = 'updateTimeMillis';
const String kGithubBuildStatusUpdatesField = 'updates';

/// A update having been posted to a GitHub PR on the status of the build.
///
/// This documents layout is currently:
/// ```
///  /projects/flutter-dashboard/databases/cocoon/commits/
///    document: <this.head>
/// ```
/*final - TODO(matanlurey): Can't add because of MockFirestoreService. */
class GithubBuildStatus extends AppDocument<GithubBuildStatus> {
  static AppDocumentId<GithubBuildStatus> documentIdFor({
    required String headSha,
  }) {
    return AppDocumentId.fromDocumentId(headSha, runtimeMetadata: metadata);
  }

  @override
  AppDocumentMetadata<GithubBuildStatus> get runtimeMetadata => metadata;

  /// Description of the document in Firestore.
  static final metadata = AppDocumentMetadata<GithubBuildStatus>(
    collectionId: kGithubBuildStatusCollectionId,
    fromDocument: GithubBuildStatus.fromDocument,
  );

  /// Lookup [GithubBuildStatus] from Firestore.
  ///
  /// `documentName` follows `/projects/{project}/databases/{database}/documents/{document_path}`
  static Future<GithubBuildStatus> fromFirestore({
    required FirestoreService firestoreService,
    required String documentName,
  }) async {
    final document = await firestoreService.getDocument(documentName);
    return GithubBuildStatus.fromDocument(document);
  }

  /// Create [GithubBuildStatus] from a GithubBuildStatus Document.
  GithubBuildStatus.fromDocument(Document other) {
    this
      ..name = other.name
      ..fields = {...?other.fields}
      ..createTime = other.createTime
      ..updateTime = other.updateTime;
  }

  static const String statusSuccess = 'success';

  static const String statusFailure = 'failure';

  static const String statusNeutral = 'neutral';

  int? get prNumber =>
      int.parse(fields[kGithubBuildStatusPrNumberField]!.integerValue!);

  /// A serializable form of [slug].
  ///
  /// This will be of the form `<org>/<repo>`. e.g. `flutter/flutter`.
  String? get repository =>
      fields[kGithubBuildStatusRepositoryField]!.stringValue!;

  /// [RepositorySlug] of where this commit exists.
  RepositorySlug get slug => RepositorySlug.full(repository!);

  String? get head => fields[kGithubBuildStatusHeadField]!.stringValue!;

  String? get status => fields[kGithubBuildStatusStatusField]!.stringValue!;

  /// The last time when the status is updated for the PR.
  int? get updateTimeMillis =>
      int.parse(fields[kGithubBuildStatusUpdateTimeMillisField]!.integerValue!);

  int? get updates =>
      int.parse(fields[kGithubBuildStatusUpdatesField]!.integerValue!);

  String setStatus(String status) {
    fields[kGithubBuildStatusStatusField] = Value(stringValue: status);
    return status;
  }

  int setUpdates(int updates) {
    fields[kGithubBuildStatusUpdatesField] = Value(
      integerValue: updates.toString(),
    );
    return updates;
  }

  int setUpdateTimeMillis(int updateTimeMillis) {
    fields[kGithubBuildStatusUpdateTimeMillisField] = Value(
      integerValue: updateTimeMillis.toString(),
    );
    return updateTimeMillis;
  }
}
