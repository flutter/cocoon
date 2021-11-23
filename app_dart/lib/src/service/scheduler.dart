// Copyright 2021 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:typed_data';

import 'package:gcloud/db.dart';
import 'package:github/github.dart' as github;
import 'package:github/hooks.dart';
import 'package:googleapis/bigquery/v2.dart';
import 'package:retry/retry.dart';
import 'package:truncate/truncate.dart';
import 'package:yaml/yaml.dart';

import '../foundation/providers.dart';
import '../foundation/typedefs.dart';
import '../foundation/utils.dart';
import '../model/appengine/commit.dart';
import '../model/appengine/task.dart';
import '../model/ci_yaml/ci_yaml.dart';
import '../model/ci_yaml/target.dart';
import '../model/github/checks.dart' as cocoon_checks;
import '../model/luci/buildbucket.dart';
import '../model/proto/internal/scheduler.pb.dart' as pb;
import '../service/logging.dart';
import 'cache_service.dart';
import 'config.dart';
import 'datastore.dart';
import 'github_checks_service.dart';
import 'github_service.dart';
import 'luci.dart';
import 'luci_build_service.dart';
import 'scheduler/graph.dart';

export 'scheduler/graph.dart';

/// Scheduler service to validate all commits to supported Flutter repositories.
///
/// Scheduler responsibilties include:
///   1. Tracking commits in Cocoon
///   2. Ensuring commits are validated (via scheduling tasks against commits)
///   3. Retry mechanisms for tasks
class Scheduler {
  Scheduler({
    required this.cache,
    required this.config,
    required this.githubChecksService,
    required this.luciBuildService,
    this.datastoreProvider = DatastoreService.defaultProvider,
    this.httpClientProvider = Providers.freshHttpClient,
  });

  final CacheService cache;
  final Config config;
  final DatastoreServiceProvider datastoreProvider;
  final GithubChecksService githubChecksService;
  final HttpClientProvider httpClientProvider;

  late DatastoreService datastore;
  LuciBuildService luciBuildService;

  /// Name of the subcache to store scheduler related values in redis.
  static const String subcacheName = 'scheduler';

  /// Ensure [commits] exist in Cocoon.
  ///
  /// If [Commit] does not exist in Datastore:
  ///   * Write it to datastore
  ///   * Schedule tasks listed in its scheduler config
  /// Otherwise, ignore it.
  Future<void> addCommits(List<Commit> commits) async {
    datastore = datastoreProvider(config.db);
    final List<Commit> newCommits = await _getMissingCommits(commits);
    log.fine('Found ${newCommits.length} new commits on GitHub');
    for (Commit commit in newCommits) {
      await _addCommit(commit);
    }
  }

  /// Schedule tasks against [PullRequest].
  ///
  /// If [PullRequest] was merged, schedule prod tasks against it.
  /// Otherwise if it is presubmit, schedule try tasks against it.
  Future<void> addPullRequest(github.PullRequest pr) async {
    datastore = datastoreProvider(config.db);
    // TODO(chillers): Support triggering on presubmit. https://github.com/flutter/flutter/issues/77858
    if (!pr.merged!) {
      log.warning('Only pull requests that were closed and merged should have tasks scheduled');
      return;
    }

    final String fullRepo = pr.base!.repo!.fullName;
    final String? branch = pr.base!.ref;
    final String sha = pr.mergeCommitSha!;

    final String id = '$fullRepo/$branch/$sha';
    final Key<String> key = datastore.db.emptyKey.append<String>(Commit, id: id);
    final Commit mergedCommit = Commit(
      author: pr.user!.login!,
      authorAvatarUrl: pr.user!.avatarUrl!,
      branch: branch,
      key: key,
      // The field has a max length of 1500 so ensure the commit message is not longer.
      message: truncate(pr.title!, 1490, omission: '...'),
      repository: fullRepo,
      sha: sha,
      timestamp: pr.mergedAt!.millisecondsSinceEpoch,
    );

    if (await _commitExistsInDatastore(mergedCommit)) {
      log.fine('$sha already exists in datastore. Scheduling skipped.');
      return;
    }

    log.fine('Scheduling $sha via GitHub webhook');
    await _addCommit(mergedCommit);
  }

  Future<void> _addCommit(Commit commit) async {
    if (!Config.schedulerSupportedRepos.contains(commit.slug)) {
      log.fine('Skipping ${commit.id} as repo is not supported');
      return;
    }

    final List<Task> tasks = await _getTasks(commit);
    try {
      await datastore.withTransaction<void>((Transaction transaction) async {
        transaction.queueMutations(inserts: <Commit>[commit]);
        transaction.queueMutations(inserts: tasks);
        await transaction.commit();
        log.fine('Committed ${tasks.length} new tasks for commit ${commit.sha!}');
      });
    } catch (error) {
      log.severe('Failed to add commit ${commit.sha!}: $error');
    }

    await _uploadToBigQuery(commit);
  }

  /// Return subset of [commits] not stored in Datastore.
  Future<List<Commit>> _getMissingCommits(List<Commit> commits) async {
    final List<Commit> newCommits = <Commit>[];
    // Ensure commits are sorted from newest to oldest (descending order)
    commits.sort((Commit a, Commit b) => b.timestamp!.compareTo(a.timestamp!));
    for (Commit commit in commits) {
      // Cocoon may randomly drop commits, so check the entire list.
      if (!await _commitExistsInDatastore(commit)) {
        newCommits.add(commit);
      }
    }

    // Reverses commits to be in order of oldest to newest.
    return newCommits;
  }

  /// Whether [Commit] already exists in [datastore].
  ///
  /// Datastore is Cocoon's source of truth for what commits have been scheduled.
  /// Since webhooks or cron jobs can schedule commits, we must verify a commit
  /// has not already been scheduled.
  Future<bool> _commitExistsInDatastore(Commit commit) async {
    try {
      await datastore.db.lookupValue<Commit>(commit.key);
    } on KeyNotFoundException {
      return false;
    }
    return true;
  }

  /// Create all [Task] specified in the [CiYaml] for [Commit].
  Future<List<Task>> _getTasks(Commit commit) async {
    final CiYaml ciYaml = await getCiYaml(commit);
    final List<Target> initialTargets = ciYaml.getInitialTargets(ciYaml.postsubmitTargets);
    return targetsToTask(commit, initialTargets).toList();
  }

  /// Load in memory the `.ci.yaml`.
  Future<CiYaml> getCiYaml(
    Commit commit, {
    RetryOptions retryOptions = const RetryOptions(maxAttempts: 3),
  }) async {
    final String ciPath = '${commit.repository}/${commit.sha!}/$kCiYamlPath';
    final Uint8List ciYamlBytes = (await cache.getOrCreate(
      subcacheName,
      ciPath,
      createFn: () => _downloadCiYaml(
        commit,
        ciPath,
        retryOptions: retryOptions,
      ),
      ttl: const Duration(hours: 1),
    ))!;
    final pb.SchedulerConfig schedulerConfig = pb.SchedulerConfig.fromBuffer(ciYamlBytes);
    return CiYaml(
      config: schedulerConfig,
      slug: commit.slug,
      branch: commit.branch!,
    );
  }

  /// Get all [LuciBuilder] run for [ciYaml].
  Future<List<LuciBuilder>> getPostSubmitBuilders(CiYaml ciYaml) async {
    final Iterable<Target> postsubmitLuciTargets =
        ciYaml.postsubmitTargets.where((Target target) => _isCocoonSchedulable(target, presubmit: false));
    final List<LuciBuilder> builders =
        postsubmitLuciTargets.map((Target target) => LuciBuilder.fromTarget(target)).toList();
    return builders;
  }

  /// Get `.ci.yaml` from GitHub, and store the bytes in redis for future retrieval.
  ///
  /// If GitHub returns [HttpStatus.notFound], an empty config will be inserted assuming
  /// that commit does not support the scheduler config file.
  Future<Uint8List> _downloadCiYaml(
    Commit commit,
    String ciPath, {
    RetryOptions retryOptions = const RetryOptions(maxAttempts: 3),
  }) async {
    final String configContent = await githubFileContent(
      commit.slug,
      '.ci.yaml',
      httpClientProvider: httpClientProvider,
      ref: commit.sha!,
      retryOptions: retryOptions,
    );
    final YamlMap configYaml = loadYaml(configContent) as YamlMap;
    return schedulerConfigFromYaml(configYaml).writeToBuffer();
  }

  /// Cancel all incomplete targets against a pull request.
  Future<void> cancelPreSubmitTargets({
    required github.PullRequest pullRequest,
    String reason = 'Newer commit available',
  }) async {
    await luciBuildService.cancelBuilds(pullRequest, reason);
  }

  /// Schedule presubmit targets against a pull request.
  ///
  /// Cancels all existing targets then schedules the targets.
  ///
  /// Schedules a `ci.yaml validation` check to validate [SchedulerConfig] is valid
  /// and all builds were able to be triggered.
  Future<void> triggerPresubmitTargets({
    required github.PullRequest pullRequest,
    String reason = 'Newer commit available',
    RetryOptions retryOptions = const RetryOptions(maxAttempts: 3),
  }) async {
    final github.CheckRun ciValidationCheckRun = await githubChecksService.githubChecksUtil.createCheckRun(
      config,
      pullRequest.base!.repo!.slug(),
      pullRequest.head!.sha!,
      'ci.yaml validation',
      output: const github.CheckRunOutput(
        title: '.ci.yaml validation',
        summary: 'If this check is stuck pending, push an empty commit to retrigger the checks',
      ),
    );
    final github.RepositorySlug slug = pullRequest.base!.repo!.slug();
    final dynamic exception = await retryOptions.retry<dynamic>(() async => _triggerPresubmitTargets(
          pullRequest: pullRequest,
          reason: reason,
        ));

    // Update validate ci.yaml check
    if (exception == null) {
      // Success in validating ci.yaml
      await githubChecksService.githubChecksUtil.updateCheckRun(
        config,
        slug,
        ciValidationCheckRun,
        status: github.CheckRunStatus.completed,
        conclusion: github.CheckRunConclusion.success,
      );
    } else {
      log.warning('Marking PR #${pullRequest.number} ci.yaml validation as failed');
      log.warning(exception.toString());
      // Failure when validating ci.yaml
      await githubChecksService.githubChecksUtil.updateCheckRun(
        config,
        slug,
        ciValidationCheckRun,
        status: github.CheckRunStatus.completed,
        conclusion: github.CheckRunConclusion.failure,
        output: github.CheckRunOutput(
          title: 'ci.yaml validation',
          summary: '.ci.yaml has failures',
          text: exception.toString(),
        ),
      );
    }
    log.info(
        'Finished triggering builds for: pr ${pullRequest.number}, commit ${pullRequest.base!.sha}, branch ${pullRequest.head!.ref} and slug ${pullRequest.base!.repo!.slug()}}');
  }

  /// Internal wrapper for [triggerPresubmitTargets] retry logic.
  Future<dynamic> _triggerPresubmitTargets({
    required github.PullRequest pullRequest,
    String reason = 'Newer commit available',
  }) async {
    dynamic exception;
    // Always cancel running builds so we don't ever schedule duplicates.
    await cancelPreSubmitTargets(
      pullRequest: pullRequest,
      reason: reason,
    );
    log.fine('Cancelled existing presubmit runs');
    try {
      final List<Target> presubmitTargets = await getPresubmitTargets(pullRequest);
      await luciBuildService.scheduleTryBuilds(
        targets: presubmitTargets,
        pullRequest: pullRequest,
      );
    } on FormatException catch (error, backtrace) {
      log.warning(backtrace.toString());
      exception = error;
    } catch (error, backtrace) {
      log.warning(backtrace.toString());
      exception = error;
    }

    return exception;
  }

  /// Given a pull request event, retry all failed LUCI checks.
  ///
  /// 1. Aggregate .ci.yaml and try_builders.json presubmit builds.
  /// 2. Get failed LUCI builds for this pull request at [commitSha].
  /// 3. Rerun the failed builds that also have a failed check status.
  Future<void> retryPresubmitTargets({
    required github.PullRequest pullRequest,
    required CheckSuiteEvent checkSuiteEvent,
  }) async {
    final github.GitHub githubClient = await config.createGitHubClient(pullRequest: pullRequest);
    final Map<String, github.CheckRun> checkRuns = await githubChecksService.githubChecksUtil.allCheckRuns(
      githubClient,
      checkSuiteEvent,
    );
    final List<Target> presubmitTargets = await getPresubmitTargets(pullRequest);
    final List<Build?> failedBuilds = await luciBuildService.failedBuilds(pullRequest, presubmitTargets);
    for (Build? build in failedBuilds) {
      final github.CheckRun checkRun = checkRuns[build!.builderId.builder!]!;

      if (checkRun.status != github.CheckRunStatus.completed) {
        // Check run is still in progress, do not retry.
        continue;
      }

      await luciBuildService.rescheduleTryBuildUsingCheckSuiteEvent(
        pullRequest,
        checkSuiteEvent,
        checkRun,
      );
    }
  }

  /// Get LUCI presubmit builders from .ci.yaml.
  Future<List<Target>> getPresubmitTargets(github.PullRequest pullRequest) async {
    final Commit commit = Commit(
      branch: pullRequest.base!.ref,
      repository: pullRequest.base!.repo!.fullName,
      sha: pullRequest.head!.sha,
    );
    final CiYaml ciYaml = await getCiYaml(commit);
    final Iterable<Target> presubmitTargets =
        ciYaml.presubmitTargets.where((Target target) => target.value.scheduler == pb.SchedulerSystem.luci);
    // Filter builders based on the PR diff
    final GithubService githubService = await config.createGithubService(commit.slug);
    final List<String?> files = await githubService.listFiles(pullRequest);
    return await getTargetsToRun(presubmitTargets, files);
  }

  /// Reschedules a failed build using a [CheckRunEvent]. The CheckRunEvent is
  /// generated when someone clicks the re-run button from a failed build from
  /// the Github UI.
  /// Relevant APIs:
  ///   https://developer.github.com/v3/checks/runs/#check-runs-and-requested-actions
  Future<bool> processCheckRun(cocoon_checks.CheckRunEvent checkRunEvent) async {
    switch (checkRunEvent.action) {
      case 'rerequested':
        final String? builderName = checkRunEvent.checkRun!.name;
        final bool success = await luciBuildService.rescheduleUsingCheckRunEvent(checkRunEvent);
        log.fine('BuilderName: $builderName State: $success');
        return success;
    }

    return false;
  }

  /// Push [Commit] to BigQuery as part of the infra metrics dashboards.
  Future<void> _uploadToBigQuery(Commit commit) async {
    const String projectId = 'flutter-dashboard';
    const String dataset = 'cocoon';
    const String table = 'Checklist';

    final TabledataResource tabledataResource = await config.createTabledataResourceApi();
    final List<Map<String, Object>> tableDataInsertAllRequestRows = <Map<String, Object>>[];

    /// Consolidate [commits] together
    ///
    /// Prepare for bigquery [insertAll]
    tableDataInsertAllRequestRows.add(<String, Object>{
      'json': <String, Object?>{
        'ID': commit.id,
        'CreateTimestamp': commit.timestamp,
        'FlutterRepositoryPath': commit.repository,
        'CommitSha': commit.sha!,
        'CommitAuthorLogin': commit.author,
        'CommitAuthorAvatarURL': commit.authorAvatarUrl,
        'CommitMessage': commit.message,
        'Branch': commit.branch,
      },
    });

    /// Final [rows] to be inserted to [BigQuery]
    final TableDataInsertAllRequest rows =
        TableDataInsertAllRequest.fromJson(<String, Object>{'rows': tableDataInsertAllRequestRows});

    /// Insert [commits] to [BigQuery]
    try {
      await tabledataResource.insertAll(rows, projectId, dataset, table);
    } on ApiRequestError {
      log.warning('Failed to add commits to BigQuery: $ApiRequestError');
    }
  }

  /// Whether [target] should be scheduled by Cocooon's [Scheduler].
  ///
  /// If presubmit, Cocoon schedules all LUCI based targets (cocoon and luci).
  /// If postsubmit, Cocoon only schedules targets set to run on cocoon.
  bool _isCocoonSchedulable(Target target, {bool presubmit = true}) {
    if (presubmit) {
      return target.value.scheduler == pb.SchedulerSystem.luci || target.value.scheduler == pb.SchedulerSystem.cocoon;
    }

    return target.value.scheduler == pb.SchedulerSystem.luci;
  }
}
