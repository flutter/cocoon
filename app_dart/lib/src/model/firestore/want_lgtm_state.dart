// Copyright 2026 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:github/github.dart';
import 'package:googleapis/firestore/v1.dart';

import '../../service/firestore.dart';
import 'base.dart';

/// Identifier for a [WantLgtmState] document.
final class WantLgtmStateId extends AppDocumentId<WantLgtmState> {
  const WantLgtmStateId({required this.slug, required this.pr});

  /// Reconstructs a [WantLgtmStateId] from a raw document ID.
  ///
  /// The document ID format is `<owner> <name> <prNumber>` (space-delimited).
  factory WantLgtmStateId.fromDocumentId(String documentId) {
    final parts = documentId.split(' ');
    if (parts.length != 3) {
      throw FormatException('Invalid WantLgtmState document ID: "$documentId"');
    }
    return WantLgtmStateId(
      slug: RepositorySlug(parts[0], parts[1]),
      pr: int.parse(parts[2]),
    );
  }

  final RepositorySlug slug;
  final int pr;

  @override
  String get documentId => '${slug.owner} ${slug.name} $pr';

  @override
  AppDocumentMetadata<WantLgtmState> get runtimeMetadata =>
      WantLgtmState.metadata;
}

/// Represents the persisted `WANT_LGTM` check run state for a pull request.
final class WantLgtmState extends AppDocument<WantLgtmState> {
  static const kCollectionId = 'wantLgtmStates';

  static const kSlugField = 'slug';
  static const kSlugOwnerField = 'slug_owner';
  static const kSlugNameField = 'slug_name';
  static const kPrField = 'pr';
  static const kDirectiveField = 'directive';
  static const kHeadShaField = 'head_sha';
  static const kCheckRunIdField = 'check_run_id';
  static const kCheckRunStatusField = 'check_run_status';
  static const kCheckRunConclusionField = 'check_run_conclusion';
  static const kCheckRunTitleField = 'check_run_title';
  static const kUpdatedAtField = 'updated_at';

  @override
  AppDocumentMetadata<WantLgtmState> get runtimeMetadata => metadata;

  /// Description of the document in Firestore.
  static final metadata = AppDocumentMetadata<WantLgtmState>(
    collectionId: kCollectionId,
    fromDocument: WantLgtmState.fromDocument,
  );

  /// Constructs a [WantLgtmState] from a Firestore [Document].
  static WantLgtmState fromDocument(Document doc) {
    return WantLgtmState()
      ..fields = doc.fields!
      ..name = doc.name;
  }

  /// Returns the typed [AppDocumentId] for a given [slug] and [pr].
  static AppDocumentId<WantLgtmState> documentIdFor({
    required RepositorySlug slug,
    required int pr,
  }) => WantLgtmStateId(slug: slug, pr: pr);

  /// Returns the full Firestore document resource name for a given [slug] and [pr].
  static String documentNameFor({
    required RepositorySlug slug,
    required int pr,
  }) {
    final docId = documentIdFor(slug: slug, pr: pr);
    return '$kDocumentParent/$kCollectionId/${docId.documentId}';
  }

  /// Look up [WantLgtmState] from Firestore, or return `null` if not found.
  static Future<WantLgtmState?> fromFirestoreOrNull({
    required FirestoreService firestoreService,
    required RepositorySlug slug,
    required int pr,
  }) async {
    final documentName = documentNameFor(slug: slug, pr: pr);
    final document = await firestoreService.getDocumentOrNull(documentName);
    return document == null ? null : WantLgtmState.fromDocument(document);
  }

  /// Finds a [WantLgtmState] by its GitHub [checkRunId].
  static Future<WantLgtmState?> findByCheckRunId({
    required FirestoreService firestoreService,
    required int checkRunId,
  }) async {
    final filterMap = {'$kCheckRunIdField =': checkRunId};
    final documents = await firestoreService.query(kCollectionId, filterMap);
    if (documents.isEmpty) {
      return null;
    }
    return WantLgtmState.fromDocument(documents.first);
  }

  /// Queries all [WantLgtmState] documents with status `in_progress`.
  static Future<List<WantLgtmState>> queryInProgress({
    required FirestoreService firestoreService,
    RepositorySlug? slug,
  }) async {
    final filterMap = <String, Object>{
      '$kCheckRunStatusField =': 'in_progress',
    };
    if (slug != null) {
      filterMap['$kSlugField ='] = slug.fullName;
    }
    final documents = await firestoreService.query(kCollectionId, filterMap);
    return documents.map(WantLgtmState.fromDocument).toList();
  }

  /// Initializes a new [WantLgtmState] instance.
  static WantLgtmState initialize({
    required RepositorySlug slug,
    required int pr,
    required String headSha,
    required int checkRunId,
    required String checkRunStatus,
    required String checkRunTitle,
    String? checkRunConclusion,
    String? directive,
    DateTime? updatedAt,
  }) {
    final state = WantLgtmState()
      ..name = documentNameFor(slug: slug, pr: pr)
      ..slug = slug
      ..pr = pr
      ..headSha = headSha
      ..checkRunId = checkRunId
      ..checkRunStatus = checkRunStatus
      ..checkRunTitle = checkRunTitle
      ..checkRunConclusion = checkRunConclusion
      ..directive = directive
      ..updatedAt = updatedAt ?? DateTime.now().toUtc();
    return state;
  }

  /// The repository owner.
  String get slugOwner => fields[kSlugOwnerField]!.stringValue!;
  set slugOwner(String value) => fields[kSlugOwnerField] = value.toValue();

  /// The repository name.
  String get slugName => fields[kSlugNameField]!.stringValue!;
  set slugName(String value) => fields[kSlugNameField] = value.toValue();

  /// The repository slug.
  RepositorySlug get slug {
    if (fields[kSlugField]?.stringValue case final fullSlug?
        when fullSlug.contains('/')) {
      final parts = fullSlug.split('/');
      return RepositorySlug(parts[0], parts[1]);
    }
    return RepositorySlug(slugOwner, slugName);
  }

  set slug(RepositorySlug value) {
    fields[kSlugField] = value.fullName.toValue();
    slugOwner = value.owner;
    slugName = value.name;
  }

  /// The pull request number.
  int get pr => int.parse(fields[kPrField]!.integerValue!);
  set pr(int value) => fields[kPrField] = value.toValue();

  /// The raw directive string, or null if omitted/removed.
  String? get directive => fields[kDirectiveField]?.stringValue;
  set directive(String? value) {
    if (value != null) {
      fields[kDirectiveField] = value.toValue();
    } else {
      fields.remove(kDirectiveField);
    }
  }

  /// The head commit SHA associated with the check run.
  String get headSha => fields[kHeadShaField]!.stringValue!;
  set headSha(String value) => fields[kHeadShaField] = value.toValue();

  /// The GitHub Check Run ID.
  int get checkRunId => int.parse(fields[kCheckRunIdField]!.integerValue!);
  set checkRunId(int value) => fields[kCheckRunIdField] = value.toValue();

  /// The GitHub Check Run status (`queued`, `in_progress`, `completed`).
  String get checkRunStatus => fields[kCheckRunStatusField]!.stringValue!;
  set checkRunStatus(String value) =>
      fields[kCheckRunStatusField] = value.toValue();

  /// The GitHub Check Run conclusion (`success`, `neutral`, null, etc.).
  String? get checkRunConclusion =>
      fields[kCheckRunConclusionField]?.stringValue;
  set checkRunConclusion(String? value) {
    if (value != null) {
      fields[kCheckRunConclusionField] = value.toValue();
    } else {
      fields.remove(kCheckRunConclusionField);
    }
  }

  /// The title of the check run output.
  String get checkRunTitle => fields[kCheckRunTitleField]!.stringValue!;
  set checkRunTitle(String value) =>
      fields[kCheckRunTitleField] = value.toValue();

  /// The timestamp of the last state update.
  DateTime? get updatedAt {
    final timestamp = fields[kUpdatedAtField]?.timestampValue;
    return timestamp != null ? DateTime.parse(timestamp) : null;
  }

  set updatedAt(DateTime? value) {
    if (value != null) {
      fields[kUpdatedAtField] = Value(
        timestampValue: value.toUtc().toIso8601String(),
      );
    } else {
      fields.remove(kUpdatedAtField);
    }
  }

  /// Converts this document to a Firestore [Write] operation.
  Write toWrite({bool? exists}) {
    return documentsToWrites([this], exists: exists).first;
  }

  /// Saves this document to Firestore via a transaction write.
  Future<void> save(FirestoreService firestoreService, {bool? exists}) async {
    await firestoreService.writeViaTransaction(
      documentsToWrites([this], exists: exists),
    );
  }
}
