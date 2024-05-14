// Copyright 2021 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_service/src/model/appengine/task.dart';
import 'package:cocoon_service/src/service/datastore.dart';
import 'package:cocoon_service/src/service/luci_build_service.dart';
import 'package:cocoon_service/src/service/scheduler/policy.dart';
import 'package:test/test.dart';

import '../../src/datastore/fake_datastore.dart';
import '../../src/utilities/entity_generators.dart';

void main() {
  group('BatchPolicy', () {
    late FakeDatastoreDB db;
    late DatastoreService datastore;

    final BatchPolicy policy = BatchPolicy();

    setUp(() {
      db = FakeDatastoreDB();
      datastore = DatastoreService(db, 5);
    });

    final List<Task> allPending = <Task>[
      generateTask(3),
      generateTask(2),
      generateTask(1),
    ];

    final List<Task> latestAllPending = <Task>[
      generateTask(6),
      generateTask(5),
      generateTask(4),
      generateTask(3),
      generateTask(2),
      generateTask(1, status: Task.statusSucceeded),
    ];

    final List<Task> latestFinishedButRestPending = <Task>[
      generateTask(6, status: Task.statusSucceeded),
      generateTask(5),
      generateTask(4),
      generateTask(3),
      generateTask(2),
      generateTask(1),
    ];

    final List<Task> latestFailed = <Task>[
      generateTask(6, status: Task.statusFailed),
      generateTask(5),
      generateTask(4),
      generateTask(3),
      generateTask(2),
      generateTask(1),
    ];

    final List<Task> latestPending = <Task>[
      generateTask(6),
      generateTask(5),
      generateTask(4),
      generateTask(3),
      generateTask(2, status: Task.statusSucceeded),
      generateTask(1, status: Task.statusSucceeded),
    ];

    final List<Task> failedWithRunning = <Task>[
      generateTask(6),
      generateTask(5),
      generateTask(4),
      generateTask(3, status: Task.statusFailed),
      generateTask(2, status: Task.statusInProgress),
      generateTask(1),
    ];

    test('triggers if less tasks than batch size', () async {
      db.addOnQuery<Task>((Iterable<Task> results) => allPending);
      expect(
        await policy.triggerPriority(task: generateTask(4), datastore: datastore),
        null,
      );
    });

    test('triggers after batch size', () async {
      db.addOnQuery<Task>((Iterable<Task> results) => latestAllPending);
      expect(
        await policy.triggerPriority(task: generateTask(7), datastore: datastore),
        LuciBuildService.kDefaultPriority,
      );
    });

    test('triggers with higher priority on recent failures', () async {
      db.addOnQuery<Task>((Iterable<Task> results) => latestFailed);
      expect(
        await policy.triggerPriority(task: generateTask(7), datastore: datastore),
        LuciBuildService.kRerunPriority,
      );
    });

    test('does not trigger on recent failures if there is already a running task', () async {
      db.addOnQuery<Task>((Iterable<Task> results) => failedWithRunning);
      expect(
        await policy.triggerPriority(task: generateTask(7), datastore: datastore),
        isNull,
      );
    });

    test('does not trigger when a test was recently scheduled', () async {
      db.addOnQuery<Task>((Iterable<Task> results) => latestFinishedButRestPending);
      expect(await policy.triggerPriority(task: generateTask(7), datastore: datastore), isNull);
    });

    test('does not trigger when pending queue is smaller than batch', () async {
      db.addOnQuery<Task>((Iterable<Task> results) => latestPending);
      expect(await policy.triggerPriority(task: generateTask(7), datastore: datastore), isNull);
    });

    test('do not return rerun priority when tasks length is smaller than batch size', () {
      expect(shouldRerunPriority(allPending, 5), false);
    });
  });

  group('GuaranteedPolicy', () {
    late FakeDatastoreDB db;
    late DatastoreService datastore;

    final GuaranteedPolicy policy = GuaranteedPolicy();

    setUp(() {
      db = FakeDatastoreDB();
      datastore = DatastoreService(db, 5);
    });

    final List<Task> pending = <Task>[
      generateTask(1),
    ];

    final List<Task> latestFailed = <Task>[generateTask(1, status: Task.statusFailed)];

    test('triggers every task', () async {
      db.addOnQuery<Task>((Iterable<Task> results) => pending);
      expect(
        await policy.triggerPriority(task: generateTask(2), datastore: datastore),
        LuciBuildService.kDefaultPriority,
      );
    });

    test('triggers with higher priority on recent failure', () async {
      db.addOnQuery<Task>((Iterable<Task> results) => latestFailed);
      expect(
        await policy.triggerPriority(task: generateTask(2), datastore: datastore),
        LuciBuildService.kRerunPriority,
      );
    });
  });
}
