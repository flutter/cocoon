// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_server_test/test_logging.dart';
import 'package:cocoon_service/src/model/github/checks.dart';
import 'package:github/github.dart' as github;
import 'package:test/test.dart';

void main() {
  useTestLoggerPerTest();

  test('CheckRunEvent', () {
    final object = CheckRunEvent(action: 'Amazing');
    expect(
      object.toString(),
      stringContainsInOrder(['CheckRunEvent', '"action": "Amazing"']),
    );
  });

  group('CheckRun', () {
    test('toString', () {
      const object = CheckRun(conclusion: 'Amazing');
      expect(
        object.toString(),
        stringContainsInOrder(['CheckRun', '"conclusion": "Amazing"']),
      );
    });

    test('toGithubCheckRun populates all fields', () {
      const checkRun = CheckRun(
        id: 1234,
        name: 'Guard',
        headSha: 'the_sha',
        conclusion: 'neutral',
        checkSuite: github.CheckSuite(
          id: 5678,
          headBranch: 'main',
          headSha: 'the_sha',
          conclusion: github.CheckRunConclusion.neutral,
          pullRequests: [],
        ),
      );

      final githubCheckRun = checkRun.toGithubCheckRun();
      expect(githubCheckRun.id, 1234);
      expect(githubCheckRun.name, 'Guard');
      expect(githubCheckRun.headSha, 'the_sha');
      expect(githubCheckRun.conclusion.value, 'neutral');
      expect(githubCheckRun.checkSuiteId, 5678);
    });

    test('toGithubCheckRun handles null checkSuite', () {
      const checkRun = CheckRun(
        id: 1234,
        name: 'Guard',
        headSha: 'the_sha',
        conclusion: 'success',
      );

      final githubCheckRun = checkRun.toGithubCheckRun();
      expect(githubCheckRun.id, 1234);
      expect(githubCheckRun.name, 'Guard');
      expect(githubCheckRun.headSha, 'the_sha');
      expect(githubCheckRun.conclusion.value, 'success');
      expect(githubCheckRun.checkSuiteId, isNull);
    });
  });

  test('MergeGroupEvent', () {
    final object = MergeGroupEvent(
      mergeGroup: const MergeGroup(
        headSha: 'headSha',
        headRef: 'headRef',
        baseSha: 'baseSha',
        baseRef: 'baseRef',
        headCommit: HeadCommit(id: 'id', treeId: 'treeId', message: 'message'),
      ),
      action: 'Amazing',
    );
    expect(
      object.toString(),
      stringContainsInOrder([
        'MergeGroupEvent',
        '"action": "Amazing"',
        '"head_sha": "headSha"',
        '"tree_id": "treeId"',
      ]),
    );
  });
}
