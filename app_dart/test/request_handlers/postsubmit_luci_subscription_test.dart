// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_service/cocoon_service.dart';
import 'package:cocoon_service/src/model/appengine/commit.dart';
import 'package:cocoon_service/src/model/appengine/task.dart';
import 'package:cocoon_service/src/request_handling/exceptions.dart';
import 'package:cocoon_service/src/service/datastore.dart';
import 'package:gcloud/db.dart';
import 'package:test/test.dart';

import '../src/datastore/fake_config.dart';
import '../src/request_handling/fake_authentication.dart';
import '../src/request_handling/fake_http.dart';
import '../src/request_handling/subscription_tester.dart';
import '../src/utilities/entity_generators.dart';
import '../src/utilities/push_message.dart';

void main() {
  late PostsubmitLuciSubscription handler;
  late FakeConfig config;
  late FakeHttpRequest request;
  late SubscriptionTester tester;

  const String rawKey =
      'ahFmbHV0dGVyLWRhc2hib2FyZHJfCxIJQ2hlY2tsaXN0Ij9mbHV0dGVyL2ZsdXR0ZXIvbWFzdGVyLzg3Zjg4NzM0NzQ3ODA1NTg5ZjIxMzE3NTM2MjBkNjFiMjI5MjI4MjIMCxIEVGFzaxiAgNiftvKACAw';

  setUp(() async {
    config = FakeConfig();
    handler = PostsubmitLuciSubscription(
      config,
      FakeAuthenticationProvider(),
      datastoreProvider: (_) => DatastoreService(config.db, 5),
    );
    request = FakeHttpRequest();

    tester = SubscriptionTester(
      request: request,
    );
  });

  test('throws exception when task key is not in message', () async {
    tester.message = pushMessageJson(
      'COMPLETED',
      result: 'SUCCESS',
      userData: '{}',
    );

    expect(() => tester.post(handler), throwsA(isA<BadRequestException>()));
  });

  test('throws exception if task key does not exist in datastore', () {
    tester.message = pushMessageJson(
      'COMPLETED',
      result: 'SUCCESS',
      userData: '{\\"task_key\\":\\"$rawKey\\"}',
    );

    expect(() => tester.post(handler), throwsA(isA<KeyNotFoundException>()));
  });

  test('updates task based on message', () async {
    final Commit commit = generateCommit(1, sha: '87f88734747805589f2131753620d61b22922822');
    final Task task = generateTask(
      4507531199512576,
      parent: commit,
    );

    tester.message = pushMessageJson(
      'COMPLETED',
      result: 'SUCCESS',
      userData: '{\\"task_key\\":\\"$rawKey\\"}',
    );

    config.db.values[task.key] = task;

    expect(task.status, Task.statusNew);
    expect(task.endTimestamp, 0);

    await tester.post(handler);

    expect(task.status, Task.statusSucceeded);
    expect(task.endTimestamp, 123);
  });
}
