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

  test('should insert a document by path', () async {
    final expected = g.Document();
    final created = g.Document();
    when(
      mockDocumentsResource.createDocument(
        any,
        any,
        any,
        documentId: anyNamed('documentId'),
      ),
    ).thenAnswer((i) async {
      expect(i.positionalArguments, [
        created,
        'projects/project-id/databases/database-id/documents',
        'tasks',
      ]);
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

  test('should upsert a document by path', () async {
    final expected = g.Document();
    final created = g.Document();
    when(mockDocumentsResource.patch(any, any)).thenAnswer((i) async {
      expect(i.positionalArguments, [
        expected,
        'projects/project-id/databases/database-id/documents/tasks/new-or-existing-task',
      ]);
      return created;
    });

    await expectLater(
      firestore.upsertByPath('tasks/new-or-existing-task', expected),
      completion(same(created)),
    );
  });

  test('should fail to upsert a document by path, throwing an error', () async {
    final expected = Error();

    when(mockDocumentsResource.patch(any, any)).thenAnswer((i) async {
      // Any error will do (it will be rethrown).
      throw expected;
    });
    await expectLater(
      firestore.upsertByPath('tasks/new-or-existing-task', g.Document()),
      throwsA(same(expected)),
    );
  });

  test('should update a document by path', () async {
    final expected = g.Document();
    final created = g.Document();
    when(mockDocumentsResource.patch(any, any)).thenAnswer((i) async {
      expect(i.positionalArguments, [
        same(created),
        'projects/project-id/databases/database-id/documents/tasks/existing-task',
      ]);
      return expected;
    });

    await expectLater(
      firestore.updateByPath('tasks/existing-task', created),
      completes,
    );
    await expectLater(
      firestore.tryUpdateByPath('tasks/existing-task', created),
      completes,
    );
  });

  test('should fail to update a document by path, returning null', () async {
    final created = g.Document();
    when(mockDocumentsResource.patch(any, any)).thenAnswer((i) async {
      throw notFound;
    });

    await expectLater(
      firestore.tryUpdateByPath('tasks/existing-task', created),
      completion(isNull),
    );
  });

  test('should fail to update a document by path, throwing an error', () async {
    final created = g.Document();
    when(mockDocumentsResource.patch(any, any)).thenAnswer((i) async {
      throw notFound;
    });

    await expectLater(
      firestore.updateByPath('tasks/existing-task', created),
      throwsA(
        isA<StateError>().having(
          (e) => e.message,
          'message',
          contains('No document found at "tasks/existing-task"'),
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
          isA<g.Write>()
              .having(
                (w) => w.update!.name,
                'update.name',
                'projects/project-id/databases/database-id/tasks/new-task-1',
              )
              .having(
                (w) => w.currentDocument?.exists,
                'currentDocument.exists',
                isFalse,
              ),
          isA<g.Write>()
              .having(
                (w) => w.update!.name,
                'update.name',
                'projects/project-id/databases/database-id/tasks/new-task-2',
              )
              .having(
                (w) => w.currentDocument?.exists,
                'currentDocument.exists',
                isFalse,
              ),
          isA<g.Write>()
              .having(
                (w) => w.update!.name,
                'update.name',
                'projects/project-id/databases/database-id/tasks/existing-task',
              )
              .having(
                (w) => w.currentDocument?.exists,
                'currentDocument.exists',
                isFalse,
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

  test('should upsert multiple documents in batch', () async {
    when(mockDocumentsResource.batchWrite(any, any)).thenAnswer((i) async {
      expect(i.positionalArguments, [
        isA<g.BatchWriteRequest>().having((e) => e.writes, 'writes', [
          isA<g.Write>()
              .having(
                (w) => w.update!.name,
                'update.name',
                'projects/project-id/databases/database-id/tasks/new-task-1',
              )
              .having(
                (w) => w.currentDocument?.exists,
                'currentDocument.exists',
                isNull,
              ),
          isA<g.Write>()
              .having(
                (w) => w.update!.name,
                'update.name',
                'projects/project-id/databases/database-id/tasks/new-task-2',
              )
              .having(
                (w) => w.currentDocument?.exists,
                'currentDocument.exists',
                isNull,
              ),
          isA<g.Write>()
              .having(
                (w) => w.update!.name,
                'update.name',
                'projects/project-id/databases/database-id/tasks/existing-task',
              )
              .having(
                (w) => w.currentDocument?.exists,
                'currentDocument.exists',
                isNull,
              ),
        ]),
        'projects/project-id/databases/database-id',
      ]);
      return g.BatchWriteResponse(
        status: [
          g.Status(code: gRPC$OK),
          g.Status(code: gRPC$OK),
          g.Status(code: gRPC$OK),
        ],
      );
    });

    await expectLater(
      firestore.tryUpsertAll({
        'tasks/new-task-1': g.Document(),
        'tasks/new-task-2': g.Document(),
        'tasks/existing-task': g.Document(),
      }),
      completion([
        true, //
        true, //
        true,
      ]),
    );
  });

  test('should update multiple documents in batch', () async {
    when(mockDocumentsResource.batchWrite(any, any)).thenAnswer((i) async {
      expect(i.positionalArguments, [
        isA<g.BatchWriteRequest>().having((e) => e.writes, 'writes', [
          isA<g.Write>()
              .having(
                (w) => w.update!.name,
                'update.name',
                'projects/project-id/databases/database-id/tasks/existing-task-1',
              )
              .having(
                (w) => w.currentDocument?.exists,
                'currentDocument.exists',
                isTrue,
              ),
          isA<g.Write>()
              .having(
                (w) => w.update!.name,
                'update.name',
                'projects/project-id/databases/database-id/tasks/existing-task-2',
              )
              .having(
                (w) => w.currentDocument?.exists,
                'currentDocument.exists',
                isTrue,
              ),
          isA<g.Write>()
              .having(
                (w) => w.update!.name,
                'update.name',
                'projects/project-id/databases/database-id/tasks/existing-task-3',
              )
              .having(
                (w) => w.currentDocument?.exists,
                'currentDocument.exists',
                isTrue,
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
      firestore.tryUpdateAll({
        'tasks/existing-task-1': g.Document(),
        'tasks/existing-task-2': g.Document(),
        'tasks/existing-task-3': g.Document(),
      }),
      completion([
        true, //
        true, //
        false,
      ]),
    );
  });
}
