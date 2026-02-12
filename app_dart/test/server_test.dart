// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_integration_test/testing.dart';
import 'package:cocoon_service/cocoon_service.dart';
import 'package:cocoon_service/server.dart';
import 'package:cocoon_service/src/service/commit_service.dart';
import 'package:test/test.dart';

void main() {
  test('verify server can be created', () {
    final firestore = FakeFirestoreService();
    final bigQuery = MockBigQueryService();
    createServer(
      config: FakeConfig(webhookKeyValue: 'fake-secret'),
      cache: CacheService(inMemory: true),
      authProvider: FakeDashboardAuthentication(),
      swarmingAuthProvider: FakeDashboardAuthentication(),
      branchService: BranchService(
        config: FakeConfig(),
        gerritService: FakeGerritService(),
      ),
      buildBucketClient: FakeBuildBucketClient(),
      luciBuildService: FakeLuciBuildService(
        config: FakeConfig(),
        firestore: firestore,
      ),
      githubChecksService: GithubChecksService(FakeConfig()),
      commitService: CommitService(config: FakeConfig(), firestore: firestore),
      gerritService: FakeGerritService(),
      scheduler: FakeScheduler(
        config: FakeConfig(),
        firestore: firestore,
        bigQuery: bigQuery,
      ),
      ciYamlFetcher: FakeCiYamlFetcher(),
      buildStatusService: FakeBuildStatusService(),
      firestore: firestore,
      bigQuery: bigQuery,
      contentAwareHashService: FakeContentAwareHashService(
        config: FakeConfig(webhookKeyValue: 'fake-secret'),
      ),
    );
  });
}
