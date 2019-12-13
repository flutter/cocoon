// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_service/src/model/appengine/agent.dart';
import 'package:cocoon_service/src/request_handlers/authorize_agent.dart';
import 'package:cocoon_service/src/service/datastore.dart';
import 'package:test/test.dart';

import '../src/datastore/fake_cocoon_config.dart';
import '../src/request_handling/api_request_handler_tester.dart';
import '../src/request_handling/fake_authentication.dart';

void main() {
  group('AuthorizeAgent', () {
    FakeConfig config;
    ApiRequestHandlerTester tester;
    AuthorizeAgent handler;

    setUp(() {
      config = FakeConfig();
      tester = ApiRequestHandlerTester();
      tester.requestData = <String, dynamic>{
        'AgentID': 'test',
      };
      handler = AuthorizeAgent(
        config,
        FakeAuthenticationProvider(),
        datastoreProvider: () => DatastoreService(db: config.db),
      );
    });

    test('update authorization token for agent', () async {
      final Agent agent = Agent(
          key: config.db.emptyKey.append(Agent, id: 'test'),
          agentId: 'test',
          authToken: <int>[1, 2, 3]);
      config.db.values[agent.key] = agent;

      expect(agent.agentId, 'test');
      expect(agent.authToken.length, 3);

      await tester.post(handler);

      // Length of the hashed code using [dbcrypt] is 60
      expect(agent.authToken.length, 60);
    });
  });
}
