// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_service/src/model/appengine/commit.dart';
import 'package:cocoon_service/src/model/appengine/task.dart';
import 'package:cocoon_service/src/service/build_status_provider.dart';
import 'package:cocoon_service/src/service/datastore.dart';
import 'package:gcloud/db.dart';
import 'package:test/test.dart';

import '../src/datastore/fake_datastore.dart';

List<Commit> oneCommit = <Commit>[
  Commit(key: Key.emptyKey(Partition('ns')).append(Commit, id: 'sha1'), sha: 'sha1'),
];

List<Commit> twoCommits = <Commit>[
  Commit(key: Key.emptyKey(Partition('ns')).append(Commit, id: 'sha1'), sha: 'sha1'),
  Commit(key: Key.emptyKey(Partition('ns')).append(Commit, id: 'sha2'), sha: 'sha2'),
];

List<Task> allGreen = <Task>[
  Task(stageName: 'stage1', name: 'task1', status: Task.statusSucceeded),
  Task(stageName: 'stage2', name: 'task2', status: Task.statusSucceeded),
  Task(stageName: 'stage2', name: 'task3', status: Task.statusSucceeded),
];

List<Task> middleTaskFailed = <Task>[
  Task(stageName: 'stage1', name: 'task1', status: Task.statusSucceeded),
  Task(stageName: 'stage2', name: 'task2', status: Task.statusFailed),
  Task(stageName: 'stage2', name: 'task3', status: Task.statusSucceeded),
];

List<Task> middleTaskFlakyFailed = <Task>[
  Task(stageName: 'stage1', name: 'task1', status: Task.statusSucceeded),
  Task(stageName: 'stage2', name: 'task2', isFlaky: true, status: Task.statusFailed),
  Task(stageName: 'stage2', name: 'task3', status: Task.statusSucceeded),
];

List<Task> middleTaskInProgress = <Task>[
  Task(stageName: 'stage1', name: 'task1', status: Task.statusSucceeded),
  Task(stageName: 'stage2', name: 'task2', status: Task.statusInProgress),
  Task(stageName: 'stage2', name: 'task3', status: Task.statusSucceeded),
];

void main() {
  group('BuildStatusProvider', () {
    FakeDatastoreDB db;
    BuildStatusProvider buildStatusProvider;

    setUp(() {
      db = FakeDatastoreDB();
      buildStatusProvider = BuildStatusProvider(datastoreProvider: () => DatastoreService(db: db));
    });

    group('calculateStatus', () {
      test('returns failure if there are no commits', () async {
        final BuildStatus status = await buildStatusProvider.calculateCumulativeStatus();
        expect(status, BuildStatus.failed);
      });

      test('returns success if top commit is all green', () async {
        db.addOnQuery<Commit>((Iterable<Commit> results) => oneCommit);
        db.addOnQuery<Task>((Iterable<Task> results) => allGreen);
        final BuildStatus status = await buildStatusProvider.calculateCumulativeStatus();
        expect(status, BuildStatus.succeeded);
      });

      test('returns success if top commit is all green followed by red commit', () async {
        db.addOnQuery<Commit>((Iterable<Commit> results) => twoCommits);
        int row = 0;
        db.addOnQuery<Task>((Iterable<Task> results) {
          return row++ == 0 ? allGreen : middleTaskFailed;
        });
        final BuildStatus status = await buildStatusProvider.calculateCumulativeStatus();
        expect(status, BuildStatus.succeeded);
      });

      test('returns failure if last commit contains any red tasks', () async {
        db.addOnQuery<Commit>((Iterable<Commit> results) => oneCommit);
        db.addOnQuery<Task>((Iterable<Task> results) => middleTaskFailed);
        final BuildStatus status = await buildStatusProvider.calculateCumulativeStatus();
        expect(status, BuildStatus.failed);
      });

      test('ignores failures on flaky commits', () async {
        db.addOnQuery<Commit>((Iterable<Commit> results) => oneCommit);
        db.addOnQuery<Task>((Iterable<Task> results) => middleTaskFlakyFailed);
        final BuildStatus status = await buildStatusProvider.calculateCumulativeStatus();
        expect(status, BuildStatus.succeeded);
      });

      test('returns success if partial green, and all unfinished tasks were last green', () async {
        db.addOnQuery<Commit>((Iterable<Commit> results) => twoCommits);
        int row = 0;
        db.addOnQuery<Task>((Iterable<Task> results) {
          return row++ == 0 ? middleTaskInProgress : allGreen;
        });
        final BuildStatus status = await buildStatusProvider.calculateCumulativeStatus();
        expect(status, BuildStatus.succeeded);
      });

      test('returns failure if partial green, and any unfinished task was last red', () async {
        db.addOnQuery<Commit>((Iterable<Commit> results) => twoCommits);
        int row = 0;
        db.addOnQuery<Task>((Iterable<Task> results) {
          return row++ == 0 ? middleTaskInProgress : middleTaskFailed;
        });
        final BuildStatus status = await buildStatusProvider.calculateCumulativeStatus();
        expect(status, BuildStatus.failed);
      });
    });
  });
}
