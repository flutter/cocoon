// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_service/cocoon_service.dart';
import 'package:github/github.dart';
import 'package:googleapis/firestore/v1.dart' hide Status;

import '../../service/firestore.dart';
import '../appengine/github_gold_status_update.dart';

const String kGithubGoldStatusCollectionId = 'githubGoldStatuses';
const String kGithubGoldStatusPrNumberField = 'prNumber';
const String kGithubGoldStatusHeadField = 'head';
const String kGithubGoldStatusStatusField = 'status';
const String kGithubGoldStatusDescriptionField = 'description';
const String kGithubGoldStatusUpdatesField = 'updates';
const String kGithubGoldStatusRepositoryField = 'repository';

class GithubGoldStatus extends Document {
  /// Lookup [GithubGoldStatus] from Firestore.
  ///
  /// `documentName` follows `/projects/{project}/databases/{database}/documents/{document_path}`
  static Future<GithubGoldStatus> fromFirestore({
    required FirestoreService firestoreService,
    required String documentName,
  }) async {
    final Document document = await firestoreService.getDocument(documentName);
    return GithubGoldStatus.fromDocument(githubGoldStatus: document);
  }

  /// Create [GithubGoldStatus] from a GithubGoldStatus Document.
  static GithubGoldStatus fromDocument({
    required Document githubGoldStatus,
  }) {
    return GithubGoldStatus()
      ..fields = githubGoldStatus.fields!
      ..name = githubGoldStatus.name!;
  }

  // The flutter-gold status cannot report a `failure` status
  // due to auto-rollers. This is why we hold a `pending` status
  // when there are image changes. This provides the opportunity
  // for images to be triaged, and the auto-roller to proceed.
  // For more context, see: https://github.com/flutter/flutter/issues/48744

  static const String statusCompleted = 'success';

  static const String statusRunning = 'pending';

  int? get prNumber => int.parse(fields![kGithubGoldStatusPrNumberField]!.integerValue!);

  String? get head => fields![kGithubGoldStatusHeadField]!.stringValue!;

  String? get status => fields![kGithubGoldStatusStatusField]!.stringValue!;

  String? get description => fields![kGithubGoldStatusDescriptionField]!.stringValue!;

  int? get updates => int.parse(fields![kGithubGoldStatusUpdatesField]!.integerValue!);

  /// A serializable form of [slug].
  ///
  /// This will be of the form `<org>/<repo>`. e.g. `flutter/flutter`.
  String? get repository => fields![kGithubGoldStatusRepositoryField]!.stringValue!;

  /// [RepositorySlug] of where this commit exists.
  RepositorySlug get slug => RepositorySlug.full(repository!);

  @override
  String toString() {
    final StringBuffer buf = StringBuffer()
      ..write('$runtimeType(')
      ..write(', $kGithubGoldStatusPrNumberField: $prNumber')
      ..write(', $kGithubGoldStatusHeadField: $head')
      ..write(', $kGithubGoldStatusStatusField: $status')
      ..write(', $kGithubGoldStatusDescriptionField $description')
      ..write(', $kGithubGoldStatusUpdatesField: $updates')
      ..write(', $kGithubGoldStatusRepositoryField: $repository')
      ..write(')');
    return buf.toString();
  }
}

/// Generates GithubGoldStatus document based on datastore GithubGoldStatusUpdate data model.
GithubGoldStatus githubGoldStatusToDocument(GithubGoldStatusUpdate githubGoldStatus) {
  return GithubGoldStatus.fromDocument(
    githubGoldStatus: Document(
      name: '$kDatabase/documents/$kGithubGoldStatusCollectionId/${githubGoldStatus.head}_${githubGoldStatus.pr}',
      fields: <String, Value>{
        kGithubGoldStatusDescriptionField: Value(stringValue: githubGoldStatus.description),
        kGithubGoldStatusHeadField: Value(stringValue: githubGoldStatus.head),
        kGithubGoldStatusPrNumberField: Value(integerValue: githubGoldStatus.pr.toString()),
        kGithubGoldStatusRepositoryField: Value(stringValue: githubGoldStatus.repository),
        kGithubGoldStatusStatusField: Value(stringValue: githubGoldStatus.status),
        kGithubGoldStatusUpdatesField: Value(integerValue: githubGoldStatus.updates.toString()),
      },
    ),
  );
}
