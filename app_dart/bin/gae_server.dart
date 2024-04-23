// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:appengine/appengine.dart';
import 'package:cocoon_service/cocoon_service.dart';
import 'package:cocoon_service/server.dart';
import 'package:cocoon_service/src/service/build_bucket_v2_client.dart';
import 'package:cocoon_service/src/service/commit_service.dart';
// import 'package:cocoon_service/src/service/github_checks_service_v2.dart';
// import 'package:cocoon_service/src/service/luci_build_service_v2.dart';
// import 'package:cocoon_service/src/service/scheduler_v2.dart';
import 'package:gcloud/db.dart';

Future<void> main() async {
  await withAppEngineServices(() async {
    useLoggingPackageAdaptor();

    final CacheService cache = CacheService(inMemory: false);
    final Config config = Config(dbService, cache);
    final AuthenticationProvider authProvider = AuthenticationProvider(config: config);
    final AuthenticationProvider swarmingAuthProvider = SwarmingAuthenticationProvider(config: config);

    final BuildBucketClient buildBucketClient = BuildBucketClient(
      accessTokenService: AccessTokenService.defaultProvider(config),
    );

    final BuildBucketV2Client buildBucketV2Client = BuildBucketV2Client(
      accessTokenService: AccessTokenService.defaultProvider(config),
    );

    /// LUCI service class to communicate with buildBucket service.
    final LuciBuildService luciBuildService = LuciBuildService(
      config: config,
      cache: cache,
      buildBucketClient: buildBucketClient,
      buildBucketV2Client: buildBucketV2Client,
      pubsub: const PubSub(),
    );

    // final LuciBuildServiceV2 luciBuildServiceV2 = LuciBuildServiceV2(
    //   config: config,
    //   cache: cache,
    //   buildBucketV2Client: buildBucketV2Client,
    //   pubsub: const PubSub(),
    // );

    /// Github checks api service used to provide luci test execution status on the Github UI.
    final GithubChecksService githubChecksService = GithubChecksService(
      config,
    );

    // final GithubChecksServiceV2 githubChecksServiceV2 = GithubChecksServiceV2(
    //   config,
    // );

    // Gerrit service class to communicate with GoB.
    final GerritService gerritService = GerritService(config: config);

    /// Cocoon scheduler service to manage validating commits in presubmit and postsubmit.
    final Scheduler scheduler = Scheduler(
      cache: cache,
      config: config,
      githubChecksService: githubChecksService,
      luciBuildService: luciBuildService,
    );

    // final SchedulerV2 schedulerV2 = SchedulerV2(
    //   cache: cache,
    //   config: config,
    //   githubChecksService: githubChecksServiceV2,
    //   luciBuildService: luciBuildServiceV2,
    // );

    final BranchService branchService = BranchService(
      config: config,
      gerritService: gerritService,
    );

    final CommitService commitService = CommitService(config: config);

    final Server server = createServer(
      config: config,
      cache: cache,
      authProvider: authProvider,
      branchService: branchService,
      buildBucketClient: buildBucketClient,
      gerritService: gerritService,
      scheduler: scheduler,
      luciBuildService: luciBuildService,
      githubChecksService: githubChecksService,
      commitService: commitService,
      swarmingAuthProvider: swarmingAuthProvider,
    );

    return runAppEngine(
      server,
      onAcceptingConnections: (InternetAddress address, int port) {
        final String host = address.isLoopback ? 'localhost' : address.host;
        print('Serving requests at http://$host:$port/');
      },
    );
  });
}
