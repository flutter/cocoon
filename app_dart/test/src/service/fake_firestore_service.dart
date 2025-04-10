// Copyright 2024 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:cocoon_service/src/model/firestore/base.dart';
import 'package:cocoon_service/src/service/config.dart';
import 'package:cocoon_service/src/service/firestore.dart';
import 'package:googleapis/firestore/v1.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../model/firestore_matcher.dart';
import '../utilities/mocks.dart';

export '../model/firestore_matcher.dart';

final queryKeyValidator = RegExp(r'(^[a-zA-Z_][a-zA-Z_0-9]*)$');

abstract base class _FakeInMemoryFirestoreService
    with FirestoreQueries
    implements FirestoreService {
  /// Every document currently stored in the fake.
  Iterable<Document> get documents => _documents.values;
  final _documents = <String, Document>{};

  @protected
  String get expectedProjectId => Config.flutterGcpProjectId;

  @protected
  String get expectedDatabaseId => Config.flutterGcpFirestoreDatabase;

  void _assertExpectedDatabase(String database) {
    final parts = p.posix.split(database);
    if (parts.length != 4) {
      throw StateError('Unexpected database: "$database"');
    }
    final [pLiteral, pName, dLiteral, dName] = parts;
    if (pLiteral != 'projects' || dLiteral != 'databases') {
      throw StateError('Unexpected database: "$database"');
    }
    if (pName != expectedProjectId || dName != expectedDatabaseId) {
      throw StateError('Unexpected database: "$database"');
    }
  }

  final alphabet = ('ABCDEFGHIJKLMNOPQRSTUVWXYZ'
              'abcdefghijklmnopqrstuvwxyz'
              '0123456789' *
          32)
      .split('');

  String _generateUniqueId() {
    final result = (alphabet..shuffle()).take(20).join('');

    if (_documents.containsKey(result)) {
      return _generateUniqueId();
    }

    return result;
  }

  DateTime _now() => DateTime.now();

  Document _clone(Document other) {
    return Document(
      name: other.name,
      fields: {...?other.fields},
      createTime: other.createTime,
      updateTime: other.updateTime,
    );
  }

  /// Resolves a full path a [Document.name] by a collection and document ID.
  String resolveDocumentName(String collectionId, String documentId) {
    return p.posix.join(
      'projects',
      expectedProjectId,
      'databases',
      expectedDatabaseId,
      'documents',
      collectionId,
      documentId,
    );
  }

  /// Returns the document specified by [documentName].
  ///
  /// If the document does not exist, returns `null`.
  Document? tryPeekDocumentByName(String documentName) {
    final document = _documents[documentName];
    return document == null ? null : _clone(document);
  }

  /// Returns the document specified by [collectionId]/[documentId].
  ///
  /// If the document does not exist, returns `null`.
  Document? tryPeekDocumentByPath(String collectionId, String documentId) {
    final documentName = resolveDocumentName(collectionId, documentId);
    return tryPeekDocumentByName(documentName);
  }

  /// Returns the document specified by [documentName].
  ///
  /// The document must exist.
  Document peekDocumentByName(String documentName) {
    final document = _documents[documentName];
    if (document == null) {
      throw StateError('No document "$documentName" found');
    }
    return _clone(document);
  }

  /// Returns the document that ends with [relativePath].
  ///
  /// The document must exist.
  Document peekDocumentByPath(String collectionId, String documentId) {
    final documentName = resolveDocumentName(collectionId, documentId);
    return peekDocumentByName(documentName);
  }

  /// Stores a [document].
  ///
  /// Note that this method bypasses normal database conventions, and is
  /// intended to represent changes to the database that happen _before_ a test
  /// runs, or as a side-effect not covered in a test.
  ///
  /// [Document.name] must be set, or this method fails.
  ///
  /// If [created] is set, it is used, otherwise [DateTime.now] is used for
  /// a new document, and the _prevous_ [Document.createTime] is used for a
  /// pre-existing document.
  ///
  /// If [updated] is set, it is used, otherwise [DateTime.now] is used.
  ///
  /// Returns a clone of the newly inserted document.
  Document putDocument(
    Document document, {
    DateTime? created,
    DateTime? updated,
  }) {
    final name = document.name;
    if (name == null) {
      throw ArgumentError.value(document, 'document', 'name must be set');
    }
    if (_failOnWriteDocument[name] case final exception?) {
      throw exception;
    }

    final collection = p.basename(p.dirname(name));
    if (_failOnWriteCollection[collection] case final exception?) {
      throw exception;
    }
    final existing = tryPeekDocumentByName(name);
    _documents[name] = Document(
      name: name,
      fields: {...?document.fields},
      createTime:
          created?.toUtc().toIso8601String() ??
          existing?.createTime ??
          _now().toUtc().toIso8601String(),
      updateTime: (updated ?? _now()).toUtc().toIso8601String(),
    );
    return _clone(_documents[name]!);
  }

  final _failOnWriteDocument = <String, Exception>{};

  /// Instructs the fake to throw an exception if [document] is written.
  void failOnWriteDocument(
    Document document, [
    DetailedApiRequestError? exception,
  ]) {
    if (document.name == null) {
      fail('Missing "name" field');
    }
    _failOnWriteDocument[document.name!] =
        exception ??
        DetailedApiRequestError(
          500,
          'Used failOnWriteDocument(${document.name})',
        );
  }

  final _failOnWriteCollection = <String, Exception>{};

  /// Instructs the fake to throw an exception if [collection] is written.
  void failOnWriteCollection(
    String collection, [
    DetailedApiRequestError? exception,
  ]) {
    _failOnWriteCollection[collection] =
        exception ??
        DetailedApiRequestError(500, 'Used failOnWriteCollection($collection)');
  }

  @override
  Future<BatchWriteResponse> batchWriteDocuments(
    BatchWriteRequest request,
    String database,
  ) async {
    _assertExpectedDatabase(database);
    return BatchWriteResponse(
      status: _batchWriteSync(request.writes ?? const []),
    );
  }

  /// Same as [batchWriteDocuments], but does not yield the microtask loop.
  List<Status> _batchWriteSync(List<Write> writes) {
    final response = <Status>[];
    for (final write in writes) {
      final document = write.update;
      if (document == null) {
        response.add(Status(code: 3, message: 'Missing "update" field'));
        continue;
      }

      final name = document.name;
      if (name == null) {
        response.add(Status(code: 3, message: 'Missing "name" field'));
        continue;
      }

      switch (write.currentDocument) {
        // Must find an existing document to update.
        case final p? when p.exists == true:
          final existing = tryPeekDocumentByName(name);
          if (existing == null) {
            response.add(Status(code: 9, message: '"$name" does not exist'));
            continue;
          }
          putDocument(document);

        // Must not find an existing document and insert.
        case final p? when p.exists == false:
          final name = document.name ?? _generateUniqueId();
          if (tryPeekDocumentByName(name) != null) {
            response.add(Status(code: 9, message: '"$name" already exists'));
            continue;
          }
          putDocument(document);

        // Upsert: update if existing and insert if missing.
        default:
          putDocument(document);
      }
      response.add(Status(code: 0));
    }
    return response;
  }

  @override
  Future<Document> getDocument(String name) async {
    final result = tryPeekDocumentByName(name);
    if (result == null) {
      throw DetailedApiRequestError(
        HttpStatus.notFound,
        'Document "$name" not found',
      );
    }
    return result;
  }

  @override
  Future<Document> createDocument(
    Document document, {
    required String collectionId,
  }) async {
    if (document.name case final name?
        when tryPeekDocumentByName(name) != null) {
      throw DetailedApiRequestError(
        HttpStatus.notFound,
        'Document "$name" already exists',
      );
    }
    return putDocument(
      _clone(document)
        ..name = resolveDocumentName(collectionId, _generateUniqueId()),
    );
  }

  @override
  Future<CommitResponse> writeViaTransaction(List<Write> writes) async {
    // Poor man's write-only transaction:
    //
    // 1. Store a copy of the existing documents.
    // 2. Attempt to make writes
    // 3. If any write would fail (non-0 status), restore.
    //
    // We have to make some assumptions here to make this easier to reason
    // about compared to prod code, namely we assume each Write uniquely
    // writes to a document, i.e. there are not multiple writes each writing
    // to the same document.
    final beforeTransaction = _documents.map((k, v) => MapEntry(k, _clone(v)));
    final result = _batchWriteSync(writes);
    if (result.any((r) => r.code != 0)) {
      _documents
        ..clear()
        ..addAll(beforeTransaction);
      throw DetailedApiRequestError(500, 'The transaction was aborted');
    }

    final updated = _now().toUtc().toIso8601String();
    return CommitResponse(
      commitTime: updated,
      writeResults: List.generate(
        writes.length,
        (_) => WriteResult(updateTime: updated),
      ),
    );
  }

  @override
  Future<List<Document>> query(
    String collectionId,
    Map<String, Object> filterMap, {
    int? limit,
    Map<String, String>? orderMap,
    String compositeFilterOp = kCompositeFilterOpAnd,
  }) async {
    var results = documents.where((document) {
      final collection = p.basename(p.dirname(document.name!));
      return collectionId == collection;
    });

    results = results.where((document) {
      return _matchesFilter(document.fields!, filterMap);
    });

    if (compositeFilterOp != kCompositeFilterOpAnd) {
      throw UnimplementedError('compositeFilterOp: $compositeFilterOp');
    }

    var sorted = [...results];

    if (orderMap != null) {
      if (orderMap.values.any((v) => v != kQueryOrderDescending)) {
        throw UnimplementedError('orderMap: ${[...orderMap.values]}');
      }

      for (var key in orderMap.keys) {
        if (!queryKeyValidator.hasMatch(key)) {
          throw ArgumentError.value(
            'order map key($key) does not match firestore regex',
          );
        }
      }

      // Hard-coded to assume all sorts are DESCENDING.
      sorted.sort((a, b) {
        for (final fieldName in orderMap.keys) {
          final aField = a.fields?[fieldName];
          final bField = b.fields?[fieldName];
          if (aField == null) {
            return 1;
          }
          if (bField == null) {
            return -1;
          }

          final result = _compareValues(bField, aField);
          if (result != 0) {
            return result;
          }
        }

        return 0;
      });
    }

    if (limit != null) {
      sorted = [...sorted.take(limit)];
    }

    return sorted;
  }

  static bool _matchesFilter(
    Map<String, Value> fields,
    Map<String, Object> filters,
  ) {
    for (final MapEntry(key: fieldAndOp, value: value) in filters.entries) {
      final [fieldName, operator] = fieldAndOp.trim().split(' ');
      final fieldValue = fields[fieldName];

      // bool can be == or !=, but not compared.
      switch (operator) {
        case '=':
          if (!_equals(fieldValue, value)) {
            return false;
          }
          continue;
        case '!=':
          if (_equals(fieldValue, value)) {
            return false;
          }
          continue;
      }

      if (fieldValue == null) {
        return false;
      }

      final result = _compare(fieldValue, value);
      if (result == null) {
        return false;
      }
      final matched = switch (operator) {
        '<' => result < 0,
        '<=' => result <= 0,
        '>' => result > 0,
        '>=' => result >= 0,
        _ => throw UnimplementedError('"$operator" operator'),
      };

      if (!matched) {
        return false;
      }
    }

    return true;
  }

  static bool _equals(Value? fieldValue, Object rawValue) {
    return switch (rawValue) {
      final String v => v == fieldValue?.stringValue,
      final int v => v == int.tryParse(fieldValue?.integerValue ?? ''),
      final bool v => v == fieldValue?.booleanValue,
      _ => false,
    };
  }

  static int? _compare(Value fieldValue, Object rawValue) {
    return switch (rawValue) {
      final String v => fieldValue.stringValue?.compareTo(v),
      final int v => int.tryParse(fieldValue.integerValue ?? '')?.compareTo(v),
      _ => throw UnimplementedError('"${rawValue.runtimeType}" filter'),
    };
  }

  static int _compareValues(Value a, Value b) {
    if (a.stringValue case final string?) {
      return string.compareTo(b.stringValue!);
    }
    if (a.integerValue case final integer?) {
      return int.parse(integer).compareTo(int.parse(b.integerValue!));
    }
    throw UnimplementedError('${a.toJson()}');
  }
}

/// A partial fake implementation of [FirestoreService].
///
/// For methods that are implemented by [_FakeInMemoryFirestoreService],
/// operates as an in-memory fake, with writes/reads flowing through the API,
/// which is an in-memory database simulation.
///
/// For other methods, they delegate to [mock], which can be manipulated at
/// test runtime similar to any other mock (i.e. `when(firestore.mock)`).
///
/// The awkwardness will be removed after
/// https://github.com/flutter/flutter/issues/165931.
final class FakeFirestoreService extends _FakeInMemoryFirestoreService {
  /// A mock [FirestoreService] for legacy methods that don't faked-out APIs.
  final mock = MockFirestoreService();

  @override
  Future<ProjectsDatabasesDocumentsResource> documentResource() {
    return mock.documentResource();
  }
}

/// Checks that the models described by [metadata] match storage of [matcher].
///
/// ## Example
///
/// ```dart
/// expect(
///   fakeFirestoreService,
///   inStorage(Task.metadata, hasLength(1)),
/// );
/// ```
Matcher existsInStorage<T extends AppDocument<T>>(
  AppDocumentMetadata<T> metadata,
  Object? matcherOrCollection,
) {
  return _InStorage(metadata, wrapMatcher(matcherOrCollection));
}

final class _InStorage<T extends AppDocument<T>> extends Matcher {
  const _InStorage(this.metadata, this.matcher);
  final AppDocumentMetadata<T> metadata;
  final Matcher matcher;

  @override
  Description describe(Description description) {
    description = description.add('is storing $T instances where ');
    return matcher.describe(description);
  }

  @override
  bool matches(Object? item, _) {
    if (item is! FakeFirestoreService) {
      return false;
    }
    return matcher.matches(
      item.documents.where((d) => isDocumentA(d, metadata)),
      {},
    );
  }

  @override
  Description describeMismatch(
    Object? item,
    Description mismatchDescription,
    _,
    _,
  ) {
    if (item is! FakeFirestoreService) {
      return mismatchDescription
          .add('Expected a FakeFirestoreService, but got a')
          .addDescriptionOf(item);
    }
    final documentsOfType = [
      ...item.documents
          .where((d) => isDocumentA(d, metadata))
          .map(metadata.fromDocument)
          .map((d) => d.toJsonRaw()),
    ];
    return mismatchDescription.add(
      'Has ${documentsOfType.length} $T: '
      '${const JsonEncoder.withIndent('  ').convert(documentsOfType)}',
    );
  }
}
