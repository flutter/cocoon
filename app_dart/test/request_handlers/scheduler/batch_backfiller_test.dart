// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_service/cocoon_service.dart';
import 'package:cocoon_service/src/model/appengine/commit.dart';
import 'package:cocoon_service/src/model/appengine/task.dart';
import 'package:test/test.dart';

import '../../src/datastore/fake_config.dart';
import '../../src/datastore/fake_datastore.dart';
import '../../src/request_handling/fake_pubsub.dart';
import '../../src/request_handling/request_handler_tester.dart';
import '../../src/service/fake_luci_build_service.dart';
import '../../src/service/fake_scheduler.dart';
import '../../src/utilities/entity_generators.dart';

final List<Commit> commits = <Commit>[
  generateCommit(3),
  generateCommit(2),
  generateCommit(1),
];

void main() {
  late BatchBackfiller handler;
  late RequestHandlerTester tester;
  late FakeDatastoreDB db;
  late FakePubSub pubsub;
  late FakeScheduler scheduler;

  group('BatchBackfiller', () {
    setUp(() async {
      db = FakeDatastoreDB()..addOnQuery<Commit>((Iterable<Commit> results) => commits);
      final Config config = FakeConfig(dbValue: db);
      pubsub = FakePubSub();
      scheduler = FakeScheduler(
        config: config,
        ciYaml: batchPolicyConfig,
        luciBuildService: FakeLuciBuildService(
          config,
          pubsub: pubsub,
        ),
      );
      handler = BatchBackfiller(
        config: config,
        scheduler: scheduler,
      );
      tester = RequestHandlerTester();
    });

    test('does not backfill on completed task column', () async {
      List<Task> allGreen = <Task>[
        generateTask(1, name: 'Linux_android A', status: Task.statusSucceeded),
        generateTask(2, name: 'Linux_android A', status: Task.statusSucceeded),
        generateTask(3, name: 'Linux_android A', status: Task.statusSucceeded),
      ];
      db.addOnQuery<Task>((Iterable<Task> results) => allGreen);
      await tester.get(handler);
      expect(pubsub.messages, isEmpty);
    });

    test('does not backfill when there is a running task', () async {
      List<Task> middleTaskInProgress = <Task>[
        generateTask(1, name: 'Linux_android A', status: Task.statusNew),
        generateTask(2, name: 'Linux_android A', status: Task.statusInProgress),
        generateTask(3, name: 'Linux_android A', status: Task.statusNew),
      ];
      db.addOnQuery<Task>((Iterable<Task> results) => middleTaskInProgress);
      await tester.get(handler);
      expect(pubsub.messages, isEmpty);
    });

    test('backfills latest task', () async {
      List<Task> allGray = <Task>[
        generateTask(1, name: 'Linux_android A', status: Task.statusNew),
        generateTask(2, name: 'Linux_android A', status: Task.statusNew),
        generateTask(3, name: 'Linux_android A', status: Task.statusNew),
      ];
      db.addOnQuery<Task>((Iterable<Task> results) => allGray);
      await tester.get(handler);
      expect(pubsub.messages.length, 1);
    });

    test('backfills older task', () async {
      List<Task> oldestGray = <Task>[
        generateTask(1, name: 'Linux_android A', status: Task.statusSucceeded),
        generateTask(2, name: 'Linux_android A', status: Task.statusSucceeded),
        generateTask(3, name: 'Linux_android A', status: Task.statusNew),
      ];
      db.addOnQuery<Task>((Iterable<Task> results) => oldestGray);
      await tester.get(handler);
      expect(pubsub.messages.length, 1);
    });

    test('updates task as in-progress after backfilling', () async {
      List<Task> oldestGray = <Task>[
        generateTask(1, name: 'Linux_android A', status: Task.statusSucceeded),
        generateTask(2, name: 'Linux_android A', status: Task.statusSucceeded),
        generateTask(3, name: 'Linux_android A', status: Task.statusNew),
      ];
      db.addOnQuery<Task>((Iterable<Task> results) => oldestGray);
      final Task task = oldestGray[2];
      expect(db.values.length, 0);
      expect(task.status, Task.statusNew);
      await tester.get(handler);
      expect(db.values.length, 1);
      expect(task.status, Task.statusInProgress);
    });

    test('backfills only column A when B does need backfill', () async {
      List<Task> scheduleA = <Task>[
        // Linux_android A
        generateTask(1, name: 'Linux_android A', status: Task.statusSucceeded),
        generateTask(2, name: 'Linux_android A', status: Task.statusSucceeded),
        generateTask(3, name: 'Linux_android A', status: Task.statusNew),
        // Linux_android B
        generateTask(1, name: 'Linux_android B', status: Task.statusSucceeded),
        generateTask(2, name: 'Linux_android B', status: Task.statusSucceeded),
        generateTask(3, name: 'Linux_android B', status: Task.statusSucceeded),
      ];
      db.addOnQuery<Task>((Iterable<Task> results) => scheduleA);
      await tester.get(handler);
      expect(pubsub.messages.length, 1);
    });

    test('backfills both column A and B', () async {
      List<Task> scheduleA = <Task>[
        // Linux_android A
        generateTask(1, name: 'Linux_android A', status: Task.statusSucceeded),
        generateTask(2, name: 'Linux_android A', status: Task.statusSucceeded),
        generateTask(3, name: 'Linux_android A', status: Task.statusNew),
        // Linux_android B
        generateTask(1, name: 'Linux_android B', status: Task.statusSucceeded),
        generateTask(2, name: 'Linux_android B', status: Task.statusSucceeded),
        generateTask(3, name: 'Linux_android B', status: Task.statusNew),
      ];
      db.addOnQuery<Task>((Iterable<Task> results) => scheduleA);
      await tester.get(handler);
      expect(pubsub.messages.length, 2);
    });
  });
}
