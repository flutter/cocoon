// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:googleapis/firestore/v1.dart' as g;

import '../../service/firestore.dart';
import 'base.dart';

/// Tracking the content aware hashes for engine builds in the merge queue.
final class ContentAwareHashBuilds extends AppDocument<ContentAwareHashBuilds> {
  @override
  AppDocumentMetadata<ContentAwareHashBuilds> get runtimeMetadata => metadata;

  /// Description of the document in Firestore.
  static final metadata = AppDocumentMetadata<ContentAwareHashBuilds>(
    collectionId: 'content_aware_hash_builds',
    fromDocument: ContentAwareHashBuilds.fromDocument,
  );

  factory ContentAwareHashBuilds({
    required DateTime createdOn,
    required String contentHash,
    required String commitSha,
    required BuildStatus buildStatus,
    required List<String> waitingShas,
  }) {
    return ContentAwareHashBuilds.fromDocument(
      g.Document(
        fields: {
          _fieldCreateTimestamp: createdOn.toValue(),
          _fieldContentHash: contentHash.toValue(),
          _fieldCommitSha: commitSha.toValue(),
          _fieldStatus: buildStatus.name.toValue(),
          _fieldWaitingShas: g.Value(
            arrayValue: g.ArrayValue(
              values: [...waitingShas.map((t) => t.toValue())],
            ),
          ),
        },
      ),
    );
  }

  /// Create [ContentAwareHashBuilds] from a firestore Document.
  ContentAwareHashBuilds.fromDocument(super.document);

  static const _fieldCreateTimestamp = 'createTimestamp';
  static const _fieldContentHash = 'content_hash';
  static const _fieldCommitSha = 'commit_sha';
  static const _fieldStatus = 'status';
  static const _fieldWaitingShas = 'waiting_shas';

  DateTime get createdOn =>
      DateTime.parse(fields[_fieldCreateTimestamp]!.timestampValue!);

  BuildStatus get status =>
      BuildStatus.values.byName(fields[_fieldStatus]!.stringValue!);

  String get contentHash => fields[_fieldContentHash]!.stringValue!;

  String get commitSha => fields[_fieldCommitSha]!.stringValue!;

  List<String> get waitingShas {
    return [
      for (final t
          in fields[_fieldWaitingShas]?.arrayValue?.values ?? <g.Value>[])
        t.stringValue!,
    ];
  }
}

/// Whether the engine build in [ContentAwareHashBuilds.commitSha] is done.
enum BuildStatus { inProgress, success, failure }
