// Copyright 2021 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_service/src/foundation/github_checks_util.dart';
import 'package:cocoon_service/src/request_handling/pubsub.dart';
import 'package:cocoon_service/src/service/buildbucket.dart';
import 'package:cocoon_service/src/service/config.dart';
import 'package:cocoon_service/src/service/gerrit_service.dart';
import 'package:cocoon_service/src/service/luci_build_service.dart';

import '../request_handling/fake_pubsub.dart';
import '../utilities/mocks.dart';
import 'fake_buildbucket.dart';

/// Fake [LuciBuildService] for use in tests.
class FakeLuciBuildService extends LuciBuildService {
  FakeLuciBuildService(
    Config config, {
    BuildBucketClient? buildbucket,
    GithubChecksUtil? githubChecksUtil,
    GerritService? gerritService,
    PubSub? pubsub,
  }) : super(
          config,
          buildbucket ?? FakeBuildBucketClient(),
          githubChecksUtil: githubChecksUtil ?? MockGithubChecksUtil(),
          gerritService: gerritService ?? MockGerritService(),
          pubsub: pubsub ?? FakePubSub(),
        );
}
