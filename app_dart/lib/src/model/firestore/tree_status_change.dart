// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:github/github.dart';
import 'package:googleapis/firestore/v1.dart' as g;

import '../../service/firestore.dart';
import 'base.dart';

/// A row for each tree status change.
final class TreeStatusChange extends AppDocument<TreeStatusChange> {
  /// Returns the latest [TreeStatusChange].
  ///
  /// If no changes exist, returns `null`.
  static Future<TreeStatusChange?> getLatest(
    FirestoreService firestore, {
    required RepositorySlug repository,
  }) async {
    final changes = await _getLatestN(
      firestore,
      repository: repository,
      limit: 1,
    );
    return changes.singleOrNull;
  }

  /// Returns the latest 10 [TreeStatusChange]s for the given repository.
  static Future<List<TreeStatusChange>> getLatest10(
    FirestoreService firestore, {
    required RepositorySlug repository,
  }) async {
    return _getLatestN(firestore, repository: repository, limit: 10);
  }

  static Future<List<TreeStatusChange>> _getLatestN(
    FirestoreService firestore, {
    required RepositorySlug repository,
    required int limit,
  }) async {
    final docs = await firestore.query(
      metadata.collectionId,
      {'$_fieldRepository =': repository.fullName},
      limit: limit,
      orderMap: {_fieldCreateTimestamp: kQueryOrderDescending},
    );
    return [...docs.map(TreeStatusChange.fromDocument)];
  }

  @override
  AppDocumentMetadata<TreeStatusChange> get runtimeMetadata => metadata;

  /// Description of the document in Firestore.
  static final metadata = AppDocumentMetadata<TreeStatusChange>(
    collectionId: 'tree_status_change',
    fromDocument: TreeStatusChange.fromDocument,
  );

  /// Creates and inserts a [TreeStatusChange] into [firestore].
  static Future<TreeStatusChange> create(
    FirestoreService firestore, {
    required DateTime createdOn,
    required TreeStatus status,
    required String authoredBy,
    required RepositorySlug repository,
    String? reason,
  }) async {
    final document = TreeStatusChange.fromDocument(
      g.Document(
        fields: {
          _fieldCreateTimestamp: createdOn.toValue(),
          _fieldStatus: status.name.toValue(),
          _fieldAuthoredBy: authoredBy.toValue(),
          _fieldRepository: repository.fullName.toValue(),
          if (reason != null) _fieldReason: reason.toValue(),
        },
      ),
    );
    final result = await firestore.createDocument(
      document,
      collectionId: metadata.collectionId,
    );
    return TreeStatusChange.fromDocument(result);
  }

  /// Create [BuildStatusSnapshot] from a GithubBuildStatus Document.
  TreeStatusChange.fromDocument(super.document);

  static const _fieldCreateTimestamp = 'createTimestamp';
  static const _fieldStatus = 'status';
  static const _fieldAuthoredBy = 'author';
  static const _fieldRepository = 'repository';
  static const _fieldReason = 'reason';

  DateTime get createdOn {
    return DateTime.parse(fields[_fieldCreateTimestamp]!.timestampValue!);
  }

  TreeStatus get status {
    return TreeStatus.values.byName(fields[_fieldStatus]!.stringValue!);
  }

  String get authoredBy {
    return fields[_fieldAuthoredBy]!.stringValue!;
  }

  RepositorySlug get repository {
    return RepositorySlug.full(fields[_fieldRepository]!.stringValue!);
  }

  String? get reason {
    return fields[_fieldReason]?.stringValue;
  }
}

/// Whether the [TreeStatusChange] was a success or failure.
enum TreeStatus { success, failure }
