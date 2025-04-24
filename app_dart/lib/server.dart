// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';
import 'dart:math';

import 'cocoon_service.dart';
import 'src/request_handlers/get_engine_artifacts_ready.dart';
import 'src/request_handlers/trigger_workflow.dart';
import 'src/request_handlers/update_discord_status.dart';
import 'src/service/big_query.dart';
import 'src/service/build_status_provider.dart';
import 'src/service/commit_service.dart';
import 'src/service/discord_service.dart';
import 'src/service/scheduler/ci_yaml_fetcher.dart';

typedef Server = Future<void> Function(HttpRequest);

/// Creates a service with the given dependencies.
Server createServer({
  required Config config,
  required FirestoreService firestore,
  required BigQueryService bigQuery,
  required CacheService cache,
  required AuthenticationProvider authProvider,
  required AuthenticationProvider swarmingAuthProvider,
  required BranchService branchService,
  required BuildBucketClient buildBucketClient,
  required LuciBuildService luciBuildService,
  required GithubChecksService githubChecksService,
  required CommitService commitService,
  required GerritService gerritService,
  required Scheduler scheduler,
  required CiYamlFetcher ciYamlFetcher,
  required BuildStatusService buildStatusService,
}) {
  final handlers = <String, RequestHandler<dynamic>>{
    '/api/check_flaky_builders': CheckFlakyBuilders(
      config: config,
      authenticationProvider: authProvider,
      bigQuery: bigQuery,
    ),
    '/api/create-branch': CreateBranch(
      branchService: branchService,
      config: config,
      authenticationProvider: authProvider,
    ),
    '/api/dart-internal-subscription': DartInternalSubscription(
      cache: cache,
      config: config,
      firestore: firestore,
    ),
    '/api/file_flaky_issue_and_pr': FileFlakyIssueAndPR(
      config: config,
      authenticationProvider: authProvider,
      bigQuery: bigQuery,
    ),
    '/api/flush-cache': FlushCache(
      config: config,
      authenticationProvider: authProvider,
      cache: cache,
    ),
    '/api/github-webhook-pullrequest': GithubWebhook(
      config: config,
      pubsub: const PubSub(),
      secret: config.webhookKey,
      topic: 'github-webhooks',
    ),
    // TODO(chillers): Move to release service. https://github.com/flutter/flutter/issues/132082
    '/api/github/frob-webhook': GithubWebhook(
      config: config,
      pubsub: const PubSub(),
      secret: config.frobWebhookKey,
      topic: 'frob-webhooks',
    ),
    '/api/github/webhook-subscription': GithubWebhookSubscription(
      config: config,
      cache: cache,
      gerritService: gerritService,
      scheduler: scheduler,
      commitService: commitService,
    ),
    '/api/v2/presubmit-luci-subscription': PresubmitLuciSubscription(
      cache: cache,
      config: config,
      luciBuildService: luciBuildService,
      githubChecksService: githubChecksService,
      scheduler: scheduler,
      ciYamlFetcher: ciYamlFetcher,
    ),
    '/api/v2/postsubmit-luci-subscription': PostsubmitLuciSubscription(
      cache: cache,
      config: config,
      githubChecksService: githubChecksService,
      ciYamlFetcher: ciYamlFetcher,
      luciBuildService: luciBuildService,
      firestore: firestore,
    ),
    '/api/push-build-status-to-github': PushBuildStatusToGithub(
      config: config,
      authenticationProvider: authProvider,
      buildStatusService: buildStatusService,
      firestore: firestore,
      bigQuery: bigQuery,
    ),
    '/api/push-gold-status-to-github': PushGoldStatusToGithub(
      config: config,
      authenticationProvider: authProvider,
      firestore: firestore,
    ),
    // I do not believe these recieve a build message.
    '/api/rerun-prod-task': RerunProdTask(
      config: config,
      authenticationProvider: authProvider,
      luciBuildService: luciBuildService,
      ciYamlFetcher: ciYamlFetcher,
      firestore: firestore,
    ),
    '/api/reset-try-task': ResetTryTask(
      config: config,
      authenticationProvider: authProvider,
      scheduler: scheduler,
    ),
    '/api/v2/reset-try-task': ResetTryTask(
      config: config,
      authenticationProvider: authProvider,
      scheduler: scheduler,
    ),
    '/api/scheduler/batch-backfiller': BatchBackfiller(
      config: config,
      ciYamlFetcher: ciYamlFetcher,
      luciBuildService: luciBuildService,
      firestore: firestore,
    ),
    '/api/v2/scheduler/batch-backfiller': BatchBackfiller(
      config: config,
      ciYamlFetcher: ciYamlFetcher,
      luciBuildService: luciBuildService,
      firestore: firestore,
    ),
    '/api/v2/scheduler/batch-request-subscription':
        SchedulerRequestSubscription(
          cache: cache,
          config: config,
          buildBucketClient: buildBucketClient,
        ),
    '/api/scheduler/vacuum-stale-tasks': VacuumStaleTasks(
      config: config,
      luciBuildService: luciBuildService,
      firestore: firestore,
    ),
    '/api/update_existing_flaky_issues': UpdateExistingFlakyIssue(
      config: config,
      authenticationProvider: authProvider,
      bigQuery: bigQuery,
    ),

    '/api/vacuum-github-commits': VacuumGithubCommits(
      config: config,
      authenticationProvider: authProvider,
      scheduler: scheduler,
    ),
    '/api/v2/vacuum-github-commits': VacuumGithubCommits(
      config: config,
      authenticationProvider: authProvider,
      scheduler: scheduler,
    ),

    /// Temporary API to trigger a dispatch-able workflow from Cocoon.
    '/api/trigger-workflow': TriggerWorkflow(
      authenticationProvider: authProvider,
      config: config,
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
      delegate: GetBuildStatus(
        config: config,
        buildStatusService: buildStatusService,
      ),
      ttl: const Duration(seconds: 15),
    ),
    '/api/public/build-status-badge': CacheRequestHandler<Body>(
      cache: cache,
      config: config,
      delegate: GetBuildStatusBadge(
        config: config,
        buildStatusService: buildStatusService,
      ),
      ttl: const Duration(seconds: 15),
    ),
    '/api/public/update-discord-status': CacheRequestHandler<Body>(
      cache: cache,
      config: config,
      delegate: UpdateDiscordStatus(
        config: config,
        discord: DiscordService(config: config),
        buildStatusService: buildStatusService,
        firestore: firestore,
      ),
      ttl: const Duration(seconds: 15),
    ),
    '/api/public/engine-artifacts-ready': CacheRequestHandler<Body>(
      cache: cache,
      config: config,
      delegate: GetEngineArtifactsReady(config: config, firestore: firestore),
      ttl: const Duration(minutes: 5),
    ),
    '/api/public/get-release-branches': CacheRequestHandler<Body>(
      cache: cache,
      config: config,
      delegate: GetReleaseBranches(
        config: config,
        branchService: branchService,
      ),
      ttl: const Duration(hours: 1),
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
      delegate: GetStatus(
        config: config,
        buildStatusService: buildStatusService,
        firestore: firestore,
      ),
    ),

    '/api/public/get-green-commits': GetGreenCommits(
      config: config,
      buildStatusService: buildStatusService,
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
      delegate: GithubRateLimitStatus(config: config, bigQuery: bigQuery),
    ),
    '/api/public/repos': GetRepos(config: config),

    /// Handler for AppEngine to identify when dart server is ready to serve requests.
    '/readiness_check': ReadinessCheck(config: config),
  };

  return (HttpRequest request) async {
    if (handlers.containsKey(request.uri.path)) {
      final handler = handlers[request.uri.path]!;
      await handler.service(request);
    } else {
      /// Requests with query parameters and anchors need to be trimmed to get the file path.
      // TODO(chillers): Use toFilePath(), https://github.com/dart-lang/sdk/issues/39373
      final queryIndex =
          request.uri.path.contains('?')
              ? request.uri.path.indexOf('?')
              : request.uri.path.length;
      final anchorIndex =
          request.uri.path.contains('#')
              ? request.uri.path.indexOf('#')
              : request.uri.path.length;

      /// Trim to the first instance of an anchor or query.
      final int trimIndex = min(queryIndex, anchorIndex);
      final filePath = request.uri.path.substring(0, trimIndex);

      const redirects = <String, String>{'/build.html': '/#/build'};
      if (redirects.containsKey(filePath)) {
        request.response.statusCode = HttpStatus.permanentRedirect;
        return request.response.redirect(Uri.parse(redirects[filePath]!));
      }
      await StaticFileHandler(filePath, config: config).service(request);
    }
  };
}
