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

  test('inserts multiple documents successfully', () async {
    final result = await firestore.tryInsertAll({
      'tasks/task-1': g.Document(
        fields: {'gold_coins': g.Value(integerValue: '1')},
      ),
      'tasks/task-2': g.Document(
        fields: {'gold_coins': g.Value(integerValue: '2')},
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

    final result = await firestore.tryInsertAll({
      'tasks/existing-task': g.Document(
        fields: {'gold_coins': g.Value(integerValue: '1')},
      ),
      'tasks/new-task': g.Document(
        fields: {'gold_coins': g.Value(integerValue: '2')},
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
