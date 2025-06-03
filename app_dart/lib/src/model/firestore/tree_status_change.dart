// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:googleapis/firestore/v1.dart' as g;

import '../../service/firestore.dart';
import 'base.dart';

/// A row for each tree status change.
final class TreeStatusChange extends AppDocument<TreeStatusChange> {
  /// Returns the latest [TreeStatusChange].
  ///
  /// If no changes exist, returns `null`.
  static Future<TreeStatusChange?> getLatest(FirestoreService firestore) async {
    final docs = await firestore.query(
      metadata.collectionId,
      {},
      limit: 1,
      orderMap: {_fieldCreateTimestamp: kQueryOrderDescending},
    );
    return docs.isEmpty ? null : TreeStatusChange.fromDocument(docs.first);
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
  }) async {
    final document = TreeStatusChange.fromDocument(
      g.Document(
        fields: {
          _fieldCreateTimestamp: createdOn.toValue(),
          _fieldStatus: status.name.toValue(),
          _fieldAuthoredBy: authoredBy.toValue(),
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

  DateTime get createdOn {
    return DateTime.parse(fields[_fieldCreateTimestamp]!.timestampValue!);
  }

  TreeStatus get status {
    return TreeStatus.values.byName(fields[_fieldStatus]!.stringValue!);
  }

  String get authoredBy {
    return fields[_fieldAuthoredBy]!.stringValue!;
  }
}

/// Whether the [TreeStatusChange] was a success or failure.
enum TreeStatus { success, failure }
