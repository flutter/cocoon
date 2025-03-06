// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_service/cocoon_service.dart';
import 'package:cocoon_service/server.dart';
import 'package:cocoon_service/src/service/commit_service.dart';
import 'package:test/test.dart';

import 'src/datastore/fake_config.dart';
import 'src/request_handling/fake_authentication.dart';
import 'src/service/fake_build_bucket_client.dart';
import 'src/service/fake_fusion_tester.dart';
import 'src/service/fake_gerrit_service.dart';
import 'src/service/fake_luci_build_service.dart';
import 'src/service/fake_scheduler.dart';

void main() {
  test('verify server can be created', () {
    createServer(
      config: FakeConfig(
        webhookKeyValue: 'fake-secret',
      ),
      cache: CacheService(inMemory: true),
      authProvider: FakeAuthenticationProvider(),
      swarmingAuthProvider: FakeAuthenticationProvider(),
      branchService: BranchService(
        config: FakeConfig(),
        gerritService: FakeGerritService(),
      ),
      buildBucketClient: FakeBuildBucketClient(),
      luciBuildService: FakeLuciBuildService(config: FakeConfig()),
      githubChecksService: GithubChecksService(FakeConfig()),
      commitService: CommitService(config: FakeConfig()),
      gerritService: FakeGerritService(),
      scheduler: FakeScheduler(config: FakeConfig()),
      fusionTester: FakeFusionTester(),
    );
  });
}
