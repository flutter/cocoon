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

    final List<Task> latestFinishedButRestPending = <Task>[
      generateTask(3, status: Task.statusSucceeded),
      generateTask(2),
      generateTask(1),
    ];

    final List<Task> latestFailed = <Task>[
      generateTask(3, status: Task.statusFailed),
      generateTask(2),
      generateTask(1),
    ];

    test('triggers after batch size', () async {
      db.addOnQuery<Task>((Iterable<Task> results) => allPending);
      expect(
          await policy.triggerPriority(task: generateTask(4), datastore: datastore), LuciBuildService.kDefaultPriority);
    });

    test('triggers with higher priority on recent failures', () async {
      db.addOnQuery<Task>((Iterable<Task> results) => latestFailed);
      expect(
          await policy.triggerPriority(task: generateTask(4), datastore: datastore), LuciBuildService.kRerunPriority);
    });

    test('does not trigger when a test was recently scheduled', () async {
      db.addOnQuery<Task>((Iterable<Task> results) => latestFinishedButRestPending);
      expect(await policy.triggerPriority(task: generateTask(4), datastore: datastore), isNull);
    });
  });
}
