// Copyright 2026 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:cocoon_service/cocoon_service.dart';
import 'package:cocoon_service/server.dart';
import 'package:cocoon_service/src/service/commit_service.dart';

import '../testing.dart';

class IntegrationServer {
  IntegrationServer._(this.server, this.config, this.firestore);

  final Server server;
  final FakeConfig config;
  final FakeFirestoreService firestore;
  
  static Future<IntegrationServer> start() async {
    final config = FakeConfig(webhookKeyValue: 'fake-secret');
    final firestore = FakeFirestoreService();
    final bigQuery = FakeBigQueryService();
    final cache = CacheService(inMemory: true);
    
    final server = createServer(
      config: config,
      firestore: firestore,
      bigQuery: bigQuery,
      cache: cache,
      authProvider: FakeDashboardAuthentication(),
      swarmingAuthProvider: FakeDashboardAuthentication(),
      branchService: BranchService(config: config, gerritService: FakeGerritService()),
      buildBucketClient: FakeBuildBucketClient(),
      luciBuildService: FakeLuciBuildService(config: config, firestore: firestore),
      githubChecksService: GithubChecksService(config),
      commitService: CommitService(config: config, firestore: firestore),
      gerritService: FakeGerritService(),
      scheduler: FakeScheduler(config: config, firestore: firestore, bigQuery: bigQuery),
      ciYamlFetcher: FakeCiYamlFetcher(),
      buildStatusService: FakeBuildStatusService(),
      contentAwareHashService: FakeContentAwareHashService(config: config),
    );

    return IntegrationServer._(server, config, firestore);
  }
}
