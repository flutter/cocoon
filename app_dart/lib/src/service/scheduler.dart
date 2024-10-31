// Copyright 2021 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math';
import 'dart:typed_data';

import 'package:buildbucket/buildbucket_pb.dart' as bbv2;
import 'package:cocoon_service/src/service/exceptions.dart';
import 'package:cocoon_service/src/service/build_status_provider.dart';
import 'package:cocoon_service/src/service/scheduler/policy.dart';
import 'package:gcloud/db.dart';
import 'package:github/github.dart';
import 'package:github/hooks.dart';
import 'package:googleapis/bigquery/v2.dart';
import 'package:googleapis/firestore/v1.dart';
import 'package:retry/retry.dart';
import 'package:truncate/truncate.dart';
import 'package:yaml/yaml.dart';

import '../foundation/providers.dart';
import '../foundation/typedefs.dart';
import '../foundation/utils.dart';
import '../model/appengine/commit.dart';
import '../model/appengine/task.dart';
import '../model/firestore/commit.dart' as firestore_commmit;
import '../model/firestore/task.dart' as firestore;
import '../model/ci_yaml/ci_yaml.dart';
import '../model/ci_yaml/target.dart';
import '../model/github/checks.dart' as cocoon_checks;
import '../model/proto/internal/scheduler.pb.dart' as pb;
import '../service/logging.dart';
import 'cache_service.dart';
import 'config.dart';
import 'datastore.dart';
import 'firestore.dart';
import 'github_checks_service.dart';
import 'github_service.dart';
import 'luci_build_service.dart';

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
    this.buildStatusProvider = BuildStatusService.defaultProvider,
  });

  final BuildStatusServiceProvider buildStatusProvider;
  final CacheService cache;
  final Config config;
  final DatastoreServiceProvider datastoreProvider;
  final GithubChecksService githubChecksService;
  final HttpClientProvider httpClientProvider;

  late DatastoreService datastore;
  late FirestoreService firestoreService;
  LuciBuildService luciBuildService;

  /// Name of the subcache to store scheduler related values in redis.
  static const String subcacheName = 'scheduler';

  /// Validates that CI tasks were successfully created from the .ci.yaml file.
  ///
  /// If this check fails, it means Cocoon failed to fully populate the list of
  /// CI checks and the PR/commit should be treated as failing.
  static const String kCiYamlCheckName = 'ci.yaml validation';

  /// A virtual check that stays in pending state until all other CI tasks are
  /// completed.
  ///
  /// This check is "required", meaning that it must pass before Github will
  /// allow a PR to land in the merge queue, or a merge group to land on the
  /// target branch (main or master).
  static const String kCiTasksName = 'CI tasks';

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
  Future<void> addPullRequest(PullRequest pr) async {
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

  /// Processes postsubmit tasks.
  Future<void> _addCommit(Commit commit) async {
    if (!config.supportedRepos.contains(commit.slug)) {
      log.fine('Skipping ${commit.id} as repo is not supported');
      return;
    }

    final CiYaml ciYaml = await getCiYaml(commit);

    final List<Target> initialTargets = ciYaml.getInitialTargets(ciYaml.postsubmitTargets);
    final List<Task> tasks = targetsToTask(commit, initialTargets).toList();

    final List<Tuple<Target, Task, int>> toBeScheduled = <Tuple<Target, Task, int>>[];
    for (Target target in initialTargets) {
      final Task task = tasks.singleWhere((Task task) => task.name == target.value.name);
      SchedulerPolicy policy = target.schedulerPolicy;
      // Release branches should run every task
      if (Config.defaultBranch(commit.slug) != commit.branch) {
        policy = GuaranteedPolicy();
      }
      final int? priority = await policy.triggerPriority(task: task, datastore: datastore);
      if (priority != null) {
        // Mark task as in progress to ensure it isn't scheduled over
        task.status = Task.statusInProgress;
        toBeScheduled.add(Tuple<Target, Task, int>(target, task, priority));
      }
    }

    // Datastore must be written to generate task keys
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

    final firestore_commmit.Commit commitDocument = firestore_commmit.commitToCommitDocument(commit);
    final List<firestore.Task> taskDocuments = firestore.targetsToTaskDocuments(commit, initialTargets);
    final List<Write> writes = documentsToWrites([...taskDocuments, commitDocument], exists: false);
    final FirestoreService firestoreService = await config.createFirestoreService();
    // TODO(keyonghan): remove try catch logic after validated to work.
    try {
      await firestoreService.writeViaTransaction(writes);
    } catch (error) {
      log.warning('Failed to add to Firestore: $error');
    }

    await _batchScheduleBuilds(commit, toBeScheduled);
    await _uploadToBigQuery(commit);
  }

  /// Schedule all builds in batch requests instead of a single request.
  ///
  /// Each batch request contains [Config.batchSize] builds to be scheduled.
  Future<void> _batchScheduleBuilds(Commit commit, List<Tuple<Target, Task, int>> toBeScheduled) async {
    log.info('Batching ${toBeScheduled.length} for ${commit.sha}');
    final List<Future<void>> futures = <Future<void>>[];
    for (int i = 0; i < toBeScheduled.length; i += config.batchSize) {
      futures.add(
        luciBuildService.schedulePostsubmitBuilds(
          commit: commit,
          toBeScheduled: toBeScheduled.sublist(i, min(i + config.batchSize, toBeScheduled.length)),
        ),
      );
    }
    await Future.wait<void>(futures);
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

  /// Process and filters ciyaml.
  Future<CiYaml> getCiYaml(
    Commit commit, {
    bool validate = false,
  }) async {
    final Commit totCommit = await generateTotCommit(slug: commit.slug, branch: Config.defaultBranch(commit.slug));
    final CiYaml totYaml = await _getCiYaml(totCommit);
    return _getCiYaml(commit, totCiYaml: totYaml, validate: validate);
  }

  /// Load in memory the `.ci.yaml`.
  Future<CiYaml> _getCiYaml(
    Commit commit, {
    CiYaml? totCiYaml,
    bool validate = false,
    RetryOptions retryOptions = const RetryOptions(delayFactor: Duration(seconds: 2), maxAttempts: 4),
  }) async {
    String ciPath;
    ciPath = '${commit.repository}/${commit.sha!}/$kCiYamlPath';
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
    log.fine('Retrieved .ci.yaml for $ciPath');
    // If totCiYaml is not null, we assume upper level function has verified that current branch is not a release branch.
    return CiYaml(
      config: schedulerConfig,
      slug: commit.slug,
      branch: commit.branch!,
      totConfig: totCiYaml,
      validate: validate,
    );
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
    final pb.SchedulerConfig schedulerConfig = pb.SchedulerConfig()..mergeFromProto3Json(configYaml);
    return schedulerConfig.writeToBuffer();
  }

  /// Cancel all incomplete targets against a pull request.
  Future<void> cancelPreSubmitTargets({
    required PullRequest pullRequest,
    String reason = 'Newer commit available',
  }) async {
    log.info('Cancelling presubmit targets with buildbucket v2.');
    await luciBuildService.cancelBuilds(
      pullRequest: pullRequest,
      reason: reason,
    );
  }

  /// Schedule presubmit targets against a pull request.
  ///
  /// Cancels all existing targets then schedules the targets.
  ///
  /// Schedules a [kCiYamlCheckName] to validate [CiYaml] is valid and all builds were able to be triggered.
  /// If [builderTriggerList] is specified, then trigger only those targets.
  Future<void> triggerPresubmitTargets({
    required PullRequest pullRequest,
    String reason = 'Newer commit available',
    List<String>? builderTriggerList,
  }) async {
    // Always cancel running builds so we don't ever schedule duplicates.
    log.info('Attempting to cancel existing presubmit targets for ${pullRequest.number}');
    await cancelPreSubmitTargets(
      pullRequest: pullRequest,
      reason: reason,
    );

    final slug = pullRequest.base!.repo!.slug();

    /// For a PR, it is only necessary to pass the "ci.yaml validation" check.
    /// After that the PR can be merged, even if other checks are still pending
    /// or are failing. This is done intentionally to allow landing emergency
    /// fixes, such as reverts, on top of the broken tree or on top of other
    /// failing checks.
    ///
    /// Compare with the usage of this lock in [triggerMergeGroupTargets].
    final ciTasksLock = await lockMergeGroupChecks(slug, pullRequest.head!.sha!);

    log.info('Creating ciYaml validation check run for ${pullRequest.number}');
    final CheckRun ciValidationCheckRun = await githubChecksService.githubChecksUtil.createCheckRun(
      config,
      slug,
      pullRequest.head!.sha!,
      kCiYamlCheckName,
      output: const CheckRunOutput(
        title: kCiYamlCheckName,
        summary: 'If this check is stuck pending, push an empty commit to retrigger the checks',
      ),
    );

    log.info('Creating presubmit targets for ${pullRequest.number}');
    dynamic exception;
    try {
      // Both the author and label should be checked to make sure that no one is
      // attempting to get a pull request without check through.
      if (pullRequest.user!.login == config.autosubmitBot &&
          pullRequest.labels!.any((element) => element.name == Config.revertOfLabel)) {
        log.info('Skipping generating the full set of checks for revert request.');
      } else {
        final List<Target> presubmitTargets = await getPresubmitTargets(pullRequest);
        final List<Target> presubmitTriggerTargets = getTriggerList(presubmitTargets, builderTriggerList);
        await luciBuildService.scheduleTryBuilds(
          targets: presubmitTriggerTargets,
          pullRequest: pullRequest,
        );
      }
    } on FormatException catch (error, backtrace) {
      log.warning('FormatException encountered when scheduling presubmit targets for ${pullRequest.number}');
      log.warning(backtrace.toString());
      exception = error;
    } catch (error, backtrace) {
      log.warning('Exception encountered when scheduling presubmit targets for ${pullRequest.number}');
      log.warning(backtrace.toString());
      exception = error;
    }

    // Update validate ci.yaml check
    log.info('Updating ci.yaml validation check for ${pullRequest.number}');
    if (exception == null) {
      // Success in validating ci.yaml
      log.info('ci.yaml validation check was successful for ${pullRequest.number}');
      await githubChecksService.githubChecksUtil.updateCheckRun(
        config,
        slug,
        ciValidationCheckRun,
        status: CheckRunStatus.completed,
        conclusion: CheckRunConclusion.success,
      );
    } else {
      log.warning('Marking PR #${pullRequest.number} $kCiYamlCheckName as failed');
      log.warning(exception.toString());
      // Failure when validating ci.yaml
      await githubChecksService.githubChecksUtil.updateCheckRun(
        config,
        slug,
        ciValidationCheckRun,
        status: CheckRunStatus.completed,
        conclusion: CheckRunConclusion.failure,
        output: CheckRunOutput(
          title: kCiYamlCheckName,
          summary: '.ci.yaml has failures',
          text: exception.toString(),
        ),
      );
    }

    await unlockMergeGroupChecks(slug, pullRequest.head!.sha!, ciTasksLock, exception);

    log.info(
      'Finished triggering builds for: pr ${pullRequest.number}, commit ${pullRequest.base!.sha}, branch ${pullRequest.head!.ref} and slug $slug}',
    );
  }

  static Duration debugCheckPretendDelay = const Duration(minutes: 1);

  Future<void> triggerMergeGroupTargets({
    required cocoon_checks.MergeGroupEvent mergeGroupEvent,
  }) async {
    final mergeGroup = mergeGroupEvent.mergeGroup;
    final headSha = mergeGroup.headSha;

    log.info('Simulating merge group checks for @ $headSha');

    final slug = mergeGroupEvent.repository!.slug();

    /// A merge group must pass all the checks in order to land on the target
    /// branch.
    ///
    /// Compare with the usage of this lock in [triggerPresubmitTargets].
    final ciTasksLock = await lockMergeGroupChecks(slug, headSha);

    final ciValidationCheckRun = await githubChecksService.githubChecksUtil.createCheckRun(
      config,
      slug,
      headSha,
      'Simulated merge queue check',
      output: const CheckRunOutput(
        title: 'Simulated merge queue check',
        summary: 'If this check is stuck pending, push an empty commit to retrigger the checks',
      ),
    );

    // Pretend the check took 1 minute to run
    await Future<void>.delayed(debugCheckPretendDelay);

    final conclusion =
        mergeGroup.headCommit.message.contains('MQ_FAIL') ? CheckRunConclusion.failure : CheckRunConclusion.success;

    await githubChecksService.githubChecksUtil.updateCheckRun(
      config,
      slug,
      ciValidationCheckRun,
      status: CheckRunStatus.completed,
      conclusion: conclusion,
    );

    await unlockMergeGroupChecks(
      slug,
      headSha,
      ciTasksLock,
      conclusion == CheckRunConclusion.success ? null : 'Some checks failed',
    );

    log.info('Finished Simulating merge group checks for @ $headSha');
  }

  Future<void> cancelMergeGroupTargets({
    required String headSha,
  }) async {
    // TODO(yjbanov): there's no actual LUCI jobs to cancel, so for now just log
    //                and move on.
    log.info('Simulating cancellation of merge group CI targets for @ $headSha');
  }

  /// Lock a PR or a merge group, preventing it from merging.
  ///
  /// Until this lock is unlocked a PR cannot enter the merge queue, and a merge
  /// group cannot be merged into the target branch (typically main or master).
  ///
  /// The locking mechanism works as follows:
  ///
  /// The lock is a required check called "CI tasks" preconfigured in the
  /// repo's Settings under Rules > Rulesets > MERGE_QUEUE >
  /// "Require status checks to pass" > "Status checks that are required". The
  /// required status prevents the merge queue from starting the merge process,
  /// effectively "locking" it, until it is "unlocked" by completing with a
  /// success (see [unlockMergeGroupChecks]).
  ///
  /// The lock remains in the pending state until all the other necessary
  /// checks are complete. If all are successful, the lock unlocks with a
  /// success, granting the MQ the permission to proceed with merging the PR.
  /// If some necessary checks fail, the lock unlocks with a failure, and the
  /// PR author needs to take action to make the PR mergeable.
  ///
  /// This required check is added both to the PR and to the merge group, and
  /// so it must be completed in both cases.
  Future<CheckRun> lockMergeGroupChecks(RepositorySlug slug, String headSha) async {
    return githubChecksService.githubChecksUtil.createCheckRun(
      config,
      slug,
      headSha,
      kCiTasksName,
      output: const CheckRunOutput(
        title: kCiTasksName,
        summary: 'If this check is stuck pending, push an empty commit to retrigger the checks',
      ),
    );
  }

  /// Completes a "CI tasks" check that was scheduled using [lockMergeGroupChecks]
  /// with either success or failure.
  ///
  /// If [exception] is null completed the check with success. Otherwise,
  /// completes the check with failure.
  ///
  /// Calling this method unlocks the merge group, allowing Github to either
  /// merge the respective PR into the target branch (if success), or remove the
  /// PR from the merge queue (if failure).
  Future<void> unlockMergeGroupChecks(RepositorySlug slug, String headSha, CheckRun lock, Object? exception) async {
    if (exception == null) {
      // All checks have passed. Unlocking Github with success.
      log.info('All required CI tasks passed for $headSha');
      await githubChecksService.githubChecksUtil.updateCheckRun(
        config,
        slug,
        lock,
        status: CheckRunStatus.completed,
        conclusion: CheckRunConclusion.success,
      );
    } else {
      // Some checks failed. Unlocking Github with failure.
      log.info('Some required CI tasks failed for $headSha');
      log.warning(exception.toString());
      await githubChecksService.githubChecksUtil.updateCheckRun(
        config,
        slug,
        lock,
        status: CheckRunStatus.completed,
        conclusion: CheckRunConclusion.failure,
        output: CheckRunOutput(
          title: kCiYamlCheckName,
          summary: 'Some required CI tasks failed for ${lock.headSha}',
          text: exception.toString(),
        ),
      );
    }
  }

  /// If [builderTriggerList] is specificed, return only builders that are contained in [presubmitTarget].
  /// Otherwise, return [presubmitTarget].
  List<Target> getTriggerList(
    List<Target> presubmitTarget,
    List<String>? builderTriggerList,
  ) {
    if (builderTriggerList != null && builderTriggerList.isNotEmpty) {
      return presubmitTarget.where((Target target) => builderTriggerList.contains(target.value.name)).toList();
    }
    return presubmitTarget;
  }

  /// Given a pull request event, retry all failed LUCI checks.
  ///
  /// 1. Aggregate .ci.yaml and try_builders.json presubmit builds.
  /// 2. Get failed LUCI builds for this pull request at [commitSha].
  /// 3. Rerun the failed builds that also have a failed check status.
  Future<void> retryPresubmitTargets({
    required PullRequest pullRequest,
    required CheckSuiteEvent checkSuiteEvent,
  }) async {
    final GitHub githubClient = await config.createGitHubClient(pullRequest: pullRequest);
    final Map<String, CheckRun> checkRuns = await githubChecksService.githubChecksUtil.allCheckRuns(
      githubClient,
      checkSuiteEvent,
    );
    final List<Target> presubmitTargets = await getPresubmitTargets(pullRequest);
    final List<bbv2.Build?> failedBuilds =
        await luciBuildService.failedBuilds(pullRequest: pullRequest, targets: presubmitTargets);
    for (bbv2.Build? build in failedBuilds) {
      final CheckRun checkRun = checkRuns[build!.builder.builder]!;

      if (checkRun.status != CheckRunStatus.completed) {
        // Check run is still in progress, do not retry.
        continue;
      }

      await luciBuildService.scheduleTryBuilds(
        targets: presubmitTargets.where((Target target) => build.builder.builder == target.value.name).toList(),
        pullRequest: pullRequest,
        checkSuiteEvent: checkSuiteEvent,
      );
    }
  }

  /// Get LUCI presubmit builders from .ci.yaml.
  ///
  /// Filters targets with runIf, matching them to the diff of [pullRequest].
  ///
  /// In the case there is an issue getting the diff from GitHub, all targets are returned.
  Future<List<Target>> getPresubmitTargets(PullRequest pullRequest) async {
    final Commit commit = Commit(
      branch: pullRequest.base!.ref,
      repository: pullRequest.base!.repo!.fullName,
      sha: pullRequest.head!.sha,
    );
    late CiYaml ciYaml;
    log.info('Attempting to read presubmit targets from ci.yaml for ${pullRequest.number}');
    if (commit.branch == Config.defaultBranch(commit.slug)) {
      ciYaml = await getCiYaml(commit, validate: true);
    } else {
      ciYaml = await getCiYaml(commit);
    }
    log.info('ci.yaml loaded successfully.');
    log.info('Collecting presubmit targets for ${pullRequest.number}');

    // Filter out schedulers targets with schedulers different than luci or cocoon.
    final List<Target> presubmitTargets = ciYaml.presubmitTargets
        .where(
          (Target target) =>
              target.value.scheduler == pb.SchedulerSystem.luci || target.value.scheduler == pb.SchedulerSystem.cocoon,
        )
        .toList();

    // See https://github.com/flutter/flutter/issues/138430.
    final includePostsubmitAsPresubmit = _includePostsubmitAsPresubmit(ciYaml, pullRequest);
    if (includePostsubmitAsPresubmit) {
      log.info('Including postsubmit targets as presubmit for ${pullRequest.number}');

      for (Target target in ciYaml.postsubmitTargets) {
        // We don't want to include a presubmit twice
        // We don't want to run the builder_cache target as a presubmit
        if (!target.value.presubmit && !target.value.properties.containsKey('cache_name')) {
          presubmitTargets.add(target);
        }
      }
    }

    log.info('Collected ${presubmitTargets.length} presubmit targets.');
    // Release branches should run every test.
    if (pullRequest.base!.ref != Config.defaultBranch(pullRequest.base!.repo!.slug())) {
      log.info('Release branch found, scheduling all targets for ${pullRequest.number}');
      return presubmitTargets;
    }
    if (includePostsubmitAsPresubmit) {
      log.info('Postsubmit targets included as presubmit, scheduling all targets for ${pullRequest.number}');
      return presubmitTargets;
    }

    // Filter builders based on the PR diff
    final GithubService githubService = await config.createGithubService(commit.slug);
    List<String> files = <String>[];
    try {
      files = await githubService.listFiles(pullRequest);
    } on GitHubError catch (error) {
      log.warning(error);
      log.warning('Unable to get diff for pullRequest=$pullRequest');
      log.warning('Running all targets');
      return presubmitTargets.toList();
    }
    return getTargetsToRun(presubmitTargets, files);
  }

  static final _allowTestAll = {
    Config.engineSlug,
    Config.flutterSlug,
  };

  /// Returns `true` if [ciYaml.postsubmitTargets] should be ran during presubmit.
  static bool _includePostsubmitAsPresubmit(CiYaml ciYaml, PullRequest pullRequest) {
    if (!_allowTestAll.contains(ciYaml.slug)) {
      return false;
    }
    if (pullRequest.labels?.any((label) => label.name.contains('test: all')) ?? false) {
      return true;
    }
    return false;
  }

  /// Reschedules a failed build using a [CheckRunEvent]. The CheckRunEvent is
  /// generated when someone clicks the re-run button from a failed build from
  /// the Github UI.
  ///
  /// If the rerequested check is for [kCiYamlCheckName], all presubmit jobs are retried.
  /// Otherwise, the specific check will be retried.
  ///
  /// Relevant APIs:
  ///   https://developer.github.com/v3/checks/runs/#check-runs-and-requested-actions
  Future<bool> processCheckRun(cocoon_checks.CheckRunEvent checkRunEvent) async {
    switch (checkRunEvent.action) {
      case 'rerequested':
        log.fine('Rerun requested by GitHub user: ${checkRunEvent.sender?.login}');
        final String? name = checkRunEvent.checkRun!.name;
        bool success = false;
        if (name == kCiYamlCheckName) {
          // The CheckRunEvent.checkRun.pullRequests array is empty for this
          // event, so we need to find the matching pull request.
          final RepositorySlug slug = checkRunEvent.repository!.slug();
          final String headSha = checkRunEvent.checkRun!.headSha!;
          final int checkSuiteId = checkRunEvent.checkRun!.checkSuite!.id!;
          final PullRequest? pullRequest =
              await githubChecksService.findMatchingPullRequest(slug, headSha, checkSuiteId);
          if (pullRequest != null) {
            log.fine('Matched PR: ${pullRequest.number} Repo: ${slug.fullName}');
            await triggerPresubmitTargets(pullRequest: pullRequest);
            success = true;
          } else {
            log.warning('No matching PR found for head_sha in check run event.');
          }
        } else {
          try {
            final RepositorySlug slug = checkRunEvent.repository!.slug();
            final String gitBranch = checkRunEvent.checkRun!.checkSuite!.headBranch ?? Config.defaultBranch(slug);
            final String sha = checkRunEvent.checkRun!.headSha!;

            // Only merged commits are added to the datastore. If a matching commit is found, this must be a postsubmit checkrun.
            datastore = datastoreProvider(config.db);
            final Key<String> commitKey =
                Commit.createKey(db: datastore.db, slug: slug, gitBranch: gitBranch, sha: sha);
            Commit? commit;
            try {
              commit = await Commit.fromDatastore(datastore: datastore, key: commitKey);
              log.fine('Commit found in datastore.');
            } on KeyNotFoundException {
              log.fine('Commit not found in datastore.');
            }

            if (commit == null) {
              log.fine('Rescheduling presubmit build.');
              // Does not do anything with the returned build oddly.
              await luciBuildService.reschedulePresubmitBuildUsingCheckRunEvent(checkRunEvent: checkRunEvent);
            } else {
              log.fine('Rescheduling postsubmit build.');
              firestoreService = await config.createFirestoreService();
              final String checkName = checkRunEvent.checkRun!.name!;
              final Task task = await Task.fromDatastore(datastore: datastore, commitKey: commitKey, name: checkName);
              // Query the lastest run of the `checkName` againt commit `sha`.
              final List<firestore.Task> taskDocuments = await firestoreService.queryCommitTasks(commit.sha!);
              final firestore.Task taskDocument =
                  taskDocuments.where((taskDocument) => taskDocument.taskName == checkName).toList().first;
              log.fine('Latest firestore task is $taskDocument');
              final CiYaml ciYaml = await getCiYaml(commit);
              final Target target =
                  ciYaml.postsubmitTargets.singleWhere((Target target) => target.value.name == task.name);
              await luciBuildService.reschedulePostsubmitBuildUsingCheckRunEvent(
                checkRunEvent,
                commit: commit,
                task: task,
                target: target,
                taskDocument: taskDocument,
                datastore: datastore,
                firestoreService: firestoreService,
              );
            }

            success = true;
          } on NoBuildFoundException {
            log.warning('No build found to reschedule.');
          }
        }

        log.fine('CheckName: $name State: $success');
        return success;
    }

    return true;
  }

  /// Push [Commit] to BigQuery as part of the infra metrics dashboards.
  Future<void> _uploadToBigQuery(Commit commit) async {
    const String projectId = 'flutter-dashboard';
    const String dataset = 'cocoon';
    const String table = 'Checklist';

    log.info('Uploading commit ${commit.sha} info to bigquery.');

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
      if (rows.rows == null) {
        log.warning('Rows to be inserted is null');
      } else {
        log.info('Inserting ${rows.rows!.length} into big query for ${commit.sha}');
      }
      await tabledataResource.insertAll(rows, projectId, dataset, table);
    } on ApiRequestError {
      log.warning('Failed to add commits to BigQuery: $ApiRequestError');
    }
  }

  /// Returns the tip of tree [Commit] using specified [branch] and [RepositorySlug].
  ///
  /// A tip of tree [Commit] is used to help generate the tip of tree [CiYaml].
  /// The generated tip of tree [CiYaml] will be compared against Presubmit Targets in current [CiYaml],
  /// to ensure new targets without `bringup: true` label are not added into the build.
  Future<Commit> generateTotCommit({required String branch, required RepositorySlug slug}) async {
    datastore = datastoreProvider(config.db);
    firestoreService = await config.createFirestoreService();
    final BuildStatusService buildStatusService = buildStatusProvider(datastore, firestoreService);
    final Commit totCommit = (await buildStatusService
            .retrieveCommitStatus(
              limit: 1,
              branch: branch,
              slug: slug,
            )
            .map<Commit>((CommitStatus status) => status.commit)
            .toList())
        .single;

    return totCommit;
  }
}
