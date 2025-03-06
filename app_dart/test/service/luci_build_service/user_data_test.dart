// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:cocoon_service/src/service/luci_build_service/user_data.dart';
import 'package:test/test.dart';

void main() {
  // TODO(matanlurey): Remove after validating https://github.com/flutter/flutter/issues/164568.
  List<int> encodeUserDataToBase64Bytes(Map<String, Object?> userDataMap) {
    // Copied from original UserData class/helper:
    // https: //github.com/flutter/cocoon/blob/07f315907f77d2749c476459678ba625bbe01014/app_dart/lib/src/model/luci/user_data.dart
    return base64Encode(json.encode(userDataMap).codeUnits).codeUnits;
  }

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

    test('should encode/decode to bytes', () {
      const userData = PresubmitUserData(
        checkRunId: 1234,
        builderName: 'Linux_foo',
        commitSha: 'abc123',
        commitBranch: 'main',
        repoOwner: 'repo-owner',
        repoName: 'repo-name',
        userAgent: 'UserData Test',
      );
      expect(userData, PresubmitUserData.fromBytes(userData.toBytes()));
    });

    test('should for legacy, support base64 encoded JSON strings', () {
      const userData = PresubmitUserData(
        checkRunId: 1234,
        builderName: 'Linux_foo',
        commitSha: 'abc123',
        commitBranch: 'main',
        repoOwner: 'repo-owner',
        repoName: 'repo-name',
        userAgent: 'UserData Test',
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

    test('should encode/decode to bytes', () {
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
      expect(userData, PostsubmitUserData.fromBytes(userData.toBytes()));
    });

    test('should for legacy, support base64 encoded JSON strings', () {
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
      expect(
        userData,
        PostsubmitUserData.fromBytes(
          encodeUserDataToBase64Bytes(userData.toJson()),
        ),
      );
    });
  });
}
