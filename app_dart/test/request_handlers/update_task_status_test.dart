// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_service/src/model/appengine/commit.dart';
import 'package:cocoon_service/src/model/appengine/task.dart';
import 'package:cocoon_service/src/model/firestore/task.dart' as f;
import 'package:cocoon_service/src/request_handlers/update_task_status.dart';
import 'package:cocoon_service/src/service/config.dart';
import 'package:cocoon_service/src/service/datastore.dart';
import 'package:gcloud/db.dart';
import 'package:googleapis/firestore/v1.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import '../src/bigquery/fake_tabledata_resource.dart';
import '../src/datastore/fake_config.dart';
import '../src/datastore/fake_datastore.dart';
import '../src/request_handling/api_request_handler_tester.dart';
import '../src/request_handling/fake_authentication.dart';
import '../src/utilities/entity_generators.dart';
import '../src/utilities/mocks.dart';

void main() {
  group('UpdateTaskStatus', () {
    late FakeConfig config;
    late ApiRequestHandlerTester tester;
    late MockFirestoreService mockFirestoreService;
    late UpdateTaskStatus handler;
    final FakeTabledataResource tabledataResourceApi = FakeTabledataResource();
    late Commit commit;
    const String commitSha = '78cbfbff4267643bb1913bc820f5ce8a3e591b40';
    const int taskId = 4506830800027648;

    setUp(() {
      mockFirestoreService = MockFirestoreService();
      final FakeDatastoreDB datastoreDB = FakeDatastoreDB();
      config = FakeConfig(
        dbValue: datastoreDB,
        tabledataResource: tabledataResourceApi,
        maxTaskRetriesValue: 2,
        firestoreService: mockFirestoreService,
      );
      tester = ApiRequestHandlerTester();
      handler = UpdateTaskStatus(
        config: config,
        authenticationProvider: FakeAuthenticationProvider(),
        datastoreProvider: (DatastoreDB db) => DatastoreService(config.db, 5),
      );
      commit = Commit(
        key: config.db.emptyKey.append(Commit, id: 'flutter/flutter/master/$commitSha'),
        repository: Config.flutterSlug.fullName,
        sha: commitSha,
        timestamp: 123,
      );
    });

    test('TestFlaky is false when not injected', () async {
      final f.Task firestoreTask = generateFirestoreTask(1);
      when(
        mockFirestoreService.getDocument(
          captureAny,
        ),
      ).thenAnswer((Invocation invocation) {
        return Future<Document>.value(
          firestoreTask,
        );
      });
      when(
        mockFirestoreService.batchWriteDocuments(
          captureAny,
          captureAny,
        ),
      ).thenAnswer((Invocation invocation) {
        return Future<BatchWriteResponse>.value(BatchWriteResponse());
      });
      final Task task = Task(
        key: commit.key.append(Task, id: taskId),
        name: 'integration_ui_ios',
        builderName: 'linux_integration_ui_ios',
        attempts: 1,
        status: Task.statusInProgress,
        isFlaky: false, // mark flaky so it doesn't get auto-retried
        commitKey: commit.key,
      );
      config.db.values[commit.key] = commit;
      config.db.values[task.key] = task;
      tester.requestData = <String, dynamic>{
        UpdateTaskStatus.gitBranchParam: 'master',
        UpdateTaskStatus.gitShaParam: commitSha,
        UpdateTaskStatus.newStatusParam: 'Failed',
        UpdateTaskStatus.builderNameParam: 'linux_integration_ui_ios',
      };

      await tester.post(handler);

      expect(task.isTestFlaky, false);
      expect(firestoreTask.testFlaky, false);
    });

    test('TestFlaky is true when injected', () async {
      final f.Task firestoreTask = generateFirestoreTask(1);
      when(
        mockFirestoreService.getDocument(
          captureAny,
        ),
      ).thenAnswer((Invocation invocation) {
        return Future<Document>.value(
          firestoreTask,
        );
      });
      when(
        mockFirestoreService.batchWriteDocuments(
          captureAny,
          captureAny,
        ),
      ).thenAnswer((Invocation invocation) {
        return Future<BatchWriteResponse>.value(BatchWriteResponse());
      });
      final Task task = Task(
        key: commit.key.append(Task, id: taskId),
        name: 'integration_ui_ios',
        builderName: 'linux_integration_ui_ios',
        attempts: 1,
        status: Task.statusInProgress,
        isFlaky: false, // mark flaky so it doesn't get auto-retried
        commitKey: commit.key,
      );
      config.db.values[commit.key] = commit;
      config.db.values[task.key] = task;
      tester.requestData = <String, dynamic>{
        UpdateTaskStatus.gitBranchParam: 'master',
        UpdateTaskStatus.gitShaParam: commitSha,
        UpdateTaskStatus.newStatusParam: 'Failed',
        UpdateTaskStatus.builderNameParam: 'linux_integration_ui_ios',
        UpdateTaskStatus.testFlayParam: true,
      };

      await tester.post(handler);

      expect(task.isTestFlaky, true);
      expect(firestoreTask.testFlaky, true);
    });

    test('task name requests can update tasks', () async {
      final f.Task firestoreTask = generateFirestoreTask(1);
      when(
        mockFirestoreService.getDocument(
          captureAny,
        ),
      ).thenAnswer((Invocation invocation) {
        return Future<Document>.value(
          firestoreTask,
        );
      });
      when(
        mockFirestoreService.batchWriteDocuments(
          captureAny,
          captureAny,
        ),
      ).thenAnswer((Invocation invocation) {
        return Future<BatchWriteResponse>.value(BatchWriteResponse());
      });
      final Task task = Task(
        key: commit.key.append(Task, id: taskId),
        name: 'integration_ui_ios',
        builderName: 'linux_integration_ui_ios',
        attempts: 1,
        status: Task.statusInProgress,
        isFlaky: true, // mark flaky so it doesn't get auto-retried
        commitKey: commit.key,
      );
      config.db.values[commit.key] = commit;
      config.db.values[task.key] = task;
      tester.requestData = <String, dynamic>{
        UpdateTaskStatus.gitBranchParam: 'master',
        UpdateTaskStatus.gitShaParam: commitSha,
        UpdateTaskStatus.newStatusParam: 'Failed',
        UpdateTaskStatus.builderNameParam: 'linux_integration_ui_ios',
      };

      await tester.post(handler);

      expect(task.status, 'Failed');
      expect(task.attempts, 1);
      expect(firestoreTask.status, 'Failed');
      expect(firestoreTask.attempts, 1);
    });

    test('task name requests when task does not exists returns exception', () async {
      tester.requestData = <String, dynamic>{
        UpdateTaskStatus.gitBranchParam: 'master',
        UpdateTaskStatus.gitShaParam: commitSha,
        UpdateTaskStatus.newStatusParam: 'Failed',
        UpdateTaskStatus.builderNameParam: 'linux_integration_ui_ios',
      };
      expect(tester.post(handler), throwsA(isA<KeyNotFoundException>()));
    });

    test('task name request updates when input has whitespace', () async {
      final f.Task firestoreTask = generateFirestoreTask(1);
      when(
        mockFirestoreService.getDocument(
          captureAny,
        ),
      ).thenAnswer((Invocation invocation) {
        return Future<Document>.value(
          firestoreTask,
        );
      });
      when(
        mockFirestoreService.batchWriteDocuments(
          captureAny,
          captureAny,
        ),
      ).thenAnswer((Invocation invocation) {
        return Future<BatchWriteResponse>.value(BatchWriteResponse());
      });
      config.db.values[commit.key] = commit;
      final Task cocoonTask = Task(
        key: commit.key.append(Task, id: taskId),
        name: 'integration_ui_ios',
        attempts: 0,
        isFlaky: true, // mark flaky so it doesn't get auto-retried
        commitKey: commit.key,
        status: Task.statusNew,
      );
      config.db.values[cocoonTask.key] = cocoonTask;
      final Task luciTask = Task(
        key: commit.key.append(Task, id: taskId),
        name: 'integration_ui_ios',
        builderName: 'linux_integration_ui_ios',
        attempts: 1,
        status: Task.statusInProgress,
        isFlaky: true, // mark flaky so it doesn't get auto-retried
        commitKey: commit.key,
      );
      config.db.values[luciTask.key] = luciTask;
      const int asciiLF = 10;
      final List<int> branchChars = List<int>.from('master'.codeUnits)..add(asciiLF);
      final List<int> shaChars = List<int>.from(commitSha.codeUnits)..add(asciiLF);
      tester.requestData = <String, dynamic>{
        UpdateTaskStatus.gitBranchParam: String.fromCharCodes(branchChars),
        UpdateTaskStatus.gitShaParam: String.fromCharCodes(shaChars),
        UpdateTaskStatus.newStatusParam: 'Failed',
        UpdateTaskStatus.builderNameParam: 'linux_integration_ui_ios',
      };

      await tester.post(handler);

      expect(luciTask.status, Task.statusFailed);
      expect(luciTask.attempts, 1);

      expect(cocoonTask.status, Task.statusNew);
      expect(cocoonTask.attempts, 0);
    });
  });
}
