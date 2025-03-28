// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:github/github.dart';
import 'package:googleapis/firestore/v1.dart' hide Status;

import '../../../cocoon_service.dart';
import '../../service/firestore.dart';
import 'base.dart';

const String kGithubGoldStatusCollectionId = 'githubGoldStatuses';
const String kGithubGoldStatusPrNumberField = 'prNumber';
const String kGithubGoldStatusHeadField = 'head';
const String kGithubGoldStatusStatusField = 'status';
const String kGithubGoldStatusDescriptionField = 'description';
const String kGithubGoldStatusUpdatesField = 'updates';
const String kGithubGoldStatusRepositoryField = 'repository';

class GithubGoldStatus extends Document with AppDocument<GithubGoldStatus> {
  /// Lookup [GithubGoldStatus] from Firestore.
  ///
  /// `documentName` follows `/projects/{project}/databases/{database}/documents/{document_path}`
  static Future<GithubGoldStatus> fromFirestore({
    required FirestoreService firestoreService,
    required String documentName,
  }) async {
    final document = await firestoreService.getDocument(documentName);
    return GithubGoldStatus.fromDocument(document);
  }

  /// Create [GithubGoldStatus] from a GithubGoldStatus Document.
  static GithubGoldStatus fromDocument(Document githubGoldStatus) {
    return GithubGoldStatus()
      ..fields = githubGoldStatus.fields!
      ..name = githubGoldStatus.name!;
  }

  static final metadata = AppDocumentMetadata<GithubGoldStatus>(
    collectionId: kGithubGoldStatusCollectionId,
    fromDocument: GithubGoldStatus.fromDocument,
    // FIXME: Verify this is correct.
    documentName: (status) {
      return '${status.slug.owner}_${status.slug.name}_${status.prNumber}';
    },
  );

  @override
  AppDocumentMetadata<GithubGoldStatus> get runtimeMetadata => metadata;

  // The flutter-gold status cannot report a `failure` status
  // due to auto-rollers. This is why we hold a `pending` status
  // when there are image changes. This provides the opportunity
  // for images to be triaged, and the auto-roller to proceed.
  // For more context, see: https://github.com/flutter/flutter/issues/48744

  static const String statusCompleted = 'success';

  static const String statusRunning = 'pending';

  int? get prNumber =>
      int.parse(fields![kGithubGoldStatusPrNumberField]!.integerValue!);

  String? get head => fields![kGithubGoldStatusHeadField]!.stringValue!;

  String? get status => fields![kGithubGoldStatusStatusField]!.stringValue!;

  String? get description =>
      fields![kGithubGoldStatusDescriptionField]!.stringValue!;

  int? get updates =>
      int.parse(fields![kGithubGoldStatusUpdatesField]!.integerValue!);

  String setStatus(String status) {
    fields![kGithubGoldStatusStatusField] = Value(stringValue: status);
    return status;
  }

  String setHead(String head) {
    fields![kGithubGoldStatusHeadField] = Value(stringValue: head);
    return head;
  }

  int setUpdates(int updates) {
    fields![kGithubGoldStatusUpdatesField] = Value(
      integerValue: updates.toString(),
    );
    return updates;
  }

  String setDescription(String description) {
    fields![kGithubGoldStatusDescriptionField] = Value(
      stringValue: description,
    );
    return description;
  }

  /// A serializable form of [slug].
  ///
  /// This will be of the form `<org>/<repo>`. e.g. `flutter/flutter`.
  String? get repository =>
      fields![kGithubGoldStatusRepositoryField]!.stringValue!;

  /// [RepositorySlug] of where this commit exists.
  RepositorySlug get slug => RepositorySlug.full(repository!);
}
