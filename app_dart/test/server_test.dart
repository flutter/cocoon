// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_service/cocoon_service.dart';
import 'package:cocoon_service/server.dart';
import 'package:cocoon_service/src/service/commit_service.dart';
import 'package:test/test.dart';

import 'src/fake_config.dart';
import 'src/request_handling/fake_dashboard_authentication.dart';
import 'src/service/fake_build_bucket_client.dart';
import 'src/service/fake_build_status_provider.dart';
import 'src/service/fake_ci_yaml_fetcher.dart';
import 'src/service/fake_firestore_service.dart';
import 'src/service/fake_gerrit_service.dart';
import 'src/service/fake_luci_build_service.dart';
import 'src/service/fake_scheduler.dart';

void main() {
  test('verify server can be created', () {
    final firestore = FakeFirestoreService();
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
      scheduler: FakeScheduler(config: FakeConfig(), firestore: firestore),
      ciYamlFetcher: FakeCiYamlFetcher(),
      buildStatusService: FakeBuildStatusService(),
      firestore: firestore,
    );
  });
}
