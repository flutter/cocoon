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
    useLoggingPackageAdaptor();

    final bool inMemoryCache = Platform.environment[_kCocoonUseInMemoryCache] == 'true';
    final CacheService cache = CacheService(inMemory: inMemoryCache);

    final Config config = Config(dbService, cache);
    final AuthenticationProvider authProvider = AuthenticationProvider(config);
    final AuthenticationProvider swarmingAuthProvider = SwarmingAuthenticationProvider(config);
    final BuildBucketClient buildBucketClient = BuildBucketClient(
      accessTokenService: AccessTokenService.defaultProvider(config),
    );

    /// LUCI service class to communicate with buildBucket service.
    final LuciBuildService luciBuildService = LuciBuildService(
      config,
      buildBucketClient,
      pubsub: const PubSub(),
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
      /// Check+merge waiting github pull requests.
      ///
      /// Check if any github pull requests are marked with label
      /// "waiting for tree to go green" and merge up to the number
      /// specified within the handler.
      ///
      /// This api is called via cron job.
      ///
      /// GET: /api/check-waiting-pull-requests
      ///
      /// Response: Status 200 OK
      '/api/check-waiting-pull-requests': CheckForWaitingPullRequests(config, authProvider),
      '/api/check_flaky_builders': CheckFlakyBuilders(config, authProvider),
      '/api/file_flaky_issue_and_pr': FileFlakyIssueAndPR(config, authProvider),
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
      '/api/presubmit-luci-subscription': PresubmitLuciSubscription(
        cache,
        config,
        buildBucketClient,
        luciBuildService,
        githubChecksService,
      ),
      '/api/postsubmit-luci-subscription': PostsubmitLuciSubscription(
        cache: cache,
        config: config,
        luciBuildService: luciBuildService,
        scheduler: scheduler,
      ),
      '/api/push-build-status-to-github': PushBuildStatusToGithub(
        config,
        authProvider,
      ),
      '/api/push-gold-status-to-github': PushGoldStatusToGithub(config, authProvider),
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
        scheduler,
      ),
      '/api/reset-try-task': ResetTryTask(
        config,
        authProvider,
        scheduler,
      ),
      '/api/scheduler/batch-request-subscription': SchedulerRequestSubscription(
        cache: cache,
        config: config,
        buildBucketClient: buildBucketClient,
      ),
      '/api/update_existing_flaky_issues': UpdateExistingFlakyIssue(
        config,
        authProvider,
      ),

      /// Updates task related details.
      ///
      /// This API updates task status in datastore and
      /// pushes performance metrics to skia-perf.
      ///
      /// POST: /api-update-status
      ///
      /// Parameters:
      ///   CommitBranch: (string in body). Branch of commit.
      ///   CommitSha: (string in body). Sha of commit.
      ///   BuilderName: (string in body). Name of the luci builder.
      ///   NewStatus: (string in body) required. Status of the task.
      ///   ResultData: (string in body) optional. Benchmark data.
      ///   BenchmarkScoreKeys: (string in body) optional. Benchmark data.
      ///
      /// Response: Status 200 OK
      '/api/update-task-status': UpdateTaskStatus(config, swarmingAuthProvider),
      '/api/vacuum-github-commits': VacuumGithubCommits(
        config,
        authProvider,
        scheduler: scheduler,
      ),

      /// Returns status of the framework tree.
      ///
      /// Returns serialized proto with enum representing the
      /// status of the tree and list of offending tasks.
      ///
      /// GET: /api/public/build-status
      ///
      /// Parameters:
      ///   branch: (string in query) default: 'master'. Name of the repo branch.
      ///
      /// Response: Status 200 OK
      /// Returns [BuildStatusResponse]:
      ///  {
      ///    1: 2,
      ///    2: [ "win_tool_tests_commands", "win_build_test", "win_module_test"]
      ///   }
      '/api/public/build-status': CacheRequestHandler<Body>(
        cache: cache,
        config: config,
        delegate: GetBuildStatus(config),
        ttl: const Duration(seconds: 15),
      ),

      /// Returns task results for commits.
      ///
      /// Returns result details about each task in each checklist for every commit.
      ///
      /// GET: /api/public/get-status
      ///
      /// Parameters:
      ///   branch: (string in query) default: 'master'. Name of the repo branch.
      ///   lastCommitKey: (string in query) optional. Encoded commit key for the last commit to return resutls.
      ///
      /// Response: Status: 200 OK
      ///   {"Statuses":[
      ///     {"Checklist":{
      ///        "Key":"ah..jgM",
      ///        "Checklist":{"FlutterRepositoryPath":"flutter/flutter",
      ///        "CreateTimestamp":1620134239000,
      ///        "Commit":{"Sha":"7f1d1414cc5f0b0317272ced49a9c0b44e5c3af8",
      ///        "Message":"Revert \"Migrate to ChannelBuffers.push\"",
      ///        "Author":{"Login":"renyou","avatar_url":"https://avatars.githubusercontent.com/u/666474?v=4"}},"Branch":"master"}},
      ///        "Stages":[{"Name":"chromebot",
      ///          "Tasks":[
      ///            {"Task":{
      ///            "ChecklistKey":"ahF..jgM",
      ///            "CreateTimestamp":1620134239000,
      ///            "StartTimestamp":0,
      ///            "EndTimestamp":1620136203757,
      ///            "Name":"linux_cubic_bezier_perf__e2e_summary",
      ///            "Attempts":1,
      ///            "Flaky":false,
      ///            "TimeoutInMinutes":0,
      ///            "Reason":"",
      ///            "BuildNumber":null,
      ///            "BuildNumberList":"1279",
      ///            "BuilderName":"Linux cubic_bezier_perf__e2e_summary",
      ///            "luciBucket":"luci.flutter.prod",
      ///            "RequiredCapabilities":["can-update-github"],
      ///            "ReservedForAgentID":"",
      ///            "StageName":"chromebot",
      ///            "Status":"Succeeded"
      ///            },
      ///          ],
      ///          "Status": "InProgress",
      ///        ]},
      ///       },
      ///     }
      '/api/public/get-status': CacheRequestHandler<Body>(
        cache: cache,
        config: config,
        delegate: GetStatus(config),
      ),

      '/api/public/get-green-commits': GetGreenCommits(config),

      /// Get supported branches for the framework repo.
      ///
      /// Get list of supported branches to run infrastructure
      /// tasks on the framework repo.
      ///
      /// GET: /api/public/get-branches
      ///
      /// Response: Status 200 OK
      /// {Branches: [
      ///   "flutter-1.26-candidate.17",
      ///   "flutter-2.2-candidate.10",
      ///   "master"
      ///   ]
      /// }
      '/api/public/get-branches': CacheRequestHandler<Body>(
        cache: cache,
        config: config,
        delegate: GetBranches(config),
        ttl: const Duration(minutes: 15),
      ),

      /// Record GitHub API quota usage in BigQuery.
      ///
      /// Pushes data to BigQuery for metric collection to
      /// analyze usage over time.
      ///
      /// This api is called via cron job.
      ///
      /// GET: /api/public/github-rate-limit-status
      ///
      /// Response: Status 200 OK
      '/api/public/github-rate-limit-status': CacheRequestHandler<Body>(
        config: config,
        cache: cache,
        ttl: const Duration(minutes: 1),
        delegate: GithubRateLimitStatus(config),
      ),
      '/api/public/repos': GetRepos(config),

      /// Handler for AppEngine to identify when dart server is ready to serve requests.
      '/readiness_check': ReadinessCheck(config: config),
    };

    return await runAppEngine((HttpRequest request) async {
      if (handlers.containsKey(request.uri.path)) {
        final RequestHandler<dynamic> handler = handlers[request.uri.path]!;
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
          return await request.response.redirect(Uri.parse(redirects[filePath]!));
        }

        await StaticFileHandler(filePath, config: config).service(request);
      }
    }, onAcceptingConnections: (InternetAddress address, int port) {
      final String host = address.isLoopback ? 'localhost' : address.host;
      print('Serving requests at http://$host:$port/');
    });
  });
}
