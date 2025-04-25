// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_server_test/test_logging.dart';
import 'package:cocoon_service/src/service/firestore.dart';
import 'package:cocoon_service/src/service/firestore/commit_and_tasks.dart';
import 'package:googleapis/firestore/v1.dart';
import 'package:test/test.dart';

import '../src/service/fake_firestore_service.dart';
import '../src/utilities/entity_generators.dart';

void main() {
  useTestLoggerPerTest();

  test('creates writes correctly from documents', () async {
    final documents = <Document>[
      Document(name: 'd1', fields: <String, Value>{'key1': 'value1'.toValue()}),
      Document(name: 'd2', fields: <String, Value>{'key1': 'value2'.toValue()}),
    ];
    final writes = documentsToWrites(documents, exists: false);
    expect(writes.length, documents.length);
    expect(writes[0].update, documents[0]);
    expect(writes[0].currentDocument!.exists, false);
  });

  group('CommitAndTasks', () {
    test('withMostRecentTaskOnly returns the largest currentAttempt', () {
      final commit = CommitAndTasks(generateFirestoreCommit(1), [
        generateFirestoreTask(1, name: 'Linux A', attempts: 2),
        generateFirestoreTask(1, name: 'Linux A', attempts: 1),
        generateFirestoreTask(1, name: 'Linux A', attempts: 3),
      ]);
      final recent = commit.withMostRecentTaskOnly();
      expect(recent.tasks, [
        isTask.hasTaskName('Linux A').hasCurrentAttempt(3),
      ]);
    });
  });
}
