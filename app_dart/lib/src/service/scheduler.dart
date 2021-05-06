// Copyright 2021 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';
import 'dart:typed_data';

import 'package:appengine/appengine.dart';
import 'package:cocoon_service/src/model/luci/buildbucket.dart';
import 'package:gcloud/db.dart';
import 'package:github/github.dart' as github;
import 'package:googleapis/bigquery/v2.dart';
import 'package:meta/meta.dart';
import 'package:retry/retry.dart';
import 'package:truncate/truncate.dart';
import 'package:yaml/yaml.dart';

import '../foundation/providers.dart';
import '../foundation/typedefs.dart';
import '../foundation/utils.dart';
import '../model/appengine/commit.dart';
import '../model/appengine/task.dart';
import '../model/github/checks.dart';
import '../model/proto/protos.dart' show SchedulerConfig, Target;
import '../request_handling/exceptions.dart';
import 'cache_service.dart';
import 'config.dart';
import 'datastore.dart';
import 'github_checks_service.dart';
import 'github_service.dart';
import 'luci.dart';
import 'luci_build_service.dart';

/// Scheduler service to validate all commits to supported Flutter repositories.
///
/// Scheduler responsibilties include:
///   1. Tracking commits in Cocoon
///   2. Ensuring commits are validated (via scheduling tasks against commits)
///   3. Retry mechanisms for tasks
class Scheduler {
  Scheduler({
    @required this.cache,
    @required this.config,
    @required this.githubChecksService,
    @required this.luciBuildService,
    this.datastoreProvider = DatastoreService.defaultProvider,
    this.httpClientProvider = Providers.freshHttpClient,
  })  : assert(datastoreProvider != null),
        assert(httpClientProvider != null);

  final CacheService cache;
  final Config config;
  final DatastoreServiceProvider datastoreProvider;
  final GithubChecksService githubChecksService;
  final HttpClientProvider httpClientProvider;

  DatastoreService datastore;
  Logging log;
  LuciBuildService luciBuildService;

  /// Name of the subcache to store scheduler related values in redis.
  static const String subcacheName = 'scheduler';

  /// Sets the appengine [log] used by this class to log debug and error
  /// messages. This method has to be called before any other method in this
  /// class.
  void setLogger(Logging log) {
    this.log = log;
    luciBuildService.setLogger(log);
  }

  /// Ensure [commits] exist in Cocoon.
  ///
  /// If [Commit] does not exist in Datastore:
  ///   * Write it to datastore
  ///   * Schedule tasks listed in its scheduler config
  /// Otherwise, ignore it.
  Future<void> addCommits(List<Commit> commits) async {
    datastore = datastoreProvider(config.db);
    final List<Commit> newCommits = await _getMissingCommits(commits);
    log.debug('Found ${newCommits.length} new commits on GitHub');
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
    if (!pr.merged) {
      log.warning('Only pull requests that were closed and merged should have tasks scheduled');
      return;
    }

    final String fullRepo = pr.base.repo.fullName;
    final String branch = pr.base.ref;
    final String sha = pr.mergeCommitSha;

    final String id = '$fullRepo/$branch/$sha';
    final Key<String> key = datastore.db.emptyKey.append<String>(Commit, id: id);
    final Commit mergedCommit = Commit(
      author: pr.user.login,
      authorAvatarUrl: pr.user.avatarUrl,
      branch: branch,
      key: key,
      // The field has a max length of 1500 so ensure the commit message is not longer.
      message: truncate(pr.title, 1490, omission: '...'),
      repository: fullRepo,
      sha: sha,
      timestamp: pr.mergedAt.millisecondsSinceEpoch,
    );

    if (await _commitExistsInDatastore(mergedCommit)) {
      log.debug('$sha already exists in datastore. Scheduling skipped.');
      return;
    }

    log.debug('Scheduling $sha via GitHub webhook');
    await _addCommit(mergedCommit);
  }

  Future<void> _addCommit(Commit commit) async {
    if (!Config.schedulerSupportedRepos.contains(commit.slug)) {
      log.debug('Skipping ${commit.id} as repo is not supported');
      return;
    }

    final List<Task> tasks = await _getTasks(commit);
    try {
      await datastore.withTransaction<void>((Transaction transaction) async {
        transaction.queueMutations(inserts: <Commit>[commit]);
        transaction.queueMutations(inserts: tasks);
        await transaction.commit();
        log.debug('Committed ${tasks.length} new tasks for commit ${commit.sha}');
      });
    } catch (error) {
      log.error('Failed to add commit ${commit.sha}: $error');
    }

    await _uploadToBigQuery(commit);
  }

  /// Return subset of [commits] not stored in Datastore.
  Future<List<Commit>> _getMissingCommits(List<Commit> commits) async {
    final List<Commit> newCommits = <Commit>[];
    // Ensure commits are sorted from newest to oldest (descending order)
    commits.sort((Commit a, Commit b) => b.timestamp.compareTo(a.timestamp));
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
    return await datastore.db.lookupValue<Commit>(commit.key, orElse: () => null) != null;
  }

  /// Create [Tasks] specified in [commit] scheduler config.
  Future<List<Task>> _getTasks(Commit commit) async {
    final List<Task> tasks = <Task>[];
    final List<LuciBuilder> prodBuilders =
        await LuciBuilder.getProdBuilders(commit.slug, config, commitSha: commit.sha);
    for (LuciBuilder builder in prodBuilders) {
      tasks.add(Task.chromebot(commitKey: commit.key, createTimestamp: commit.timestamp, builder: builder));
    }

    final SchedulerConfig schedulerConfig = await getSchedulerConfig(commit);
    final List<Target> initialTargets = _getInitialPostSubmitTargets(commit, schedulerConfig);
    final List<Task> ciYamlTasks = targetsToTask(commit, initialTargets).toList();
    tasks.addAll(ciYamlTasks);

    return tasks;
  }

  /// Load in memory the `.ci.yaml`.
  Future<SchedulerConfig> getSchedulerConfig(Commit commit, {RetryOptions retryOptions}) async {
    final String ciPath = '${commit.repository}/${commit.sha}/.ci.yaml';
    final Uint8List configBytes = await cache.getOrCreate(subcacheName, ciPath,
        createFn: () => _downloadSchedulerConfig(
              ciPath,
              retryOptions: retryOptions,
            ),
        ttl: const Duration(hours: 1));
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

  /// Get all targets run on presubmit for [Commit].
  ///
  /// Filter [SchedulerConfig] to only the targets expected to run for the branch,
  /// and that do not have any dependencies.
  List<Target> getPreSubmitTargets(Commit commit, SchedulerConfig config) {
    // Filter targets to only those run in presubmit.
    final Iterable<Target> presubmitTargets = config.targets.where((Target target) => target.presubmit);

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
  Future<Uint8List> _downloadSchedulerConfig(String ciPath, {RetryOptions retryOptions}) async {
    String configContent;
    try {
      configContent = await githubFileContent(
        ciPath,
        httpClientProvider: httpClientProvider,
        log: log,
        retryOptions: retryOptions,
      );
    } on NotFoundException {
      log.debug('Failed to find $ciPath');
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
      {int prNumber, github.RepositorySlug slug, String commitSha, String reason = 'Newer commit available'}) async {
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
  Future<void> triggerPresubmitTargets(
      {String branch,
      int prNumber,
      github.RepositorySlug slug,
      String commitSha,
      String reason = 'Newer commit available'}) async {
    if (branch == null || prNumber == null || slug == null || commitSha == null || commitSha.isEmpty) {
      throw BadRequestException(
          'Unexpected null value given: branch=$branch, slug=$slug, pr=$prNumber, commitSha=$commitSha');
    }
    // Always cancel running builds so we don't ever schedule duplicates.
    await cancelPreSubmitTargets(
      prNumber: prNumber,
      slug: slug,
      commitSha: commitSha,
      reason: reason,
    );
    final Commit presubmitCommit = Commit(branch: branch, repository: slug.fullName, sha: commitSha);
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
  }

  /// Given a pull request event, retry all failed LUCI checks.
  ///
  /// 1. Aggregate .ci.yaml and try_builders.json presubmit builds.
  /// 2. Get failed LUCI builds for this pull request at [commitSha].
  /// 3. Rerun the failed builds that also have a failed check status.
  Future<void> retryPresubmitTargets({
    int prNumber,
    github.RepositorySlug slug,
    String commitSha,
    CheckSuiteEvent checkSuiteEvent,
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
    final List<Build> failedBuilds = await luciBuildService.failedBuilds(slug, prNumber, commitSha, presubmitBuilders);
    for (Build build in failedBuilds) {
      final github.CheckRun checkRun = checkRuns[build.builderId.builder];

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

  /// Get an aggregate of LUCI presubmit builders from .ci.yaml and try_builders.json.
  Future<List<LuciBuilder>> getPresubmitBuilders({@required Commit commit, int prNumber}) async {
    // Get try_builders.json builders
    final List<LuciBuilder> builders = await config.luciBuilders(
      'try',
      commit.slug,
      commitSha: commit.sha,
    );
    //  Get .ci.yaml targets
    final SchedulerConfig schedulerConfig = await getSchedulerConfig(commit);
    final Iterable<Target> presubmitTargets = getPreSubmitTargets(commit, schedulerConfig);
    final Iterable<LuciBuilder> ciYamlBuilders =
        presubmitTargets.map((Target target) => LuciBuilder.fromTarget(target, commit.slug));
    builders.addAll(ciYamlBuilders);
    // Filter builders based on the PR diff
    final GithubService githubService = await config.createGithubService(commit.slug);
    final List<String> files = await githubService.listFiles(commit.slug, prNumber);
    return await getFilteredBuilders(builders, files);
  }

  /// Reschedules a failed build using a [CheckRunEvent]. The CheckRunEvent is
  /// generated when someone clicks the re-run button from a failed build from
  /// the Github UI.
  /// Relevant APIs:
  ///   https://developer.github.com/v3/checks/runs/#check-runs-and-requested-actions
  Future<bool> processCheckRun(CheckRunEvent checkRunEvent) async {
    switch (checkRunEvent.action) {
      case 'rerequested':
        final String builderName = checkRunEvent.checkRun.name;
        final bool success = await luciBuildService.rescheduleUsingCheckRunEvent(checkRunEvent);
        log.debug('BuilderName: $builderName State: $success');
        return success;
    }

    return false;
  }

  /// Push [Commit] to BigQuery as part of the infra metrics dashboards.
  Future<void> _uploadToBigQuery(Commit commit) async {
    const String projectId = 'flutter-dashboard';
    const String dataset = 'cocoon';
    const String table = 'Checklist';

    final TabledataResourceApi tabledataResourceApi = await config.createTabledataResourceApi();
    final List<Map<String, Object>> tableDataInsertAllRequestRows = <Map<String, Object>>[];

    /// Consolidate [commits] together
    ///
    /// Prepare for bigquery [insertAll]
    tableDataInsertAllRequestRows.add(<String, Object>{
      'json': <String, Object>{
        'ID': commit.id,
        'CreateTimestamp': commit.timestamp,
        'FlutterRepositoryPath': commit.repository,
        'CommitSha': commit.sha,
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
      await tabledataResourceApi.insertAll(rows, projectId, dataset, table);
    } on ApiRequestError {
      log.warning('Failed to add commits to BigQuery: $ApiRequestError');
    }
  }
}

/// Load [yamlConfig] to [SchedulerConfig] and validate the dependency graph.
SchedulerConfig schedulerConfigFromYaml(YamlMap yamlConfig) {
  final SchedulerConfig config = SchedulerConfig();
  config.mergeFromProto3Json(yamlConfig);
  _validateSchedulerConfig(config);

  return config;
}

void _validateSchedulerConfig(SchedulerConfig schedulerConfig) {
  if (schedulerConfig.targets.isEmpty) {
    throw const FormatException('Scheduler config must have at least 1 target');
  }

  if (schedulerConfig.enabledBranches.isEmpty) {
    throw const FormatException('Scheduler config must have at least 1 enabled branch');
  }

  final Map<String, List<Target>> targetGraph = <String, List<Target>>{};
  final List<String> exceptions = <String>[];
  // Construct [targetGraph]. With a one scan approach, cycles in the graph
  // cannot exist as it only works forward.
  for (final Target target in schedulerConfig.targets) {
    if (targetGraph.containsKey(target.name)) {
      exceptions.add('ERROR: ${target.name} already exists in graph');
    } else {
      targetGraph[target.name] = <Target>[];
      // Add edges
      if (target.dependencies.isNotEmpty) {
        if (target.dependencies.length != 1) {
          exceptions
              .add('ERROR: ${target.name} has multiple dependencies which is not supported. Use only one dependency');
        } else {
          if (target.dependencies.first == target.name) {
            exceptions.add('ERROR: ${target.name} cannot depend on itself');
          } else if (targetGraph.containsKey(target.dependencies.first)) {
            targetGraph[target.dependencies.first].add(target);
          } else {
            exceptions.add('ERROR: ${target.name} depends on ${target.dependencies.first} which does not exist');
          }
        }
      }
    }
  }
  _checkExceptions(exceptions);
}

void _checkExceptions(List<String> exceptions) {
  if (exceptions.isNotEmpty) {
    final String fullException = exceptions.reduce((String exception, _) => exception + '\n');
    throw FormatException(fullException);
  }
}
