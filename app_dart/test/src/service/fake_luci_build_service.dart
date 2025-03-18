// Copyright 2021 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_service/src/foundation/github_checks_util.dart';
import 'package:cocoon_service/src/foundation/utils.dart';
import 'package:cocoon_service/src/request_handling/pubsub.dart';
import 'package:cocoon_service/src/service/build_bucket_client.dart';
import 'package:cocoon_service/src/service/cache_service.dart';
import 'package:cocoon_service/src/service/gerrit_service.dart';
import 'package:cocoon_service/src/service/luci_build_service.dart';

import '../request_handling/fake_pubsub.dart';
import '../utilities/mocks.dart';
import 'fake_build_bucket_client.dart';
import 'fake_fusion_tester.dart';
import 'fake_gerrit_service.dart';

/// Fake [LuciBuildService] for use in tests.
class FakeLuciBuildService extends LuciBuildService {
  FakeLuciBuildService({
    required super.config,
    BuildBucketClient? buildBucketClient,
    GithubChecksUtil? githubChecksUtil,
    GerritService? gerritService,
    PubSub? pubsub,
    FusionTester? fusionTester,
  }) : super(
         cache: CacheService(inMemory: true),
         buildBucketClient: buildBucketClient ?? FakeBuildBucketClient(),
         githubChecksUtil: githubChecksUtil ?? MockGithubChecksUtil(),
         gerritService: gerritService ?? FakeGerritService(),
         pubsub: pubsub ?? FakePubSub(),
         fusionTester: fusionTester ?? FakeFusionTester(),
       );
}
