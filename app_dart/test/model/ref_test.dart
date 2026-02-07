// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_common/task_status.dart';
import 'package:cocoon_integration_test/testing.dart';
import 'package:cocoon_server_test/test_logging.dart';
import 'package:cocoon_service/src/model/commit_ref.dart';
import 'package:cocoon_service/src/model/task_ref.dart';
import 'package:github/github.dart';
import 'package:test/test.dart';

void main() {
  useTestLoggerPerTest();

  group('TaskRef', () {
    final ref = TaskRef(
      name: 'name',
      currentAttempt: 1,
      status: TaskStatus.succeeded,
      commitSha: 'abc123',
    );

    test('stores arguments', () {
      expect(
        ref,
        isTaskRef
            .hasName('name')
            .hasCurrentAttempt(1)
            .hasStatus(TaskStatus.succeeded)
            .hasCommitSha('abc123'),
      );
    });

    test('implements == and hashCode', () {
      expect(ref, equals(ref));
      expect(ref.hashCode, ref.hashCode);
    });

    test('implements toString', () {
      expect(
        ref.toString(),
        stringContainsInOrder(['name', 'abc123', 'Succeeded', '1']),
      );
    });
  });

  group('CommitRef', () {
    final ref = CommitRef(
      branch: 'branch',
      sha: 'sha',
      slug: RepositorySlug('owner', 'name'),
    );

    test('stores arguments', () {
      expect(
        ref,
        isCommitRef
            .hasBranch('branch')
            .hasSha('sha')
            .hasSlug(RepositorySlug('owner', 'name')),
      );
    });

    test('implements == and hashCode', () {
      expect(ref, equals(ref));
      expect(ref.hashCode, ref.hashCode);
    });

    test('implements toString', () {
      expect(
        ref.toString(),
        stringContainsInOrder(['sha', 'owner/name/branch']),
      );
    });
  });
}
