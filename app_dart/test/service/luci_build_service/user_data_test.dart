// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_service/src/service/luci_build_service/user_data.dart';
import 'package:test/test.dart';

void main() {
  test('should encode to JSON', () {
    const userData = BuildBucketPubSubUserData(
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

  test('should encode to JSON including firestoreTaskDocumentName', () {
    final userData = BuildBucketPubSubUserData(
      checkRunId: 1234,
      builderName: 'Linux_foo',
      commitSha: 'abc123',
      commitBranch: 'main',
      repoOwner: 'repo-owner',
      repoName: 'repo-name',
      userAgent: 'UserData Test',
      firestoreTaskDocumentName: FirestoreTaskDocumentName(
        commitSha: 'abc123',
        currentAttempt: 1,
        taskName: 'Linux_foo',
      ),
    );
    expect(userData.toJson(), {
      'check_run_id': 1234,
      'builder_name': 'Linux_foo',
      'commit_sha': 'abc123',
      'commit_branch': 'main',
      'repo_owner': 'repo-owner',
      'repo_name': 'repo-name',
      'user_agent': 'UserData Test',
      'firestore_task_document_name': 'abc123_Linux_foo_1',
    });
  });

  test('should decode from JSON', () {
    expect(
      BuildBucketPubSubUserData.fromJson(const {
        'check_run_id': 1234,
        'builder_name': 'Linux_foo',
        'commit_sha': 'abc123',
        'commit_branch': 'main',
        'repo_owner': 'repo-owner',
        'repo_name': 'repo-name',
        'user_agent': 'UserData Test',
      }),
      const BuildBucketPubSubUserData(
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

  test('should decode from JSON including firestoreTaskDocumentName', () {
    expect(
      BuildBucketPubSubUserData.fromJson(const {
        'check_run_id': 1234,
        'builder_name': 'Linux_foo',
        'commit_sha': 'abc123',
        'commit_branch': 'main',
        'repo_owner': 'repo-owner',
        'repo_name': 'repo-name',
        'user_agent': 'UserData Test',
        'firestore_task_document_name': 'abc123_Linux_foo_1',
      }),
      BuildBucketPubSubUserData(
        checkRunId: 1234,
        builderName: 'Linux_foo',
        commitSha: 'abc123',
        commitBranch: 'main',
        repoOwner: 'repo-owner',
        repoName: 'repo-name',
        userAgent: 'UserData Test',
        firestoreTaskDocumentName: FirestoreTaskDocumentName(
          commitSha: 'abc123',
          currentAttempt: 1,
          taskName: 'Linux_foo',
        ),
      ),
    );
  });

  test('should gracefully fail decoding if the format is invalid', () {
    expect(
      () => BuildBucketPubSubUserData.fromJson(const {
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

  test('should gracefully fail decoding if the firestoreTaskDocumentName format is invalid', () {
    expect(
      () => BuildBucketPubSubUserData.fromJson(const {
        'check_run_id': 1234,
        'builder_name': 'Linux_foo',
        'commit_sha': 'abc123',
        'commit_branch': 'main',
        'repo_owner': 'repo-owner',
        'repo_name': 'repo-name',
        'user_agent': 'UserData Test',
        'firestore_task_document_name': 'MALFORMED',
      }),
      throwsFormatException,
    );
  });
}
