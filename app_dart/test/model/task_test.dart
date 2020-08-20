// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_service/src/model/appengine/task.dart';
import 'package:gcloud/db.dart';
import 'package:test/test.dart';

void main() {
  group('Task', () {
    test('byAttempts comparator', () {
      final List<Task> tasks = <Task>[Task(attempts: 5), Task(attempts: 9), Task(attempts: 3)];
      tasks.sort(Task.byAttempts);
      expect(tasks.map<int>((Task task) => task.attempts), <int>[3, 5, 9]);
    });

    test('disallows illegal status', () {
      expect(() => Task(status: 'unknown'), throwsArgumentError);
      expect(() => Task()..status = 'unknown', throwsArgumentError);
    });

    test('creates a valid chromebot task', () {
      final DatastoreDB db = DatastoreDB(null);
      final Key key = db.emptyKey.append(Task, id: 42);
      final Task t = Task.chromebot(key, 123, 'taskName', false);
      validateModel(t);
    });

    test('disallows flaky be null', () {
      expect(() => Task.chromebot(null, 123, 'taskName', null), throwsA(isA<AssertionError>()));
    });
  });
}

void validateModel(Task task) {
  // Throws an exception when property validation fails.
  ModelDBImpl().toDatastoreEntity(task);
}
