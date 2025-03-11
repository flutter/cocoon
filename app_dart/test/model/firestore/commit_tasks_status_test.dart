// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_service/src/model/firestore/commit_tasks_status.dart';
import 'package:cocoon_service/src/model/firestore/task.dart';
import 'package:test/test.dart';

import '../../src/utilities/entity_generators.dart';

void main() {
  group('CommitTasksStatus', () {
    test('generates json correctly', () async {
      final commit = generateFirestoreCommit(1, sha: 'sha1');
      final commitTasksStatus = CommitTasksStatus(commit, <Task>[]);
      expect(commitTasksStatus.toJson(), <String, dynamic>{
        'Commit': <String, dynamic>{
          'DocumentName': 'sha1',
          'RepositoryPath': 'flutter/flutter',
          'CreateTimestamp': 1,
          'Sha': 'sha1',
          'Message': 'test message',
          'Author': 'author',
          'Avatar': 'avatar',
          'Branch': 'master',
        },
        'Tasks': isEmpty,
      });
    });

    test('generates json when a task does not have a build number', () async {
      final commit = generateFirestoreCommit(1, sha: 'sha1');
      final task = generateFirestoreTask(1);
      final commitTasksStatus = CommitTasksStatus(commit, <Task>[task]);
      expect(commitTasksStatus.toJson(), <String, dynamic>{
        'Commit': <String, dynamic>{
          'DocumentName': 'sha1',
          'RepositoryPath': 'flutter/flutter',
          'CreateTimestamp': 1,
          'Sha': 'sha1',
          'Message': 'test message',
          'Author': 'author',
          'Avatar': 'avatar',
          'Branch': 'master',
        },
        'Tasks': [
          <String, dynamic>{
            'Task': <String, dynamic>{
              'DocumentName': 'testSha_task1_1',
              'CommitSha': 'testSha',
              'CreateTimestamp': 0,
              'StartTimestamp': 0,
              'EndTimestamp': 0,
              'TaskName': 'task1',
              'Attempts': 1,
              'Bringup': false,
              'TestFlaky': false,
              'BuildNumber': null,
              'Status': 'New',
            },
            'BuildList': '',
          },
        ],
      });
    });

    test('generates json when a task has a build number', () async {
      final commit = generateFirestoreCommit(1, sha: 'sha1');
      final task = generateFirestoreTask(1, buildNumber: 123);
      final commitTasksStatus = CommitTasksStatus(commit, <Task>[task]);
      expect(commitTasksStatus.toJson(), <String, dynamic>{
        'Commit': <String, dynamic>{
          'DocumentName': 'sha1',
          'RepositoryPath': 'flutter/flutter',
          'CreateTimestamp': 1,
          'Sha': 'sha1',
          'Message': 'test message',
          'Author': 'author',
          'Avatar': 'avatar',
          'Branch': 'master',
        },
        'Tasks': [
          <String, dynamic>{
            'Task': <String, dynamic>{
              'DocumentName': 'testSha_task1_1',
              'CommitSha': 'testSha',
              'CreateTimestamp': 0,
              'StartTimestamp': 0,
              'EndTimestamp': 0,
              'TaskName': 'task1',
              'Attempts': 1,
              'Bringup': false,
              'TestFlaky': false,
              'BuildNumber': 123,
              'Status': 'New',
            },
            'BuildList': '123',
          },
        ],
      });
    });

    test('generates json when a task has multiple reruns', () async {
      final commit = generateFirestoreCommit(1, sha: 'sha1');
      final task1 = generateFirestoreTask(1, buildNumber: 123);
      final task2 = generateFirestoreTask(1, buildNumber: 124);
      final commitTasksStatus = CommitTasksStatus(commit, <Task>[task2, task1]);
      expect(commitTasksStatus.toJson(), <String, dynamic>{
        'Commit': <String, dynamic>{
          'DocumentName': 'sha1',
          'RepositoryPath': 'flutter/flutter',
          'CreateTimestamp': 1,
          'Sha': 'sha1',
          'Message': 'test message',
          'Author': 'author',
          'Avatar': 'avatar',
          'Branch': 'master',
        },
        'Tasks': [
          <String, dynamic>{
            'Task': <String, dynamic>{
              'DocumentName': 'testSha_task1_1',
              'CommitSha': 'testSha',
              'CreateTimestamp': 0,
              'StartTimestamp': 0,
              'EndTimestamp': 0,
              'TaskName': 'task1',
              'Attempts': 1,
              'Bringup': false,
              'TestFlaky': false,
              'BuildNumber': 124,
              'Status': 'New',
            },
            'BuildList': '124,123',
          },
        ],
      });
    });
  });
}
