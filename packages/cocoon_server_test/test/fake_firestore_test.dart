// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:cocoon_server/firestore.dart';
import 'package:cocoon_server_test/fake_firestore.dart';
import 'package:googleapis/firestore/v1.dart' as g;
import 'package:test/test.dart';

void main() {
  late Firestore firestore;

  setUp(() {
    firestore = FakeFirestore(
      projectId: 'project-id',
      databaseId: 'database-id',
    );
  });

  test('can insert and then get an existing document', () async {
    final _ = await firestore.tryInsertByPath(
      'tasks/existing-task',
      g.Document(fields: {'gold_coins': g.Value(integerValue: '1001')}),
    );

    await expectLater(
      firestore.tryGetByPath('tasks/existing-task'),
      completion(
        isA<g.Document>().having(
          (d) => jsonDecode(jsonEncode(d.toJson()))['fields'],
          'toJson()',
          {
            'gold_coins': {'integerValue': '1001'},
          },
        ),
      ),
    );
  });

  test('upserts a document', () async {
    final task = await firestore.upsertByPath(
      'tasks/existing-task',
      g.Document(fields: {'gold_coins': g.Value(integerValue: '1001')}),
    );

    task.fields!['gold_coins'] = g.Value(integerValue: '2002');
    final _ = await firestore.upsertByPath('tasks/existing-task', task);

    await expectLater(
      firestore.tryGetByPath('tasks/existing-task'),
      completion(
        isA<g.Document>().having(
          (d) => jsonDecode(jsonEncode(d.toJson()))['fields'],
          'toJson()',
          {
            'gold_coins': {'integerValue': '2002'},
          },
        ),
      ),
    );
  });

  test('upserts multiple documents', () async {
    await expectLater(
      firestore.tryBatchWrite({
        'tasks/task-1': BatchWriteOperation.upsert(
          g.Document(fields: {'gold_coins': g.Value(integerValue: '1001')}),
        ),
        'tasks/task-2': BatchWriteOperation.upsert(
          g.Document(fields: {'gold_coins': g.Value(integerValue: '2002')}),
        ),
      }),
      completion([true, true]),
    );

    await expectLater(
      firestore.tryGetByPath('tasks/task-1'),
      completion(
        isA<g.Document>().having(
          (d) => jsonDecode(jsonEncode(d.toJson()))['fields'],
          'toJson()',
          {
            'gold_coins': {'integerValue': '1001'},
          },
        ),
      ),
    );

    await expectLater(
      firestore.tryGetByPath('tasks/task-2'),
      completion(
        isA<g.Document>().having(
          (d) => jsonDecode(jsonEncode(d.toJson()))['fields'],
          'toJson()',
          {
            'gold_coins': {'integerValue': '2002'},
          },
        ),
      ),
    );

    await expectLater(
      firestore.tryBatchWrite({
        'tasks/task-1': BatchWriteOperation.upsert(
          g.Document(fields: {'gold_coins': g.Value(integerValue: '3003')}),
        ),
        'tasks/task-2': BatchWriteOperation.upsert(
          g.Document(fields: {'gold_coins': g.Value(integerValue: '4004')}),
        ),
      }),
      completion([true, true]),
    );

    await expectLater(
      firestore.tryGetByPath('tasks/task-1'),
      completion(
        isA<g.Document>().having(
          (d) => jsonDecode(jsonEncode(d.toJson()))['fields'],
          'toJson()',
          {
            'gold_coins': {'integerValue': '3003'},
          },
        ),
      ),
    );

    await expectLater(
      firestore.tryGetByPath('tasks/task-2'),
      completion(
        isA<g.Document>().having(
          (d) => jsonDecode(jsonEncode(d.toJson()))['fields'],
          'toJson()',
          {
            'gold_coins': {'integerValue': '4004'},
          },
        ),
      ),
    );
  });

  test('inserts multiple documents successfully', () async {
    final result = await firestore.tryBatchWrite({
      'tasks/task-1': BatchWriteOperation.insert(
        g.Document(fields: {'gold_coins': g.Value(integerValue: '1')}),
      ),
      'tasks/task-2': BatchWriteOperation.insert(
        g.Document(fields: {'gold_coins': g.Value(integerValue: '2')}),
      ),
    });

    expect(result, [true, true]);

    await expectLater(
      firestore.tryGetByPath('tasks/task-1'),
      completion(
        isA<g.Document>().having(
          (d) => jsonDecode(jsonEncode(d.toJson()))['fields'],
          'toJson()',
          {
            'gold_coins': {'integerValue': '1'},
          },
        ),
      ),
    );
    await expectLater(
      firestore.tryGetByPath('tasks/task-2'),
      completion(
        isA<g.Document>().having(
          (d) => jsonDecode(jsonEncode(d.toJson()))['fields'],
          'toJson()',
          {
            'gold_coins': {'integerValue': '2'},
          },
        ),
      ),
    );
  });

  test('inserts multiple documents some already exist', () async {
    final _ = await firestore.tryInsertByPath(
      'tasks/existing-task',
      g.Document(fields: {'gold_coins': g.Value(integerValue: '1001')}),
    );

    final result = await firestore.tryBatchWrite({
      'tasks/existing-task': BatchWriteOperation.insert(
        g.Document(fields: {'gold_coins': g.Value(integerValue: '1')}),
      ),
      'tasks/new-task': BatchWriteOperation.insert(
        g.Document(fields: {'gold_coins': g.Value(integerValue: '2')}),
      ),
    });

    expect(result, [false, true]);

    await expectLater(
      firestore.tryGetByPath('tasks/existing-task'),
      completion(
        isA<g.Document>().having(
          (d) => jsonDecode(jsonEncode(d.toJson()))['fields'],
          'toJson()',
          {
            'gold_coins': {'integerValue': '1001'},
          },
        ),
      ),
    );
    await expectLater(
      firestore.tryGetByPath('tasks/new-task'),
      completion(
        isA<g.Document>().having(
          (d) => jsonDecode(jsonEncode(d.toJson()))['fields'],
          'toJson()',
          {
            'gold_coins': {'integerValue': '2'},
          },
        ),
      ),
    );
  });
}
