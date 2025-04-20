// Copyright 2021 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:cocoon_server_test/test_logging.dart';
import 'package:cocoon_service/cocoon_service.dart';
import 'package:cocoon_service/src/model/firestore/task.dart';
import 'package:cocoon_service/src/service/build_status_provider/commit_tasks_status.dart';
import 'package:test/test.dart';

import '../src/datastore/fake_config.dart';
import '../src/request_handling/fake_http.dart';
import '../src/request_handling/request_handler_tester.dart';
import '../src/service/fake_build_status_provider.dart';
import '../src/utilities/entity_generators.dart';

void main() {
  useTestLoggerPerTest();

  late FakeConfig config;
  late FakeBuildStatusService buildStatusService;
  late RequestHandlerTester tester;
  late GetGreenCommits handler;

  final commit1 = generateFirestoreCommit(
    1,
    createTimestamp: 3,
    sha: 'ea28a9c34dc701de891eaf74503ca4717019f829',
  );
  final commit2 = generateFirestoreCommit(
    2,
    createTimestamp: 1,
    sha: 'd5b0b3c8d1c5fd89302089077ccabbcfaae045e4',
  );
  final commitBranched = generateFirestoreCommit(
    2,
    createTimestamp: 1,
    sha: 'ffffffffffffffffffffffffffffffffaae045e4',
    branch: 'flutter-2.13-candidate.0',
  );

  final task1Succeed = generateFirestoreTask(1, status: Task.statusSucceeded);
  final task2Failed = generateFirestoreTask(
    2,
    status: Task.statusFailed,
  ); // should fail if included
  final task3FailedFlaky = generateFirestoreTask(
    3,
    status: Task.statusFailed,
    testFlaky: true,
  ); // should succeed if included because `bringup: true`
  final task4SucceedFlaky = generateFirestoreTask(
    4,
    status: Task.statusSucceeded,
    testFlaky: true,
  );

  Future<List<T?>?> decodeHandlerBody<T>() async {
    final body = await tester.get(handler);
    return (await utf8.decoder
                .bind(body.serialize() as Stream<List<int>>)
                .transform(json.decoder)
                .single
            as List<dynamic>)
        .cast<T>();
  }

  setUp(() {
    tester = RequestHandlerTester();
    config = FakeConfig();
  });

  test('no green commits', () async {
    buildStatusService = FakeBuildStatusService(
      commitTasksStatuses: <CommitTasksStatus>[],
    );
    handler = GetGreenCommits(
      config: config,
      buildStatusService: buildStatusService,
    );
    final result = (await decodeHandlerBody<List<Object?>>())!;
    expect(result, isEmpty);
  });

  test('should return commits with all tasks succeed', () async {
    buildStatusService = FakeBuildStatusService(
      commitTasksStatuses: [
        CommitTasksStatus(commit1, [task1Succeed]),
        CommitTasksStatus(commit2, [task1Succeed, task4SucceedFlaky]),
      ],
    );
    handler = GetGreenCommits(
      config: config,
      buildStatusService: buildStatusService,
    );

    final result = (await decodeHandlerBody<String>())!;
    expect(result, <String>[commit2.sha, commit1.sha]);
  });

  test(
    'should fail commits that have failed task without [bringup: true] label',
    () async {
      buildStatusService = FakeBuildStatusService(
        commitTasksStatuses: [
          CommitTasksStatus(commit1, [task1Succeed, task2Failed]),
          CommitTasksStatus(commit2, [task1Succeed, task4SucceedFlaky]),
        ],
      );
      handler = GetGreenCommits(
        config: config,
        buildStatusService: buildStatusService,
      );

      final result = (await decodeHandlerBody<String>())!;
      expect(result, <String>[commit2.sha]);
    },
  );

  test(
    'should return commits with failed tasks but with `bringup: true` label',
    () async {
      buildStatusService = FakeBuildStatusService(
        commitTasksStatuses: [
          CommitTasksStatus(commit1, [task1Succeed, task2Failed]),
          CommitTasksStatus(commit2, [task1Succeed, task3FailedFlaky]),
        ],
      );
      handler = GetGreenCommits(
        config: config,
        buildStatusService: buildStatusService,
      );

      final result = (await decodeHandlerBody<String>())!;
      expect(result, <String>[commit2.sha]);
    },
  );

  test('should return commits with both flaky and succeeded tasks', () async {
    buildStatusService = FakeBuildStatusService(
      commitTasksStatuses: [
        CommitTasksStatus(commit1, [task1Succeed]),
        CommitTasksStatus(commit2, [task1Succeed, task4SucceedFlaky]),
      ],
    );
    handler = GetGreenCommits(
      config: config,
      buildStatusService: buildStatusService,
    );

    final result = (await decodeHandlerBody<String>())!;
    expect(result, <String>[commit2.sha, commit1.sha]);
  });

  test('should return branched commits', () async {
    buildStatusService = FakeBuildStatusService(
      commitTasksStatuses: [
        CommitTasksStatus(commitBranched, [task1Succeed]),
      ],
    );
    tester.request = FakeHttpRequest(
      queryParametersValue: <String, String>{
        GetGreenCommits.kBranchParam: commitBranched.branch,
      },
    );
    handler = GetGreenCommits(
      config: config,
      buildStatusService: buildStatusService,
    );

    final result = (await decodeHandlerBody<String>())!;
    expect(result, <String>[commitBranched.sha]);
  });
}
