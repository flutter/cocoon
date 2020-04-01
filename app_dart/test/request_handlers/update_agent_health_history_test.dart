// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:gcloud/db.dart';
import 'package:googleapis/bigquery/v2.dart';
import 'package:test/test.dart';

import 'package:cocoon_service/cocoon_service.dart';
import 'package:cocoon_service/src/model/appengine/agent.dart';
import 'package:cocoon_service/src/request_handlers/update_agent_health_history.dart';
import 'package:cocoon_service/src/request_handling/body.dart';
import 'package:cocoon_service/src/service/datastore.dart';

import '../src/bigquery/fake_tabledata_resource.dart';
import '../src/datastore/fake_cocoon_config.dart';
import '../src/datastore/fake_datastore.dart';
import '../src/request_handling/fake_authentication.dart';
import '../src/request_handling/fake_logging.dart';

void main() {
  group('UpdateAgentHealthHistory', () {
    FakeConfig config;
    FakeDatastoreDB db;
    FakeLogging log;
    UpdateAgentHealthHistory handler;
    FakeTabledataResourceApi tabledataResourceApi;

    Future<Object> decodeHandlerBody() async {
      final Body body = await handler.get();
      return utf8.decoder.bind(body.serialize()).transform(json.decoder).single;
    }

    setUp(() {
      tabledataResourceApi = FakeTabledataResourceApi();
      db = FakeDatastoreDB();
      config =
          FakeConfig(tabledataResourceApi: tabledataResourceApi, dbValue: db);
      log = FakeLogging();
      handler = UpdateAgentHealthHistory(
        config,
        FakeAuthenticationProvider(),
        datastoreProvider: ({DatastoreDB db, int maxEntityGroups}) =>
            DatastoreService(config.db, 5),
        loggingProvider: () => log,
      );
    });

    test('inserts agents to bigquery', () async {
      final Agent linux1 = Agent(
          agentId: 'linux1',
          healthCheckTimestamp: 1,
          isHealthy: true,
          healthDetails: 'healthy');
      final Agent mac1 = Agent(
          agentId: 'mac1',
          healthCheckTimestamp: 2,
          isHealthy: true,
          healthDetails: 'healthy');
      final Agent linux5 = Agent(
          agentId: 'linux5',
          healthCheckTimestamp: 3,
          isHealthy: false,
          healthDetails: 'unhealthy');
      final Agent windows1 = Agent(
          agentId: 'windows1',
          healthCheckTimestamp: 1,
          isHealthy: true,
          healthDetails: 'healthy',
          isHidden: true);

      final List<Agent> reportedAgents = <Agent>[
        linux1,
        mac1,
        linux5,
        windows1,
      ];

      db.addOnQuery<Agent>((Iterable<Agent> agents) => reportedAgents);

      final Map<String, dynamic> result =
          await decodeHandlerBody() as Map<String, dynamic>;
      final TableDataList tableDataList =
          await tabledataResourceApi.list('test', 'test', 'test');
      final Map<String, Object> value1 =
          tableDataList.rows[0].f[0].v as Map<String, Object>;
      final Map<String, Object> value2 =
          tableDataList.rows[1].f[0].v as Map<String, Object>;
      final List<dynamic> expectedOrderedAgents = <dynamic>[
        linux1.toJson(),
        linux5.toJson(),
        mac1.toJson(),
      ];

      /// Test `BigQuery` insert.
      expect(tableDataList.totalRows, '3');
      expect(value1['Timestamp'], value2['Timestamp']);
      expect(log.records[0].message,
          'Succeeded to insert 3 rows to flutter-dashboard-cocoon-Agent');

      expect(result['AgentStatuses'], equals(expectedOrderedAgents));
    });
  });
}
