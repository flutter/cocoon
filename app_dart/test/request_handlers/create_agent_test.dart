// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_service/src/model/appengine/agent.dart';
import 'package:cocoon_service/src/request_handlers/create_agent.dart';
import 'package:cocoon_service/src/request_handling/exceptions.dart';
import 'package:cocoon_service/src/service/datastore.dart';
import 'package:gcloud/db.dart';
import 'package:test/test.dart';

import '../src/datastore/fake_config.dart';
import '../src/request_handling/api_request_handler_tester.dart';
import '../src/request_handling/fake_authentication.dart';

void main() {
  group('CreateAgent', () {
    FakeConfig config;
    ApiRequestHandlerTester tester;
    CreateAgent handler;
    List<String> capabilities;

    setUp(() {
      config = FakeConfig();
      tester = ApiRequestHandlerTester();
      capabilities = <String>['test1', 'test2'];
      tester.requestData = <String, dynamic>{
        'AgentID': 'test',
        'Capabilities': capabilities,
      };
      handler = CreateAgent(
        config,
        FakeAuthenticationProvider(),
        datastoreProvider: (DatastoreDB db) => DatastoreService(config.db, 5),
      );
    });

    test('Return exception when adding an existing agent', () async {
      final Agent agent = Agent(key: config.db.emptyKey.append(Agent, id: 'test'), agentId: 'test');
      config.db.values[agent.key] = agent;

      expect(() => tester.post(handler), throwsA(isA<BadRequestException>()));
    });

    test('Return token when adding a valid agent', () async {
      final Agent agent = Agent(key: config.db.emptyKey.append(Agent, id: 'abc'), agentId: 'def');
      config.db.values[agent.key] = agent;

      expect(config.db.values.length, 1);

      final CreateAgentResponse response = await tester.post(handler);

      expect(response.token, isNotNull);
      expect(config.db.values.length, 2);
    });
  });
}
