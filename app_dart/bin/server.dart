// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';
import 'dart:math';

import 'package:appengine/appengine.dart';
import 'package:gcloud/db.dart';

import 'package:cocoon_service/cocoon_service.dart';

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

    /// Github status service to update the state of the build
    /// in the Github UI.
    final GithubStatusService githubStatusService = GithubStatusService(
      config,
      luciBuildService,
    );

    /// Github checks api service used to provide luci test execution status on the Github UI.
    final GithubChecksService githubChecksService = GithubChecksService(
      config,
    );

    /// Cocoon scheduler service to manage validating commits in presubmit and postsubmit.
    final Scheduler scheduler = Scheduler(
      cache: cache,
      config: config,
      luciBuildService: luciBuildService,
    );

    final Map<String, RequestHandler<dynamic>> handlers = <String, RequestHandler<dynamic>>{
      /// /api/append-log
      ///
      /// This API saves log chunks to datastore based on task key.
      /// [usage]
      ///   Cocoon agents call this API when executing build tasks
      '/api/append-log': AppendLog(config, authProvider),
      /// /api/authorize-agent
      ///
      /// This API authorizes an existing devicelab agent for cocoon, and at the same time 
      /// invalidates any previously issued authentication tokens for the given agent. It 
      /// is called via the CLI.
      /// [detail]
      ///   Authorize the agent record based on input AgentID.
      ///   Re-generates a 16-digit auth_token, which is used in cocoon/agent/config.yaml
      ///   Updates the above token’s hash in datastore
      /// [usage]
      ///   Go to build dashboard
      ///   Chrome Dev Tools > Console
      ///   cocoon.authAgent(['-a', 'agentID])
      ///   agentID follows flutter-devicelab-<platform>-<number>
      '/api/authorize-agent': AuthorizeAgent(config, authProvider),
      '/api/check-waiting-pull-requests': CheckForWaitingPullRequests(config, authProvider),
      /// /api/create-agent 
      ///
      /// This API creates an agent for cocoon, and is called via the CLI. 
      /// [detail] 
      ///   Create the agent record based on inputs AgentID and Capabilities. 
      ///   Generates a 16-digit auth_token, which is used in cocoon/agent/config.yaml 
      ///   Cocoon does not store the token, so copy it immediately and add it to the agent's configuration file 
      ///   Save the above token’s hash in datastore 
      /// [usage] 
      ///   Go to build dashboard 
      ///   Chrome Dev Tools > Console 
      ///   cocoon.createAgent(['-a', 'agentID, '-c', 'Capabilities'])
      ///   agentID follows flutter-devicelab-<platform>-<number> 
      ///   Capabilities: linux/android, linux, linux-vm, mac/ios, mac, mac/android, etc
      '/api/create-agent': CreateAgent(config, authProvider),
      '/api/flush-cache': FlushCache(
        config,
        authProvider,
        cache: cache,
      ),
      '/api/get-authentication-status': GetAuthenticationStatus(config, authProvider),
      /// /api/get-log
      ///
      /// This API fetches log chunks and append them together from datastore based on the task key.
      /// [usage]
      ///   Frontend dashboard calls this API when people click task button to view logs
      '/api/get-log': GetLog(config, authProvider),
      '/api/github-webhook-pullrequest': GithubWebhook(
        config,
        githubChecksService: githubChecksService,
        scheduler: scheduler,
      ),
      '/api/luci-status-handler': LuciStatusHandler(
        config,
        buildBucketClient,
        luciBuildService,
        githubStatusService,
        githubChecksService,
      ),
      /// /api/push-build-status-to-github
      ///
      /// This API first fetches the latest build status from datastore, and then compares
      /// it with the latest status of every open pull request. If different, this API
      /// updates the status both in Github and datastore.
      /// [detail]
      ///   Fetch the latest build status
      ///   Iterate every open PR in github
      ///   Compare the status in each PR with the latest build status
      ///   If different, then update the status in each PR
      ///   Batch-update status in datastore
      /// [usage]
      ///   Directly call via a cronjob in app engine every 1 min
      '/api/push-build-status-to-github': PushBuildStatusToGithub(config, authProvider),
      '/api/push-gold-status-to-github': PushGoldStatusToGithub(config, authProvider),
      '/api/push-engine-build-status-to-github': PushEngineStatusToGithub(config, authProvider, luciBuildService),
      '/api/refresh-chromebot-status': RefreshChromebotStatus(config, authProvider, luciBuildService),
      '/api/reserve-task': ReserveTask(config, authProvider),
      '/api/reset-devicelab-task': ResetDevicelabTask(
        config,
        authProvider,
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
      /// /api/update-agent-health
      ///
      /// This API updates Agent health status continuously to both datastore and bigquery. Datastore
      /// keeps the latest status while bigquery keeps the historical data.
      /// [usage]
      ///   Cocoon Agent calls this API when running in CI mode. Before executing any task, Agent
      ///   does pre-health check and then calls this API
      '/api/update-agent-health': UpdateAgentHealth(config, authProvider),
      '/api/update-agent-health-history': UpdateAgentHealthHistory(config, authProvider),
      /// /api/update-task-status
      ///
      /// This API updates task status when finished.
      /// [detail]
      ///   Checks to make sure task and its corresponding commit exist in datastore
      ///   Checks task status
      ///   If succeeded => update datastore and bigquery
      ///   If failed
      ///   If Attempts > maxRetries => update datastore and bigquery
      ///   Otherwise => reset task to be picked up by Agents
      /// [usage]
      ///   Cocoon Agent calls this API when running in CI mode whenever finishing running tasks.
      '/api/update-task-status': UpdateTaskStatus(config, swarmingAuthProvider),
      '/api/vacuum-clean': VacuumClean(config, authProvider),
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
