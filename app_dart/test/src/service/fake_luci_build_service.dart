// Copyright 2021 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_service/src/foundation/github_checks_util.dart';
import 'package:cocoon_service/src/request_handling/pubsub.dart';
import 'package:cocoon_service/src/service/build_bucket_v2_client.dart';
import 'package:cocoon_service/src/service/cache_service.dart';
import 'package:cocoon_service/src/service/gerrit_service.dart';
import 'package:cocoon_service/src/service/luci_build_service_v2.dart';

import '../request_handling/fake_pubsub.dart';
import '../utilities/mocks.dart';
import 'fake_build_bucket_v2_client.dart';
import 'fake_gerrit_service.dart';

/// Fake [LuciBuildServiceV2] for use in tests.
class FakeLuciBuildServiceV2 extends LuciBuildServiceV2 {
  FakeLuciBuildServiceV2({
    required super.config,
    BuildBucketV2Client? buildBucketClient,
    GithubChecksUtil? githubChecksUtil,
    GerritService? gerritService,
    PubSub? pubsub,
  }) : super(
          cache: CacheService(inMemory: true),
          buildBucketClient: buildBucketClient ?? FakeBuildBucketV2Client(),
          githubChecksUtil: githubChecksUtil ?? MockGithubChecksUtil(),
          gerritService: gerritService ?? FakeGerritService(),
          pubsub: pubsub ?? FakePubSub(),
        );
}
