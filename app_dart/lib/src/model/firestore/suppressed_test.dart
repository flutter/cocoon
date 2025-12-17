// Copyright 2025 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:googleapis/firestore/v1.dart' hide Status;

import '../../service/firestore.dart';
import 'base.dart';

/// List of manual overrides for failing tests to flip the tree green.
///
/// This should be used sparingly and only when a test is flakey or clearly
/// breaking a roll. This is faster than moving the test to staging via
/// the bringup:true method.
final class SuppressedTest extends AppDocument<SuppressedTest> {
  static const kCollectionId = 'suppressed_tests';

  // Field names in Firestore
  static const fieldName = 'name';
  static const fieldRepository = 'repository';
  static const fieldIssueLink = 'issueLink';
  static const fieldIsSuppressed = 'isSuppressed';
  static const fieldCreateTimestamp = 'createTimestamp';
  static const fieldUpdates = 'updates';

  // Field names for Update object
  static const updateFieldUser = 'user';
  static const updateFieldUpdateTimestamp = 'updateTimestamp';
  static const updateFieldNote = 'note';
  static const updateFieldAction = 'action';

  static final metadata = AppDocumentMetadata<SuppressedTest>(
    collectionId: kCollectionId,
    fromDocument: SuppressedTest.fromDocument,
  );

  @override
  AppDocumentMetadata<SuppressedTest> get runtimeMetadata => metadata;

  /// Creates a [SuppressedTest] from a Firestore [Document].
  SuppressedTest.fromDocument(super.document);

  /// Returns the latest [SuppressedTest] for [repository] and [testName].
  static Future<SuppressedTest?> getLatest(
    FirestoreService firestore,
    String repository,
    String testName,
  ) async {
    final docs = await firestore.query(
      SuppressedTest.kCollectionId,
      {'$fieldRepository =': repository, '$fieldName =': testName},
      limit: 1,
      orderMap: {fieldCreateTimestamp: kQueryOrderDescending},
    );
    return docs.isEmpty ? null : SuppressedTest.fromDocument(docs.first);
  }

  /// Returns all [SuppressedTest] documents for [repository].
  static Future<List<SuppressedTest>> getSuppressedTests(
    FirestoreService firestore,
    String repository,
  ) async {
    final docs = await firestore.query(kCollectionId, {
      '$fieldRepository =': repository,
      '$fieldIsSuppressed =': true,
    });
    return docs.isEmpty
        ? []
        : [for (final doc in docs) SuppressedTest.fromDocument(doc)];
  }

  /// Creates a new [SuppressedTest] document.
  factory SuppressedTest({
    required String name,
    required String repository,
    required String issueLink,
    required bool isSuppressed,
    required DateTime createTimestamp,
    List<Map<String, dynamic>> updates = const [],
  }) {
    return SuppressedTest.fromDocument(
      Document(
        fields: {
          fieldName: name.toValue(),
          fieldRepository: repository.toValue(),
          fieldIssueLink: issueLink.toValue(),
          fieldIsSuppressed: isSuppressed.toValue(),
          fieldCreateTimestamp: createTimestamp.toValue(),
          fieldUpdates: updates.toValue(),
        },
      ),
    );
  }

  /// The misbehaving test.
  String get testName => fields[fieldName]!.stringValue!;

  /// The repository this test is evaluated with.
  String get repository => fields[fieldRepository]!.stringValue!;

  /// A required github issue link describing why the test is suppressed.
  String get issueLink => fields[fieldIssueLink]!.stringValue!;

  /// Whether this test is currently suppressed.
  bool get isSuppressed => fields[fieldIsSuppressed]!.booleanValue!;

  /// When this document was created.
  DateTime get createTimestamp =>
      DateTime.parse(fields[fieldCreateTimestamp]!.timestampValue!);

  /// A list of updates to this document for audit purposes.
  List<Map<String, dynamic>> get updates {
    final values = fields[fieldUpdates]?.arrayValue?.values;
    if (values == null) {
      return const [];
    }
    return [...values.map(_valueToUpdateMap)];
  }

  static Map<String, dynamic> _valueToUpdateMap(Value value) {
    final fields = value.mapValue!.fields!;
    return {
      updateFieldUser: fields[updateFieldUser]!.stringValue!,
      updateFieldUpdateTimestamp: DateTime.parse(
        fields[updateFieldUpdateTimestamp]!.timestampValue!,
      ),
      updateFieldNote: fields[updateFieldNote]!.stringValue!,
      updateFieldAction: fields[updateFieldAction]!.stringValue!,
    };
  }
}
