// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:googleapis/firestore/v1.dart' as g;
import 'package:path/path.dart' as p;

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

  static String documentPathFor(String contentHash) =>
      p.posix.join(kDatabase, 'documents', metadata.collectionId, contentHash);

  /// Retrieves the content hash document by hash.
  ///
  /// Returns `null` if the document does not exist.
  static Future<ContentAwareHashBuilds?> getByContentHash(
    FirestoreService firestore, {
    required String contentHash,
  }) async {
    final g.Document document;
    try {
      document = await firestore.getDocument(documentPathFor(contentHash));
    } on g.DetailedApiRequestError catch (e) {
      if (e.status == HttpStatus.notFound) {
        return null;
      }
      rethrow;
    }
    return ContentAwareHashBuilds.fromDocument(document);
  }

  factory ContentAwareHashBuilds({
    required DateTime createdOn,
    required String contentHash,
    required String commitSha,
    required BuildStatus buildStatus,
    required List<String> waitingShas,
  }) {
    return ContentAwareHashBuilds.fromDocument(
      g.Document(
        name: documentPathFor(contentHash),
        fields: {
          _fieldCreateTimestamp: createdOn.toValue(),
          fieldContentHash: contentHash.toValue(),
          _fieldCommitSha: commitSha.toValue(),
          fieldStatus: buildStatus.name.toValue(),
          fieldWaitingShas: g.Value(
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
  static const fieldContentHash = 'content_hash';
  static const _fieldCommitSha = 'commit_sha';
  static const fieldStatus = 'status';
  static const fieldWaitingShas = 'waiting_shas';

  DateTime get createdOn =>
      DateTime.parse(fields[_fieldCreateTimestamp]!.timestampValue!);

  BuildStatus get status =>
      BuildStatus.values.byName(fields[fieldStatus]!.stringValue!);

  String get contentHash => fields[fieldContentHash]!.stringValue!;

  String get commitSha => fields[_fieldCommitSha]!.stringValue!;

  List<String> get waitingShas {
    return [
      for (final t
          in fields[fieldWaitingShas]?.arrayValue?.values ?? <g.Value>[])
        t.stringValue!,
    ];
  }
}

/// Whether the engine build in [ContentAwareHashBuilds.commitSha] is done.
enum BuildStatus { inProgress, success, failure }
