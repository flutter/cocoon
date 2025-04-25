// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// @docImport 'task.dart';
library;

import 'dart:io';

import 'package:github/github.dart';
import 'package:googleapis/firestore/v1.dart' hide Status;
import 'package:path/path.dart' as p;
import 'package:truncate/truncate.dart';

import '../../../cocoon_service.dart';
import '../../service/firestore.dart';
import 'base.dart';

/// Representation of each commit (row) on https://flutter-dashboard.appspot.com/#/build.
///
/// Provides enough information to render a build status without querying GitHub
/// for commit information, and is a (non-enforced) parent document of [Task],
/// where each [Commit] has many tasks associated by [Task.commitSha].
///
/// This documents layout is currently:
/// ```
///  /projects/flutter-dashboard/databases/cocoon/commits/
///    document: <this.sha>
/// ```
final class Commit extends AppDocument<Commit> {
  static const collectionId = 'commits';
  static const fieldAvatar = 'avatar';
  static const fieldBranch = 'branch';
  static const fieldCreateTimestamp = 'createTimestamp';
  static const fieldAuthor = 'author';
  static const fieldMessage = 'message';
  static const fieldRepositoryPath = 'repositoryPath';
  static const fieldSha = 'sha';

  /// Returns a document ID for the given [sha].
  static AppDocumentId<Commit> documentIdFor({required String sha}) {
    return AppDocumentId<Commit>.fromDocumentId(sha, runtimeMetadata: metadata);
  }

  @override
  AppDocumentMetadata<Commit> get runtimeMetadata => metadata;

  /// Description of the document in Firestore.
  static final metadata = AppDocumentMetadata<Commit>(
    collectionId: collectionId,
    fromDocument: Commit.fromDocument,
  );

  /// Returns [Commit] from [firestore] by the given [sha].
  static Future<Commit> fromFirestoreBySha(
    FirestoreService firestore, {
    required String sha,
  }) async {
    final commit = await tryFromFirestoreBySha(firestore, sha: sha);
    if (commit == null) {
      throw StateError('No commit "$sha" found');
    }
    return commit;
  }

  /// Returns [Commit] from [firestore] by the given [sha].
  ///
  /// If the commit does not exist, returns `null`.
  static Future<Commit?> tryFromFirestoreBySha(
    FirestoreService firestore, {
    required String sha,
  }) async {
    final documentName = p.join(kDatabase, 'documents', collectionId, sha);
    try {
      final document = await firestore.getDocument(documentName);
      return Commit._(document.fields!, documentName: document.name!);
    } on DetailedApiRequestError catch (e) {
      if (e.status == HttpStatus.notFound) {
        return null;
      }
      rethrow;
    }
  }

  factory Commit({
    required int createTimestamp,
    required String sha,
    required String author,
    required String avatar,
    required String repositoryPath,
    required String branch,
    required String message,
  }) {
    return Commit._({
      fieldAvatar: avatar.toValue(),
      fieldBranch: branch.toValue(),
      fieldCreateTimestamp: createTimestamp.toValue(),
      fieldAuthor: author.toValue(),
      fieldMessage: message.toValue(),
      fieldRepositoryPath: repositoryPath.toValue(),
      fieldSha: sha.toValue(),
    }, documentName: p.posix.join(kDatabase, 'documents', collectionId, sha));
  }

  /// Creates a Cocoon commit from a Github-authored [commit] on a [branch].
  factory Commit.fromGithubCommit(
    RepositoryCommit commit, {
    required RepositorySlug slug,
    required String branch,
  }) {
    return Commit(
      author: commit.author!.login!,
      avatar: commit.author!.avatarUrl!,
      branch: branch,
      message: truncate(commit.commit!.message!, 1490, omission: '...'),
      createTimestamp: commit.commit!.committer!.date!.millisecondsSinceEpoch,
      repositoryPath: slug.fullName,
      sha: commit.sha!,
    );
  }

  /// Creates a Cocoon commit from a Github-authored [pr].
  factory Commit.fromGithubPullRequest(PullRequest pr) {
    return Commit(
      author: pr.user!.login!,
      avatar: pr.user!.avatarUrl!,
      branch: pr.base!.ref!,
      message: truncate(pr.title!, 1490, omission: '...'),
      repositoryPath: pr.base!.repo!.fullName,
      sha: pr.mergeCommitSha!,
      createTimestamp: pr.mergedAt!.millisecondsSinceEpoch,
    );
  }

  factory Commit.fromDocument(Document document) {
    return Commit._(document.fields!, documentName: document.name!);
  }

  Commit._(Map<String, Value> fields, {required String documentName}) {
    this
      ..fields = fields
      ..documentName = documentName;
  }

  /// The timestamp (in milliseconds since the Epoch) of when the commit
  /// landed.
  int get createTimestamp =>
      int.parse(fields[fieldCreateTimestamp]!.integerValue!);

  /// The SHA1 hash of the commit.
  String get sha => fields[fieldSha]!.stringValue!;

  /// The GitHub username of the commit author.
  String get author => fields[fieldAuthor]!.stringValue!;

  /// URL of the [author]'s profile image / avatar.
  ///
  /// The bytes loaded from the URL are expected to be encoded image bytes.
  String get avatar => fields[fieldAvatar]!.stringValue!;

  /// The commit message.
  String get message => fields[fieldMessage]!.stringValue!;

  /// A serializable form of [slug].
  ///
  /// This will be of the form `<org>/<repo>`. e.g. `flutter/flutter`.
  String get repositoryPath => fields[fieldRepositoryPath]!.stringValue!;

  /// The branch of the commit.
  String get branch => fields[fieldBranch]!.stringValue!;

  /// [RepositorySlug] of where this commit exists.
  RepositorySlug get slug => RepositorySlug.full(repositoryPath);
}
