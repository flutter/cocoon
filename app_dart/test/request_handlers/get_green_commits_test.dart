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

    late Task task1;
    late Task task2;
    late Task task3;
    late Task task4;
    late Task task5;

    late Stage stage1;
    late Stage stage2;
    late Stage stage3;
    late Stage stage4;
    late Stage stage5;

    Future<T?> decodeHandlerBody<T>() async {
      final Body body = await tester.get(handler);
      return await utf8.decoder.bind(body.serialize() as Stream<List<int>>).transform(json.decoder).single as T?;
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
      commit1 = Commit(
          key: config.db.emptyKey.append(Commit, id: 'flutter/flutter/ea28a9c34dc701de891eaf74503ca4717019f829'),
          repository: 'flutter/flutter',
          sha: 'ea28a9c34dc701de891eaf74503ca4717019f829',
          timestamp: 3,
          message: 'test message 1',
          branch: 'master');
      commit2 = Commit(
          key: config.db.emptyKey.append(Commit, id: 'flutter/flutter/d5b0b3c8d1c5fd89302089077ccabbcfaae045e4'),
          repository: 'flutter/flutter',
          sha: 'd5b0b3c8d1c5fd89302089077ccabbcfaae045e4',
          timestamp: 1,
          message: 'test message 2',
          branch: 'master');

      task1 = Task(
        key: commit1.key.append(Task, id: 123),
        commitKey: commit1.key,
        name: 'Linux A',
        status: Task.statusSucceeded,
      );
      task2 = Task(
        key: commit1.key.append(Task, id: 456),
        commitKey: commit1.key,
        name: 'Windows A',
        status: Task.statusFailed,
      );
      task3 = Task(
        key: commit2.key.append(Task, id: 123),
        commitKey: commit2.key,
        name: 'Linux B',
        status: Task.statusSucceeded,
      );
      task4 = Task(
        key: commit2.key.append(Task, id: 456),
        commitKey: commit2.key,
        name: 'Windows B',
        status: Task.statusSucceeded,
      );
      task5 = Task(
        key: commit2.key.append(Task, id: 789),
        commitKey: commit2.key,
        name: 'Linux C',
        status: Task.statusSucceeded,
      );

      stage1 = Stage('cocoon', commit1, [task1, task2], Task.statusSucceeded);
      stage2 = Stage('luci', commit1, [task1], Task.statusFailed);
      stage3 = Stage('cocoon', commit2, [task3, task4, task5], Task.statusSucceeded);
      stage4 = Stage('luci', commit2, [task4, task5], Task.statusSucceeded);
      stage5 = Stage('google-test', commit2, [task3, task4], Task.statusSucceeded);
    });

    test('no green commits', () async {
      final Map<String, dynamic> result = (await decodeHandlerBody())!;
      expect(result['greenCommits'], isEmpty);
    });

    test('select and return commits with all stages succeed', () async {
      buildStatusService = FakeBuildStatusService(commitStatuses: <CommitStatus>[
        CommitStatus(commit1, <Stage>[stage1, stage2]),
        CommitStatus(commit2, <Stage>[stage3, stage4, stage5])
      ]);
      handler = GetGreenCommits(
        config,
        datastoreProvider: (DatastoreDB db) => DatastoreService(config.db, 5),
        buildStatusProvider: (_) => buildStatusService,
      );

      final Map<String, dynamic> result = (await decodeHandlerBody())!;

      expect(result['greenCommits'].length, 1);
      expect(result['greenCommits'], <String>['d5b0b3c8d1c5fd89302089077ccabbcfaae045e4']);
    });

    test('select and return more than one green commit in the order of commit timestamp', () async {
      buildStatusService = FakeBuildStatusService(commitStatuses: <CommitStatus>[
        CommitStatus(commit1, <Stage>[stage1]),
        CommitStatus(commit2, <Stage>[stage3, stage4, stage5])
      ]);
      handler = GetGreenCommits(
        config,
        datastoreProvider: (DatastoreDB db) => DatastoreService(config.db, 5),
        buildStatusProvider: (_) => buildStatusService,
      );

      final Map<String, dynamic> result = (await decodeHandlerBody())!;

      expect(result['greenCommits'].length, 2);
      expect(result['greenCommits'], <String>[
        'd5b0b3c8d1c5fd89302089077ccabbcfaae045e4',
        'ea28a9c34dc701de891eaf74503ca4717019f829',
      ]);
    });
  });
}
