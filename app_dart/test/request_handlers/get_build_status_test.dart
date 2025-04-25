// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:cocoon_server_test/test_logging.dart';
import 'package:cocoon_service/cocoon_service.dart';
import 'package:cocoon_service/src/model/firestore/task.dart';
import 'package:cocoon_service/src/service/build_status_service.dart';
import 'package:test/test.dart';

import '../src/fake_config.dart';
import '../src/request_handling/request_handler_tester.dart';
import '../src/service/fake_firestore_service.dart';
import '../src/utilities/entity_generators.dart';

void main() {
  useTestLoggerPerTest();

  late RequestHandlerTester tester;
  late GetBuildStatus handler;
  late FakeFirestoreService firestore;

  Future<T> decodeHandlerBody<T>() async {
    final body = await tester.get(handler);
    return await utf8.decoder
            .bind(body.serialize() as Stream<List<int>>)
            .transform(json.decoder)
            .single
        as T;
  }

  setUp(() {
    firestore = FakeFirestoreService();
    tester = RequestHandlerTester();
    handler = GetBuildStatus(
      config: FakeConfig(),
      buildStatusService: BuildStatusService(firestore: firestore),
    );
  });

  test('passing status', () async {
    final commit = generateFirestoreCommit(1);
    final task = generateFirestoreTask(
      1,
      status: Task.statusSucceeded,
      commitSha: commit.sha,
    );
    firestore.putDocument(commit);
    firestore.putDocument(task);

    final response = await decodeHandlerBody<Map<String, Object?>>();
    expect(response, {'buildStatus': 'success', 'failingTasks': isEmpty});
  });

  test('failing status', () async {
    final commit = generateFirestoreCommit(1);
    final taskPass = generateFirestoreTask(
      1,
      status: Task.statusSucceeded,
      commitSha: commit.sha,
    );
    final taskFail = generateFirestoreTask(
      2,
      status: Task.statusFailed,
      commitSha: commit.sha,
    );
    firestore.putDocument(commit);
    firestore.putDocument(taskPass);
    firestore.putDocument(taskFail);

    final response = await decodeHandlerBody<Map<String, Object?>>();
    expect(response, {
      'buildStatus': 'failure',
      'failingTasks': [taskFail.taskName],
    });
  });

  test('failing status from a non-default branch', () async {
    final commit = generateFirestoreCommit(
      1,
      branch: 'flutter-0.42-candidate.0',
    );
    final taskPass = generateFirestoreTask(
      1,
      status: Task.statusSucceeded,
      commitSha: commit.sha,
    );
    final taskFail = generateFirestoreTask(
      2,
      status: Task.statusFailed,
      commitSha: commit.sha,
    );
    firestore.putDocument(commit);
    firestore.putDocument(taskPass);
    firestore.putDocument(taskFail);

    tester.request!.uri = tester.request!.uri.replace(
      queryParameters: {'branch': 'flutter-0.42-candidate.0'},
    );
    final response = await decodeHandlerBody<Map<String, Object?>>();
    expect(response, {
      'buildStatus': 'failure',
      'failingTasks': [taskFail.taskName],
    });
  });
}
