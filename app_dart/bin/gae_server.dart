// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io' as io;

import 'package:appengine/appengine.dart';
import 'package:cocoon_server/google_auth_provider.dart';
import 'package:cocoon_server/secret_manager.dart';
import 'package:cocoon_service/cocoon_service.dart';
import 'package:cocoon_service/server.dart';
import 'package:cocoon_service/src/foundation/appengine_utils.dart';
import 'package:cocoon_service/src/foundation/providers.dart';
import 'package:cocoon_service/src/request_handling/http_io.dart';
import 'package:cocoon_service/src/service/big_query.dart';
import 'package:cocoon_service/src/service/build_status_service.dart';
import 'package:cocoon_service/src/service/commit_service.dart';
import 'package:cocoon_service/src/service/content_aware_hash_service.dart';
import 'package:cocoon_service/src/service/firebase_jwt_validator.dart';
import 'package:cocoon_service/src/service/flags/dynamic_config_updater.dart';
import 'package:cocoon_service/src/service/get_files_changed.dart';
import 'package:cocoon_service/src/service/log_analyzer.dart';
import 'package:cocoon_service/src/service/scheduler/ci_yaml_fetcher.dart';
import 'package:genkit/genkit.dart';
import 'package:genkit_google_genai/genkit_google_genai.dart';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';

Future<void> main() async {
  await withAppEngineServices(() async {
    useLoggingPackageAdaptor();

    Providers.contextProvider = () => AppEngineClientContext(context);

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
    final firestore = await FirestoreService.from(const GoogleAuthProvider());
    final bigQuery = await BigQueryService.from(const GoogleAuthProvider());

    // Start with a fresh copy of the DynamicConfig. If this throws, the server
    // will not start - which is a good thing.
    final configUpdater = DynamicConfigUpdater();
    final dynamicConfig = await configUpdater.fetchDynamicConfig();
    final config = Config(
      cache,
      await SecretManager.create(
        const GoogleAuthProvider(),
        projectId: Config.flutterGcpProjectId,
      ),
      initialConfig: dynamicConfig,
      httpClient: MappingHttpClient(http.Client()),
    );
    // Start updating the config to loop forever. If this fails, it will log
    // every ~1 minute.
    configUpdater.startUpdateLoop(config);

    final geminiKey = await config.geminiLogAnalyzerKey;
    final ai = Genkit(plugins: [googleAI(apiKey: geminiKey)]);

    final firebaseJwtValidator = FirebaseJwtValidator(cache: cache);

    const cronAuthentication = DashboardCronAuthentication();
    final firebaseAuthentication = DashboardFirebaseAuthentication(
      cache: cache,
      validator: firebaseJwtValidator,
      firestore: firestore,
    );
    final githubAuthentication = GithubAuthentication(
      cache: cache,
      config: config,
      validator: firebaseJwtValidator,
    );

    final cronAuthProvider = ChainOfAuthentication.forProviders([
      cronAuthentication,
    ]);
    final dashboardAuthProvider = ChainOfAuthentication.forProviders([
      cronAuthentication,
      firebaseAuthentication,
    ]);
    final presubmitAuthProvider = ChainOfAuthentication.forProviders([
      firebaseAuthentication,
      githubAuthentication,
    ]);

    final AuthenticationProvider swarmingAuthProvider =
        SwarmingAuthenticationProvider(config: config);

    final buildBucketClient = BuildBucketClient(
      accessTokenService: AccessTokenService.defaultProvider(config),
      httpClient: config.httpClient,
    );

    // Gerrit service class to communicate with GoB.
    final gerritService = GerritService(
      config: config,
      authClient: await const GoogleAuthProvider().createClient(
        baseClient: config.httpClient,
        scopes: [],
      ),
    );

    /// LUCI service class to communicate with buildBucket service.
    final luciBuildService = LuciBuildService(
      config: config,
      cache: cache,
      buildBucketClient: buildBucketClient,
      pubsub: const PubSub(),
      gerritService: gerritService,
      firestore: firestore,
    );

    /// Github checks api service used to provide luci test execution status on the Github UI.
    final githubChecksService = GithubChecksService(config);

    final ciYamlFetcher = CiYamlFetcher(
      config: config,
      cache: cache,
      firestore: firestore,
    );

    final contentHashService = ContentAwareHashService(
      config: config,
      firestore: firestore,
    );

    final githubService = await config.createDefaultGitHubService();

    /// Cocoon scheduler service to manage validating commits in presubmit and postsubmit.
    final scheduler = Scheduler(
      cache: cache,
      config: config,
      githubChecksService: githubChecksService,
      githubService: githubService,
      getFilesChanged: GithubApiGetFilesChanged(config),
      luciBuildService: luciBuildService,
      ciYamlFetcher: ciYamlFetcher,
      contentAwareHash: contentHashService,
      firestore: firestore,
      bigQuery: bigQuery,
    );

    final branchService = BranchService(
      config: config,
      gerritService: gerritService,
    );

    final commitService = CommitService(config: config, firestore: firestore);
    final buildStatusService = BuildStatusService(
      firestore: firestore,
      config: config,
    );

    final server = createServer(
      config: config,
      firestore: firestore,
      bigQuery: bigQuery,
      cache: cache,
      dashboardAuthProvider: dashboardAuthProvider,
      cronAuthProvider: cronAuthProvider,
      presubmitAuthProvider: presubmitAuthProvider,
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
      contentAwareHashService: contentHashService,
      logAnalyzer: GenkitLogAnalyzer(ai, modelName: config.flags.geminiModel),
    );

    return runAppEngine(
      (io.HttpRequest request) async {
        await server(request.toRequest());
      },
      onAcceptingConnections: (io.InternetAddress address, int port) {
        final host = address.isLoopback ? 'localhost' : address.host;
        print('Serving requests at http://$host:$port/');
      },
    );
  });
}
