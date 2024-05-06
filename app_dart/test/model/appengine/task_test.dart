// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_service/src/model/appengine/commit.dart';
import 'package:cocoon_service/src/model/appengine/task.dart';
import 'package:cocoon_service/src/model/luci/push_message.dart' as pm;
import 'package:cocoon_service/src/request_handling/exceptions.dart';
import 'package:cocoon_service/src/service/datastore.dart';
import 'package:fixnum/fixnum.dart';
import 'package:gcloud/db.dart';
import 'package:test/test.dart';

import 'package:buildbucket/buildbucket_pb.dart' as bbv2;

import '../../src/datastore/fake_config.dart';
import '../../src/utilities/entity_generators.dart';

void main() {
  group('Task', () {
    test('byAttempts comparator', () {
      final List<Task> tasks = <Task>[
        generateTask(1, attempts: 5),
        generateTask(2, attempts: 9),
        generateTask(3, attempts: 3),
      ];
      tasks.sort(Task.byAttempts);
      expect(tasks.map<int>((Task task) => task.attempts!), <int>[3, 5, 9]);
    });

    test('disallows illegal status', () {
      expect(() => generateTask(1, status: 'unknown'), throwsArgumentError);
      expect(() => generateTask(1)..status = 'unknown', throwsArgumentError);
    });

    group('updateFromBuild', () {
      test('updates if buildNumber is null', () {
        final DateTime created = DateTime.utc(2022, 1, 11, 1, 1);
        final DateTime started = DateTime.utc(2022, 1, 11, 1, 2);
        final DateTime completed = DateTime.utc(2022, 1, 11, 1, 3);
        final pm.Build build = generatePushMessageBuild(
          1,
          createdTimestamp: created,
          startedTimestamp: started,
          completedTimestamp: completed,
        );
        final Task task = generateTask(1);

        expect(task.status, Task.statusNew);
        expect(task.buildNumberList, isNull);
        expect(task.buildNumber, isNull);
        expect(task.endTimestamp, 0);
        expect(task.createTimestamp, 0);
        expect(task.startTimestamp, 0);

        task.updateFromBuild(build);

        expect(task.status, Task.statusSucceeded);
        expect(task.buildNumber, 1);
        expect(task.buildNumberList, '1');
        expect(task.createTimestamp, created.millisecondsSinceEpoch);
        expect(task.startTimestamp, started.millisecondsSinceEpoch);
        expect(task.endTimestamp, completed.millisecondsSinceEpoch);
      });

      test('defaults timestamps to 0', () {
        final pm.Build build = generatePushMessageBuild(1);
        final Task task = generateTask(1);

        expect(task.endTimestamp, 0);
        expect(task.createTimestamp, 0);
        expect(task.startTimestamp, 0);

        task.updateFromBuild(build);

        expect(task.endTimestamp, 0);
        expect(task.createTimestamp, 0);
        expect(task.startTimestamp, 0);
      });

      test('updates if buildNumber is prior to pushMessage', () {
        final pm.Build build = generatePushMessageBuild(
          1,
          buildNumber: 2,
          status: pm.Status.completed,
          result: pm.Result.success,
        );
        final Task task = generateTask(
          1,
          buildNumber: 1,
          status: Task.statusInProgress,
        );

        expect(task.buildNumberList, '1');
        expect(task.status, Task.statusInProgress);

        task.updateFromBuild(build);

        expect(task.buildNumber, 2);
        expect(task.buildNumberList, '1,2');
        expect(task.status, Task.statusSucceeded);
      });

      test('does not duplicate build numbers on multiple messages', () {
        final pm.Build build = generatePushMessageBuild(
          1,
          status: pm.Status.started,
        );
        final Task task = generateTask(
          1,
          buildNumber: 1,
          status: Task.statusSucceeded,
        );

        expect(task.buildNumber, 1);
        expect(task.buildNumberList, '1');
        expect(task.status, Task.statusSucceeded);

        task.updateFromBuild(build);

        expect(task.buildNumber, 1);
        expect(task.buildNumberList, '1');
        expect(task.status, Task.statusSucceeded);
      });

      test('does not update status if older status', () {
        final pm.Build build = generatePushMessageBuild(
          1,
          status: pm.Status.started,
        );
        final Task task = generateTask(
          1,
          buildNumber: 1,
          status: Task.statusSucceeded,
        );

        expect(task.buildNumber, 1);
        expect(task.status, Task.statusSucceeded);

        task.updateFromBuild(build);

        expect(task.buildNumber, 1);
        expect(task.status, Task.statusSucceeded);
      });

      test('does not update if build is older than task', () {
        final pm.Build build = generatePushMessageBuild(
          1,
          status: pm.Status.completed,
          result: pm.Result.success,
        );
        final Task task = generateTask(
          1,
          buildNumber: 2,
          status: Task.statusNew,
        );

        expect(task.buildNumber, 2);
        expect(task.status, Task.statusNew);

        task.updateFromBuild(build);

        expect(task.buildNumber, 2);
        expect(task.status, Task.statusNew);
      });

      test('handles cancelled build', () {
        final pm.Build build = generatePushMessageBuild(
          1,
          status: pm.Status.completed,
          result: pm.Result.canceled,
        );
        final Task task = generateTask(
          1,
          buildNumber: 1,
          status: Task.statusNew,
        );

        expect(task.status, Task.statusNew);
        task.updateFromBuild(build);
        expect(task.status, Task.statusCancelled);
      });

      test('handles infra failed build', () {
        final pm.Build build = generatePushMessageBuild(
          1,
          status: pm.Status.completed,
          result: pm.Result.failure,
          failureReason: pm.FailureReason.infraFailure,
        );
        final Task task = generateTask(
          1,
          buildNumber: 1,
          status: Task.statusNew,
        );

        expect(task.status, Task.statusNew);
        task.updateFromBuild(build);
        expect(task.status, Task.statusInfraFailure);
      });
    });
  });

  group('buildBucketV2Build', () {
    final DateTime startTimeDateTime = DateTime(2023, 1, 1, 0, 0, 0);
    final bbv2.Timestamp startTimestamp = bbv2.Timestamp.fromDateTime(startTimeDateTime);

    final DateTime endTimeDateTime = DateTime(2023, 1, 1, 0, 14, 23);
    final bbv2.Timestamp endTimestamp = bbv2.Timestamp.fromDateTime(endTimeDateTime);

    late FakeConfig config;
    late Commit commit;
    late Task expectedTask;

    setUp(() {
      config = FakeConfig();
      commit = generateCommit(12341234);
      expectedTask = generateTask(1, parent: commit);
      config.db.values[commit.key] = commit;
      config.db.values[expectedTask.key] = expectedTask;
    });

    test('fromBuildBucketV2Build', () async {
      final bbv2.Build fakeBuild = bbv2.Build(
        builder: bbv2.BuilderID(project: 'flutter', bucket: 'good-bucket', builder: 'great-builder'),
        number: 12345,
        id: Int64(1234567890),
        status: bbv2.Status.SUCCESS,
        startTime: startTimestamp,
        createTime: startTimestamp,
        endTime: endTimestamp,
        input: bbv2.Build_Input(
          gitilesCommit: bbv2.GitilesCommit(
            project: 'flutter/flutter',
            id: '12341234',
            ref: 'refs/heads/master',
          ),
        ),
      );

      final Task t = await Task.fromBuildbucketV2Build(fakeBuild, DatastoreService(config.db, 5));
      expect(t.buildNumber, 12345);
      expect(t.builderName, 'great-builder');
      expect(t.startTimestamp, startTimeDateTime.millisecondsSinceEpoch);
      expect(t.createTimestamp, startTimeDateTime.millisecondsSinceEpoch);
      expect(t.endTimestamp, endTimeDateTime.millisecondsSinceEpoch);
      expect(t.attempts, 1);
      expect(t.luciBucket, 'good-bucket');
      expect(t.name, 'great-builder');
      expect(t.commitKey!.id, commit.key.id);
      expect(t.status, 'Succeeded');
    });

    test('updateFromBuildBucketV2Build', () {
      final bbv2.Build fakeBuild = bbv2.Build(
        builder: bbv2.BuilderID(project: 'okay-project', bucket: 'good-bucket', builder: 'great-builder'),
        number: 12345,
        id: Int64(1234567890),
        status: bbv2.Status.SUCCESS,
        startTime: startTimestamp,
        createTime: startTimestamp,
        endTime: endTimestamp,
        input: bbv2.Build_Input(
          gitilesCommit: bbv2.GitilesCommit(
            project: 'flutter/flutter',
            id: '12341234',
            ref: 'refs/heads/main',
          ),
        ),
      );

      final Task task = Task(
        attempts: 1,
        buildNumber: 1234,
        buildNumberList: '1234',
        builderName: 'great-builder',
        commitKey: null,
        createTimestamp: 10,
        endTimestamp: 50,
        luciBucket: 'good-bucket',
        name: 'test123',
        stageName: 'dart-internal',
        startTimestamp: 10,
        status: 'Failed',
        key: null,
        timeoutInMinutes: 0,
        reason: '',
        requiredCapabilities: [],
        reservedForAgentId: '',
      );

      task.updateFromBuildbucketV2Build(fakeBuild);

      final Task expectedUpdatedTask = Task(
        attempts: 2,
        buildNumber: 12345,
        buildNumberList: '1234,12345',
        builderName: 'great-builder',
        commitKey: null,
        createTimestamp: startTimeDateTime.millisecondsSinceEpoch,
        endTimestamp: endTimeDateTime.millisecondsSinceEpoch,
        luciBucket: 'good-bucket',
        name: 'test123',
        stageName: 'dart-internal',
        startTimestamp: startTimeDateTime.millisecondsSinceEpoch,
        status: 'Succeeded',
        key: null,
        timeoutInMinutes: 0,
        reason: '',
        requiredCapabilities: [],
        reservedForAgentId: '',
      );

      expect(task.toString(), equals(expectedUpdatedTask.toString()));
    });
  });

  // TODO(chillers): There is a bug where `dart test` does not work in offline mode.
  // Need to file issue and get traces.
  group('Task.fromDatastore', () {
    late FakeConfig config;
    late Commit commit;
    late Task expectedTask;

    setUp(() {
      config = FakeConfig();
      commit = generateCommit(1);
      expectedTask = generateTask(1, parent: commit);
      config.db.values[commit.key] = commit;
      config.db.values[expectedTask.key] = expectedTask;
    });

    test('look up by id', () async {
      final Task task = await Task.fromDatastore(
        datastore: DatastoreService(config.db, 5),
        commitKey: commit.key,
        id: '${expectedTask.id}',
      );
      expect(task, expectedTask);
    });

    test('look up by id fails if cannot be found', () async {
      expect(
        Task.fromDatastore(
          datastore: DatastoreService(config.db, 5),
          commitKey: commit.key,
          id: '12345',
        ),
        throwsA(isA<KeyNotFoundException>()),
      );
    });

    test('look up by name', () async {
      final Task task = await Task.fromDatastore(
        datastore: DatastoreService(config.db, 5),
        commitKey: commit.key,
        name: expectedTask.name,
      );
      expect(task, expectedTask);
    });

    test('look up by name fails if cannot be found', () async {
      try {
        await Task.fromDatastore(
          datastore: DatastoreService(config.db, 5),
          commitKey: commit.key,
          name: 'Linux not_found',
        );
      } catch (e) {
        expect(e, isA<InternalServerError>());
        expect(
          e.toString(),
          equals(
            'HTTP 500: Expected to find 1 task for Linux not_found, but found 0',
          ),
        );
      }
    });

    test('look up by name fails if multiple Tasks with the same name are found', () async {
      final DatastoreService datastore = DatastoreService(config.db, 5);
      final String taskName = expectedTask.name!;
      final Task duplicatedTask = generateTask(2, parent: commit, name: taskName);
      config.db.values[duplicatedTask.key] = duplicatedTask;
      try {
        await Task.fromDatastore(
          datastore: datastore,
          commitKey: commit.key,
          name: taskName,
        );
      } catch (e) {
        expect(e, isA<InternalServerError>());
        expect(
          e.toString(),
          equals(
            'HTTP 500: Expected to find 1 task for $taskName, but found 2',
          ),
        );
      }
    });
  });
}
