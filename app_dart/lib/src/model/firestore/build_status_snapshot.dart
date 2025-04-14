// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:collection/collection.dart';
import 'package:googleapis/firestore/v1.dart' as g;
import 'package:meta/meta.dart';

import '../../service/firestore.dart';
import 'base.dart';

/// A tree-status update.
final class BuildStatusSnapshot extends AppDocument<BuildStatusSnapshot> {
  static Future<BuildStatusSnapshot?> getLatest(
    FirestoreService firestore,
  ) async {
    final docs = await firestore.query(
      metadata.collectionId,
      {},
      limit: 1,
      orderMap: {_fieldCreateTimestamp: kQueryOrderDescending},
    );
    return docs.isEmpty ? null : BuildStatusSnapshot.fromDocument(docs.first);
  }

  @override
  AppDocumentMetadata<BuildStatusSnapshot> get runtimeMetadata => metadata;

  /// Description of the document in Firestore.
  static final metadata = AppDocumentMetadata<BuildStatusSnapshot>(
    collectionId: 'build_status_snapshot',
    fromDocument: BuildStatusSnapshot.fromDocument,
  );

  factory BuildStatusSnapshot({
    required DateTime createdOn,
    required BuildStatus status,
    required List<String> failingTasks,
  }) {
    final sortedTasks = failingTasks.sorted();
    return BuildStatusSnapshot.fromDocument(
      g.Document(
        fields: {
          _fieldCreateTimestamp: createdOn.toValue(),
          _fieldStatus: status.name.toValue(),
          _fieldFailingTasks: g.Value(
            arrayValue: g.ArrayValue(
              values: [...sortedTasks.map((t) => t.toValue())],
            ),
          ),
        },
      ),
    );
  }

  /// Create [BuildStatusSnapshot] from a GithubBuildStatus Document.
  BuildStatusSnapshot.fromDocument(super.document);

  static const _fieldCreateTimestamp = 'createTimestamp';
  static const _fieldStatus = 'status';
  static const _fieldFailingTasks = 'failing_tasks';

  DateTime get createdOn {
    return DateTime.parse(fields[_fieldCreateTimestamp]!.timestampValue!);
  }

  BuildStatus get status {
    return BuildStatus.values.byName(fields[_fieldStatus]!.stringValue!);
  }

  Set<String> get failingTasks {
    return {
      ...fields[_fieldFailingTasks]!.arrayValue!.values!.map(
        (t) => t.stringValue!,
      ),
    };
  }

  /// Returns if the [status] and/or [failingTasks] is different than [other].
  @useResult
  SnapshotDiff diffContents(BuildStatusSnapshot other) {
    final BuildStatus? newStatus;
    if (status != other.status) {
      newStatus = status;
    } else {
      newStatus = null;
    }

    final nowPassing = other.failingTasks.difference(failingTasks);
    final nowFailing = failingTasks.difference(other.failingTasks);
    return SnapshotDiff._(
      newStatus: newStatus,
      nowPassing: nowPassing,
      stillFailing: failingTasks.intersection(other.failingTasks),
      nowFailing: nowFailing,
    );
  }
}

@immutable
final class SnapshotDiff {
  const SnapshotDiff._({
    required this.newStatus,
    required this.nowPassing,
    required this.stillFailing,
    required this.nowFailing,
  });

  /// If non-null,
  final BuildStatus? newStatus;
  final Set<String> nowPassing;
  final Set<String> stillFailing;
  final Set<String> nowFailing;

  /// Whether a meaningful difference was recorded.
  bool get isDifferent {
    return newStatus != null || nowPassing.isNotEmpty || nowFailing.isNotEmpty;
  }
}

/// Whether the [BuildStatusSnapshot] was a success or failure.
enum BuildStatus { success, failure }
