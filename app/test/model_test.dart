// Copyright (c) 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:test/test.dart';

import 'package:cocoon/model.dart';

main() {
  group('GetStatusResult', () {
    test('deserializes from JSON', () {
      GetStatusResult result = GetStatusResult.fromJson({
        'Statuses': [
          {
            'Checklist': {
              'Key': '1234567',
              'Checklist': {
                'FlutterRepositoryPath': 'flutter/flutter',
                'Commit': {
                  'Sha': 'asdfasdf',
                  'Author': {
                    'Login': 'supercoder',
                    'AvatarURL': 'http://photo'
                  }
                },
                'CreateTimestamp': '2016-06-27T21:20:53.698152Z',
              }
            },
            'Tasks': [
              {
                'Key': '7654321',
                'Task': {
                  'ChecklistKey': '1234567',
                  'StageName': 'travis',
                  'Name': 'linux travis',
                  'Status': 'Scheduled',
                  'StartTimestamp': '2016-06-27T08:20:53Z',
                  'EndTimestamp': '2016-06-27T09:00:05.123456789Z',
                }
              }
            ]
          },
        ]
      });

      BuildStatus status = result.statuses.single;
      ChecklistEntity checklistEntity = status.checklist;
      Checklist checklist = checklistEntity.checklist;
      CommitInfo commit = checklist.commit;
      AuthorInfo author = commit.author;
      TaskEntity taskEntity = status.tasks.single;
      Task task = taskEntity.task;

      expect(status, new isInstanceOf<BuildStatus>());
      expect(checklistEntity.key, new Key('1234567'));
      expect(checklist.flutterRepositoryPath, 'flutter/flutter');
      expect(checklist.createTimestamp, new DateTime(2016, 6, 27, 21, 20, 53, 0, 698));
      expect(commit.sha, 'asdfasdf');
      expect(author.login, 'supercoder');
      expect(author.avatarUrl, 'http://photo');
      expect(taskEntity.key, new Key('7654321'));
      expect(task.checklistKey, new Key('1234567'));
      expect(task.stageName, 'travis');
      expect(task.name, 'linux travis');
      expect(task.status, 'Scheduled');
      expect(task.startTimestamp, new DateTime(2016, 6, 27, 8, 20, 53));
      expect(task.endTimestamp, new DateTime(2016, 6, 27, 9, 0, 5, 123, 456));
    });
  });
}
