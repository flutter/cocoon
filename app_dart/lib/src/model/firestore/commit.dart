// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_service/cocoon_service.dart';
import 'package:github/github.dart';
import 'package:googleapis/firestore/v1.dart' hide Status;

import '../../service/firestore.dart';

class Commit extends Document {
  /// Lookup [Task] from Firestore.
  ///
  /// `documentName` follows `/projects/{project}/databases/{<}database}/documents/{document_path}`
  static Future<Commit> fromFirestore({
    required FirestoreService firestoreService,
    required String documentName,
  }) async {
    final Document document = await firestoreService.getDocument(documentName);
    return Commit.fromDocument(commitDocument: document);
  }

  /// Create [Commit] from a Commit Document.
  static Commit fromDocument({
    required Document commitDocument,
  }) {
    return Commit()
      ..fields = commitDocument.fields!
      ..name = commitDocument.name!;
  }

 /// The timestamp (in milliseconds since the Epoch) of when the commit
  /// landed.
  int? get createTimestamp => int.parse(fields![kCommitCreateTimestampField]!.integerValue!);

  /// The SHA1 hash of the commit.
  String? get sha => fields![kCommitShaField]!.stringValue!;

  /// The GitHub username of the commit author.
  String? get author => fields![kCommitAuthorField]!.stringValue!;

  /// URL of the [author]'s profile image / avatar.
  ///
  /// The bytes loaded from the URL are expected to be encoded image bytes.
  String? get avatar => fields![kCommitAvatarField]!.stringValue!;

  /// The commit message.
  ///
  /// This may be null, since we didn't always load/store this property in
  /// the datastore, so historical entries won't have this information.
  String? get message => fields![kCommitMessageField]!.stringValue!;

  /// A serializable form of [slug].
  ///
  /// This will be of the form `<org>/<repo>`. e.g. `flutter/flutter`.
  String? get repositoryPath => fields![kCommitRepositoryPathField]!.stringValue!;

  /// The branch of the commit.
  String? get branch => fields![kCommitBranchField]!.stringValue!;

  /// [RepositorySlug] of where this commit exists.
  RepositorySlug get slug => RepositorySlug.full(repositoryPath!);

  @override
  String toString() {
    final StringBuffer buf = StringBuffer()
      ..write('$runtimeType(')
      ..write(', $kCommitCreateTimestampField: $createTimestamp')
      ..write(', $kCommitAuthorField: $author')
      ..write(', $kCommitAvatarField: $avatar')
      ..write(', $kCommitBranchField: $branch')
      ..write(', $kCommitMessageField: $message')
      ..write(', $kCommitRepositoryPathField: $repositoryPath')
      ..write(', $kCommitShaField: $sha')
      ..write(')');
    return buf.toString();
  }
}
