// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:cocoon_service/src/model/appengine/agent.dart';
import 'package:cocoon_service/src/request_handlers/update_status_cache.dart';
import 'package:cocoon_service/src/request_handling/body.dart';
import 'package:cocoon_service/src/service/build_status_provider.dart';
import 'package:cocoon_service/src/service/datastore.dart';
import 'package:neat_cache/cache_provider.dart';
import 'package:neat_cache/neat_cache.dart';
import 'package:test/test.dart';

import '../src/datastore/fake_cocoon_config.dart';
import '../src/datastore/fake_datastore.dart';
import '../src/service/fake_build_status_provider.dart';

void main() {
  group('UpdateStatusCache', () {
    FakeConfig config;
    FakeDatastoreDB db;
    FakeBuildStatusProvider buildStatusProvider;
    UpdateStatusCache handler;
    CacheProvider<List<int>> cacheProvider;
    Cache<List<int>> cache;

    Future<Object> decodeHandlerBody() async {
      final Body body = await handler.get();
      return utf8.decoder.bind(body.serialize()).transform(json.decoder).single;
    }

    setUp(() async {
      config = FakeConfig(redisResponseSubcacheValue: 'update_status_cache_test');
      buildStatusProvider =
          FakeBuildStatusProvider(commitStatuses: <CommitStatus>[]);
      db = FakeDatastoreDB();
      cacheProvider = Cache.inMemoryCacheProvider(16);
      cache = Cache<List<int>>(cacheProvider);

      handler = UpdateStatusCache(
        config,
        cache: cache,
        datastoreProvider: () => DatastoreService(db: db),
        buildStatusProvider: buildStatusProvider,
      );
    });

    tearDown(() async {
      await cacheProvider.close();
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

    test('stores response in cache', () async {
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

      final Cache<String> responseCache =
          cache.withPrefix(await config.redisResponseSubcache).withCodec(utf8);

      final String storedValue = await responseCache['get-status'].get();
      final Map<String, dynamic> storedJsonResponse = jsonDecode(storedValue);

      expect(storedJsonResponse, result);
    });
  });
}
