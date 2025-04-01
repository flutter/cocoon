// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

@GenerateNiceMocks([
  MockSpec<g.FirestoreApi>(),
  MockSpec<g.ProjectsResource>(),
  MockSpec<g.ProjectsDatabasesResource>(),
  MockSpec<g.ProjectsDatabasesDocumentsResource>(
    onMissingStub: OnMissingStub.throwException,
  ),
])
import 'dart:io';

import 'package:cocoon_server/firestore.dart';
import 'package:googleapis/firestore/v1.dart' as g;
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import 'firestore_test.mocks.dart';

void main() {
  final notFound = g.DetailedApiRequestError(HttpStatus.notFound, '');
  final preExists = g.DetailedApiRequestError(HttpStatus.conflict, '');

  late MockProjectsDatabasesDocumentsResource mockDocumentsResource;
  late Firestore firestore;

  setUp(() {
    mockDocumentsResource = MockProjectsDatabasesDocumentsResource();

    final databases = MockProjectsDatabasesResource();
    when(databases.documents).thenReturn(mockDocumentsResource);

    final projects = MockProjectsResource();
    when(projects.databases).thenReturn(databases);

    final api = MockFirestoreApi();
    when(api.projects).thenReturn(projects);
    firestore = Firestore.fromApi(
      api,
      projectId: 'project-id',
      databaseId: 'database-id',
    );
  });

  test('should get a document by path', () async {
    final expected = g.Document();
    when(
      mockDocumentsResource.get(
        'projects/project-id/databases/database-id/tasks/task-name',
      ),
    ).thenAnswer((_) async => expected);

    await expectLater(
      firestore.getByPath('tasks/task-name'),
      completion(same(expected)),
    );
    await expectLater(
      firestore.tryGetByPath('tasks/task-name'),
      completion(same(expected)),
    );
  });

  test('should fail to get a document by path, returning null', () async {
    when(
      mockDocumentsResource.get(
        'projects/project-id/databases/database-id/tasks/task-name',
      ),
    ).thenAnswer(
      (_) async => throw g.DetailedApiRequestError(HttpStatus.notFound, ''),
    );

    await expectLater(
      firestore.tryGetByPath('tasks/task-name'),
      completion(isNull),
    );
  });

  test('should fail to get a document by path, throwing an error', () async {
    when(
      mockDocumentsResource.get(
        'projects/project-id/databases/database-id/tasks/task-name',
      ),
    ).thenAnswer((_) async => throw notFound);

    await expectLater(
      firestore.getByPath('tasks/task-name'),
      throwsA(
        isA<StateError>().having(
          (e) => e.message,
          'message',
          contains('No document found at "tasks/task-name"'),
        ),
      ),
    );
  });

  test('should insert a document by path, and ignore document.name', () async {
    final expected = g.Document(fields: {});
    final created = g.Document(fields: {}, name: 'Should be stripped');
    when(
      mockDocumentsResource.createDocument(
        any,
        any,
        any,
        documentId: anyNamed('documentId'),
      ),
    ).thenAnswer((i) async {
      expect(i.positionalArguments, [
        isA<g.Document>()
            .having((d) => d.name, 'name', isNull)
            .having((d) => d.fields, 'fields', expected.fields),
        'projects/project-id/databases/database-id/documents',
        'tasks',
      ], reason: '${expected.fields}');
      expect(i.namedArguments, containsPair(#documentId, 'new-task'));
      return expected;
    });

    await expectLater(
      firestore.insertByPath('tasks/new-task', created),
      completes,
    );
    await expectLater(
      firestore.tryInsertByPath('tasks/new-task', created),
      completes,
    );
  });

  test('should fail to insert a document by path, returning null', () async {
    when(
      mockDocumentsResource.createDocument(
        any,
        any,
        any,
        documentId: anyNamed('documentId'),
      ),
    ).thenAnswer((_) async => throw preExists);

    await expectLater(
      firestore.tryInsertByPath('tasks/new-task', g.Document()),
      completion(isNull),
    );
  });

  test('should fail to insert a document by path, throwing an error', () async {
    when(
      mockDocumentsResource.createDocument(
        any,
        any,
        any,
        documentId: anyNamed('documentId'),
      ),
    ).thenAnswer((_) async => throw preExists);

    await expectLater(
      firestore.insertByPath('tasks/new-task', g.Document()),
      throwsA(
        isA<StateError>().having(
          (e) => e.message,
          'message',
          contains('Existing document found at "tasks/new-task"'),
        ),
      ),
    );
  });

  const gRPC$OK = 0;
  const gRPC$AlreadyExists = 1;

  test('should insert multiple documents in batch', () async {
    when(mockDocumentsResource.batchWrite(any, any)).thenAnswer((i) async {
      expect(i.positionalArguments, [
        isA<g.BatchWriteRequest>().having((e) => e.writes, 'writes', [
          isA<g.Write>().having(
            (w) => w.update!.name,
            'update.name',
            'projects/project-id/databases/database-id/tasks/new-task-1',
          ),
          isA<g.Write>().having(
            (w) => w.update!.name,
            'update.name',
            'projects/project-id/databases/database-id/tasks/new-task-2',
          ),
          isA<g.Write>().having(
            (w) => w.update!.name,
            'update.name',
            'projects/project-id/databases/database-id/tasks/existing-task',
          ),
        ]),
        'projects/project-id/databases/database-id',
      ]);
      return g.BatchWriteResponse(
        status: [
          g.Status(code: gRPC$OK),
          g.Status(code: gRPC$OK),
          g.Status(code: gRPC$AlreadyExists),
        ],
      );
    });

    await expectLater(
      firestore.tryInsertAll({
        'tasks/new-task-1': g.Document(),
        'tasks/new-task-2': g.Document(),
        'tasks/existing-task': g.Document(),
      }),
      completion([
        true, //
        true, //
        false,
      ]),
    );
  });
}
