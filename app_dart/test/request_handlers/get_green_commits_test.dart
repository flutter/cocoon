// Copyright 2021 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:cocoon_service/cocoon_service.dart';
import 'package:cocoon_service/src/model/appengine/commit.dart';
import 'package:cocoon_service/src/model/appengine/stage.dart';
import 'package:cocoon_service/src/model/appengine/task.dart';
import 'package:cocoon_service/src/service/build_status_provider.dart';
import 'package:cocoon_service/src/service/datastore.dart';
import 'package:gcloud/db.dart';
import 'package:test/test.dart';

import '../src/datastore/fake_config.dart';
import '../src/request_handling/fake_authentication.dart';
import '../src/request_handling/request_handler_tester.dart';
import '../src/service/fake_build_status_provider.dart';
import '../src/utilities/entity_generators.dart';

void main() {
  group('GetStatus', () {
    late FakeConfig config;
    FakeClientContext clientContext;
    FakeKeyHelper keyHelper;
    FakeBuildStatusService buildStatusService;
    late RequestHandlerTester tester;
    late GetGreenCommits handler;

    late Commit commit1;
    late Commit commit2;

    late Task task1Succeed;
    late Task task2Failed;
    late Task task3FailedFlaky;
    late Task task4SucceedFlaky;

    late Stage stageOneSucceed;
    late Stage stageFailed;
    late Stage stageMultipleSucceed;
    late Stage stageFailedFlaky;

    Future<List<T?>?> decodeHandlerBody<T>() async {
      final Body body = await tester.get(handler);
      return (await utf8.decoder.bind(body.serialize() as Stream<List<int>>).transform(json.decoder).single
              as List<dynamic>)
          .cast<T>();
    }

    setUp(() {
      clientContext = FakeClientContext();
      keyHelper = FakeKeyHelper(applicationContext: clientContext.applicationContext);
      tester = RequestHandlerTester();
      config = FakeConfig(keyHelperValue: keyHelper);
      buildStatusService = FakeBuildStatusService(commitStatuses: <CommitStatus>[]);
      handler = GetGreenCommits(
        config,
        datastoreProvider: (DatastoreDB db) => DatastoreService(config.db, 5),
        buildStatusProvider: (_) => buildStatusService,
      );

      commit1 = generateCommit(1, timestamp: 3, sha: 'ea28a9c34dc701de891eaf74503ca4717019f829');
      commit2 = generateCommit(2, timestamp: 1, sha: 'd5b0b3c8d1c5fd89302089077ccabbcfaae045e4');

      task1Succeed = generateTask(1, status: Task.statusSucceeded);
      task2Failed = generateTask(2, status: Task.statusFailed); // should fail if included
      task3FailedFlaky = generateTask(3,
          status: Task.statusFailed, isFlaky: true); // should succeed if included because `bringup: true`
      task4SucceedFlaky = generateTask(4, status: Task.statusSucceeded, isFlaky: true);

      stageOneSucceed =
          Stage('cocoon', commit1, [task1Succeed], Task.statusInProgress); // should scceed, since task 1 succeed
      stageFailed = Stage('luci', commit1, [task1Succeed, task2Failed],
          Task.statusInProgress); // should fail, since task 1 succeed and task2 fail
      stageMultipleSucceed = Stage('cocoon', commit2, [task1Succeed, task4SucceedFlaky],
          Task.statusInProgress); // should succeed, since both task 1 and task 4 succeed
      stageFailedFlaky = Stage('luci', commit2, [task1Succeed, task3FailedFlaky],
          Task.statusInProgress); // should succeed, even though it includes task 3
    });

    test('no green commits', () async {
      final List<String?> result = (await decodeHandlerBody())!;
      expect(result, isEmpty);
    });

    test(
        'select and return commits with all tasks succeed, and exclude commits with failed tasks and without `bringup: true` label',
        () async {
      buildStatusService = FakeBuildStatusService(commitStatuses: <CommitStatus>[
        CommitStatus(commit1, <Stage>[stageOneSucceed, stageFailed]),
        CommitStatus(commit2, <Stage>[stageOneSucceed, stageMultipleSucceed])
      ]);
      handler = GetGreenCommits(
        config,
        datastoreProvider: (DatastoreDB db) => DatastoreService(config.db, 5),
        buildStatusProvider: (_) => buildStatusService,
      );

      final List<String?> result = (await decodeHandlerBody())!;

      expect(result.length, 1);
      expect(result, <String>['d5b0b3c8d1c5fd89302089077ccabbcfaae045e4']);
    });

    test('Also select green commits that include failed tasks but have bringup: true label', () async {
      buildStatusService = FakeBuildStatusService(commitStatuses: <CommitStatus>[
        CommitStatus(commit1, <Stage>[stageOneSucceed, stageMultipleSucceed]),
        CommitStatus(commit2, <Stage>[stageOneSucceed, stageFailedFlaky])
      ]);
      handler = GetGreenCommits(
        config,
        datastoreProvider: (DatastoreDB db) => DatastoreService(config.db, 5),
        buildStatusProvider: (_) => buildStatusService,
      );

      final List<String?> result = (await decodeHandlerBody())!;

      expect(result.length, 2);
      expect(result, <String>[
        'd5b0b3c8d1c5fd89302089077ccabbcfaae045e4',
        'ea28a9c34dc701de891eaf74503ca4717019f829',
      ]);
    });
  });
}
