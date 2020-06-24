// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_service/src/model/appengine/commit.dart';
import 'package:cocoon_service/src/model/appengine/task.dart';
import 'package:cocoon_service/src/request_handlers/vacuum-clean.dart';
import 'package:cocoon_service/src/service/datastore.dart';
import 'package:gcloud/db.dart';
import 'package:test/test.dart';

import '../src/datastore/fake_cocoon_config.dart';
import '../src/datastore/fake_datastore.dart';
import '../src/request_handling/api_request_handler_tester.dart';
import '../src/request_handling/fake_authentication.dart';

void main() {
  group('VacuumClean', () {
    FakeConfig config;
    ApiRequestHandlerTester tester;
    VacuumClean handler;
    FakeDatastoreDB db;

    setUp(() {
      db = FakeDatastoreDB();
      config = FakeConfig(
          dbValue: db, commitNumberValue: 10, maxTaskRetriesValue: 2);
      tester = ApiRequestHandlerTester();
      handler = VacuumClean(
        config,
        FakeAuthenticationProvider(),
        datastoreProvider: (DatastoreDB db) => DatastoreService(config.db, 5),
      );
    });

    test('does not update task status when task started less than one hour ago',
        () async {
      final Commit commit =
          Commit(key: db.emptyKey.append(Commit, id: 'flutter/flutter/abc'));
      final Task task = Task(
          key: commit.key.append(Task, id: 123),
          commitKey: commit.key,
          attempts: 1,
          status: Task.statusInProgress,
          startTimestamp: DateTime.now().millisecondsSinceEpoch);
      db.values[commit.key] = commit;
      db.values[task.key] = task;

      expect(task.status, Task.statusInProgress);
      await tester.get(handler);
      expect(task.status, Task.statusInProgress);
    });

    test('updates task status to new when task started one hour ago', () async {
      final int now = DateTime.now().millisecondsSinceEpoch;
      const Duration twoHour = Duration(hours: 2);
      final Commit commit =
          Commit(key: db.emptyKey.append(Commit, id: 'flutter/flutter/abc'));
      final Task task = Task(
          key: commit.key.append(Task, id: 123),
          commitKey: commit.key,
          attempts: 1,
          status: Task.statusInProgress,
          startTimestamp: now - twoHour.inMilliseconds);
      db.values[commit.key] = commit;
      db.values[task.key] = task;

      expect(task.status, Task.statusInProgress);
      await tester.get(handler);
      expect(task.status, Task.statusNew);
    });

    test('updates task status to failed when task retries exceed limit',
        () async {
      final int now = DateTime.now().millisecondsSinceEpoch;
      const Duration twoHour = Duration(hours: 2);
      final Commit commit =
          Commit(key: db.emptyKey.append(Commit, id: 'flutter/flutter/abc'));
      final Task task = Task(
          key: commit.key.append(Task, id: 123),
          commitKey: commit.key,
          attempts: 3,
          status: Task.statusInProgress,
          startTimestamp: now - twoHour.inMilliseconds);
      db.values[commit.key] = commit;
      db.values[task.key] = task;

      expect(task.status, Task.statusInProgress);
      await tester.get(handler);
      expect(task.status, Task.statusFailed);
    });

    test('updates task status for non-master branch', () async {
      final int now = DateTime.now().millisecondsSinceEpoch;
      const Duration twoHour = Duration(hours: 2);
      final Commit commit = Commit(
          key: db.emptyKey.append(Commit, id: 'flutter/flutter/abc'),
          branch: 'nonMaster');
      final Task task = Task(
          key: commit.key.append(Task, id: 123),
          commitKey: commit.key,
          attempts: 3,
          status: Task.statusInProgress,
          startTimestamp: now - twoHour.inMilliseconds);
      db.values[commit.key] = commit;
      db.values[task.key] = task;

      expect(task.status, Task.statusInProgress);
      await tester.get(handler);
      expect(task.status, Task.statusFailed);
    });
  });
}
