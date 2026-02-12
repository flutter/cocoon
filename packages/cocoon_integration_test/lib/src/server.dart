// Copyright 2026 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_service/cocoon_service.dart';
import 'package:cocoon_service/server.dart';
import 'package:cocoon_service/src/service/build_status_service.dart';
import 'package:cocoon_service/src/service/commit_service.dart';
import 'package:retry/retry.dart';

import '../testing.dart';

class IntegrationServer {
  IntegrationServer({
    FakeConfig? config,
    FakeFirestoreService? firestore,
    FakeBigQueryService? bigQuery,
    FakeDashboardAuthentication? authProvider,
    FakeDashboardAuthentication? swarmingAuthProvider,
    FakeGerritService? gerritService,
    FakeBuildBucketClient? buildBucketClient,
    FakeLuciBuildService? luciBuildService,
    FakeScheduler? scheduler,
    FakeCiYamlFetcher? ciYamlFetcher,
    BuildStatusService? buildStatusService,
    FakeContentAwareHashService? contentAwareHashService,
    CacheService? cache,
  }) {
    this.config = config ?? FakeConfig(webhookKeyValue: 'fake-secret');
    this.firestore = firestore ?? FakeFirestoreService();
    this.bigQuery = bigQuery ?? FakeBigQueryService();
    this.authProvider = authProvider ?? FakeDashboardAuthentication();
    this.swarmingAuthProvider =
        swarmingAuthProvider ?? FakeDashboardAuthentication();
    this.gerritService = gerritService ?? FakeGerritService();
    this.buildBucketClient = buildBucketClient ?? FakeBuildBucketClient();
    this.luciBuildService =
        luciBuildService ??
        FakeLuciBuildService(config: this.config, firestore: this.firestore);
    this.scheduler =
        scheduler ??
        FakeScheduler(
          config: this.config,
          firestore: this.firestore,
          bigQuery: this.bigQuery,
        );
    this.ciYamlFetcher = ciYamlFetcher ?? FakeCiYamlFetcher();
    this.buildStatusService =
        buildStatusService ??
        BuildStatusService(firestore: this.firestore, config: this.config);
    this.contentAwareHashService =
        contentAwareHashService ??
        FakeContentAwareHashService(config: this.config);
    this.cache = cache ?? FakeCacheService();

    server = createServer(
      config: this.config,
      firestore: this.firestore,
      bigQuery: this.bigQuery,
      cache: this.cache,
      authProvider: this.authProvider,
      swarmingAuthProvider: this.swarmingAuthProvider,
      branchService: BranchService(
        config: this.config,
        gerritService: this.gerritService,
        retryOptions: const RetryOptions(maxAttempts: 1),
      ),
      buildBucketClient: this.buildBucketClient,
      luciBuildService: this.luciBuildService,
      githubChecksService: GithubChecksService(this.config),
      commitService: CommitService(
        config: this.config,
        firestore: this.firestore,
      ),
      gerritService: this.gerritService,
      scheduler: this.scheduler,
      ciYamlFetcher: this.ciYamlFetcher,
      buildStatusService: this.buildStatusService,
      contentAwareHashService: this.contentAwareHashService,
    );
  }

  late final Server server;
  late final FakeConfig config;
  late final FakeFirestoreService firestore;
  late final FakeBigQueryService bigQuery;
  late final FakeDashboardAuthentication authProvider;
  late final FakeDashboardAuthentication swarmingAuthProvider;
  late final FakeGerritService gerritService;
  late final FakeBuildBucketClient buildBucketClient;
  late final FakeLuciBuildService luciBuildService;
  late final FakeScheduler scheduler;
  late final FakeCiYamlFetcher ciYamlFetcher;
  late final BuildStatusService buildStatusService;
  late final FakeContentAwareHashService contentAwareHashService;
  late final CacheService cache;
}
