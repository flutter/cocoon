// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_service/src/service/luci_build_service/user_data.dart';
import 'package:test/test.dart';

void main() {
  group('PresubmitUserData', () {
    test('should encode to JSON', () {
      const userData = PresubmitUserData(
        checkRunId: 1234,
        builderName: 'Linux_foo',
        commitSha: 'abc123',
        commitBranch: 'main',
        repoOwner: 'repo-owner',
        repoName: 'repo-name',
        userAgent: 'UserData Test',
      );
      expect(userData.toJson(), {
        'check_run_id': 1234,
        'builder_name': 'Linux_foo',
        'commit_sha': 'abc123',
        'commit_branch': 'main',
        'repo_owner': 'repo-owner',
        'repo_name': 'repo-name',
        'user_agent': 'UserData Test',
      });
    });

    test('should decode from JSON', () {
      expect(
        PresubmitUserData.fromJson(const {
          'check_run_id': 1234,
          'builder_name': 'Linux_foo',
          'commit_sha': 'abc123',
          'commit_branch': 'main',
          'repo_owner': 'repo-owner',
          'repo_name': 'repo-name',
          'user_agent': 'UserData Test',
        }),
        const PresubmitUserData(
          checkRunId: 1234,
          builderName: 'Linux_foo',
          commitSha: 'abc123',
          commitBranch: 'main',
          repoOwner: 'repo-owner',
          repoName: 'repo-name',
          userAgent: 'UserData Test',
        ),
      );
    });

    test('should gracefully fail decoding if the format is invalid', () {
      expect(
        () => PresubmitUserData.fromJson(const {
          'check_run_id': 1234,
          'builder_nameMALFORRMED': 'Linux_foo',
          'commit_sha': 'abc123',
          'commit_branch': 'main',
          'repo_owner': 'repo-owner',
          'repo_name': 'repo-name',
          'user_agent': 'UserData Test',
        }),
        throwsFormatException,
      );
    });
  });

  group('PostsubmitUserData', () {
    test('should encode to JSON', () {
      final userData = PostsubmitUserData(
        checkRunId: 1234,
        repoOwner: 'repo-owner',
        repoName: 'repo-name',
        taskKey: 'task-key',
        commitKey: 'commit-key',
        firestoreTaskDocumentName: FirestoreTaskDocumentName(
          commitSha: 'abc123',
          currentAttempt: 1,
          taskName: 'task-name',
        ),
      );
      expect(userData.toJson(), {
        'check_run_id': 1234,
        'repo_owner': 'repo-owner',
        'repo_name': 'repo-name',
        'task_key': 'task-key',
        'commit_key': 'commit-key',
        'firestore_task_document_name': 'abc123_task-name_1',
      });
    });

    test('should decode from JSON', () {
      expect(
        PostsubmitUserData.fromJson(const {
          'check_run_id': 1234,
          'repo_owner': 'repo-owner',
          'repo_name': 'repo-name',
          'task_key': 'task-key',
          'commit_key': 'commit-key',
          'firestore_task_document_name': 'abc123_task-name_1',
        }),
        PostsubmitUserData(
          checkRunId: 1234,
          repoOwner: 'repo-owner',
          repoName: 'repo-name',
          taskKey: 'task-key',
          commitKey: 'commit-key',
          firestoreTaskDocumentName: FirestoreTaskDocumentName(
            commitSha: 'abc123',
            currentAttempt: 1,
            taskName: 'task-name',
          ),
        ),
      );
    });

    test('should gracefully fail decoding if the format is invalid', () {
      expect(
        () => PostsubmitUserData.fromJson(const {
          'check_run_id': 1234,
          'repo_owner': 'repo-owner',
          'repo_name': 'repo-name',
        }),
        throwsFormatException,
      );
    });
  });
}
