// Copyright 2024 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';
import 'dart:math';

import 'package:cocoon_service/src/service/config.dart';
import 'package:cocoon_service/src/service/firestore.dart';
import 'package:googleapis/firestore/v1.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../utilities/mocks.dart';

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
      fail('Unexpected database: "$database"');
    }
    final [pLiteral, pName, dLiteral, dName] = parts;
    if (pLiteral != 'projects' || dLiteral != 'databases') {
      fail('Unexpected database: "$database"');
    }
    if (pName != expectedProjectId || dName != expectedDatabaseId) {
      fail('Unexpected database: "$database"');
    }
  }

  final _random = Random();
  String _generateUniqueId() {
    const length = 20;
    const chars =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
        'abcdefghijklmnopqrstuvwxyz'
        '0123456789';
    final buffer = StringBuffer();

    for (var i = 0; i < length; i++) {
      final randomIndex = _random.nextInt(chars.length);
      buffer.write(chars[randomIndex]);
    }

    final result = buffer.toString();
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

  /// Returns the document specified by [documentName].
  ///
  /// If the document does not exist, returns `null`.
  Document? tryPeekDocument(String documentName) {
    final document = _documents[documentName];
    return document == null ? null : _clone(document);
  }

  /// Returns the document that ends with [relativePath].
  ///
  /// The document must exist.
  Document peekDocumentByPath(String relativePath) {
    final documentName = p.posix.join(
      'projects',
      expectedProjectId,
      'databases',
      expectedDatabaseId,
      'documents',
      relativePath,
    );
    final existingDocument = tryPeekDocument(documentName);
    if (existingDocument == null) {
      fail('No document "$documentName" found');
    }
    return existingDocument;
  }

  /// Stores a [document].
  ///
  /// Note that this method bypasses normal database conventions, and is
  /// intended to represent changes to the database that happen _before_ a test
  /// runs, or as a side-effect not covered in a test.
  ///
  /// Either [Document.name] or [name] must be set, or this method fails.
  ///
  /// If [created] is set, it is used, otherwise [DateTime.now] is used for
  /// a new document, and the _prevous_ [Document.createTime] is used for a
  /// pre-existing document.
  ///
  /// If [updated] is set, it is used, otherwise [DateTime.now] is used.
  ///
  /// Returns `true` if a new document was inserted, and `false` if updated.
  bool putDocument(
    Document document, {
    String? name,
    DateTime? created,
    DateTime? updated,
  }) {
    name ??= document.name;
    if (name == null) {
      throw ArgumentError.value(document, 'document', 'name must be set');
    }
    if (_failOnWrite[name] case final exception?) {
      throw exception;
    }
    final existing = tryPeekDocument(name);
    if (existing == null) {
      _documents[name] = Document(
        name: name,
        fields: {...?document.fields},
        createTime: (created ?? _now()).toUtc().toIso8601String(),
        updateTime: (updated ?? _now()).toUtc().toIso8601String(),
      );
      return true;
    }
    _documents[name] = Document(
      name: name,
      fields: {...?document.fields},
      createTime: created?.toUtc().toIso8601String() ?? existing.createTime,
      updateTime: (updated ?? _now()).toUtc().toIso8601String(),
    );
    return false;
  }

  final _failOnWrite = <String, Exception>{};

  /// Instructs the fake to throw an exception if [document] is written.
  void failOnWrite(Document document, [DetailedApiRequestError? exception]) {
    if (document.name == null) {
      fail('Missing "name" field');
    }
    _failOnWrite[document.name!] =
        exception ??
        DetailedApiRequestError(500, 'Used failOnWrite(${document.name})');
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
      switch (write.currentDocument) {
        // Must find an existing document to update.
        case final p? when p.exists == true:
          final name = document.name;
          if (name == null) {
            response.add(Status(code: 3, message: 'Missing "name" field'));
            continue;
          }
          final existing = tryPeekDocument(name);
          if (existing == null) {
            response.add(Status(code: 9, message: '"$name" does not exist'));
            continue;
          }
          putDocument(document);

        // Must not find an existing document and insert.
        case final p? when p.exists == false:
          final name = document.name ?? _generateUniqueId();
          if (tryPeekDocument(name) != null) {
            response.add(Status(code: 9, message: '"$name" already exists'));
            continue;
          }
          putDocument(document, name: name);

        // Upsert: update if existing and insert if missing.
        default:
          final name = document.name ?? _generateUniqueId();
          putDocument(document, name: name);
      }
      response.add(Status(code: 0));
    }
    return response;
  }

  @override
  Future<Document> getDocument(String name) async {
    final result = tryPeekDocument(name);
    if (result == null) {
      throw DetailedApiRequestError(
        HttpStatus.notFound,
        'Document "$name" not found',
      );
    }
    return result;
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

    if (limit != null) {
      results = results.take(limit);
    }

    if (compositeFilterOp != kCompositeFilterOpAnd) {
      throw UnimplementedError('compositeFilterOp: $compositeFilterOp');
    }

    var sorted = [...results];

    if (orderMap != null) {
      if (orderMap.values.any((v) => v != kQueryOrderDescending)) {
        throw UnimplementedError('orderMap: ${[...orderMap.values]}');
      }

      sorted.sort((a, b) {
        for (final fieldName in orderMap.keys) {
          final aField = a.fields?[fieldName];
          final bField = b.fields?[fieldName];
          if (aField == null) {
            return -1;
          }
          if (bField == null) {
            return 1;
          }

          final result = _compareValues(aField, bField);
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
      final [...fieldParts, operator] = fieldAndOp.split(' ');
      final fieldName = fieldParts.join(' ');
      final fieldValue = fields[fieldName];
      if (fieldValue == null) {
        return false;
      }
      final result = _compare(fieldValue, value);
      if (result == null) {
        return false;
      }
      final matched = switch (operator) {
        '=' => result == 0,
        '!=' => result != 0,
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
