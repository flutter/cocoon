// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_service/src/model/appengine/commit.dart';
import 'package:cocoon_service/src/model/appengine/task.dart';
import 'package:cocoon_service/src/model/luci/push_message.dart';
import 'package:cocoon_service/src/request_handlers/scheduler/postsubmit_build_test_subscription.dart';
import 'package:cocoon_service/src/request_handling/body.dart';
import 'package:cocoon_service/src/request_handling/exceptions.dart';
import 'package:cocoon_service/src/service/cache_service.dart';
import 'package:cocoon_service/src/service/datastore.dart';
import 'package:collection/collection.dart';
import 'package:test/test.dart';

import '../../src/datastore/fake_config.dart';
import '../../src/request_handling/fake_authentication.dart';
import '../../src/request_handling/fake_http.dart';
import '../../src/request_handling/subscription_tester.dart';
import '../../src/service/fake_scheduler.dart';
import '../../src/utilities/entity_generators.dart';
import '../../src/utilities/push_message.dart';

void main() {
  group(PostsubmitBuildTestSubscription, () {
    late PostsubmitBuildTestSubscription handler;
    late FakeConfig config;
    late FakeHttpRequest request;
    late SubscriptionTester tester;
    late FakeScheduler scheduler;

    setUp(() {
      config = FakeConfig();
      scheduler = FakeScheduler(
        ciYaml: buildTestConfig,
        config: config,
      );
      handler = PostsubmitBuildTestSubscription(
        cache: CacheService(inMemory: true),
        config: config,
        authProvider: FakeAuthenticationProvider(),
        datastoreProvider: (_) => DatastoreService(config.db, 5),
        scheduler: scheduler,
      );
      request = FakeHttpRequest();

      tester = SubscriptionTester(
        request: request,
      );
    });

    test('throw BadRequest on empty commit_key', () async {
      tester.message = createBuildbucketPushMessage(
        'COMPLETED',
        result: 'SUCCESS',
        builderName: '',
        userData: '{}',
      );

      expect(() => tester.post(handler), throwsA(isA<BadRequestException>()));
    });

    test('ack on empty builds', () async {
      tester.message = const PushMessage(data: '{}');

      expect(await tester.post(handler), Body.empty);
    });

    test('ack on non-successful builds', () async {
      final Commit commit = generateCommit(1);
      final Task parentTask = generateTask(
        1,
        name: 'Linux build',
        parent: commit,
      );
      tester.message = createBuildbucketPushMessage(
        'COMPLETED',
        result: 'FAILURE',
        builderName: '',
        userData: '{\\"task_key\\":\\"${parentTask.key.id}\\", \\"commit_key\\":\\"${parentTask.key.parent?.id}\\"}',
      );
      expect(await tester.post(handler), Body.empty);
    });

    test('trigger dependent builds', () async {
      final Commit commit = generateCommit(1);
      final Task parentTask = generateTask(
        1,
        name: 'Linux build',
        parent: commit,
      );
      config.db.values[commit.key] = commit;
      config.db.values[parentTask.key] = parentTask;
      tester.message = createBuildbucketPushMessage(
        'COMPLETED',
        result: 'SUCCESS',
        builderName: '',
        userData: '{\\"task_key\\":\\"${parentTask.key.id}\\", \\"commit_key\\":\\"${parentTask.key.parent?.id}\\"}',
      );

      expect(config.db.values.values.whereType<Task>(), hasLength(1));

      await tester.post(handler);

      expect(config.db.values.values.whereType<Task>(), hasLength(2));
      final Task? task =
          config.db.values.values.whereType<Task>().firstWhereOrNull((Task task) => task.name == 'Linux test');
      expect(task, isNotNull);
      expect(task!.status, Task.statusInProgress);
    });

    test('ack when there are no dependencies', () async {
      final Commit commit = generateCommit(1);
      final Task parentTask = generateTask(
        1,
        name: 'Linux test',
        parent: commit,
      );
      config.db.values[commit.key] = commit;
      config.db.values[parentTask.key] = parentTask;
      tester.message = createBuildbucketPushMessage(
        'COMPLETED',
        result: 'SUCCESS',
        builderName: '',
        userData: '{\\"task_key\\":\\"${parentTask.key.id}\\", \\"commit_key\\":\\"${parentTask.key.parent?.id}\\"}',
      );

      expect(config.db.values.values.whereType<Task>(), hasLength(1));

      await tester.post(handler);

      expect(config.db.values.values.whereType<Task>(), hasLength(1));
    });
  });
}
