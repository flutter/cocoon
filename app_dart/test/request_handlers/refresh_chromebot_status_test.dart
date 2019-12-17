// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_service/src/model/appengine/commit.dart';
import 'package:cocoon_service/src/model/appengine/task.dart';
import 'package:cocoon_service/src/request_handlers/refresh_chromebot_status.dart';
import 'package:cocoon_service/src/service/datastore.dart';
import 'package:cocoon_service/src/service/luci.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import '../src/datastore/fake_cocoon_config.dart';
import '../src/request_handling/api_request_handler_tester.dart';
import '../src/request_handling/fake_authentication.dart';

void main() {
  group('RefreshChromebotStatus', () {
    FakeConfig config;
    ApiRequestHandlerTester tester;
    MockLuciService mockLuciService;
    RefreshChromebotStatus handler;

    setUp(() {
      config = FakeConfig(
        luciBuildersValue: const <Map<String, String>>[
          <String, String>{
            'name': 'Builder1',
            'repo': 'flutter',
            'taskName': 'foo',
          },
        ],
      );
      tester = ApiRequestHandlerTester();
      mockLuciService = MockLuciService();
      handler = RefreshChromebotStatus(
        config,
        FakeAuthenticationProvider(),
        luciServiceProvider: (_) => mockLuciService,
        datastoreProvider: () => DatastoreService(db: config.db),
      );
    });

    test('updates datastore entry for task', () async {
      final Commit commit =
          Commit(key: config.db.emptyKey.append(Commit, id: 'abc'), sha: 'abc');
      final Task task = Task(key: commit.key.append(Task, id: 123));
      config.db.values[commit.key] = commit;
      config.db.values[task.key] = task;

      final Map<LuciBuilder, List<LuciTask>> luciTasks =
          Map<LuciBuilder, List<LuciTask>>.fromIterable(
        await LuciBuilder.getBuilders(config),
        key: (dynamic builder) => builder,
        value: (dynamic builder) => <LuciTask>[
          const LuciTask(commitSha: 'abc', status: Task.statusNew),
          const LuciTask(commitSha: 'abc', status: Task.statusFailed)
        ],
      );
      when(mockLuciService.getRecentTasks(
              repo: 'flutter', requireTaskName: true))
          .thenAnswer((Invocation invocation) {
        return Future<Map<LuciBuilder, List<LuciTask>>>.value(luciTasks);
      });

      expect(task.status, isNot(Task.statusNew));
      await tester.get(handler);
      expect(task.status, Task.statusNew);
    });
  });
}

// ignore: must_be_immutable
class MockLuciService extends Mock implements LuciService {}
