// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_service/cocoon_service.dart';
import 'package:cocoon_service/server.dart';
import 'package:cocoon_service/src/service/commit_service.dart';
import 'package:cocoon_service/src/service/github_checks_service_v2.dart';
import 'package:test/test.dart';

import 'src/datastore/fake_config.dart';
import 'src/request_handling/fake_authentication.dart';
import 'src/service/fake_build_bucket_v2_client.dart';
import 'src/service/fake_buildbucket.dart';
import 'src/service/fake_gerrit_service.dart';
import 'src/service/fake_luci_build_service.dart';
import 'src/service/fake_luci_build_service_v2.dart';
import 'src/service/fake_scheduler.dart';
import 'src/service/fake_scheduler_v2.dart';

void main() {
  test('verify server can be created', () {
    createServer(
      config: FakeConfig(
        webhookKeyValue: 'fake-secret',
      ),
      cache: CacheService(inMemory: true),
      authProvider: FakeAuthenticationProvider(),
      swarmingAuthProvider: FakeAuthenticationProvider(),
      branchService: BranchService(config: FakeConfig(), gerritService: FakeGerritService()),
      buildBucketClient: FakeBuildBucketClient(),
      buildBucketV2Client: FakeBuildBucketV2Client(),
      luciBuildService: FakeLuciBuildService(config: FakeConfig()),
      luciBuildServiceV2: FakeLuciBuildServiceV2(config: FakeConfig()),
      githubChecksService: GithubChecksService(FakeConfig()),
      githubChecksServiceV2: GithubChecksServiceV2(FakeConfig()),
      commitService: CommitService(config: FakeConfig()),
      gerritService: FakeGerritService(),
      scheduler: FakeScheduler(config: FakeConfig()),
      schedulerV2: FakeSchedulerV2(config: FakeConfig()),
    );
  });
}
