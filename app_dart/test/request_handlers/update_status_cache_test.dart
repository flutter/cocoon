// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:cocoon_service/src/model/appengine/agent.dart';
import 'package:cocoon_service/src/request_handlers/update_status_cache.dart';
import 'package:cocoon_service/src/request_handling/body.dart';
import 'package:cocoon_service/src/service/build_status_provider.dart';
import 'package:cocoon_service/src/service/datastore.dart';
import 'package:test/test.dart';

import '../src/datastore/fake_cocoon_config.dart';
import '../src/datastore/fake_datastore.dart';
import '../src/service/fake_build_status_provider.dart';

void main() {
  group('GetStatus', () {
    FakeConfig config;
    FakeDatastoreDB db;
    FakeBuildStatusProvider buildStatusProvider;
    UpdateStatusCache handler;

    Future<Object> decodeHandlerBody() async {
      final Body body = await handler.get();
      return utf8.decoder.bind(body.serialize()).transform(json.decoder).single;
    }

    setUp(() {
      config = FakeConfig();
      buildStatusProvider = FakeBuildStatusProvider(commitStatuses: <CommitStatus>[]);
      db = FakeDatastoreDB();
      handler = UpdateStatusCache(
        config,
        datastoreProvider: () => DatastoreService(db: db),
        buildStatusProvider: buildStatusProvider,
      );
    });

    test('no statuses or agents', () async {
      final Map<String, dynamic> result = await decodeHandlerBody();
      expect(result['Statuses'], isEmpty);
      expect(result['AgentStatuses'], isEmpty);
    });

    test('reports agents', () async {
      final Agent linux1 = Agent(agentId: 'linux1');
      final Agent mac1 = Agent(agentId: 'mac1');
      final Agent linux100 = Agent(agentId: 'linux100');
      final Agent linux5 = Agent(agentId: 'linux5');
      final Agent windows1 = Agent(agentId: 'windows1', isHidden: true);

      final List<Agent> reportedAgents = <Agent>[
        linux1,
        mac1,
        linux100,
        linux5,
        windows1,
      ];

      db.addOnQuery<Agent>((Iterable<Agent> agents) => reportedAgents);
      final Map<String, dynamic> result = await decodeHandlerBody();

      expect(result['Statuses'], isEmpty);

      final List<dynamic> expectedOrderedAgents = <dynamic>[
        linux1.toJson(),
        linux5.toJson(),
        linux100.toJson(),
        mac1.toJson(),
      ];

      expect(result['AgentStatuses'], equals(expectedOrderedAgents));
    });
  });
}
