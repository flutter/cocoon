// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';
import 'dart:math';

import 'package:appengine/appengine.dart';
import 'package:cocoon_service/cocoon_service.dart';
import 'package:gcloud/db.dart';

/// For local development, you might want to set this to true.
const String _kCocoonUseInMemoryCache = 'COCOON_USE_IN_MEMORY_CACHE';

Future<void> main() async {
  await withAppEngineServices(() async {
    final bool inMemoryCache = Platform.environment[_kCocoonUseInMemoryCache] == 'true';
    final CacheService cache = CacheService(inMemory: inMemoryCache);

    final Config config = Config(dbService, cache);
    final AuthenticationProvider authProvider = AuthenticationProvider(config);
    final AuthenticationProvider swarmingAuthProvider = SwarmingAuthenticationProvider(config);
    final BuildBucketClient buildBucketClient = BuildBucketClient(
      accessTokenService: AccessTokenService.defaultProvider(config),
    );
    final ServiceAccountInfo serviceAccountInfo = await config.deviceLabServiceAccount;

    /// LUCI service class to communicate with buildBucket service.
    final LuciBuildService luciBuildService = LuciBuildService(
      config,
      buildBucketClient,
      serviceAccountInfo,
    );

    /// Github checks api service used to provide luci test execution status on the Github UI.
    final GithubChecksService githubChecksService = GithubChecksService(
      config,
    );

    /// Cocoon scheduler service to manage validating commits in presubmit and postsubmit.
    final Scheduler scheduler = Scheduler(
      cache: cache,
      config: config,
      githubChecksService: githubChecksService,
      luciBuildService: luciBuildService,
    );

    final Map<String, RequestHandler<dynamic>> handlers = <String, RequestHandler<dynamic>>{
      '/api/check-waiting-pull-requests': CheckForWaitingPullRequests(config, authProvider),
      '/api/flush-cache': FlushCache(
        config,
        authProvider,
        cache: cache,
      ),
      '/api/get-authentication-status': GetAuthenticationStatus(config, authProvider),
      '/api/github-webhook-pullrequest': GithubWebhook(
        config,
        githubChecksService: githubChecksService,
        scheduler: scheduler,
      ),

      /// API to run authenticated graphql queries. It requires to pass the graphql query as the body
      /// of a POST request.
      '/api/query-github-graphql': QueryGithubGraphql(config, authProvider),
      '/api/luci-status-handler': LuciStatusHandler(
        config,
        buildBucketClient,
        luciBuildService,
        githubChecksService,
      ),
      '/api/push-build-status-to-github': PushBuildStatusToGithub(config, authProvider),
      '/api/push-gold-status-to-github': PushGoldStatusToGithub(config, authProvider),
      '/api/push-engine-build-status-to-github': PushEngineStatusToGithub(
        config,
        authProvider,
        luciBuildService,
        scheduler: scheduler,
      ),
      '/api/refresh-chromebot-status': RefreshChromebotStatus(
        config,
        authProvider,
        luciBuildService,
        scheduler: scheduler,
      ),
      '/api/reset-prod-task': ResetProdTask(
        config,
        authProvider,
        luciBuildService,
      ),
      '/api/reset-try-task': ResetTryTask(
        config,
        authProvider,
        scheduler,
      ),
      '/api/update-task-status': UpdateTaskStatus(config, swarmingAuthProvider),
      '/api/vacuum-github-commits': VacuumGithubCommits(
        config,
        authProvider,
        scheduler: scheduler,
      ),
      '/api/public/build-status': CacheRequestHandler<Body>(
        cache: cache,
        config: config,
        delegate: GetBuildStatus(config),
        ttl: const Duration(seconds: 15),
      ),
      '/api/public/get-status': CacheRequestHandler<Body>(
        cache: cache,
        config: config,
        delegate: GetStatus(config),
      ),
      '/api/public/get-branches': CacheRequestHandler<Body>(
        cache: cache,
        config: config,
        delegate: GetBranches(config),
        ttl: const Duration(minutes: 15),
      ),
      '/api/public/github-rate-limit-status': CacheRequestHandler<Body>(
        config: config,
        cache: cache,
        ttl: const Duration(minutes: 1),
        delegate: GithubRateLimitStatus(config),
      ),

      /// Handler for AppEngine to identify when dart server is ready to serve requests.
      '/readiness_check': ReadinessCheck(),
    };

    return await runAppEngine((HttpRequest request) async {
      final RequestHandler<dynamic> handler = handlers[request.uri.path];
      if (handler != null) {
        await handler.service(request);
      } else {
        /// Requests with query parameters and anchors need to be trimmed to get the file path.
        // TODO(chillers): Use toFilePath(), https://github.com/dart-lang/sdk/issues/39373
        final int queryIndex = request.uri.path.contains('?') ? request.uri.path.indexOf('?') : request.uri.path.length;
        final int anchorIndex =
            request.uri.path.contains('#') ? request.uri.path.indexOf('#') : request.uri.path.length;

        /// Trim to the first instance of an anchor or query.
        final int trimIndex = min(queryIndex, anchorIndex);
        final String filePath = request.uri.path.substring(0, trimIndex);

        const Map<String, String> redirects = <String, String>{
          '/build.html': '/#/build',
          '/repository': '/repository/index.html',
          '/repository/': '/repository/index.html',
          '/repository.html': '/repository/index.html',
        };
        if (redirects.containsKey(filePath)) {
          request.response.statusCode = HttpStatus.permanentRedirect;
          return await request.response.redirect(Uri.parse(redirects[filePath]));
        }

        await StaticFileHandler(filePath, config: config).service(request);
      }
    }, onAcceptingConnections: (InternetAddress address, int port) {
      final String host = address.isLoopback ? 'localhost' : address.host;
      print('Serving requests at http://$host:$port/');
    });
  });
}
