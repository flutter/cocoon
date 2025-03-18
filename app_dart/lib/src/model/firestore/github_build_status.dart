// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:github/github.dart';
import 'package:googleapis/firestore/v1.dart' hide Status;

import '../../../cocoon_service.dart';
import '../../service/firestore.dart';
import '../appengine/github_build_status_update.dart';

const String kGithubBuildStatusCollectionId = 'githubBuildStatuses';
const String kGithubBuildStatusPrNumberField = 'prNumber';
const String kGithubBuildStatusRepositoryField = 'repository';
const String kGithubBuildStatusHeadField = 'head';
const String kGithubBuildStatusStatusField = 'status';
const String kGithubBuildStatusUpdateTimeMillisField = 'updateTimeMillis';
const String kGithubBuildStatusUpdatesField = 'updates';

/// Class that represents an update having been posted to a GitHub PR on the
/// status of the Flutter build.
class GithubBuildStatus extends Document {
  /// Lookup [GithubBuildStatus] from Firestore.
  ///
  /// `documentName` follows `/projects/{project}/databases/{database}/documents/{document_path}`
  static Future<GithubBuildStatus> fromFirestore({
    required FirestoreService firestoreService,
    required String documentName,
  }) async {
    final document = await firestoreService.getDocument(documentName);
    return GithubBuildStatus.fromDocument(githubBuildStatus: document);
  }

  /// Create [GithubBuildStatus] from a GithubBuildStatus Document.
  static GithubBuildStatus fromDocument({required Document githubBuildStatus}) {
    return GithubBuildStatus()
      ..fields = githubBuildStatus.fields!
      ..name = githubBuildStatus.name!;
  }

  static const String statusSuccess = 'success';

  static const String statusFailure = 'failure';

  static const String statusNeutral = 'neutral';

  int? get prNumber =>
      int.parse(fields![kGithubBuildStatusPrNumberField]!.integerValue!);

  /// A serializable form of [slug].
  ///
  /// This will be of the form `<org>/<repo>`. e.g. `flutter/flutter`.
  String? get repository =>
      fields![kGithubBuildStatusRepositoryField]!.stringValue!;

  /// [RepositorySlug] of where this commit exists.
  RepositorySlug get slug => RepositorySlug.full(repository!);

  String? get head => fields![kGithubBuildStatusHeadField]!.stringValue!;

  String? get status => fields![kGithubBuildStatusStatusField]!.stringValue!;

  /// The last time when the status is updated for the PR.
  int? get updateTimeMillis => int.parse(
    fields![kGithubBuildStatusUpdateTimeMillisField]!.integerValue!,
  );

  int? get updates =>
      int.parse(fields![kGithubBuildStatusUpdatesField]!.integerValue!);

  String setStatus(String status) {
    fields![kGithubBuildStatusStatusField] = Value(stringValue: status);
    return status;
  }

  int setUpdates(int updates) {
    fields![kGithubBuildStatusUpdatesField] = Value(
      integerValue: updates.toString(),
    );
    return updates;
  }

  int setUpdateTimeMillis(int updateTimeMillis) {
    fields![kGithubBuildStatusUpdateTimeMillisField] = Value(
      integerValue: updateTimeMillis.toString(),
    );
    return updateTimeMillis;
  }

  @override
  String toString() {
    final buf =
        StringBuffer()
          ..write('$runtimeType(')
          ..write(', $kGithubBuildStatusRepositoryField: $repository')
          ..write(', $kGithubBuildStatusPrNumberField: $prNumber')
          ..write(', $kGithubBuildStatusHeadField: $head')
          ..write(', $kGithubBuildStatusStatusField: $status')
          ..write(', $kGithubBuildStatusUpdatesField: $updates')
          ..write(
            ', $kGithubBuildStatusUpdateTimeMillisField: $updateTimeMillis',
          )
          ..write(')');
    return buf.toString();
  }
}

/// Generates GithubGoldStatus document based on datastore GithubGoldStatusUpdate data model.
GithubBuildStatus githubBuildStatusToDocument(
  GithubBuildStatusUpdate githubBuildStatus,
) {
  return GithubBuildStatus.fromDocument(
    githubBuildStatus: Document(
      name:
          '$kDatabase/documents/$kGithubBuildStatusCollectionId/${githubBuildStatus.head}_${githubBuildStatus.pr}',
      fields: <String, Value>{
        kGithubBuildStatusUpdateTimeMillisField: Value(
          stringValue: githubBuildStatus.updateTimeMillis.toString(),
        ),
        kGithubBuildStatusHeadField: Value(stringValue: githubBuildStatus.head),
        kGithubBuildStatusPrNumberField: Value(
          integerValue: githubBuildStatus.pr.toString(),
        ),
        kGithubBuildStatusRepositoryField: Value(
          stringValue: githubBuildStatus.repository,
        ),
        kGithubBuildStatusStatusField: Value(
          stringValue: githubBuildStatus.status,
        ),
        kGithubBuildStatusUpdatesField: Value(
          integerValue: githubBuildStatus.updates.toString(),
        ),
      },
    ),
  );
}
