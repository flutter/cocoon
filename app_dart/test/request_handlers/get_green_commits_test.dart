// Copyright 2021 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:cocoon_service/cocoon_service.dart';
import 'package:cocoon_service/src/model/appengine/stage.dart';
import 'package:cocoon_service/src/model/appengine/task.dart';
import 'package:cocoon_service/src/service/build_status_provider.dart';
import 'package:cocoon_service/src/service/datastore.dart';
import 'package:gcloud/db.dart';
import 'package:test/test.dart';

import '../src/datastore/fake_config.dart';
import '../src/request_handling/fake_authentication.dart';
import '../src/request_handling/fake_http.dart';
import '../src/request_handling/request_handler_tester.dart';
import '../src/service/fake_build_status_provider.dart';
import '../src/utilities/entity_generators.dart';
import '../src/utilities/mocks.dart';

void main() {
  group('GetGreenCommits', () {
    late FakeConfig config;
    FakeClientContext clientContext;
    FakeKeyHelper keyHelper;
    FakeBuildStatusService buildStatusService;
    late MockFirestoreService mockFirestoreService;
    late RequestHandlerTester tester;
    late GetGreenCommits handler;

    final commit1 = generateCommit(
      1,
      timestamp: 3,
      sha: 'ea28a9c34dc701de891eaf74503ca4717019f829',
    );
    final commit2 = generateCommit(
      2,
      timestamp: 1,
      sha: 'd5b0b3c8d1c5fd89302089077ccabbcfaae045e4',
    );
    final commitBranched = generateCommit(
      2,
      timestamp: 1,
      sha: 'ffffffffffffffffffffffffffffffffaae045e4',
      branch: 'flutter-2.13-candidate.0',
    );

    final task1Succeed = generateTask(1, status: Task.statusSucceeded);
    final task2Failed = generateTask(
      2,
      status: Task.statusFailed,
    ); // should fail if included
    final task3FailedFlaky = generateTask(
      3,
      status: Task.statusFailed,
      isFlaky: true,
    ); // should succeed if included because `bringup: true`
    final task4SucceedFlaky = generateTask(
      4,
      status: Task.statusSucceeded,
      isFlaky: true,
    );

    final stageOneSucceed = Stage('cocoon', commit1, [
      task1Succeed,
    ], Task.statusInProgress); // should scceed, since task 1 succeed
    final stageFailed = Stage(
      'luci',
      commit1,
      [task1Succeed, task2Failed],
      Task.statusInProgress,
    ); // should fail, since task 1 succeed and task2 fail
    final stageMultipleSucceed = Stage(
      'cocoon',
      commit2,
      [task1Succeed, task4SucceedFlaky],
      Task.statusInProgress,
    ); // should succeed, since both task 1 and task 4 succeed
    final stageFailedFlaky = Stage('luci', commit2, [
      task1Succeed,
      task3FailedFlaky,
    ], Task.statusInProgress); // should succeed, even though it includes task 3

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
      clientContext = FakeClientContext();
      mockFirestoreService = MockFirestoreService();
      keyHelper = FakeKeyHelper(
        applicationContext: clientContext.applicationContext,
      );
      tester = RequestHandlerTester();
      config = FakeConfig(
        keyHelperValue: keyHelper,
        firestoreService: mockFirestoreService,
      );
      buildStatusService = FakeBuildStatusService(
        commitStatuses: <CommitStatus>[],
      );
      handler = GetGreenCommits(
        config: config,
        datastoreProvider: (DatastoreDB db) => DatastoreService(config.db, 5),
        buildStatusProvider: (_, _) => buildStatusService,
      );
    });

    test('no green commits', () async {
      final result = (await decodeHandlerBody<List<Object?>>())!;
      expect(result, isEmpty);
    });

    test('should return commits with all tasks succeed', () async {
      buildStatusService = FakeBuildStatusService(
        commitStatuses: <CommitStatus>[
          CommitStatus(commit1, <Stage>[stageOneSucceed]),
          CommitStatus(commit2, <Stage>[stageOneSucceed, stageMultipleSucceed]),
        ],
      );
      handler = GetGreenCommits(
        config: config,
        datastoreProvider: (DatastoreDB db) => DatastoreService(config.db, 5),
        buildStatusProvider: (_, _) => buildStatusService,
      );

      final result = (await decodeHandlerBody<String>())!;
      expect(result, <String>[commit2.sha!, commit1.sha!]);
    });

    test(
      'should fail commits that have failed task without [bringup: true] label',
      () async {
        buildStatusService = FakeBuildStatusService(
          commitStatuses: <CommitStatus>[
            CommitStatus(commit1, <Stage>[stageFailed]),
            CommitStatus(commit2, <Stage>[
              stageOneSucceed,
              stageMultipleSucceed,
            ]),
          ],
        );
        handler = GetGreenCommits(
          config: config,
          datastoreProvider: (DatastoreDB db) => DatastoreService(config.db, 5),
          buildStatusProvider: (_, _) => buildStatusService,
        );

        final result = (await decodeHandlerBody<String>())!;
        expect(result, <String>[commit2.sha!]);
      },
    );

    test(
      'should return commits with failed tasks but with `bringup: true` label',
      () async {
        buildStatusService = FakeBuildStatusService(
          commitStatuses: <CommitStatus>[
            CommitStatus(commit1, <Stage>[stageFailed]),
            CommitStatus(commit2, <Stage>[stageFailedFlaky]),
          ],
        );
        handler = GetGreenCommits(
          config: config,
          datastoreProvider: (DatastoreDB db) => DatastoreService(config.db, 5),
          buildStatusProvider: (_, _) => buildStatusService,
        );

        final result = (await decodeHandlerBody<String>())!;
        expect(result, <String>[commit2.sha!]);
      },
    );

    test('should return commits with both flaky and succeeded tasks', () async {
      buildStatusService = FakeBuildStatusService(
        commitStatuses: <CommitStatus>[
          CommitStatus(commit1, <Stage>[stageOneSucceed, stageMultipleSucceed]),
          CommitStatus(commit2, <Stage>[stageOneSucceed, stageFailedFlaky]),
        ],
      );
      handler = GetGreenCommits(
        config: config,
        datastoreProvider: (DatastoreDB db) => DatastoreService(config.db, 5),
        buildStatusProvider: (_, _) => buildStatusService,
      );

      final result = (await decodeHandlerBody<String>())!;
      expect(result, <String>[commit2.sha!, commit1.sha!]);
    });

    test('should return branched commits', () async {
      buildStatusService = FakeBuildStatusService(
        commitStatuses: <CommitStatus>[
          CommitStatus(commitBranched, <Stage>[stageOneSucceed]),
        ],
      );
      tester.request = FakeHttpRequest(
        queryParametersValue: <String, String>{
          GetGreenCommits.kBranchParam: commitBranched.branch!,
        },
      );
      handler = GetGreenCommits(
        config: config,
        datastoreProvider: (DatastoreDB db) => DatastoreService(config.db, 5),
        buildStatusProvider: (_, _) => buildStatusService,
      );

      final result = (await decodeHandlerBody<String>())!;
      expect(result, <String>[commitBranched.sha!]);
    });
  });
}
