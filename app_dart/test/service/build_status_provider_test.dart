// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_service/src/model/appengine/commit.dart';
import 'package:cocoon_service/src/model/appengine/task.dart';
import 'package:cocoon_service/src/service/build_status_provider.dart';
import 'package:cocoon_service/src/service/datastore.dart';
import 'package:gcloud/db.dart';
import 'package:test/test.dart';

import '../src/datastore/fake_cocoon_config.dart';
import '../src/datastore/fake_datastore.dart';

List<Commit> oneCommit = <Commit>[
  Commit(key: Key<String>.emptyKey(Partition('ns')).append(Commit, id: 'sha1'), sha: 'sha1'),
];

List<Commit> twoCommits = <Commit>[
  Commit(key: Key<String>.emptyKey(Partition('ns')).append(Commit, id: 'sha1'), sha: 'sha1'),
  Commit(key: Key<String>.emptyKey(Partition('ns')).append(Commit, id: 'sha2'), sha: 'sha2'),
];

List<Task> allGreen = <Task>[
  Task(stageName: 'stage1', name: 'task1', status: Task.statusSucceeded),
  Task(stageName: 'stage2', name: 'task2', status: Task.statusSucceeded),
  Task(stageName: 'stage2', name: 'task3', status: Task.statusSucceeded),
];

List<Task> allRed = <Task>[
  Task(stageName: 'stage1', name: 'task1', status: Task.statusFailed),
  Task(stageName: 'stage2', name: 'task2', status: Task.statusFailed),
  Task(stageName: 'stage2', name: 'task3', status: Task.statusFailed),
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

List<Task> middleTaskRerunning = <Task>[
  Task(stageName: 'stage1', name: 'task1', status: Task.statusSucceeded),
  Task(stageName: 'stage2', name: 'task2', status: Task.statusNew, attempts: 2),
  Task(stageName: 'stage2', name: 'task3', status: Task.statusSucceeded),
];

List<Task> middleTaskRerunGreen = <Task>[
  Task(stageName: 'stage1', name: 'task1', status: Task.statusSucceeded),
  Task(stageName: 'stage2', name: 'task2', status: Task.statusSucceeded, attempts: 2),
  Task(stageName: 'stage2', name: 'task3', status: Task.statusSucceeded),
];

List<Task> middleTaskInfraFailure = <Task>[
  Task(stageName: 'stage1', name: 'task1', status: Task.statusSucceeded),
  Task(stageName: 'stage2', name: 'task2', status: Task.statusInfraFailure),
  Task(stageName: 'stage2', name: 'task3', status: Task.statusSucceeded),
];

void main() {
  group('BuildStatusProvider', () {
    FakeDatastoreDB db;
    BuildStatusService buildStatusService;
    FakeConfig config;
    DatastoreService datastoreService;

    setUp(() {
      db = FakeDatastoreDB();
      config = FakeConfig(dbValue: db);
      datastoreService = DatastoreService(config.db, 5);
      buildStatusService = BuildStatusService.defaultProvider(datastoreService);
    });

    group('calculateStatus', () {
      test('returns failure if there are no commits', () async {
        final BuildStatus status = await buildStatusService.calculateCumulativeStatus();
        expect(status, BuildStatus.failure(const <String>[]));
      });

      test('returns success if top commit is all green', () async {
        db.addOnQuery<Commit>((Iterable<Commit> results) => oneCommit);
        db.addOnQuery<Task>((Iterable<Task> results) => allGreen);
        final BuildStatus status = await buildStatusService.calculateCumulativeStatus();
        expect(status, BuildStatus.success());
      });

      test('returns success if top commit is all green followed by red commit', () async {
        db.addOnQuery<Commit>((Iterable<Commit> results) => twoCommits);
        int row = 0;
        db.addOnQuery<Task>((Iterable<Task> results) {
          return row++ == 0 ? allGreen : middleTaskFailed;
        });
        final BuildStatus status = await buildStatusService.calculateCumulativeStatus();
        expect(status, BuildStatus.success());
      });

      test('returns failure if last commit contains any red tasks', () async {
        db.addOnQuery<Commit>((Iterable<Commit> results) => oneCommit);
        db.addOnQuery<Task>((Iterable<Task> results) => middleTaskFailed);
        final BuildStatus status = await buildStatusService.calculateCumulativeStatus();
        expect(status, BuildStatus.failure(const <String>['task2']));
      });

      test('ignores failures on flaky commits', () async {
        db.addOnQuery<Commit>((Iterable<Commit> results) => oneCommit);
        db.addOnQuery<Task>((Iterable<Task> results) => middleTaskFlakyFailed);
        final BuildStatus status = await buildStatusService.calculateCumulativeStatus();
        expect(status, BuildStatus.success());
      });

      test('returns success if partial green, and all unfinished tasks were last green', () async {
        db.addOnQuery<Commit>((Iterable<Commit> results) => twoCommits);
        int row = 0;
        db.addOnQuery<Task>((Iterable<Task> results) {
          return row++ == 0 ? middleTaskInProgress : allGreen;
        });
        final BuildStatus status = await buildStatusService.calculateCumulativeStatus();
        expect(status, BuildStatus.success());
      });

      test('returns failure if partial green, and any unfinished task was last red', () async {
        db.addOnQuery<Commit>((Iterable<Commit> results) => twoCommits);
        int row = 0;
        db.addOnQuery<Task>((Iterable<Task> results) {
          return row++ == 0 ? middleTaskInProgress : middleTaskFailed;
        });
        final BuildStatus status = await buildStatusService.calculateCumulativeStatus();
        expect(status, BuildStatus.failure(const <String>['task2']));
      });

      test('returns failure when green but a task is rerunning', () async {
        db.addOnQuery<Commit>((Iterable<Commit> results) => twoCommits);
        int row = 0;
        db.addOnQuery<Task>((Iterable<Task> results) {
          return row++ == 0 ? middleTaskRerunning : allGreen;
        });
        final BuildStatus status = await buildStatusService.calculateCumulativeStatus();
        expect(status, BuildStatus.failure(const <String>['task2']));
      });

      test('returns failure when a task has an infra failure', () async {
        db.addOnQuery<Commit>((Iterable<Commit> results) => twoCommits);
        int row = 0;
        db.addOnQuery<Task>((Iterable<Task> results) {
          return row++ == 0 ? middleTaskInfraFailure : allGreen;
        });
        final BuildStatus status = await buildStatusService.calculateCumulativeStatus();
        expect(status, BuildStatus.failure(const <String>['task2']));
      });

      test('returns success when all green with a successful rerun', () async {
        db.addOnQuery<Commit>((Iterable<Commit> results) => twoCommits);
        int row = 0;
        db.addOnQuery<Task>((Iterable<Task> results) {
          return row++ == 0 ? middleTaskRerunGreen : allRed;
        });
        final BuildStatus status = await buildStatusService.calculateCumulativeStatus();
        expect(status, BuildStatus.success());
      });

      test('return status when with branch parameter', () async {
        final Commit commit1 = Commit(
            key: Key<String>.emptyKey(Partition('ns')).append(Commit, id: 'sha1'),
            sha: 'sha1',
            branch: 'flutter-0.0-candidate.0');
        final Commit commit2 = Commit(
            key: Key<String>.emptyKey(Partition('ns')).append(Commit, id: 'sha2'), sha: 'sha2', branch: 'master');

        db.values[commit1.key] = commit1;
        db.values[commit2.key] = commit2;

        final Task task1 = Task(
            key: commit1.key.append(Task, id: 1),
            commitKey: commit1.key,
            name: 'task1',
            status: Task.statusSucceeded,
            stageName: 'stage1');

        db.values[task1.key] = task1;

        // Test master branch.
        final List<CommitStatus> statuses1 = await buildStatusService.retrieveCommitStatus(limit: 5).toList();
        expect(statuses1.length, 1);
        expect(statuses1.first.commit.branch, 'master');

        // Test dev branch.
        final List<CommitStatus> statuses2 =
            await buildStatusService.retrieveCommitStatus(limit: 5, branch: 'flutter-0.0-candidate.0').toList();
        expect(statuses2.length, 1);
        expect(statuses2.first.commit.branch, 'flutter-0.0-candidate.0');
      });
    });
  });
}
