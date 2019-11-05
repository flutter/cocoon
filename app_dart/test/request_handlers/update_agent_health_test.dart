// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_service/src/model/appengine/agent.dart';
import 'package:cocoon_service/src/request_handlers/update_agent_health.dart';
import 'package:cocoon_service/src/service/datastore.dart';
import 'package:googleapis/bigquery/v2.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import '../src/datastore/fake_cocoon_config.dart';
import '../src/request_handling/api_request_handler_tester.dart';
import '../src/request_handling/fake_authentication.dart';

void main() {
  group('UpdateAgentHealth', () {
    FakeConfig config;
    ApiRequestHandlerTester tester;
    UpdateAgentHealth handler;

    setUp(() {
      final MockTabledataResourceApi tabledataResourceApi = MockTabledataResourceApi();

      when(tabledataResourceApi.insertAll(any, any, any, any)).thenAnswer((_) {
        return Future<TableDataInsertAllResponse>.value(null);
      });

      config = FakeConfig(tabledataResourceApi: tabledataResourceApi);
      tester = ApiRequestHandlerTester();
      tester.requestData = <String, dynamic>{
        'AgentID': 'test',
        'IsHealthy': true,
        'HealthDetails': 'bar detail'
      };
      handler = UpdateAgentHealth(
        config,
        FakeAuthenticationProvider(),
        datastoreProvider: () => DatastoreService(db: config.db),
      );
    });

    test('updates datastore entry for agent', () async {
      final Agent agent = Agent(
          key: config.db.emptyKey.append(Agent, id: 'test'), agentId: 'test');
      config.db.values[agent.key] = agent;

      expect(agent.agentId, 'test');
      expect(agent.isHealthy, isNot(true));
      expect(agent.healthDetails, isNot('bar detail'));

      final UpdateAgentHealthResponse response = await tester.post(handler);

      expect(agent.agentId, 'test');
      expect(response.agent.isHealthy, true);
      expect(agent.healthDetails, 'bar detail');
    });
  });
}

class MockTabledataResourceApi extends Mock implements TabledataResourceApi {} 

