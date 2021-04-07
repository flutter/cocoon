// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_service/src/model/appengine/agent.dart';
import 'package:cocoon_service/src/model/appengine/commit.dart';
import 'package:cocoon_service/src/model/appengine/task.dart';
import 'package:cocoon_service/src/service/datastore.dart';
import 'package:cocoon_service/src/service/task_provider.dart';
import 'package:test/test.dart';

import '../src/datastore/fake_config.dart';

void main() {
  FakeConfig config;

  setUp(() {
    config = FakeConfig();
  });

  group('TaskService', () {
    int taskIdCounter;
    Agent agent;
    Commit commit;

    TaskService taskService;

    Task newTask() {
      final int taskId = taskIdCounter++;
      final String taskName = 'test_$taskId';
      return Task(
        key: commit.key.append(Task, id: taskName),
        name: taskName,
        status: Task.statusNew,
        stageName: 'devicelab',
        attempts: 0,
        isFlaky: false,
        requiredCapabilities: <String>['linux/android'],
      );
    }

    setUp(() {
      taskIdCounter = 1;
      agent = Agent(agentId: 'aid', capabilities: <String>['linux/android']);
      commit = Commit(key: config.db.emptyKey.append(Commit, id: 'abc'), sha: 'abc');
      taskService = TaskService(DatastoreService(config.db, 5));
    });

    test('if no commits in query returns null', () async {
      config.flutterBranchesValue = <String>['master'];
      expect(await taskService.findNextTask(agent, config), isNull);
    });

    group('if commits in query', () {
      void setTaskResults(List<Task> tasks) {
        for (Task task in tasks) {
          config.db.values[task.key] = task;
        }
      }

      setUp(() {
        config.db.values[commit.key] = commit;
        config.flutterBranchesValue = <String>['master'];
      });

      test('throws if task has no required capabilities', () async {
        setTaskResults(<Task>[
          newTask()..requiredCapabilities.clear(),
        ]);
        expect(taskService.findNextTask(agent, config), throwsA(isA<InvalidTaskException>()));
      });

      test('returns available task', () async {
        setTaskResults(<Task>[
          newTask()..name = 'a',
        ]);
        final FullTask result = await taskService.findNextTask(agent, config);
        expect(result.task.name, 'a');
        expect(result.commit, commit);
      });

      test('skips tasks where agent capabilities are insufficient', () async {
        setTaskResults(<Task>[
          newTask()..requiredCapabilities[0] = 'mac/ios',
        ]);
        expect(await taskService.findNextTask(agent, config), isNull);
      });

      test('skips tasks that are not managed by devicelab', () async {
        setTaskResults(<Task>[
          newTask()..stageName = 'cirrus',
        ]);
        expect(await taskService.findNextTask(agent, config), isNull);
      });

      test('only considers tasks with status "new"', () async {
        setTaskResults(<Task>[
          newTask()..status = Task.statusInProgress,
          newTask()..status = Task.statusSucceeded,
          newTask()..status = Task.statusFailed,
        ]);
        expect(await taskService.findNextTask(agent, config), isNull);
      });

      test('picks the task with fewest attempts first', () async {
        setTaskResults(<Task>[
          newTask()
            ..name = 'c'
            ..attempts = 3,
          newTask()
            ..name = 'a'
            ..attempts = 1,
          newTask()
            ..name = 'b'
            ..attempts = 2,
        ]);
        final FullTask result = await taskService.findNextTask(agent, config);
        expect(result.task.name, 'a');
      });
    });

    group('if release branch exists', () {
      void setTaskResults(List<Task> tasks) {
        for (Task task in tasks) {
          config.db.values[task.key] = task;
        }
      }

      setUp(() {
        config.db.values[commit.key] = commit;
        config.flutterBranchesValue = <String>['master', 'flutter-0.0-candidate.0'];
      });

      test('return release branch task first when exist', () async {
        setTaskResults(<Task>[
          newTask(),
        ]);
        final Commit releaseCommit =
            Commit(key: config.db.emptyKey.append(Commit, id: 'abc'), sha: 'abc', branch: 'flutter-0.0-candidate.0');
        config.db.values[releaseCommit.key] = releaseCommit;
        final FullTask result = await taskService.findNextTask(agent, config);
        expect(result.commit.branch, 'flutter-0.0-candidate.0');
      });
    });
  });
}
