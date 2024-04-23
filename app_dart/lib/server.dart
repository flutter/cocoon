// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';
import 'dart:math';

import 'package:cocoon_service/cocoon_service.dart';
import 'package:cocoon_service/src/request_handlers/postsubmit_luci_subscription_v2.dart';
import 'package:cocoon_service/src/request_handlers/presubmit_luci_subscription_v2.dart';
import 'package:cocoon_service/src/request_handlers/reset_prod_task_v2.dart';
import 'package:cocoon_service/src/request_handlers/reset_try_task_v2.dart';
import 'package:cocoon_service/src/request_handlers/scheduler/batch_backfiller_v2.dart';
import 'package:cocoon_service/src/request_handlers/scheduler/scheduler_request_subscription.dart';
import 'package:cocoon_service/src/request_handlers/vacuum_github_commits_v2.dart';
import 'package:cocoon_service/src/service/build_bucket_v2_client.dart';
import 'package:cocoon_service/src/service/commit_service.dart';
import 'package:cocoon_service/src/service/github_checks_service_v2.dart';
import 'package:cocoon_service/src/service/luci_build_service_v2.dart';
import 'package:cocoon_service/src/service/scheduler_v2.dart';

typedef Server = Future<void> Function(HttpRequest);

/// Creates a service with the given dependencies.
Server createServer({
  required Config config,
  required CacheService cache,
  required AuthenticationProvider authProvider,
  required AuthenticationProvider swarmingAuthProvider,
  required BranchService branchService,
  required BuildBucketClient buildBucketClient,
  required BuildBucketV2Client buildBucketV2Client,
  required LuciBuildService luciBuildService,
  required LuciBuildServiceV2 luciBuildServiceV2,
  required GithubChecksService githubChecksService,
  required GithubChecksServiceV2 githubChecksServiceV2,
  required CommitService commitService,
  required GerritService gerritService,
  required Scheduler scheduler,
  required SchedulerV2 schedulerV2,
}) {
  final Map<String, RequestHandler<dynamic>> handlers = <String, RequestHandler<dynamic>>{
    '/api/check_flaky_builders': CheckFlakyBuilders(
      config: config,
      authenticationProvider: authProvider,
    ),
    '/api/create-branch': CreateBranch(
      branchService: branchService,
      config: config,
      authenticationProvider: authProvider,
    ),
    '/api/dart-internal-subscription': DartInternalSubscription(
      cache: cache,
      config: config,
      buildBucketV2Client: buildBucketV2Client,
    ),
    '/api/file_flaky_issue_and_pr': FileFlakyIssueAndPR(
      config: config,
      authenticationProvider: authProvider,
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
      schedulerV2: schedulerV2,
      commitService: commitService,
    ),
    '/api/presubmit-luci-subscription': PresubmitLuciSubscription(
      cache: cache,
      config: config,
      luciBuildService: luciBuildService,
      githubChecksService: githubChecksService,
      scheduler: scheduler,
    ),
    '/api/v2/presubmit-luci-subscription': PresubmitLuciSubscriptionV2(
      cache: cache,
      config: config,
      luciBuildService: luciBuildServiceV2,
      githubChecksService: githubChecksServiceV2,
      scheduler: schedulerV2,
    ),
    '/api/postsubmit-luci-subscription': PostsubmitLuciSubscription(
      cache: cache,
      config: config,
      scheduler: scheduler,
      githubChecksService: githubChecksService,
    ),
    '/api/v2/postsubmit-luci-subscription': PostsubmitLuciSubscriptionV2(
      cache: cache,
      config: config,
      scheduler: schedulerV2,
      githubChecksService: githubChecksServiceV2,
    ),
    '/api/push-build-status-to-github': PushBuildStatusToGithub(
      config: config,
      authenticationProvider: authProvider,
    ),
    '/api/push-gold-status-to-github': PushGoldStatusToGithub(
      config: config,
      authenticationProvider: authProvider,
    ),
    // I do not believe these recieve a build message.
    '/api/reset-prod-task': ResetProdTask(
      config: config,
      authenticationProvider: authProvider,
      luciBuildService: luciBuildService,
      scheduler: scheduler,
    ),
    '/api/v2/reset-prod-task': ResetProdTaskV2(
      config: config,
      authenticationProvider: authProvider,
      luciBuildService: luciBuildServiceV2,
      scheduler: schedulerV2,
    ),
    '/api/reset-try-task': ResetTryTask(
      config: config,
      authenticationProvider: authProvider,
      scheduler: scheduler,
    ),
    '/api/v2/reset-try-task': ResetTryTaskV2(
      config: config,
      authenticationProvider: authProvider,
      scheduler: schedulerV2,
    ),
    '/api/scheduler/batch-backfiller': BatchBackfiller(
      config: config,
      scheduler: scheduler,
    ),
    '/api/v2/scheduler/batch-backfiller': BatchBackfillerV2(
      config: config,
      scheduler: schedulerV2,
    ),
    '/api/scheduler/batch-request-subscription': SchedulerRequestSubscription(
      cache: cache,
      config: config,
      buildBucketClient: buildBucketClient,
    ),
    '/api/v2/scheduler/batch-request-subscription': SchedulerRequestSubscriptionV2(
      cache: cache,
      config: config,
      buildBucketClient: buildBucketV2Client,
    ),
    '/api/scheduler/vacuum-stale-tasks': VacuumStaleTasks(
      config: config,
    ),
    '/api/update_existing_flaky_issues': UpdateExistingFlakyIssue(
      config: config,
      authenticationProvider: authProvider,
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
    '/api/update-task-status': UpdateTaskStatus(
      config: config,
      authenticationProvider: swarmingAuthProvider,
    ),
    '/api/vacuum-github-commits': VacuumGithubCommits(
      config: config,
      authenticationProvider: authProvider,
      scheduler: scheduler,
    ),
    '/api/v2/vacuum-github-commits': VacuumGithubCommitsV2(
      config: config,
      authenticationProvider: authProvider,
      scheduler: schedulerV2,
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
      delegate: GetBuildStatus(config: config),
      ttl: const Duration(seconds: 15),
    ),
    '/api/public/build-status-badge': CacheRequestHandler<Body>(
      cache: cache,
      config: config,
      delegate: GetBuildStatusBadge(config: config),
      ttl: const Duration(seconds: 15),
    ),
    '/api/public/get-release-branches': CacheRequestHandler<Body>(
      cache: cache,
      config: config,
      delegate: GetReleaseBranches(config: config, branchService: branchService),
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
      delegate: GetStatus(config: config),
    ),

    '/api/public/get-status-firestore': CacheRequestHandler<Body>(
      cache: cache,
      config: config,
      delegate: GetStatusFirestore(config: config),
    ),

    '/api/public/get-green-commits': GetGreenCommits(config: config),

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
      delegate: GithubRateLimitStatus(config: config),
    ),
    '/api/public/repos': GetRepos(config: config),

    /// Handler for AppEngine to identify when dart server is ready to serve requests.
    '/readiness_check': ReadinessCheck(config: config),
  };

  return ((HttpRequest request) async {
    if (handlers.containsKey(request.uri.path)) {
      final RequestHandler<dynamic> handler = handlers[request.uri.path]!;
      await handler.service(request);
    } else {
      /// Requests with query parameters and anchors need to be trimmed to get the file path.
      // TODO(chillers): Use toFilePath(), https://github.com/dart-lang/sdk/issues/39373
      final int queryIndex = request.uri.path.contains('?') ? request.uri.path.indexOf('?') : request.uri.path.length;
      final int anchorIndex = request.uri.path.contains('#') ? request.uri.path.indexOf('#') : request.uri.path.length;

      /// Trim to the first instance of an anchor or query.
      final int trimIndex = min(queryIndex, anchorIndex);
      final String filePath = request.uri.path.substring(0, trimIndex);

      const Map<String, String> redirects = <String, String>{
        '/build.html': '/#/build',
      };
      if (redirects.containsKey(filePath)) {
        request.response.statusCode = HttpStatus.permanentRedirect;
        return request.response.redirect(Uri.parse(redirects[filePath]!));
      }
      await StaticFileHandler(filePath, config: config).service(request);
    }
  });
}
