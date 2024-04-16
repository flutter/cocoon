// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_service/src/model/appengine/commit.dart';
import 'package:cocoon_service/src/model/appengine/task.dart' as datastore;
import 'package:cocoon_service/src/model/ci_yaml/target.dart';
import 'package:cocoon_service/src/model/firestore/task.dart';
import 'package:cocoon_service/src/model/luci/push_message.dart' as pm;
import 'package:cocoon_service/src/service/firestore.dart';
import 'package:googleapis/firestore/v1.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import '../../src/utilities/entity_generators.dart';
import '../../src/utilities/mocks.dart';

void main() {
  group('Task', () {
    test('disallows illegal status', () {
      final Task task = Task();
      expect(() => task.setStatus('unknown'), throwsArgumentError);
    });

    test('creates task document correctly from task data model', () async {
      final datastore.Task task = generateTask(1);
      final String commitSha = task.commitKey!.id!.split('/').last;
      final Task taskDocument = taskToDocument(task);
      expect(taskDocument.name, '$kDatabase/documents/$kTaskCollectionId/${commitSha}_${task.name}_${task.attempts}');
      expect(taskDocument.createTimestamp, task.createTimestamp);
      expect(taskDocument.endTimestamp, task.endTimestamp);
      expect(taskDocument.bringup, task.isFlaky);
      expect(taskDocument.taskName, task.name);
      expect(taskDocument.startTimestamp, task.startTimestamp);
      expect(taskDocument.status, task.status);
      expect(taskDocument.testFlaky, task.isTestFlaky);
      expect(taskDocument.commitSha, commitSha);
    });

    test('creates task documents correctly from targets', () async {
      final Commit commit = generateCommit(1);
      final List<Target> targets = <Target>[
        generateTarget(1, platform: 'Mac'),
        generateTarget(2, platform: 'Linux'),
      ];
      final List<Task> taskDocuments = targetsToTaskDocuments(commit, targets);
      expect(taskDocuments.length, 2);
      expect(
        taskDocuments[0].name,
        '$kDatabase/documents/$kTaskCollectionId/${commit.sha}_${targets[0].value.name}_$kTaskInitialAttempt',
      );
      expect(taskDocuments[0].fields![kTaskCreateTimestampField]!.integerValue, commit.timestamp.toString());
      expect(taskDocuments[0].fields![kTaskEndTimestampField]!.integerValue, '0');
      expect(taskDocuments[0].fields![kTaskBringupField]!.booleanValue, false);
      expect(taskDocuments[0].fields![kTaskNameField]!.stringValue, targets[0].value.name);
      expect(taskDocuments[0].fields![kTaskStartTimestampField]!.integerValue, '0');
      expect(taskDocuments[0].fields![kTaskStatusField]!.stringValue, Task.statusNew);
      expect(taskDocuments[0].fields![kTaskTestFlakyField]!.booleanValue, false);
      expect(taskDocuments[0].fields![kTaskCommitShaField]!.stringValue, commit.sha);
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
        final Task task = generateFirestoreTask(1);

        expect(task.status, Task.statusNew);
        expect(task.buildNumber, isNull);
        expect(task.endTimestamp, 0);
        expect(task.createTimestamp, 0);
        expect(task.startTimestamp, 0);

        task.updateFromBuild(build);

        expect(task.status, Task.statusSucceeded);
        expect(task.buildNumber, 1);
        expect(task.createTimestamp, created.millisecondsSinceEpoch);
        expect(task.startTimestamp, started.millisecondsSinceEpoch);
        expect(task.endTimestamp, completed.millisecondsSinceEpoch);
      });

      test('defaults timestamps to 0', () {
        final pm.Build build = generatePushMessageBuild(1);
        final Task task = generateFirestoreTask(1);

        expect(task.endTimestamp, 0);
        expect(task.createTimestamp, 0);
        expect(task.startTimestamp, 0);

        task.updateFromBuild(build);

        expect(task.endTimestamp, 0);
        expect(task.createTimestamp, 0);
        expect(task.startTimestamp, 0);
      });

      test('does not update status if older status', () {
        final pm.Build build = generatePushMessageBuild(
          1,
          status: pm.Status.started,
        );
        final Task task = generateFirestoreTask(
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

      test('handles cancelled build', () {
        final pm.Build build = generatePushMessageBuild(
          1,
          status: pm.Status.completed,
          result: pm.Result.canceled,
        );
        final Task task = generateFirestoreTask(
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
        final Task task = generateFirestoreTask(
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

  // TODO(chillers): There is a bug where `dart test` does not work in offline mode.
  // Need to file issue and get traces.
  group('Task.fromFirestore', () {
    late MockFirestoreService mockFirestoreService;

    setUp(() {
      mockFirestoreService = MockFirestoreService();
    });

    test('generates task correctly', () async {
      final Task firestoreTask = generateFirestoreTask(1);
      when(
        mockFirestoreService.getDocument(
          captureAny,
        ),
      ).thenAnswer((Invocation invocation) {
        return Future<Document>.value(
          firestoreTask,
        );
      });
      final Task resultedTask = await Task.fromFirestore(
        firestoreService: mockFirestoreService,
        documentName: 'test',
      );
      expect(resultedTask.name, firestoreTask.name);
      expect(resultedTask.fields, firestoreTask.fields);
    });
  });

  group('resert as retry', () {
    test('success', () {
      final Task task = generateFirestoreTask(
        1,
        status: Task.statusFailed,
        testFlaky: true,
      );
      task.resetAsRetry(attempt: 2);

      expect(int.parse(task.name!.split('_').last), 2);
      expect(task.status, Task.statusNew);
      expect(task.testFlaky, false);
    });
  });

  test('task facade', () {
    final Task taskDocument = generateFirestoreTask(1);
    final Map<String, dynamic> expectedResult = <String, dynamic>{
      kTaskDocumentName: taskDocument.name,
      kTaskCreateTimestamp: taskDocument.createTimestamp,
      kTaskStartTimestamp: taskDocument.startTimestamp,
      kTaskEndTimestamp: taskDocument.endTimestamp,
      kTaskTaskName: taskDocument.taskName,
      kTaskAttempts: taskDocument.attempts,
      kTaskBringup: taskDocument.bringup,
      kTaskTestFlaky: taskDocument.testFlaky,
      kTaskBuildNumber: taskDocument.buildNumber,
      kTaskStatus: taskDocument.status,
    };
    expect(taskDocument.facade, expectedResult);
  });
}
