// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_service/src/model/appengine/commit.dart';
import 'package:cocoon_service/src/request_handlers/migrate_checklist.dart';
import 'package:cocoon_service/src/service/datastore.dart';
import 'package:googleapis/bigquery/v2.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import '../src/datastore/fake_cocoon_config.dart';
import '../src/request_handling/api_request_handler_tester.dart';
import '../src/request_handling/fake_authentication.dart';

void main() {
  group('MigrateCheklist', () {
    FakeConfig config;
    ApiRequestHandlerTester tester;
    MigrateChecklist handler;
    MockTabledataResourceApi mockTabledataResourceApi;

    setUp(() {
      config = FakeConfig();
      tester = ApiRequestHandlerTester();
      mockTabledataResourceApi = MockTabledataResourceApi();
      handler = MigrateChecklist(
        config,
        FakeAuthenticationProvider(),
        datastoreProvider: () => DatastoreService(db: config.db),
        tabledataResourceApi: mockTabledataResourceApi,
      );
    });

    test('migrate checklist from datastore to bigquery', () async {
      final Commit commit = Commit(
          key: config.db.emptyKey.append(Commit, id: 'test'), sha: 'test');
      config.db.values[commit.key] = commit;
      const String projectId = 'test';
      const String dataset = 'test';
      const String table = 'test';
      final TableDataInsertAllRequest rows =
          TableDataInsertAllRequest.fromJson(<String, Object>{
        'rows': <Map<String, Object>>[
          <String, Object>{
            'json': <String, Object>{
              'ID': commit.id,
              'CreateTimestamp': commit.timestamp,
              'FlutterRepositoryPath': commit.repository,
              'CommitSha': commit.sha,
              'CommitAuthorLogin': commit.author,
              'CommitAuthorAvatarURL': commit.authorAvatarUrl,
            },
          }
        ],
      });

      when(mockTabledataResourceApi.insertAll(rows, projectId, dataset, table)).thenAnswer((_) {
          return Future<TableDataInsertAllResponse>.value(null);
        });
        
      expect(commit.isExported, false);

      final MigrateChecklistResponse response = await tester.get(handler);

      expect(response.response.length, 1);
      expect(response.response[0].isExported, true);
    });
  });
}

class MockTabledataResourceApi extends Mock implements TabledataResourceApi {}