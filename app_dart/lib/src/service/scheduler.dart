// Copyright 2021 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';
import 'dart:typed_data';

import 'package:gcloud/db.dart';
import 'package:github/github.dart' as github;
import 'package:googleapis/bigquery/v2.dart';
import 'package:retry/retry.dart';
import 'package:truncate/truncate.dart';
import 'package:yaml/yaml.dart';

import '../foundation/providers.dart';
import '../foundation/typedefs.dart';
import '../foundation/utils.dart';
import '../model/appengine/commit.dart';
import '../model/appengine/task.dart';
import '../model/github/checks.dart';
import '../model/luci/buildbucket.dart';
import '../model/proto/internal/scheduler.pb.dart';
import '../request_handling/exceptions.dart';
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

  /// Create [Tasks] specified in [commit] scheduler config.
  Future<List<Task>> _getTasks(Commit commit) async {
    final List<Task> tasks = <Task>[];
    final List<LuciBuilder>? prodBuilders = await config.luciBuilders('prod', commit.slug, commitSha: commit.sha!);
    if (prodBuilders != null) {
      for (LuciBuilder builder in prodBuilders) {
        tasks.add(Task.chromebot(commitKey: commit.key, createTimestamp: commit.timestamp!, builder: builder));
      }
    }
    final SchedulerConfig schedulerConfig = await getSchedulerConfig(commit);
    final List<Target> initialTargets = _getInitialPostSubmitTargets(commit, schedulerConfig);
    final List<Task> ciYamlTasks = targetsToTask(commit, initialTargets).toList();
    tasks.addAll(ciYamlTasks);

    return tasks;
  }

  /// Load in memory the `.ci.yaml`.
  Future<SchedulerConfig> getSchedulerConfig(Commit commit, {RetryOptions? retryOptions}) async {
    final String ciPath = '${commit.repository}/${commit.sha!}/.ci.yaml';
    final Uint8List configBytes = (await cache.getOrCreate(
      subcacheName,
      ciPath,
      createFn: () => _downloadSchedulerConfig(
        ciPath,
        retryOptions: retryOptions,
      ),
      ttl: const Duration(hours: 1),
    ))!;
    return SchedulerConfig.fromBuffer(configBytes);
  }

  /// Get all postsubmit targets that should be immediately started for [Commit].
  List<Target> _getInitialPostSubmitTargets(Commit commit, SchedulerConfig config) {
    final List<Target> postsubmitTargets = getPostSubmitTargets(commit, config);

    // Filter targets to only those without dependencies.
    final List<Target> initialTargets =
        postsubmitTargets.where((Target target) => target.dependencies.isEmpty).toList();
    return initialTargets;
  }

  /// Get all targets run on postsubmit for [Commit].
  ///
  /// Filter [SchedulerConfig] to only the targets expected to run for the branch,
  /// and that do not have any dependencies.
  List<Target> getPostSubmitTargets(Commit commit, SchedulerConfig config) {
    // Filter targets to only those run in postsubmit.
    final List<Target> postsubmitTargets = config.targets.where((Target target) => target.postsubmit).toList();
    return _filterEnabledTargets(commit, config, postsubmitTargets);
  }

  /// Get all [LuciBuilder] run on postsubmit for [Commit].
  ///
  /// Get an aggregate of LUCI presubmit builders from .ci.yaml and prod_builders.json.
  Future<List<LuciBuilder>> getPostSubmitBuilders(Commit commit, SchedulerConfig schedulerConfig) async {
    // 1. Get prod_builders.json builders
    final List<LuciBuilder> postsubmitBuilders =
        await config.luciBuilders('prod', commit.slug, commitSha: commit.sha!) ?? <LuciBuilder>[];
    // 2. Get ci.yaml builders (filter to only those that are relevant)
    final List<Target> postsubmitLuciTargets = schedulerConfig.targets
        .where((Target target) => target.postsubmit && target.scheduler == SchedulerSystem.luci)
        .toList();
    final List<Target> filteredTargets = _filterEnabledTargets(commit, schedulerConfig, postsubmitLuciTargets);
    postsubmitBuilders.addAll(filteredTargets.map((Target target) => LuciBuilder.fromTarget(target, commit.slug)));
    return postsubmitBuilders;
  }

  /// Get all targets run on presubmit for [Commit].
  ///
  /// Filter [SchedulerConfig] to only the targets expected to run for the branch,
  /// and that do not have any dependencies.
  List<Target> getPreSubmitTargets(Commit commit, SchedulerConfig config) {
    // Filter targets to only those run in presubmit.
    final Iterable<Target> presubmitTargets =
        config.targets.where((Target target) => target.presubmit && !target.bringup);

    return _filterEnabledTargets(commit, config, presubmitTargets.toList());
  }

  /// Filter [targets] to only those that are expected to run for [Commit] with [SchedulerConfig].
  ///
  /// A [Target] is expected to run if:
  ///   1. [Target.enabledBranches] exists and matches [Commit].
  ///   2. Otherwise, [SchedulerConfig.enabledBranches] matches [Commit].
  List<Target> _filterEnabledTargets(Commit commit, SchedulerConfig config, List<Target> targets) {
    final List<Target> filteredTargets = <Target>[];

    // 1. Add targets with local definition
    final Iterable<Target> overrideBranchTargets = targets.where((Target target) => target.enabledBranches.isNotEmpty);
    final Iterable<Target> enabledTargets =
        overrideBranchTargets.where((Target target) => target.enabledBranches.contains(commit.branch));
    filteredTargets.addAll(enabledTargets);

    // 2. Add targets with global definition
    if (config.enabledBranches.contains(commit.branch)) {
      final Iterable<Target> defaultBranchTargets = targets.where((Target target) => target.enabledBranches.isEmpty);
      filteredTargets.addAll(defaultBranchTargets);
    }

    return filteredTargets;
  }

  /// Get `.ci.yaml` from GitHub, and store the bytes in redis for future retrieval.
  ///
  /// If GitHub returns [HttpStatus.notFound], an empty config will be inserted assuming
  /// that commit does not support the scheduler config file.
  Future<Uint8List> _downloadSchedulerConfig(String ciPath, {RetryOptions? retryOptions}) async {
    String configContent;
    try {
      configContent = await githubFileContent(
        ciPath,
        httpClientProvider: httpClientProvider,
        retryOptions: retryOptions,
      );
    } on NotFoundException {
      log.fine('Failed to find $ciPath');
      return SchedulerConfig.getDefault().writeToBuffer();
    } on HttpException catch (_, e) {
      log.warning('githubFileContent failed to get $ciPath: $e');
      return SchedulerConfig.getDefault().writeToBuffer();
    }
    final YamlMap configYaml = loadYaml(configContent) as YamlMap;
    return schedulerConfigFromYaml(configYaml).writeToBuffer();
  }

  /// Cancel all incomplete targets against a pull request.
  Future<void> cancelPreSubmitTargets(
      {int? prNumber, github.RepositorySlug? slug, String? commitSha, String reason = 'Newer commit available'}) async {
    if (prNumber == null || slug == null || commitSha == null || commitSha.isEmpty) {
      throw BadRequestException('Unexpected null value given: slug=$slug, pr=$prNumber, commitSha=$commitSha');
    }
    await luciBuildService.cancelBuilds(
      slug,
      prNumber,
      commitSha,
      reason,
    );
  }

  /// Schedule presubmit targets against a pull request.
  ///
  /// Cancels all existing targets then schedules the targets.
  ///
  /// Schedules a `ci.yaml validation` check to validate [SchedulerConfig] is valid
  /// and all builds were able to be triggered.
  Future<void> triggerPresubmitTargets(
      {required String branch,
      required int prNumber,
      required github.RepositorySlug slug,
      required String commitSha,
      String reason = 'Newer commit available'}) async {
    if (commitSha.isEmpty) {
      throw BadRequestException(
          'Empty commit.sha! given: branch=$branch, slug=$slug, pr=$prNumber, commitSha=$commitSha');
    }
    // Always cancel running builds so we don't ever schedule duplicates.
    log.fine('about to cancel presubmit targets');
    await cancelPreSubmitTargets(
      prNumber: prNumber,
      slug: slug,
      commitSha: commitSha,
      reason: reason,
    );
    final github.CheckRun ciValidationCheckRun = await githubChecksService.githubChecksUtil.createCheckRun(
      config,
      slug,
      'ci.yaml validation',
      commitSha,
      output: const github.CheckRunOutput(
        title: '.ci.yaml validation',
        summary: 'If this check is stuck pending, push an empty commit to retrigger the checks',
      ),
    );
    dynamic exception;
    final Commit presubmitCommit = Commit(branch: branch, repository: slug.fullName, sha: commitSha);
    try {
      final List<LuciBuilder> presubmitBuilders = await getPresubmitBuilders(
        commit: presubmitCommit,
        prNumber: prNumber,
      );
      await luciBuildService.scheduleTryBuilds(
        builders: presubmitBuilders,
        slug: slug,
        prNumber: prNumber,
        commitSha: commitSha,
      );
    } on FormatException catch (e) {
      log.info(e.toString());
      exception = e;
    } catch (e) {
      log.warning(e.toString());
      exception = e;
    }

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
      log.warning('Marking PR #$prNumber ci.yaml validation as failed');
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
    log.fine('finish triggering presubmit targets');
  }

  /// Given a pull request event, retry all failed LUCI checks.
  ///
  /// 1. Aggregate .ci.yaml and try_builders.json presubmit builds.
  /// 2. Get failed LUCI builds for this pull request at [commitSha].
  /// 3. Rerun the failed builds that also have a failed check status.
  Future<void> retryPresubmitTargets({
    required int prNumber,
    required github.RepositorySlug slug,
    required String commitSha,
    required CheckSuiteEvent checkSuiteEvent,
  }) async {
    final github.GitHub githubClient = await config.createGitHubClient(slug);
    final Map<String, github.CheckRun> checkRuns = await githubChecksService.githubChecksUtil.allCheckRuns(
      githubClient,
      checkSuiteEvent,
    );
    final Commit presubmitCommit = Commit(repository: slug.fullName, sha: commitSha);
    final List<LuciBuilder> presubmitBuilders = await getPresubmitBuilders(
      commit: presubmitCommit,
      prNumber: prNumber,
    );
    final List<Build?> failedBuilds = await luciBuildService.failedBuilds(slug, prNumber, commitSha, presubmitBuilders);
    for (Build? build in failedBuilds) {
      final github.CheckRun checkRun = checkRuns[build!.builderId.builder!]!;

      if (checkRun.status != github.CheckRunStatus.completed) {
        // Check run is still in progress, do not retry.
        continue;
      }

      await luciBuildService.rescheduleTryBuildUsingCheckSuiteEvent(
        checkSuiteEvent,
        checkRun,
      );
    }
  }

  /// Get LUCI presubmit builders from .ci.yaml.
  Future<List<LuciBuilder>> getPresubmitBuilders({required Commit commit, required int prNumber}) async {
    // Get try_builders.json builders
    log.fine('Getting presubmit builders from json file');
    final List<LuciBuilder> presubmitBuilders = await config.luciBuilders(
          'try',
          commit.slug,
          commitSha: commit.sha!,
        ) ??
        <LuciBuilder>[];
    //  Get .ci.yaml targets
    final SchedulerConfig schedulerConfig = await getSchedulerConfig(commit);
    if (!schedulerConfig.enabledBranches.contains(commit.branch)) {
      throw Exception('${commit.branch} is not enabled for this .ci.yaml.\nAdd it to run tests against this PR.');
    }
    //  Get .ci.yaml targets
    final Iterable<Target> presubmitLuciTargets =
        getPreSubmitTargets(commit, schedulerConfig).where((Target target) => target.scheduler == SchedulerSystem.luci);
    presubmitBuilders.addAll(presubmitLuciTargets.map((Target target) => LuciBuilder.fromTarget(target, commit.slug)));
    // Filter builders based on the PR diff
    final GithubService githubService = await config.createGithubService(commit.slug);
    final List<String?> files = await githubService.listFiles(commit.slug, prNumber);
    return await getFilteredBuilders(presubmitBuilders, files);
  }

  /// Reschedules a failed build using a [CheckRunEvent]. The CheckRunEvent is
  /// generated when someone clicks the re-run button from a failed build from
  /// the Github UI.
  /// Relevant APIs:
  ///   https://developer.github.com/v3/checks/runs/#check-runs-and-requested-actions
  Future<bool> processCheckRun(CheckRunEvent checkRunEvent) async {
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
}
