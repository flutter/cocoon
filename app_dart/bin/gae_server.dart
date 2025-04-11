// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:appengine/appengine.dart';
import 'package:cocoon_server/google_auth_provider.dart';
import 'package:cocoon_server/secret_manager.dart';
import 'package:cocoon_service/cocoon_service.dart';
import 'package:cocoon_service/server.dart';
import 'package:cocoon_service/src/service/build_status_provider.dart';
import 'package:cocoon_service/src/service/commit_service.dart';
import 'package:cocoon_service/src/service/content_aware_hash_service.dart';
import 'package:cocoon_service/src/service/get_files_changed.dart';
import 'package:cocoon_service/src/service/scheduler/ci_yaml_fetcher.dart';
import 'package:gcloud/db.dart';
import 'package:logging/logging.dart';

Future<void> main() async {
  await withAppEngineServices(() async {
    useLoggingPackageAdaptor();

    // This is bad, and I should feel bad, but I won't because the logging system
    // is inherently bad. We're allocating the logger (or getting back one) and
    // then turning it off - there is no way to "filter". Luckily; the library
    // does not set the level for the logger, making this just a little brittle.
    hierarchicalLoggingEnabled = true;
    for (final logName in ['neat_cache', 'neat_cache:redis']) {
      final log = Logger(logName);
      log.level = Level.WARNING;
    }

    final cache = CacheService(inMemory: false);
    final config = Config(
      dbService,
      cache,
      await SecretManager.create(
        const GoogleAuthProvider(),
        projectId: Config.flutterGcpProjectId,
      ),
    );
    final authProvider = AuthenticationProvider(config: config);
    final AuthenticationProvider swarmingAuthProvider =
        SwarmingAuthenticationProvider(config: config);

    final buildBucketClient = BuildBucketClient(
      accessTokenService: AccessTokenService.defaultProvider(config),
    );

    // Gerrit service class to communicate with GoB.
    final gerritService = GerritService(
      config: config,
      authClient: await const GoogleAuthProvider().createClient(scopes: []),
    );

    /// LUCI service class to communicate with buildBucket service.
    final luciBuildService = LuciBuildService(
      config: config,
      cache: cache,
      buildBucketClient: buildBucketClient,
      pubsub: const PubSub(),
      gerritService: gerritService,
    );

    /// Github checks api service used to provide luci test execution status on the Github UI.
    final githubChecksService = GithubChecksService(config);

    final ciYamlFetcher = CiYamlFetcher(cache: cache, config: config);

    /// Cocoon scheduler service to manage validating commits in presubmit and postsubmit.
    final scheduler = Scheduler(
      cache: cache,
      config: config,
      githubChecksService: githubChecksService,
      getFilesChanged: GithubApiGetFilesChanged(config),
      luciBuildService: luciBuildService,
      ciYamlFetcher: ciYamlFetcher,
      contentAwareHash: ContentAwareHashService(config: config),
    );

    final branchService = BranchService(
      config: config,
      gerritService: gerritService,
    );

    final commitService = CommitService(config: config);
    final buildStatusService = BuildStatusService(config);

    final server = createServer(
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
      ciYamlFetcher: ciYamlFetcher,
      buildStatusService: buildStatusService,
    );

    return runAppEngine(
      server,
      onAcceptingConnections: (InternetAddress address, int port) {
        final host = address.isLoopback ? 'localhost' : address.host;
        print('Serving requests at http://$host:$port/');
      },
    );
  });
}
