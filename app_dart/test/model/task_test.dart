// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_service/src/model/appengine/commit.dart';
import 'package:cocoon_service/src/model/appengine/task.dart';
import 'package:cocoon_service/src/model/luci/push_message.dart';
import 'package:cocoon_service/src/service/luci.dart';
import 'package:gcloud/db.dart';
import 'package:test/test.dart';

import '../src/utilities/entity_generators.dart';

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

    test('creates a valid chromebot task', () {
      final Key<String> commitKey = generateKey<String>(Commit, 'flutter/flutter/master/42');
      const LuciBuilder builder = LuciBuilder(
        name: 'builderAbc',
        repo: 'flutter/flutter',
        taskName: 'taskName',
        flaky: false,
      );
      final Task task = Task.chromebot(commitKey: commitKey, createTimestamp: 123, builder: builder);
      validateModel(task);
      expect(task.name, 'taskName');
      expect(task.builderName, 'builderAbc');
      expect(task.createTimestamp, 123);
      expect(task.isFlaky, false);
      expect(task.requiredCapabilities, <String>['can-update-github']);
      expect(task.timeoutInMinutes, 0);
    });

    test('flaky defaults to false', () {
      final Key<String> commitKey = generateKey<String>(Commit, 'flutter/flutter/master/42');
      const LuciBuilder builder = LuciBuilder(
        name: 'builderAbc',
        repo: 'flutter/flutter',
        taskName: 'taskName',
        flaky: null,
      );
      expect(Task.chromebot(commitKey: commitKey, createTimestamp: 123, builder: builder).isFlaky, isFalse);
    });

    group('updateFromBuild', () {
      test('updates if buildNumber is null', () {
        final DateTime created = DateTime.utc(2022, 1, 11, 1, 1);
        final DateTime started = DateTime.utc(2022, 1, 11, 1, 2);
        final DateTime completed = DateTime.utc(2022, 1, 11, 1, 3);
        final Build build = generatePushMessageBuild(
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

      test('updates if buildNumber is prior to pushMessage', () {
        final Build build = generatePushMessageBuild(
          1,
          buildNumber: 2,
          status: Status.started,
        );
        final Task task = generateTask(
          1,
          buildNumber: 1,
          status: Task.statusSucceeded,
        );

        expect(task.buildNumberList, '1');
        expect(task.status, Task.statusSucceeded);

        task.updateFromBuild(build);

        expect(task.buildNumber, 2);
        expect(task.buildNumberList, '1,2');
        expect(task.status, Task.statusInProgress);
      });

      test('does not update status if older status', () {
        final Build build = generatePushMessageBuild(
          1,
          status: Status.started,
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
        final Build build = generatePushMessageBuild(
          1,
          status: Status.completed,
          result: Result.success,
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
    });
  });
}

void validateModel(Task task) {
  // Throws an exception when property validation fails.
  ModelDBImpl().toDatastoreEntity(task);
}
