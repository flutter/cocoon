// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_service/src/model/firestore/task.dart';
import 'package:cocoon_service/src/model/luci/push_message.dart' as pm;
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
}
