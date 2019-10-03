// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_service/src/model/appengine/agent.dart';
import 'package:cocoon_service/src/request_handlers/update_agent_health_history.dart';
import 'package:cocoon_service/src/service/bigquery.dart';
import 'package:test/test.dart';

import '../src/datastore/fake_cocoon_config.dart';
import '../src/request_handling/api_request_handler_tester.dart';
import '../src/request_handling/fake_authentication.dart';

void main() {
  group('UpdateAgentHealthHistory', () {
    FakeConfig config;
    ApiRequestHandlerTester tester;
    UpdateAgentHealthHistory handler;

    setUp(() {
      config = FakeConfig();
      tester = ApiRequestHandlerTester();
      tester.requestData = <String, dynamic>{
        'AgentID': 'test',
        'IsHealthy': true,
        'HealthDetails': 'bar detail'
      };
      handler = UpdateAgentHealthHistory(
        config,
        FakeAuthenticationProvider(),
        bigqueryApi: () => BigqueryService(TabledataResourceApi: config.tabledataResource),
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
