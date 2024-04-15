// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_service/src/model/firestore/commit.dart';
import 'package:cocoon_service/src/model/firestore/commit_tasks_status.dart';
import 'package:cocoon_service/src/model/firestore/task.dart';
import 'package:test/test.dart';

import '../../src/utilities/entity_generators.dart';

void main() {
  group('CommitTasksStatus', () {
    test('generates json correctly', () async {
      final Commit commit = generateFirestoreCommit(1, sha: 'sha1');
      final CommitTasksStatus commitTasksStatus = CommitTasksStatus(commit, <Task>[]);
      expect(SerializableCommitTasksStatus(commitTasksStatus).toJson(), <String, dynamic>{
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
        'Tasks': [],
      });
    });
  });
}
