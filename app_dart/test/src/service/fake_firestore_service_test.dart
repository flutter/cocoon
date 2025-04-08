// Copyright 2024 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_server_test/test_logging.dart';
import 'package:cocoon_service/src/service/firestore.dart';
import 'package:googleapis/firestore/v1.dart' as g;
import 'package:test/test.dart';

import 'fake_firestore_service.dart';

void main() {
  useTestLoggerPerTest();

  late FakeFirestoreService firestore;

  setUp(() {
    firestore = FakeFirestoreService();
  });

  group('tryPeekDocument', () {
    test('returns null if the document does not exist', () {
      expect(
        firestore.tryPeekDocumentByPath('messages', 'does-not-exist'),
        isNull,
      );
    });

    test('returns a clone of a matching document', () {
      final newDoc = firestore.putDocument(
        g.Document(
          fields: {'Hello': g.Value(stringValue: 'World')},
          name: firestore.resolveDocumentName('messages', 'greeting'),
        ),
      );

      expect(
        firestore.tryPeekDocumentByName(newDoc.name!),
        isA<g.Document>().having(
          (d) => d.fields?['Hello']?.stringValue,
          "['Hello']?.stringValue",
          'World',
        ),
      );

      newDoc.fields!['Hello'] = g.Value(stringValue: 'Changed');

      expect(
        firestore.tryPeekDocumentByName(newDoc.name!),
        isA<g.Document>().having(
          (d) => d.fields?['Hello']?.stringValue,
          "['Hello']?.stringValue",
          'World',
        ),
        reason: 'Should have returned a clone that is not changed',
      );
    });
  });

  test('failOnWrite forces a 500 error', () {
    final blockDoc = g.Document(
      fields: {'Hello': g.Value(stringValue: 'World')},
      name: firestore.resolveDocumentName('messages', 'greeting'),
    );

    firestore.failOnWrite(blockDoc);

    expect(
      () => firestore.putDocument(blockDoc),
      throwsA(
        isA<g.DetailedApiRequestError>().having((e) => e.status, 'status', 500),
      ),
    );
  });

  group('batchWriteDocuments', () {
    const expectedDatabase = 'projects/flutter-dashboard/databases/cocoon';

    group('must match expected database', () {
      test('bad projectId', () async {
        await expectLater(
          firestore.batchWriteDocuments(
            g.BatchWriteRequest(),
            'projects/unexpected-project-id/databases/cocoon',
          ),
          throwsA(isStateError),
        );
      });

      test('bad databaseId', () async {
        await expectLater(
          firestore.batchWriteDocuments(
            g.BatchWriteRequest(),
            'projects/flutter-dashboard/databases/unexpected-database-id',
          ),
          throwsA(isStateError),
        );
      });

      test('bad overall format', () async {
        await expectLater(
          firestore.batchWriteDocuments(
            g.BatchWriteRequest(),
            'projectZ/flutter-dashboard/databaseS/cocoon',
          ),
          throwsA(isStateError),
        );
      });
    });

    test('requires "update"', () async {
      final response = await firestore.batchWriteDocuments(
        g.BatchWriteRequest(writes: [g.Write()]),
        expectedDatabase,
      );

      expect(
        response.status,
        allOf(isNotEmpty, everyElement((g.Status status) => status.code != 0)),
      );
    });

    test('requires "name"', () async {
      final response = await firestore.batchWriteDocuments(
        g.BatchWriteRequest(writes: [g.Write(update: g.Document())]),
        expectedDatabase,
      );

      expect(
        response.status,
        allOf(isNotEmpty, everyElement((g.Status status) => status.code != 0)),
      );
    });

    test('updates an existing document if it exists', () async {
      final existingDoc = g.Document(
        name: firestore.resolveDocumentName('collection-id', 'document-id'),
      );
      firestore.putDocument(existingDoc);

      final response = await firestore.batchWriteDocuments(
        g.BatchWriteRequest(
          writes: [
            g.Write(
              currentDocument: g.Precondition(exists: true),
              update: g.Document(
                name: existingDoc.name,
                fields: {'Hello': g.Value(stringValue: 'World')},
              ),
            ),
          ],
        ),
        expectedDatabase,
      );

      expect(
        response.status,
        allOf(isNotEmpty, everyElement((g.Status status) => status.code == 0)),
      );

      expect(
        firestore.tryPeekDocumentByName(existingDoc.name!),
        isA<g.Document>().having(
          (d) => d.fields?['Hello']?.stringValue,
          "['Hello']?.stringValue",
          'World',
        ),
      );
    });

    test('fails to update a document that does not exist', () async {
      final response = await firestore.batchWriteDocuments(
        g.BatchWriteRequest(
          writes: [
            g.Write(
              currentDocument: g.Precondition(exists: true),
              update: g.Document(
                name: firestore.resolveDocumentName(
                  'collection-id',
                  'document-id',
                ),
                fields: {'Hello': g.Value(stringValue: 'World')},
              ),
            ),
          ],
        ),
        expectedDatabase,
      );

      expect(
        response.status,
        allOf(isNotEmpty, everyElement((g.Status status) => status.code != 0)),
      );

      expect(
        firestore.tryPeekDocumentByName(
          firestore.resolveDocumentName('collection-id', 'document-id'),
        ),
        isNull,
      );
    });

    test('inserts a new document if it does not exist', () async {
      final response = await firestore.batchWriteDocuments(
        g.BatchWriteRequest(
          writes: [
            g.Write(
              currentDocument: g.Precondition(exists: false),
              update: g.Document(
                name: firestore.resolveDocumentName(
                  'collection-id',
                  'document-id',
                ),
                fields: {'Hello': g.Value(stringValue: 'World')},
              ),
            ),
          ],
        ),
        expectedDatabase,
      );

      expect(
        response.status,
        allOf(isNotEmpty, everyElement((g.Status status) => status.code == 0)),
      );

      expect(
        firestore.tryPeekDocumentByName(
          firestore.resolveDocumentName('collection-id', 'document-id'),
        ),
        isA<g.Document>().having(
          (d) => d.fields?['Hello']?.stringValue,
          "['Hello']?.stringValue",
          'World',
        ),
      );
    });

    test('fails to insert a new document if already exists', () async {
      final existingDoc = g.Document(
        name: firestore.resolveDocumentName('collection-id', 'document-id'),
      );
      firestore.putDocument(existingDoc);

      final response = await firestore.batchWriteDocuments(
        g.BatchWriteRequest(
          writes: [
            g.Write(
              currentDocument: g.Precondition(exists: false),
              update: g.Document(
                name: firestore.resolveDocumentName(
                  'collection-id',
                  'document-id',
                ),
                fields: {'Hello': g.Value(stringValue: 'World')},
              ),
            ),
          ],
        ),
        expectedDatabase,
      );

      expect(
        response.status,
        allOf(isNotEmpty, everyElement((g.Status status) => status.code != 0)),
      );

      expect(
        firestore.tryPeekDocumentByName(
          firestore.resolveDocumentName('collection-id', 'document-id'),
        ),
        isA<g.Document>().having(
          (d) => d.fields?['Hello']?.stringValue,
          "['Hello']?.stringValue",
          isNull,
        ),
      );
    });

    test('updates existing document and inserts a new document', () async {
      final existingDoc = g.Document(
        name: firestore.resolveDocumentName('collection-id', 'existing-id'),
      );
      firestore.putDocument(existingDoc);

      final response = await firestore.batchWriteDocuments(
        g.BatchWriteRequest(
          writes: [
            g.Write(
              update: g.Document(
                name: firestore.resolveDocumentName(
                  'collection-id',
                  'existing-id',
                ),
                fields: {'Hello': g.Value(stringValue: 'World')},
              ),
            ),
            g.Write(
              update: g.Document(
                name: firestore.resolveDocumentName('collection-id', 'new-id'),
                fields: {'Hello': g.Value(stringValue: 'World')},
              ),
            ),
          ],
        ),
        expectedDatabase,
      );

      expect(
        response.status,
        allOf(isNotEmpty, everyElement((g.Status status) => status.code == 0)),
      );

      expect(
        firestore.tryPeekDocumentByName(
          firestore.resolveDocumentName('collection-id', 'existing-id'),
        ),
        isA<g.Document>().having(
          (d) => d.fields?['Hello']?.stringValue,
          "['Hello']?.stringValue",
          'World',
        ),
      );

      expect(
        firestore.tryPeekDocumentByName(
          firestore.resolveDocumentName('collection-id', 'new-id'),
        ),
        isA<g.Document>().having(
          (d) => d.fields?['Hello']?.stringValue,
          "['Hello']?.stringValue",
          'World',
        ),
      );
    });
  });

  group('writeViaTransaction', () {
    test('writes successfully', () async {
      final existingDoc = g.Document(
        name: firestore.resolveDocumentName('collection-id', 'existing-id'),
      );
      firestore.putDocument(existingDoc);

      await firestore.writeViaTransaction([
        g.Write(
          update: g.Document(
            name: firestore.resolveDocumentName('collection-id', 'existing-id'),
            fields: {'Hello': g.Value(stringValue: 'World')},
          ),
        ),
        g.Write(
          update: g.Document(
            name: firestore.resolveDocumentName('collection-id', 'new-id'),
            fields: {'Hello': g.Value(stringValue: 'World')},
          ),
        ),
      ]);

      expect(
        firestore.tryPeekDocumentByName(
          firestore.resolveDocumentName('collection-id', 'existing-id'),
        ),
        isA<g.Document>().having(
          (d) => d.fields?['Hello']?.stringValue,
          "['Hello']?.stringValue",
          'World',
        ),
      );

      expect(
        firestore.tryPeekDocumentByName(
          firestore.resolveDocumentName('collection-id', 'new-id'),
        ),
        isA<g.Document>().having(
          (d) => d.fields?['Hello']?.stringValue,
          "['Hello']?.stringValue",
          'World',
        ),
      );
    });

    test('aborts and does not apply writes', () async {
      final existingDoc = g.Document(
        name: firestore.resolveDocumentName('collection-id', 'existing-id'),
      );
      firestore.putDocument(existingDoc);

      await expectLater(
        firestore.writeViaTransaction([
          g.Write(
            // This will fail
            currentDocument: g.Precondition(exists: false),
            update: g.Document(
              name: firestore.resolveDocumentName(
                'collection-id',
                'existing-id',
              ),
              fields: {'Hello': g.Value(stringValue: 'World')},
            ),
          ),
          g.Write(
            update: g.Document(
              name: firestore.resolveDocumentName('collection-id', 'new-id'),
              fields: {'Hello': g.Value(stringValue: 'World')},
            ),
          ),
        ]),
        throwsA(
          isA<g.DetailedApiRequestError>().having(
            (e) => e.status,
            'status',
            500,
          ),
        ),
      );

      expect(
        firestore.tryPeekDocumentByName(
          firestore.resolveDocumentName('collection-id', 'existing-id'),
        ),
        isA<g.Document>().having(
          (d) => d.fields?['Hello']?.stringValue,
          "['Hello']?.stringValue",
          isNull,
        ),
      );

      expect(
        firestore.tryPeekDocumentByName(
          firestore.resolveDocumentName('collection-id', 'new-id'),
        ),
        isNull,
      );
    });
  });

  group('query', () {
    group('filter', () {
      group('bool', () {
        setUp(() {
          firestore.putDocument(
            g.Document(
              name: firestore.resolveDocumentName('items', '1'),
              fields: {'is_flaky': g.Value(booleanValue: true)},
            ),
          );

          firestore.putDocument(
            g.Document(
              name: firestore.resolveDocumentName('items', '2'),
              fields: {'is_flaky': g.Value(booleanValue: false)},
            ),
          );

          firestore.putDocument(
            g.Document(
              name: firestore.resolveDocumentName('items', '3'),
              fields: {'is_flaky': g.Value(booleanValue: null)},
            ),
          );

          firestore.putDocument(
            g.Document(
              name: firestore.resolveDocumentName('items', '4'),
              fields: {},
            ),
          );
        });

        test('== true', () async {
          final query = await firestore.query('items', {'is_flaky =': true});
          expect(query.map((q) => q.name), [endsWith('1')]);
        });

        test('!= true', () async {
          final query = await firestore.query('items', {'is_flaky !=': true});
          expect(query.map((q) => q.name), [
            endsWith('2'),
            endsWith('3'),
            endsWith('4'),
          ]);
        });

        test('== false', () async {
          final query = await firestore.query('items', {'is_flaky =': false});
          expect(query.map((q) => q.name), [endsWith('2')]);
        });

        test('!= false', () async {
          final query = await firestore.query('items', {'is_flaky !=': false});
          expect(query.map((q) => q.name), [
            endsWith('1'),
            endsWith('3'),
            endsWith('4'),
          ]);
        });
      });

      group('string', () {
        setUp(() {
          firestore.putDocument(
            g.Document(
              name: firestore.resolveDocumentName('items', '1'),
              fields: {'task': g.Value(stringValue: 'Eat')},
            ),
          );

          firestore.putDocument(
            g.Document(
              name: firestore.resolveDocumentName('items', '2'),
              fields: {'task': g.Value(stringValue: 'Sleep')},
            ),
          );

          firestore.putDocument(
            g.Document(
              name: firestore.resolveDocumentName('items', '3'),
              fields: {'task': g.Value(stringValue: null)},
            ),
          );

          firestore.putDocument(
            g.Document(
              name: firestore.resolveDocumentName('items', '4'),
              fields: {},
            ),
          );
        });

        test('== "Eat"', () async {
          final query = await firestore.query('items', {'task =': 'Eat'});
          expect(query.map((q) => q.name), [endsWith('1')]);
        });

        test('!= Eat', () async {
          final query = await firestore.query('items', {'task !=': 'Eat'});
          expect(query.map((q) => q.name), [
            endsWith('2'),
            endsWith('3'),
            endsWith('4'),
          ]);
        });

        test('> Eat', () async {
          final query = await firestore.query('items', {'task >': 'Eat'});
          expect(query.map((q) => q.name), [endsWith('2')]);
        });

        test('>= Eat', () async {
          final query = await firestore.query('items', {'task >=': 'Eat'});
          expect(query.map((q) => q.name), [endsWith('1'), endsWith('2')]);
        });
      });

      group('int', () {
        setUp(() {
          firestore.putDocument(
            g.Document(
              name: firestore.resolveDocumentName('items', '1'),
              fields: {'calories': g.Value(integerValue: '200')},
            ),
          );

          firestore.putDocument(
            g.Document(
              name: firestore.resolveDocumentName('items', '2'),
              fields: {'calories': g.Value(integerValue: '500')},
            ),
          );

          firestore.putDocument(
            g.Document(
              name: firestore.resolveDocumentName('items', '3'),
              fields: {'calories': g.Value(integerValue: null)},
            ),
          );

          firestore.putDocument(
            g.Document(
              name: firestore.resolveDocumentName('items', '4'),
              fields: {},
            ),
          );
        });

        test('== 200', () async {
          final query = await firestore.query('items', {'calories =': 200});
          expect(query.map((q) => q.name), [endsWith('1')]);
        });

        test('!= 200', () async {
          final query = await firestore.query('items', {'calories !=': 200});
          expect(query.map((q) => q.name), [
            endsWith('2'),
            endsWith('3'),
            endsWith('4'),
          ]);
        });

        test('> 200', () async {
          final query = await firestore.query('items', {'calories >': 200});
          expect(query.map((q) => q.name), [endsWith('2')]);
        });

        test('>= 200', () async {
          final query = await firestore.query('items', {'calories >=': 200});
          expect(query.map((q) => q.name), [endsWith('1'), endsWith('2')]);
        });
      });

      test('multiple filters', () async {
        firestore.putDocument(
          g.Document(
            name: firestore.resolveDocumentName('items', '1'),
            fields: {
              'is_spicy': g.Value(booleanValue: true),
              'calories': g.Value(integerValue: '200'),
            },
          ),
        );

        firestore.putDocument(
          g.Document(
            name: firestore.resolveDocumentName('items', '2'),
            fields: {
              'is_spicy': g.Value(booleanValue: false),
              'calories': g.Value(integerValue: '500'),
            },
          ),
        );

        final query = await firestore.query('items', {
          'calories >=': 200,
          'is_spicy =': true,
        });
        expect(query.map((q) => q.name), [endsWith('1')]);
      });
    });

    group('limit', () {
      setUp(() {
        firestore.putDocument(
          g.Document(
            name: firestore.resolveDocumentName('items', '1'),
            fields: {'number': g.Value(integerValue: '1')},
          ),
        );

        firestore.putDocument(
          g.Document(
            name: firestore.resolveDocumentName('items', '2'),
            fields: {'number': g.Value(integerValue: '2')},
          ),
        );

        firestore.putDocument(
          g.Document(
            name: firestore.resolveDocumentName('items', '3'),
            fields: {'number': g.Value(integerValue: '3')},
          ),
        );

        firestore.putDocument(
          g.Document(
            name: firestore.resolveDocumentName('items', '4'),
            fields: {'number': g.Value(integerValue: '4')},
          ),
        );
      });

      test('unspecified', () async {
        final query = await firestore.query('items', {'number >=': 1});
        expect(query.map((q) => q.name), [
          endsWith('1'),
          endsWith('2'),
          endsWith('3'),
          endsWith('4'),
        ]);
      });

      test('> total items', () async {
        final query = await firestore.query('items', {
          'number >=': 1,
        }, limit: 100);
        expect(query.map((q) => q.name), [
          endsWith('1'),
          endsWith('2'),
          endsWith('3'),
          endsWith('4'),
        ]);
      });

      test('< total items', () async {
        final query = await firestore.query('items', {
          'number >=': 1,
        }, limit: 2);
        expect(query.map((q) => q.name), [endsWith('1'), endsWith('2')]);
      });

      // Regression test: If a filter is applied, and the limit is 1, the query
      // should return the first item that matches the filter, not the first
      // item in the collection and then apply the filter.
      test('should apply last', () async {
        final query = await firestore.query(
          'items',
          {'number >=': 1},
          limit: 1,
          orderMap: {'number': kQueryOrderDescending},
        );
        expect(query.map((q) => q.name), [endsWith('4')]);
      });
    });

    group('order', () {
      test('unordered', () async {
        for (var i = 4; i >= 1; i--) {
          firestore.putDocument(
            g.Document(
              name: firestore.resolveDocumentName('items', '$i'),
              fields: {'alpha': g.Value(integerValue: '$i')},
            ),
          );
        }

        final query = await firestore.query('items', {}, orderMap: {});

        expect(query.map((q) => q.name), [
          endsWith('4'),
          endsWith('3'),
          endsWith('2'),
          endsWith('1'),
        ]);
      });

      test('1 field', () async {
        for (var i = 4; i >= 1; i--) {
          firestore.putDocument(
            g.Document(
              name: firestore.resolveDocumentName('items', '$i'),
              fields: {'alpha': g.Value(integerValue: '$i')},
            ),
          );
        }

        final query = await firestore.query(
          'items',
          {},
          orderMap: {'alpha': kQueryOrderDescending},
        );

        expect(query.map((q) => q.name), [
          endsWith('4'),
          endsWith('3'),
          endsWith('2'),
          endsWith('1'),
        ]);
      });

      test('2 fields', () async {
        firestore.putDocument(
          g.Document(
            name: firestore.resolveDocumentName('items', '1'),
            fields: {
              'alpha': g.Value(integerValue: '1'),
              'beta': g.Value(integerValue: '1'),
            },
          ),
        );

        firestore.putDocument(
          g.Document(
            name: firestore.resolveDocumentName('items', '2'),
            fields: {
              'alpha': g.Value(integerValue: '1'),
              'beta': g.Value(integerValue: '2'),
            },
          ),
        );

        firestore.putDocument(
          g.Document(
            name: firestore.resolveDocumentName('items', '3'),
            fields: {
              'alpha': g.Value(integerValue: '2'),
              'beta': g.Value(integerValue: '3'),
            },
          ),
        );

        final query = await firestore.query(
          'items',
          {},
          orderMap: {
            'alpha': kQueryOrderDescending,
            'beta': kQueryOrderDescending,
          },
        );

        expect(query.map((q) => q.name), [
          endsWith('3'),
          endsWith('2'),
          endsWith('1'),
        ]);
      });
    });
  });
}
