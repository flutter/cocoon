// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:cocoon_server_test/test_logging.dart';
import 'package:cocoon_service/src/model/firestore/task.dart' as firestore;
import 'package:cocoon_service/src/service/luci_build_service/user_data.dart';
import 'package:test/test.dart';

void main() {
  useTestLoggerPerTest();

  // TODO(matanlurey): Remove after validating https://github.com/flutter/flutter/issues/164568.
  List<int> encodeUserDataToBase64Bytes(Map<String, Object?> userDataMap) {
    // Copied from original UserData class/helper:
    // https: //github.com/flutter/cocoon/blob/07f315907f77d2749c476459678ba625bbe01014/app_dart/lib/src/model/luci/user_data.dart
    return base64Encode(json.encode(userDataMap).codeUnits).codeUnits;
  }

  group('PresubmitUserData', () {
    test('should encode to JSON', () {
      final userData = PresubmitUserData(
        checkRunId: 1234,
        commitSha: 'abc123',
        commitBranch: 'main',
        repoOwner: 'repo-owner',
        repoName: 'repo-name',
      );
      expect(userData.toJson(), {
        'check_run_id': 1234,
        'commit_sha': 'abc123',
        'commit_branch': 'main',
        'repo_owner': 'repo-owner',
        'repo_name': 'repo-name',
      });
    });

    test('should decode from JSON', () {
      expect(
        PresubmitUserData.fromJson(const {
          'check_run_id': 1234,
          'commit_sha': 'abc123',
          'commit_branch': 'main',
          'repo_owner': 'repo-owner',
          'repo_name': 'repo-name',
        }),
        PresubmitUserData(
          checkRunId: 1234,
          commitSha: 'abc123',
          commitBranch: 'main',
          repoOwner: 'repo-owner',
          repoName: 'repo-name',
        ),
      );
    });

    test('should gracefully fail decoding if the format is invalid', () {
      expect(
        () => PresubmitUserData.fromJson(const {
          'check_run_id': 1234,
          'commit_MALFORMED': 'abc123',
          'commit_branch': 'main',
          'user_agent': 'UserData Test',
        }),
        throwsFormatException,
      );
    });

    test('should encode/decode to bytes', () {
      final userData = PresubmitUserData(
        checkRunId: 1234,
        commitSha: 'abc123',
        commitBranch: 'main',
        repoOwner: 'repo-owner',
        repoName: 'repo-name',
      );
      expect(userData, PresubmitUserData.fromBytes(userData.toBytes()));
    });

    test('should for legacy, support base64 encoded JSON strings', () {
      final userData = PresubmitUserData(
        checkRunId: 1234,
        commitSha: 'abc123',
        commitBranch: 'main',
        repoOwner: 'repo-owner',
        repoName: 'repo-name',
      );
      expect(
        userData,
        PresubmitUserData.fromBytes(
          encodeUserDataToBase64Bytes(userData.toJson()),
        ),
      );
    });
  });

  group('PostsubmitUserData', () {
    test('should encode to JSON', () {
      final userData = PostsubmitUserData(
        checkRunId: 1234,
        taskKey: 'task-key',
        commitKey: 'commit-key',
        firestoreTaskDocumentName: firestore.TaskId(
          commitSha: 'abc123',
          currentAttempt: 1,
          taskName: 'task-name',
        ),
      );
      expect(userData.toJson(), {
        'check_run_id': 1234,
        'task_key': 'task-key',
        'commit_key': 'commit-key',
        'firestore_task_document_name': 'abc123_task-name_1',
      });
    });

    test('should decode from JSON', () {
      expect(
        PostsubmitUserData.fromJson(const {
          'check_run_id': 1234,
          'task_key': 'task-key',
          'commit_key': 'commit-key',
          'firestore_task_document_name': 'abc123_task-name_1',
        }),
        PostsubmitUserData(
          checkRunId: 1234,
          taskKey: 'task-key',
          commitKey: 'commit-key',
          firestoreTaskDocumentName: firestore.TaskId(
            commitSha: 'abc123',
            currentAttempt: 1,
            taskName: 'task-name',
          ),
        ),
      );
    });

    test('should gracefully fail decoding if the format is invalid', () {
      expect(
        () => PostsubmitUserData.fromJson(const {'check_run_id': 1234}),
        throwsFormatException,
      );
    });

    test('should encode/decode to bytes', () {
      final userData = PostsubmitUserData(
        checkRunId: 1234,
        taskKey: 'task-key',
        commitKey: 'commit-key',
        firestoreTaskDocumentName: firestore.TaskId(
          commitSha: 'abc123',
          currentAttempt: 1,
          taskName: 'task-name',
        ),
      );
      expect(userData, PostsubmitUserData.fromBytes(userData.toBytes()));
    });

    test('should for legacy, support base64 encoded JSON strings', () {
      final userData = PostsubmitUserData(
        checkRunId: 1234,
        taskKey: 'task-key',
        commitKey: 'commit-key',
        firestoreTaskDocumentName: firestore.TaskId(
          commitSha: 'abc123',
          currentAttempt: 1,
          taskName: 'task-name',
        ),
      );
      expect(
        userData,
        PostsubmitUserData.fromBytes(
          encodeUserDataToBase64Bytes(userData.toJson()),
        ),
      );
    });
  });
}
