// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io' as io;

import 'package:cocoon_integration_test/testing.dart';
import 'package:cocoon_server_test/fake_secret_manager.dart';
import 'package:cocoon_service/cocoon_service.dart';
import 'package:cocoon_service/server.dart';
import 'package:cocoon_service/src/request_handling/http_io.dart';
import 'package:cocoon_service/src/service/build_status_service.dart';
import 'package:cocoon_service/src/service/commit_service.dart';
import 'package:cocoon_service/src/service/firebase_jwt_validator.dart';
import 'package:cocoon_service/src/service/get_files_changed.dart';
import 'package:cocoon_service/src/service/log_analyzer.dart';
import 'package:cocoon_service/src/service/scheduler/ci_yaml_fetcher.dart';
import 'package:http/http.dart' as http;

Future<void> main() async {
  final cache = CacheService.inMemory();
  final secretManager = FakeSecretManager()
    ..putString('APP_DART_GEMINI_LOG_ANALYZER_KEY', 'dummy_key')
    ..putString('APP_DART_WEBHOOK_KEY', 'dummy_webhook_key')
    ..putString('APP_DART_FROB_WEBHOOK_KEY', 'dummy_frob_webhook_key');
  final config = Config(
    cache,
    secretManager,
    initialConfig: DynamicConfig.fromJson({}),
    httpClient: MappingHttpClient(http.Client()),
  );
  final firestore = FakeFirestoreService();
  final bigQuery = FakeBigQueryService();

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
    authClient: config.httpClient,
  );

  /// LUCI service class to communicate with buildBucket service.
  final luciBuildService = LuciBuildService(
    config: config,
    cache: cache,
    buildBucketClient: buildBucketClient,
    gerritService: gerritService,
    pubsub: const PubSub(),
    firestore: firestore,
  );

  /// Github checks api service used to provide luci test execution status on the Github UI.
  final githubChecksService = GithubChecksService(config);

  final ciYamlFetcher = CiYamlFetcher(
    config: config,
    cache: cache,
    firestore: firestore,
  );

  final contentHashService = FakeContentAwareHashService(config: config);

  /// Cocoon scheduler service to manage validating commits in presubmit and postsubmit.
  final scheduler = Scheduler(
    cache: cache,
    config: config,
    githubChecksService: githubChecksService,
    githubService: FakeGithubService(),
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
    logAnalyzer: FakeLogAnalyzer(),
  );

  final port = int.tryParse(io.Platform.environment['PORT'] ?? '') ?? 8080;
  final httpServer = await io.HttpServer.bind(io.InternetAddress.anyIPv6, port);
  print('Serving requests at http://localhost:${httpServer.port}/');
  await for (final request in httpServer) {
    try {
      await server(request.toRequest());
    } catch (e, s) {
      io.stderr.writeln('Error processing request: $e\n$s');
      try {
        request.response.statusCode = io.HttpStatus.internalServerError;
      } catch (_) {
        // Headers may already have been sent.
      }
      try {
        await request.response.close();
      } catch (_) {
        // Response may already be closed or the client disconnected.
      }
    }
  }
}
