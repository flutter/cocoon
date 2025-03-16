// Copyright 2021 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:math';

import 'package:cocoon_server/logging.dart';
import 'package:collection/collection.dart';
import 'package:gcloud/db.dart';
import 'package:github/github.dart';
import 'package:github/hooks.dart';
import 'package:googleapis/bigquery/v2.dart';
import 'package:googleapis/firestore/v1.dart';
import 'package:meta/meta.dart';
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
import '../model/firestore/ci_staging.dart';
import '../model/firestore/commit.dart' as firestore_commmit;
import '../model/firestore/pr_check_runs.dart';
import '../model/firestore/task.dart' as firestore;
import '../model/github/checks.dart' as cocoon_checks;
import '../model/proto/internal/scheduler.pb.dart' as pb;
import 'build_status_provider.dart';
import 'cache_service.dart';
import 'config.dart';
import 'datastore.dart';
import 'exceptions.dart';
import 'firestore.dart';
import 'get_files_changed.dart';
import 'github_checks_service.dart';
import 'luci_build_service.dart';
import 'luci_build_service/engine_artifacts.dart';
import 'luci_build_service/pending_task.dart';
import 'scheduler/policy.dart';
import 'scheduler/process_check_run_result.dart';

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
    required this.fusionTester,
    required this.getFilesChanged,
    this.datastoreProvider = DatastoreService.defaultProvider,
    this.httpClientProvider = Providers.freshHttpClient,
    this.buildStatusProvider = BuildStatusService.defaultProvider,
    @visibleForTesting this.markCheckRunConclusion = CiStaging.markConclusion,
    @visibleForTesting
    this.initializeCiStagingDocument = CiStaging.initializeDocument,
    @visibleForTesting this.findPullRequestFor = PrCheckRuns.findPullRequestFor,
    @visibleForTesting
    this.findPullRequestForSha = PrCheckRuns.findPullRequestForSha,
  });

  final GetFilesChanged getFilesChanged;
  final BuildStatusServiceProvider buildStatusProvider;
  final CacheService cache;
  final Config config;
  final DatastoreServiceProvider datastoreProvider;
  final GithubChecksService githubChecksService;
  final HttpClientProvider httpClientProvider;
  final FusionTester fusionTester;
  late DatastoreService datastore;
  late FirestoreService firestoreService;
  LuciBuildService luciBuildService;

  Future<StagingConclusion> Function({
    required String checkRun,
    required String conclusion,
    required FirestoreService firestoreService,
    required String sha,
    required RepositorySlug slug,
    required CiStage stage,
  })
  markCheckRunConclusion;

  Future<Document> Function({
    required FirestoreService firestoreService,
    required RepositorySlug slug,
    required String sha,
    required CiStage stage,
    required List<String> tasks,
    required String checkRunGuard,
  })
  initializeCiStagingDocument;

  final Future<PullRequest> Function(
    FirestoreService firestoreService,
    int checkRunId,
    String checkRunName,
  )
  findPullRequestFor;

  final Future<PullRequest?> Function(
    FirestoreService firestoreService,
    String sha,
  )
  findPullRequestForSha;

  /// Name of the subcache to store scheduler related values in redis.
  static const String subcacheName = 'scheduler';

  /// List of check runs that do not need to be tracked or looked up in
  /// any staging logic.
  static const kCheckRunsToIgnore = [
    Config.kMergeQueueLockName,
    Config.kCiYamlCheckName,
  ];

  /// Briefly describes what the "Merge Queue Guard" check is for.
  ///
  /// Find more details about this check at [kMergeQueueLockName].
  ///
  /// This description appears next to the Github check run in the pull request
  /// and merge queue UI.
  static const String kMergeQueueLockDescription =
      'This is only here to block the merge queue; nothing to see here in PRs';

  /// Ensure [commits] exist in Cocoon.
  ///
  /// If [Commit] does not exist in Datastore:
  ///   * Write it to datastore
  ///   * Schedule tasks listed in its scheduler config
  /// Otherwise, ignore it.
  Future<void> addCommits(List<Commit> commits) async {
    datastore = datastoreProvider(config.db);
    final newCommits = await _getMissingCommits(commits);
    log.fine('Found ${newCommits.length} new commits on GitHub');
    for (var commit in newCommits) {
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
      log.warning(
        'Only pull requests that were closed and merged should have tasks scheduled',
      );
      return;
    }

    final branch = pr.base!.ref;
    final fullRepo = pr.base!.repo!.fullName;
    final sha = pr.mergeCommitSha!;

    // TODO(matanlurey): Expand to every release candidate branch instead of a test branch.
    // See https://github.com/flutter/flutter/issues/163896.
    var markAllTasksSkipped = false;
    if (branch == 'flutter-0.42-candidate.0') {
      markAllTasksSkipped = true;
      log.info(
        '[release-candidate-postsubmit-skip] For merged PR ${pr.number}, SHA=$sha, skipping all post-submit tasks',
      );
    }

    final id = '$fullRepo/$branch/$sha';
    final key = datastore.db.emptyKey.append<String>(Commit, id: id);
    final mergedCommit = Commit(
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
    await _addCommit(mergedCommit, skipAllTasks: markAllTasksSkipped);
  }

  /// Processes postsubmit tasks.
  Future<void> _addCommit(Commit commit, {bool skipAllTasks = false}) async {
    if (!config.supportedRepos.contains(commit.slug)) {
      log.fine('Skipping ${commit.id} as repo is not supported');
      return;
    }

    final ciYaml = await getCiYaml(commit);

    final targets = ciYaml.getInitialTargets(ciYaml.postsubmitTargets());
    final isFusion = await fusionTester.isFusionBasedRef(
      commit.slug,
      commit.sha!,
    );
    if (isFusion) {
      final fusionPostTargets = ciYaml.postsubmitTargets(
        type: CiType.fusionEngine,
      );
      final fusionInitialTargets = ciYaml.getInitialTargets(
        fusionPostTargets,
        type: CiType.fusionEngine,
      );
      targets.addAll(fusionInitialTargets);
      // Note on post submit targets: CiYaml filters out release_true for release branches and fusion trees
    }

    final tasks = <Task>[...targetsToTasks(commit, targets)];
    final firestoreService = await config.createFirestoreService();
    final toBeScheduled = <PendingTask>[];
    for (var target in targets) {
      final task = tasks.singleWhere(
        (Task task) => task.name == target.value.name,
      );
      var policy = target.schedulerPolicy;

      // TODO(matanlurey): Clean up the logic below, we actually do *not* want
      // release branches to run every task automatically, and instead defer to
      // manual scheduling.
      //
      // See https://github.com/flutter/flutter/issues/163896.
      if (skipAllTasks) {
        task.status = Task.statusSkipped;
        continue;
      }

      // Release branches should run every task
      if (Config.defaultBranch(commit.slug) != commit.branch) {
        policy = const GuaranteedPolicy();
      }
      final priority = await policy.triggerPriority(
        taskName: task.name!,
        commitSha: commit.sha!,
        recentTasks: await firestoreService.queryRecentTasksByName(
          name: task.name!,
        ),
      );
      if (priority != null) {
        // Mark task as in progress to ensure it isn't scheduled over
        task.status = Task.statusInProgress;
        toBeScheduled.add(
          PendingTask(target: target, task: task, priority: priority),
        );
      }
    }

    // Datastore must be written to generate task keys
    try {
      log.info(
        'Datastore tasks created for $commit: ${tasks.map((t) => '"${t.name}"').join(', ')}',
      );
      await datastore.withTransaction<void>((Transaction transaction) async {
        transaction.queueMutations(inserts: <Commit>[commit]);
        transaction.queueMutations(inserts: tasks);
        await transaction.commit();
        log.fine(
          'Committed ${tasks.length} new tasks for commit ${commit.sha!}',
        );
      });
    } catch (error) {
      log.severe('Failed to add commit ${commit.sha!}: $error');
    }

    log.info(
      'Firestore initial targets created for $commit: ${targets.map((t) => '"${t.value.name}"').join(', ')}',
    );
    final commitDocument = firestore_commmit.commitToCommitDocument(commit);
    final taskDocuments = firestore.targetsToTaskDocuments(commit, targets);
    final writes = documentsToWrites([
      ...taskDocuments,
      commitDocument,
    ], exists: false);
    // TODO(keyonghan): remove try catch logic after validated to work.
    try {
      await firestoreService.writeViaTransaction(writes);
    } catch (error) {
      log.warning('Failed to add to Firestore: $error');
    }

    log.info(
      'Immediately scheduled tasks for $commit: ${toBeScheduled.map((t) => '"${t.task.name}"').join(', ')}',
    );
    await _batchScheduleBuilds(commit, toBeScheduled);
    await _uploadToBigQuery(commit);
  }

  /// Schedule all builds in batch requests instead of a single request.
  ///
  /// Each batch request contains [Config.batchSize] builds to be scheduled.
  Future<void> _batchScheduleBuilds(
    Commit commit,
    List<PendingTask> toBeScheduled,
  ) async {
    final batchLog = StringBuffer(
      'Scheduling ${toBeScheduled.length} tasks in batches for ${commit.sha} as follows:\n',
    );
    final futures = <Future<void>>[];
    for (var i = 0; i < toBeScheduled.length; i += config.batchSize) {
      final batch = toBeScheduled.sublist(
        i,
        min(i + config.batchSize, toBeScheduled.length),
      );
      batchLog.writeln(
        '  - ${batch.map((t) => '"${t.task.name}"').join(', ')}',
      );
      futures.add(
        luciBuildService.schedulePostsubmitBuilds(
          commit: commit,
          toBeScheduled: batch,
        ),
      );
    }
    log.info(batchLog);
    await Future.wait<void>(futures);
  }

  /// Return subset of [commits] not stored in Datastore.
  Future<List<Commit>> _getMissingCommits(List<Commit> commits) async {
    final newCommits = <Commit>[];
    // Ensure commits are sorted from newest to oldest (descending order)
    commits.sort((Commit a, Commit b) => b.timestamp!.compareTo(a.timestamp!));
    for (var commit in commits) {
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
  Future<CiYamlSet> getCiYaml(Commit commit, {bool validate = false}) async {
    final isFusion = await fusionTester.isFusionBasedRef(
      commit.slug,
      commit.sha!,
    );
    final totCommit = await generateTotCommit(
      slug: commit.slug,
      branch: Config.defaultBranch(commit.slug),
    );
    final totYaml = await _getCiYaml(totCommit, isFusionCommit: isFusion);
    return _getCiYaml(
      commit,
      totCiYaml: totYaml,
      validate: validate,
      isFusionCommit: isFusion,
    );
  }

  /// Load in memory the `.ci.yaml`.
  Future<CiYamlSet> _getCiYaml(
    Commit commit, {
    CiYamlSet? totCiYaml,
    bool validate = false,
    RetryOptions retryOptions = const RetryOptions(
      delayFactor: Duration(seconds: 2),
      maxAttempts: 4,
    ),
    bool isFusionCommit = false,
  }) async {
    Future<pb.SchedulerConfig> getSchedulerConfig(String ciPath) async {
      final ciYamlBytes =
          (await cache.getOrCreate(
            subcacheName,
            // This is a key for a cache; not a path - so its needs to be 'unique'
            '${commit.repository}/${commit.sha!}/$ciPath',
            createFn:
                () async =>
                    (await _downloadCiYaml(
                      commit,
                      // actual path to go and fetch
                      ciPath,
                      retryOptions: retryOptions,
                    )).writeToBuffer(),
            ttl: const Duration(hours: 1),
          ))!;
      final schedulerConfig = pb.SchedulerConfig.fromBuffer(ciYamlBytes);
      log.fine('Retrieved .ci.yaml for $ciPath');
      return schedulerConfig;
    }

    // First, whatever was asked of us.
    final schedulerConfig = await getSchedulerConfig(kCiYamlPath);

    // Second - maybe the engine CI
    pb.SchedulerConfig? engineFusionConfig;
    if (isFusionCommit) {
      // Fetch the engine yaml and mark it up.
      engineFusionConfig = await getSchedulerConfig(kCiYamlFusionEnginePath);
      log.fine('fusion engine .ci.yaml file fetched');
    }

    // If totCiYaml is not null, we assume upper level function has verified that current branch is not a release branch.
    return CiYamlSet(
      yamls: {
        CiType.any: schedulerConfig,
        if (engineFusionConfig != null) CiType.fusionEngine: engineFusionConfig,
      },
      slug: commit.slug,
      branch: commit.branch!,
      totConfig: totCiYaml,
      validate: validate,
      isFusion: isFusionCommit,
    );
  }

  /// Get `.ci.yaml` from GitHub
  Future<pb.SchedulerConfig> _downloadCiYaml(
    Commit commit,
    String ciPath, {
    RetryOptions retryOptions = const RetryOptions(maxAttempts: 3),
  }) async {
    final configContent = await githubFileContent(
      commit.slug,
      ciPath,
      httpClientProvider: httpClientProvider,
      ref: commit.sha!,
      retryOptions: retryOptions,
    );
    final configYaml = loadYaml(configContent) as YamlMap;
    final schedulerConfig =
        pb.SchedulerConfig()..mergeFromProto3Json(configYaml);
    return schedulerConfig;
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
  /// Schedules a [kCiYamlCheckName] to validate [CiYamlSet] is valid and all builds were able to be triggered.
  /// If [builderTriggerList] is specified, then trigger only those targets.
  Future<void> triggerPresubmitTargets({
    required PullRequest pullRequest,
    String reason = 'Newer commit available',
    List<String>? builderTriggerList,
  }) async {
    // Always cancel running builds so we don't ever schedule duplicates.
    log.info(
      'Attempting to cancel existing presubmit targets for ${pullRequest.number}',
    );
    await cancelPreSubmitTargets(pullRequest: pullRequest, reason: reason);

    final slug = pullRequest.base!.repo!.slug();

    // The MQ only waits for "required status checks" before deciding whether to
    // merge the PR into the target branch. This required check added to both
    // the PR and to the merge group, and so it must be completed in both cases.
    final lock = await lockMergeGroupChecks(slug, pullRequest.head!.sha!);

    // Track if we should unlock the merge group lock in case of non-fusion or
    // revert bots.
    var unlockMergeGroup = false;

    final ciValidationCheckRun = await _createCiYamlCheckRun(pullRequest, slug);

    log.info('Creating presubmit targets for ${pullRequest.number}');
    Object? exception;
    var isFusion = false;
    do {
      try {
        final sha = pullRequest.head!.sha!;
        isFusion = await fusionTester.isFusionBasedRef(slug, sha);
        if (!isFusion) {
          unlockMergeGroup = true;
        }

        // Both the author and label should be checked to make sure that no one is
        // attempting to get a pull request without check through.
        if (pullRequest.user!.login == config.autosubmitBot &&
            pullRequest.labels!.any(
              (element) => element.name == Config.revertOfLabel,
            )) {
          log.info(
            'Skipping generating the full set of checks for revert request.',
          );
          unlockMergeGroup = true;
          break;
        }
        // Feature request: skip engine builds and tests in monorepo if the PR only contains framework related
        // files.
        // NOTE: This creates an empty staging doc for the engine builds as staging is handled on check_run completion
        //       events from GitHub. Engine Tests are also skipped, and the base.sha is passed to LUCI to use prod
        //       binaries.
        if (isFusion &&
            await _applyFrameworkOnlyPrOptimization(
              slug,
              changedFilesCount: pullRequest.changedFilesCount!,
              prNumber: pullRequest.number!,
              prBranch: pullRequest.base!.ref!,
            )) {
          final logCrumb =
              'triggerPresubmitTargets($slug, $sha){frameworkOnly}';
          log.info('$logCrumb: FRAMEWORK_ONLY_TESTING_PR');

          await initializeCiStagingDocument(
            firestoreService: firestoreService,
            slug: slug,
            sha: sha,
            stage: CiStage.fusionEngineBuild,
            tasks: [],
            checkRunGuard: '',
          );

          await _runCiTestingStage(
            pullRequest: pullRequest,
            checkRunGuard: '$lock',
            logCrumb: logCrumb,

            // The if-branch already skips the engine build phase.
            testsToRun: _FlutterRepoTestsToRun.frameworkTestsOnly,
          );
          break;
        }
        final presubmitTargets =
            isFusion
                ? await _getTestsForStage(
                  pullRequest,
                  CiStage.fusionEngineBuild,
                )
                : await getPresubmitTargets(pullRequest);
        final presubmitTriggerTargets = filterTargets(
          presubmitTargets,
          builderTriggerList,
        );

        // When running presubmits for a fusion PR; create a new staging document to track tasks needed
        // to complete before we can schedule more tests (i.e. build engine artifacts before testing against them).
        final EngineArtifacts engineArtifacts;
        if (isFusion) {
          await initializeCiStagingDocument(
            firestoreService: firestoreService,
            slug: slug,
            sha: sha,
            stage: CiStage.fusionEngineBuild,
            tasks: [...presubmitTriggerTargets.map((t) => t.value.name)],
            checkRunGuard: '$lock',
          );
          engineArtifacts = const EngineArtifacts.noFrameworkTests(
            reason: 'This is the engine phase of the build',
          );
        } else {
          engineArtifacts = const EngineArtifacts.noFrameworkTests(
            reason: 'This is not the flutter/flutter repository',
          );
        }
        await luciBuildService.scheduleTryBuilds(
          targets: presubmitTriggerTargets,
          pullRequest: pullRequest,
          engineArtifacts: engineArtifacts,
        );
      } on FormatException catch (error, backtrace) {
        log.warning(
          'FormatException encountered when scheduling presubmit targets for ${pullRequest.number}',
        );
        log.warning(backtrace.toString());
        exception = error;
      } catch (error, backtrace) {
        log.warning(
          'Exception encountered when scheduling presubmit targets for ${pullRequest.number}',
        );
        log.warning(backtrace.toString());
        exception = error;
      }
    } while (false);

    // Update validate ci.yaml check
    await closeCiYamlCheckRun(
      'PR ${pullRequest.number}',
      exception,
      slug,
      ciValidationCheckRun,
    );

    // Normally the lock stays pending until the PR is ready to be enqueued, but
    // there are situations (see code above) when it needs to be unlocked
    // immediately.
    if (unlockMergeGroup) {
      await unlockMergeQueueGuard(slug, pullRequest.head!.sha!, lock);
    }
    log.info(
      'Finished triggering builds for: pr ${pullRequest.number}, commit ${pullRequest.base!.sha}, branch ${pullRequest.head!.ref} and slug $slug}',
    );
  }

  Future<bool> _applyFrameworkOnlyPrOptimization(
    RepositorySlug slug, {
    required int changedFilesCount,
    required int prNumber,
    required String prBranch,
  }) async {
    // The flutter/recipes change that makes this optimization possible
    // (https://flutter-review.googlesource.com/c/recipes/+/62501) occurred
    // *after* the branch to flutter-release "flutter-3.29-candidate.0", meaning
    // that release branch is using an older version of recipes that does not
    // support this optimization.
    //
    // So, to avoid making it impossible to create a release branch, or to
    // update the existing release branch (i.e. hot fixes), we only apply the
    // optimization on the "master" branch.
    //
    // In theory, many moons from now when maintained release branches are
    // guaranteed to include the flutter/recipes change we could remove this
    // check.
    final refuseLogPrefix =
        'Refusing to skip engine builds for PR#$prNumber branch';
    if (prBranch != Config.defaultBranch(Config.flutterSlug)) {
      log.info(
        '$refuseLogPrefix: $prBranch (not ${Config.defaultBranch(Config.flutterSlug)} branch)',
      );
      return false;
    }
    if (changedFilesCount > config.maxFilesChangedForSkippingEnginePhase) {
      log.info(
        '$refuseLogPrefix: $changedFilesCount > ${config.maxFilesChangedForSkippingEnginePhase}',
      );
      return false;
    }
    final filesChanged = await getFilesChanged.get(slug, prNumber);
    switch (filesChanged) {
      case InconclusiveFilesChanged(:final reason):
        // We would have hoped to avoid making this call at all (based on changedFilesCount), or we hit an HTTP issue.
        log.warning('$refuseLogPrefix: $reason');
        return false;
      case SuccessfulFilesChanged(:final filesChanged):
        for (final file in filesChanged) {
          if (file == 'DEPS' || file.startsWith('engine/')) {
            log.info(
              '$refuseLogPrefix: Engine source files or dependencies changed.\n${filesChanged.join('\n')}',
            );
            return false;
          }
        }
        return true;
    }
  }

  Future<void> closeCiYamlCheckRun(
    String description,
    Object? exception,
    RepositorySlug slug,
    CheckRun ciValidationCheckRun,
  ) async {
    log.info('Updating ci.yaml validation check for $description');
    if (exception == null) {
      // Success in validating ci.yaml
      log.info('ci.yaml validation check was successful for $description');
      await githubChecksService.githubChecksUtil.updateCheckRun(
        config,
        slug,
        ciValidationCheckRun,
        status: CheckRunStatus.completed,
        conclusion: CheckRunConclusion.success,
      );
    } else {
      log.warning(
        'Marking $description ${Config.kCiYamlCheckName} as failed',
        e,
      );
      // Failure when validating ci.yaml
      await githubChecksService.githubChecksUtil.updateCheckRun(
        config,
        slug,
        ciValidationCheckRun,
        status: CheckRunStatus.completed,
        conclusion: CheckRunConclusion.failure,
        output: CheckRunOutput(
          title: Config.kCiYamlCheckName,
          summary: '.ci.yaml has failures',
          text: exception.toString(),
        ),
      );
    }
  }

  Future<CheckRun> _createCiYamlCheckRun(
    PullRequest pullRequest,
    RepositorySlug slug,
  ) async {
    log.info('Creating ciYaml validation check run for ${pullRequest.number}');
    final ciValidationCheckRun = await githubChecksService.githubChecksUtil
        .createCheckRun(
          config,
          slug,
          pullRequest.head!.sha!,
          Config.kCiYamlCheckName,
          output: const CheckRunOutput(
            title: Config.kCiYamlCheckName,
            summary:
                'If this check is stuck pending, push an empty commit to retrigger the checks',
          ),
        );
    return ciValidationCheckRun;
  }

  static Duration debugCheckPretendDelay = const Duration(minutes: 1);

  Future<void> triggerMergeGroupTargets({
    required cocoon_checks.MergeGroupEvent mergeGroupEvent,
  }) async {
    // Behave similar to addPullRequest, except we're not yet merged into master.
    //   - We are mirrored in to GoB
    //   - We want PROD builds
    //   - We want check_runs as well
    //   - We want updates on check_runs to the presubmit pubsub.
    // We do not want "Task" objects because these are for flutter-dashboard tracking (post submit)
    final mergeGroup = mergeGroupEvent.mergeGroup;
    final headSha = mergeGroup.headSha;
    final slug = mergeGroupEvent.repository!.slug();
    final isFusion = await fusionTester.isFusionBasedRef(slug, headSha);

    final logCrumb =
        'triggerMergeGroupTargets($slug, $headSha, ${isFusion ? 'real' : 'simulated'})';

    log.info('$logCrumb: scheduling merge group checks');

    final lock = await lockMergeGroupChecks(slug, headSha);

    // If the repo is not fusion, it doesn't run anything in the MQ, so just
    // close the merge group guard.
    if (!isFusion) {
      await unlockMergeQueueGuard(slug, headSha, lock);
      return;
    }

    final mergeGroupTargets = {
      ...await getMergeGroupTargetsForStage(
        mergeGroup.baseRef,
        slug,
        headSha,
        CiStage.fusionEngineBuild,
      ),
    };

    try {
      // Filter out targets missing builders - we cannot wait to complete the merge group if we will never complete.
      final availableBuilders = await luciBuildService.getAvailableBuilderSet(
        project: 'flutter',
        bucket: 'prod',
      );
      final availableTargets = {
        ...mergeGroupTargets.where(
          (target) => availableBuilders.contains(target.value.name),
        ),
      };
      if (availableTargets.length != mergeGroupTargets.length) {
        log.warning(
          '$logCrumb: missing builders for targtets: ${mergeGroupTargets.difference(availableTargets)}',
        );
      }
      // Create the staging doc that will track our engine progress and allow us to unlock
      // the merge group lock later.
      await initializeCiStagingDocument(
        firestoreService: firestoreService,
        slug: slug,
        sha: headSha,
        stage: CiStage.fusionEngineBuild,
        tasks: [...availableTargets.map((t) => t.value.name)],
        checkRunGuard: '$lock',
      );

      // Create the minimal Commit needed to pass the next stage.
      // Note: headRef encodes refs/heads/... and what we want is the branch
      final commit = Commit(
        branch: mergeGroup.headRef.substring('refs/heads/'.length),
        repository: slug.fullName,
        sha: headSha,
      );

      await luciBuildService.scheduleMergeGroupBuilds(
        targets: [...availableTargets],
        commit: commit,
      );

      // Do not unlock the merge group guard in successful case - that will be done by staging checks.
      log.info('$logCrumb: successfully scheduled merge group checks');
    } catch (error, stackTrace) {
      log.warning(
        '$logCrumb: error encountered when scheduling merge group checks',
        error,
        stackTrace,
      );
      // If Cocoon/LUCI failed to schedule targets, the PR should be kicked out
      // of the queue. To do that, the merge queue guard must fail as it's the
      // only required GitHub check.
      await failGuardForMergeGroup(
        slug,
        headSha,
        'Failed to schedule checks for merge group',
        '''
$logCrumb

ERROR: $error
$stackTrace
''',
        lock,
      );
    }
  }

  Future<List<Target>> getMergeGroupTargetsForStage(
    String baseRef,
    RepositorySlug slug,
    String headSha,
    CiStage stage,
  ) async {
    final mergeGroupTargets = [
      ...await getMergeGroupTargets(baseRef, slug, headSha),
      ...await getMergeGroupTargets(
        baseRef,
        slug,
        headSha,
        type: CiType.fusionEngine,
      ),
    ].where(
      (Target target) => switch (stage) {
        CiStage.fusionEngineBuild =>
          target.value.properties['release_build'] == 'true',
        CiStage.fusionTests =>
          target.value.properties['release_build'] != 'true',
      },
    );

    return [...mergeGroupTargets];
  }

  Future<List<Target>> getMergeGroupTargets(
    String baseRef,
    RepositorySlug slug,
    String headSha, {
    CiType type = CiType.any,
  }) async {
    log.info(
      'Attempting to read merge group targets from ci.yaml for $headSha',
    );

    final commit = Commit(
      branch: baseRef.substring('refs/heads/'.length),
      repository: slug.fullName,
      sha: headSha,
    );

    late CiYamlSet ciYaml;
    if (commit.branch == Config.defaultBranch(commit.slug)) {
      ciYaml = await getCiYaml(commit, validate: true);
    } else {
      ciYaml = await getCiYaml(commit);
    }
    log.info(
      'ci.yaml loaded successfully; collecting merge group targets for $headSha',
    );

    final inner = ciYaml.ciYamlFor(type);

    // Filter out targets with schedulers different than luci or cocoon.
    bool filter(Target target) =>
        target.value.scheduler == pb.SchedulerSystem.luci ||
        target.value.scheduler == pb.SchedulerSystem.cocoon;
    return [...inner.presubmitTargets.where(filter)];
  }

  /// Cancels builds for a destroyed merge group.
  Future<void> cancelDestroyedMergeGroupTargets({
    required String headSha,
  }) async {
    log.info('Cancelling merge group targets for $headSha');
    await luciBuildService.cancelBuildsBySha(
      sha: headSha,
      reason: 'Merge group was destroyed',
    );
  }

  /// Pushes the required "Merge Queue Guard" check to the merge queue, which
  /// serves as a "lock".
  ///
  /// While this check is still in progress, the merge queue will not merge the
  /// respective PR onto the target branch (e.g. main or master), because this
  /// check is "required".
  Future<CheckRun> lockMergeGroupChecks(
    RepositorySlug slug,
    String headSha,
  ) async {
    return githubChecksService.githubChecksUtil.createCheckRun(
      config,
      slug,
      headSha,
      Config.kMergeQueueLockName,
      output: const CheckRunOutput(
        title: Config.kMergeQueueLockName,
        summary: kMergeQueueLockDescription,
      ),
    );
  }

  /// Completes the "Merge Queue Guard" check run.
  ///
  /// If the guard is guarding a merge group, this immediately makes the merge
  /// group eligible for landing onto the target branch (e.g. master), depending
  /// on the success of the merge groups queued in front of this one.
  ///
  /// If the guard is guarding a pull request, this immediately makes the pull
  /// request eligible for enqueuing into the merge queue.
  Future<void> unlockMergeQueueGuard(
    RepositorySlug slug,
    String headSha,
    CheckRun lock,
  ) async {
    log.info('Unlocking Merge Queue Guard for $slug/$headSha');
    await githubChecksService.githubChecksUtil.updateCheckRun(
      config,
      slug,
      lock,
      status: CheckRunStatus.completed,
      conclusion: CheckRunConclusion.success,
    );
  }

  /// Fails the "Merge Queue Guard" check for a merge group.
  ///
  /// This removes the merge group from the merge queue without landing it. The
  /// corresponding pull request will have to be fixed and re-enqueued again.
  Future<void> failGuardForMergeGroup(
    RepositorySlug slug,
    String headSha,
    String summary,
    String details,
    CheckRun lock,
  ) async {
    log.info('Failing merge group guard for merge group $headSha in $slug');
    await githubChecksService.githubChecksUtil.updateCheckRun(
      config,
      slug,
      lock,
      status: CheckRunStatus.completed,
      conclusion: CheckRunConclusion.failure,
      output: CheckRunOutput(
        title: Config.kCiYamlCheckName,
        summary: summary,
        text: details,
      ),
    );
  }

  /// If [builderTriggerList] is specificed, return only builders that are contained in [presubmitTarget].
  /// Otherwise, return [presubmitTarget].
  List<Target> filterTargets(
    List<Target> presubmitTarget,
    List<String>? builderTriggerList,
  ) {
    if (builderTriggerList != null && builderTriggerList.isNotEmpty) {
      return presubmitTarget
          .where(
            (Target target) => builderTriggerList.contains(target.value.name),
          )
          .toList();
    }
    return presubmitTarget;
  }

  /// Get LUCI presubmit builders from .ci.yaml.
  ///
  /// Filters targets with runIf, matching them to the diff of [pullRequest].
  ///
  /// In the case there is an issue getting the diff from GitHub, all targets are returned.
  @visibleForTesting
  Future<List<Target>> getPresubmitTargets(
    PullRequest pullRequest, {
    CiType type = CiType.any,
  }) async {
    final commit = Commit(
      branch: pullRequest.base!.ref,
      repository: pullRequest.base!.repo!.fullName,
      sha: pullRequest.head!.sha,
    );
    late CiYamlSet ciYaml;
    log.info(
      'Attempting to read presubmit targets from ci.yaml for ${pullRequest.number}',
    );
    if (commit.branch == Config.defaultBranch(commit.slug)) {
      ciYaml = await getCiYaml(commit, validate: true);
    } else {
      ciYaml = await getCiYaml(commit);
    }
    log.info('ci.yaml loaded successfully.');
    log.info('Collecting presubmit targets for ${pullRequest.number}');

    final inner = ciYaml.ciYamlFor(type);

    // Filter out schedulers targets with schedulers different than luci or cocoon.
    final presubmitTargets =
        inner.presubmitTargets
            .where(
              (Target target) =>
                  target.value.scheduler == pb.SchedulerSystem.luci ||
                  target.value.scheduler == pb.SchedulerSystem.cocoon,
            )
            .toList();

    // See https://github.com/flutter/flutter/issues/138430.
    final includePostsubmitAsPresubmit = _includePostsubmitAsPresubmit(
      inner,
      pullRequest,
    );
    if (includePostsubmitAsPresubmit) {
      log.info(
        'Including postsubmit targets as presubmit for ${pullRequest.number}',
      );

      for (var target in inner.postsubmitTargets) {
        // We don't want to include a presubmit twice
        // We don't want to run the builder_cache target as a presubmit
        if (!target.value.presubmit &&
            !target.value.properties.containsKey('cache_name')) {
          presubmitTargets.add(target);
        }
      }
    }

    log.info('Collected ${presubmitTargets.length} presubmit targets.');
    // Release branches should run every test.
    if (pullRequest.base!.ref !=
        Config.defaultBranch(pullRequest.base!.repo!.slug())) {
      log.info(
        'Release branch found, scheduling all targets for ${pullRequest.number}',
      );
      return presubmitTargets;
    }
    if (includePostsubmitAsPresubmit) {
      log.info(
        'Postsubmit targets included as presubmit, scheduling all targets for ${pullRequest.number}',
      );
      return presubmitTargets;
    }

    // Filter builders based on the PR diff
    final filesChanged = await getFilesChanged.get(
      pullRequest.base!.repo!.slug(),
      pullRequest.number!,
    );
    return getTargetsToRun(presubmitTargets, filesChanged);
  }

  static final _allowTestAll = {Config.flutterSlug};

  /// Returns `true` if [ciYaml.postsubmitTargets] should be ran during presubmit.
  static bool _includePostsubmitAsPresubmit(
    CiYaml ciYaml,
    PullRequest pullRequest,
  ) {
    if (!_allowTestAll.contains(ciYaml.slug)) {
      return false;
    }
    if (pullRequest.labels?.any((label) => label.name.contains('test: all')) ??
        false) {
      return true;
    }
    return false;
  }

  /// Process a completed GitHub `check_run`.
  ///
  /// Handles both fusion engine build and test stages, and both pull requests
  /// and merge groups.
  Future<bool> processCheckRunCompletion(
    cocoon_checks.CheckRunEvent checkRunEvent,
  ) async {
    final checkRun = checkRunEvent.checkRun!;
    final name = checkRun.name;
    final sha = checkRun.headSha;
    final slug = checkRunEvent.repository?.slug();
    final conclusion = checkRun.conclusion;

    if (name == null ||
        sha == null ||
        slug == null ||
        conclusion == null ||
        kCheckRunsToIgnore.contains(name)) {
      return true;
    }

    final logCrumb = 'checkCompleted($name, $slug, $sha, $conclusion)';

    final isFusion = await fusionTester.isFusionBasedRef(slug, sha);
    if (!isFusion) {
      return true;
    }

    final isMergeGroup = detectMergeGroup(checkRun);

    firestoreService = await config.createFirestoreService();

    // Check runs are fired at every stage. However, at this point it is unknown
    // if this check run belongs in the engine build stage or in the test stage.
    // So first look for it in the engine stage, and if it's missing, look for
    // it in the test stage.
    var stage = CiStage.fusionEngineBuild;
    var stagingConclusion = await _recordCurrentCiStage(
      slug: slug,
      sha: sha,
      stage: stage,
      name: name,
      conclusion: conclusion,
    );

    if (stagingConclusion.result == StagingConclusionResult.missing) {
      // Check run not found in the engine stage. Look for it in the test stage.
      stage = CiStage.fusionTests;
      stagingConclusion = await _recordCurrentCiStage(
        slug: slug,
        sha: sha,
        stage: stage,
        name: name,
        conclusion: conclusion,
      );
    }

    // First; check if we even recorded anything. This can occur if we've already passed the check_run and
    // have moved on to running more tests (which wouldn't be present in our document).
    if (!stagingConclusion.isOk) {
      return false;
    }

    // If an internal error happened in Cocoon, we need human assistance to
    // figure out next steps.
    if (stagingConclusion.result == StagingConclusionResult.internalError) {
      // If an internal error happened in the merge group, there may be no further
      // signals from GitHub that would cause the merge group to either land or
      // fail. The safest thing to do is to kick the pull request out of the queue
      // and let humans sort it out. If the group is left hanging in the queue, it
      // will hold up all other PRs that are trying to land.
      if (isMergeGroup) {
        final guard = checkRunFromString(stagingConclusion.checkRunGuard!);
        await failGuardForMergeGroup(
          slug,
          sha,
          stagingConclusion.summary,
          stagingConclusion.details,
          guard,
        );
      }
      return false;
    }

    // Are there tests remaining? Keep waiting.
    if (stagingConclusion.isPending) {
      log.info(
        '$logCrumb: not progressing, remaining work count: ${stagingConclusion.remaining}',
      );
      return false;
    }

    if (stagingConclusion.isFailed) {
      // Something failed in the current CI stage:
      //
      // * If this is a pull request: keep the merge guard open and do not proceed
      //   to the next stage. Let the author sort out what's up.
      // * If this is a merge group: kick the pull request out of the queue, and
      //   let the author sort it out.
      if (isMergeGroup) {
        final guard = checkRunFromString(stagingConclusion.checkRunGuard!);
        await failGuardForMergeGroup(
          slug,
          sha,
          stagingConclusion.summary,
          stagingConclusion.details,
          guard,
        );
      }
      return true;
    }

    // The logic for finishing a stage is different between build and test stages:
    //
    // * If this is a build stage, then:
    //    * If this is a pull request presubmit, then start the test stage.
    //    * If this is a merge group (in MQ), then close the MQ guard, letting
    //      GitHub land it.
    // * If this is a test stage, then close the MQ guard (allowing the PR to
    //   enter the MQ).
    switch (stage) {
      case CiStage.fusionEngineBuild:
        await _closeSuccessfulEngineBuildStage(
          checkRun: checkRun,
          mergeQueueGuard: stagingConclusion.checkRunGuard!,
          slug: slug,
          sha: sha,
          logCrumb: logCrumb,
        );
      case CiStage.fusionTests:
        await _closeSuccessfulTestStage(
          mergeQueueGuard: stagingConclusion.checkRunGuard!,
          slug: slug,
          sha: sha,
          logCrumb: logCrumb,
        );
    }
    return true;
  }

  /// Whether the [checkRunEvent] is for a merge group (rather than a pull request).
  bool detectMergeGroup(cocoon_checks.CheckRun checkRun) {
    final headBranch = checkRun.checkSuite?.headBranch;
    if (headBranch == null) {
      return false;
    }
    return tryParseGitHubMergeQueueBranch(headBranch).parsed;
  }

  Future<void> _closeSuccessfulEngineBuildStage({
    required cocoon_checks.CheckRun checkRun,
    required String mergeQueueGuard,
    required RepositorySlug slug,
    required String sha,
    required String logCrumb,
  }) async {
    // We know that we're in a fusion repo; now we need to figure out if we are
    //   1) in a presubmit test or
    //   2) in the merge queue
    if (detectMergeGroup(checkRun)) {
      await _closeMergeQueue(
        mergeQueueGuard: mergeQueueGuard,
        slug: slug,
        sha: sha,
        stage: CiStage.fusionEngineBuild,
        logCrumb: logCrumb,
      );
      return;
    }

    log.info(
      '$logCrumb: Stage completed successfully: ${CiStage.fusionEngineBuild}',
    );

    await proceedToCiTestingStage(
      checkRun: checkRun,
      mergeQueueGuard: mergeQueueGuard,
      slug: slug,
      sha: sha,
      logCrumb: logCrumb,
    );
  }

  Future<void> _closeSuccessfulTestStage({
    required String mergeQueueGuard,
    required RepositorySlug slug,
    required String sha,
    required String logCrumb,
  }) async {
    log.info('$logCrumb: Stage completed: ${CiStage.fusionTests}');
    await unlockMergeQueueGuard(slug, sha, checkRunFromString(mergeQueueGuard));
  }

  /// Returns the presubmit targets for the fusion repo [pullRequest] that should run for the given [stage].
  Future<List<Target>> _getTestsForStage(
    PullRequest pullRequest,
    CiStage stage, {
    bool skipEngine = false,
  }) async {
    final presubmitTargets = [
      ...await getPresubmitTargets(pullRequest),
      if (!skipEngine)
        ...await getPresubmitTargets(pullRequest, type: CiType.fusionEngine),
    ].where(
      (Target target) => switch (stage) {
        CiStage.fusionEngineBuild =>
          target.value.properties['release_build'] == 'true',
        CiStage.fusionTests =>
          target.value.properties['release_build'] != 'true',
      },
    );
    return [...presubmitTargets];
  }

  Future<void> _closeMergeQueue({
    required String mergeQueueGuard,
    required RepositorySlug slug,
    required String sha,
    required CiStage stage,
    required String logCrumb,
  }) async {
    log.info('$logCrumb: Merge Queue finished successfully');

    // Unlock the guarding check_run.
    final checkRunGuard = checkRunFromString(mergeQueueGuard);
    await unlockMergeQueueGuard(slug, sha, checkRunGuard);
  }

  /// Schedules post-engine build tests (i.e. engine tests, and framework tests).
  Future<void> _runCiTestingStage({
    required PullRequest pullRequest,
    required String checkRunGuard,
    required String logCrumb,
    required _FlutterRepoTestsToRun testsToRun,
  }) async {
    try {
      // Both the author and label should be checked to make sure that no one is
      // attempting to get a pull request without check through.
      if (pullRequest.user!.login == config.autosubmitBot &&
          pullRequest.labels!.any(
            (element) => element.name == Config.revertOfLabel,
          )) {
        log.info(
          '$logCrumb: skipping generating the full set of checks for revert request.',
        );
      } else {
        // Schedule the tests that would have run in a call to triggerPresubmitTargets - but for both the
        // engine and the framework.
        final presubmitTargets = await _getTestsForStage(
          pullRequest,
          CiStage.fusionTests,
          skipEngine: testsToRun == _FlutterRepoTestsToRun.frameworkTestsOnly,
        );

        // Create the document for tracking test check runs.
        await initializeCiStagingDocument(
          firestoreService: firestoreService,
          slug: pullRequest.base!.repo!.slug(),
          sha: pullRequest.head!.sha!,
          stage: CiStage.fusionTests,
          tasks: [...presubmitTargets.map((t) => t.value.name)],
          checkRunGuard: checkRunGuard,
        );

        // Here is where it gets fun: how do framework tests* know what engine
        // artifacts to fetch and use on CI? For presubmits on flutter/flutter;
        // see https://github.com/flutter/flutter/issues/164031.
        //
        // *In theory, also engine tests, but engine tests build from the engine
        // from source and rely on remote-build execution (RBE) for builds to
        // fast and cached.
        final EngineArtifacts engineArtifacts;
        if (testsToRun == _FlutterRepoTestsToRun.frameworkTestsOnly) {
          // Use the engine that this PR was branched off of.
          engineArtifacts = EngineArtifacts.usingExistingEngine(
            commitSha: pullRequest.base!.sha!,
          );
        } else {
          // Use the engine that was built from source *for* this PR.
          engineArtifacts = EngineArtifacts.builtFromSource(
            commitSha: pullRequest.head!.sha!,
          );
        }

        await luciBuildService.scheduleTryBuilds(
          targets: presubmitTargets,
          pullRequest: pullRequest,
          engineArtifacts: engineArtifacts,
        );
      }
    } on FormatException catch (error, backtrace) {
      log.warning(
        '$logCrumb: FormatException encountered when scheduling presubmit targets for ${pullRequest.number}',
        error,
        backtrace,
      );
      rethrow;
    } catch (error, backtrace) {
      log.warning(
        '$logCrumb: Exception encountered when scheduling presubmit targets for ${pullRequest.number}',
        error,
        backtrace,
      );
      rethrow;
    }
  }

  @visibleForTesting
  Future<void> proceedToCiTestingStage({
    required cocoon_checks.CheckRun checkRun,
    required RepositorySlug slug,
    required String sha,
    required String mergeQueueGuard,
    required String logCrumb,
  }) async {
    final checkRunGuard = checkRunFromString(mergeQueueGuard);

    // Look up the PR in our cache first. This reduces github quota and requires less calls.
    PullRequest? pullRequest;
    final id = checkRun.id!;
    final name = checkRun.name!;
    try {
      pullRequest = await findPullRequestFor(firestoreService, id, name);
    } catch (e, s) {
      log.warning('$logCrumb: unable to find PR in PrCheckRuns', e, s);
    }

    // We've failed to find the pull request; try a reverse look it from the check suite.
    if (pullRequest == null) {
      final checkSuiteId = checkRun.checkSuite!.id!;
      pullRequest = await githubChecksService.findMatchingPullRequest(
        slug,
        sha,
        checkSuiteId,
      );
    }

    // We cannot make any forward progress. Abandon all hope, Check runs who enter here.
    if (pullRequest == null) {
      throw 'No PR found matching this check_run($id, $name)';
    }

    try {
      await _runCiTestingStage(
        pullRequest: pullRequest,
        checkRunGuard: '$checkRunGuard',
        logCrumb: logCrumb,
        testsToRun: _FlutterRepoTestsToRun.engineTestsAndFrameworkTests,
      );
    } catch (error, stacktrace) {
      await githubChecksService.githubChecksUtil.createCheckRun(
        config,
        slug,
        pullRequest.head!.sha!,
        'CI Caught Failure',
        conclusion: CheckRunConclusion.failure,
        output: CheckRunOutput(
          title: 'CI Caught Failure',
          summary: 'A critical error occurred, preventing further CI testing.',
          text: '''
This check run indicates a failure in the CI process that stopped further tests from running.  We need to investigate to determine the root cause.

Possible causes:
* **Configuration Changes:** The `.ci.yaml` file might have been modified between the creation of this pull request and the start of this test run. This can lead to ci yaml validation errors.
* **Infrastructure Issues:** Problems with the CI environment itself (e.g., quota) could have caused the failure.

**Error Details:**

```
$error
```

Stack trace:

```
$stacktrace
```
''',
        ),
      );
    }
  }

  Future<StagingConclusion> _recordCurrentCiStage({
    required RepositorySlug slug,
    required String sha,
    required CiStage stage,
    required String name,
    required String conclusion,
  }) async {
    final logCrumb = 'checkCompleted($name, $slug, $sha, $conclusion)';
    final documentName = CiStaging.documentNameFor(
      slug: slug,
      sha: sha,
      stage: stage,
    );
    log.info('$logCrumb: $documentName');

    // We're doing a transactional update, which could fail if multiple tasks are running at the same time; so retry
    // a sane amount of times before giving up.
    const r = RetryOptions(maxAttempts: 3, delayFactor: Duration(seconds: 2));

    return r.retry(() {
      return markCheckRunConclusion(
        firestoreService: firestoreService,
        slug: slug,
        sha: sha,
        stage: stage,
        checkRun: name,
        conclusion: conclusion,
      );
    });
  }

  /// Reschedules a failed build using a [CheckRunEvent]. The CheckRunEvent is
  /// generated when someone clicks the re-run button from a failed build from
  /// the Github UI.
  ///
  /// If the rerequested check is for [Config.kCiYamlCheckName], all presubmit jobs are retried.
  /// Otherwise, the specific check will be retried.
  ///
  /// Relevant APIs:
  ///   https://developer.github.com/v3/checks/runs/#check-runs-and-requested-actions
  @useResult
  Future<ProcessCheckRunResult> processCheckRun(
    cocoon_checks.CheckRunEvent checkRunEvent,
  ) async {
    switch (checkRunEvent.action) {
      case 'completed':
        await processCheckRunCompletion(checkRunEvent);
        return const ProcessCheckRunResult.success();

      case 'rerequested':
        log.fine(
          'Rerun requested by GitHub user: ${checkRunEvent.sender?.login}',
        );
        final name = checkRunEvent.checkRun!.name;
        var success = false;
        if (name == Config.kMergeQueueLockName) {
          final slug = checkRunEvent.repository!.slug();
          final checkSuiteId = checkRunEvent.checkRun!.checkSuite!.id!;
          log.fine(
            'Requested re-run of "${Config.kMergeQueueLockName}" for $slug / $checkSuiteId - ignoring',
          );
          success = true;
        } else if (name == Config.kCiYamlCheckName) {
          // The CheckRunEvent.checkRun.pullRequests array is empty for this
          // event, so we need to find the matching pull request.
          final slug = checkRunEvent.repository!.slug();
          final headSha = checkRunEvent.checkRun!.headSha!;
          final checkSuiteId = checkRunEvent.checkRun!.checkSuite!.id!;
          final pullRequest = await githubChecksService.findMatchingPullRequest(
            slug,
            headSha,
            checkSuiteId,
          );
          if (pullRequest != null) {
            log.fine(
              'Matched PR: ${pullRequest.number} Repo: ${slug.fullName}',
            );
            await triggerPresubmitTargets(pullRequest: pullRequest);
            success = true;
          } else {
            log.warning(
              'No matching PR found for head_sha in check run event.',
            );
          }
        } else {
          try {
            final slug = checkRunEvent.repository!.slug();
            final gitBranch =
                checkRunEvent.checkRun!.checkSuite!.headBranch ??
                Config.defaultBranch(slug);
            final sha = checkRunEvent.checkRun!.headSha!;

            // Only merged commits are added to the datastore. If a matching commit is found, this must be a postsubmit checkrun.
            datastore = datastoreProvider(config.db);
            final commitKey = Commit.createKey(
              db: datastore.db,
              slug: slug,
              gitBranch: gitBranch,
              sha: sha,
            );
            Commit? commit;
            try {
              commit = await Commit.fromDatastore(
                datastore: datastore,
                key: commitKey,
              );
              log.fine('Commit found in datastore.');
            } on KeyNotFoundException {
              log.fine('Commit not found in datastore.');
            }

            if (commit == null) {
              log.fine(
                'Rescheduling presubmit build for ${checkRunEvent.checkRun?.name}',
              );
              final pullRequest = await findPullRequestForSha(
                await config.createFirestoreService(),
                checkRunEvent.checkRun!.headSha!,
              );
              if (pullRequest == null) {
                return ProcessCheckRunResult.userError(
                  'Asked to reschedule presubmits for unknown sha/PR: ${checkRunEvent.checkRun!.headSha!}',
                );
              }

              final isFusion = await fusionTester.isFusionBasedRef(slug, sha);
              final List<Target> presubmitTargets;
              final EngineArtifacts engineArtifacts;
              if (isFusion) {
                // Fusion repos have presubmits split across two .ci.yaml files.
                // /ci.yaml
                // /engine/src/flutter/.ci.yaml
                presubmitTargets = [
                  ...await getPresubmitTargets(pullRequest),
                  ...await getPresubmitTargets(
                    pullRequest,
                    type: CiType.fusionEngine,
                  ),
                ];
                if (await _applyFrameworkOnlyPrOptimization(
                  slug,
                  changedFilesCount: pullRequest.changedFilesCount!,
                  prNumber: pullRequest.number!,
                  prBranch: pullRequest.base!.ref!,
                )) {
                  engineArtifacts = EngineArtifacts.usingExistingEngine(
                    commitSha: pullRequest.base!.sha!,
                  );
                } else {
                  engineArtifacts = EngineArtifacts.builtFromSource(
                    commitSha: pullRequest.head!.sha!,
                  );
                }
              } else {
                presubmitTargets = await getPresubmitTargets(pullRequest);
                engineArtifacts = const EngineArtifacts.noFrameworkTests(
                  reason: 'Not flutter/flutter',
                );
              }

              final target = presubmitTargets.firstWhereOrNull(
                (target) => checkRunEvent.checkRun!.name == target.value.name,
              );
              if (target == null) {
                return ProcessCheckRunResult.internalError(
                  'Could not reschedule checkRun "${checkRunEvent.checkRun!.name}", '
                  'not found in list of presubmit targets: ${presubmitTargets.map((t) => t.value.name).toList()}',
                );
              }
              await luciBuildService.scheduleTryBuilds(
                targets: [target],
                pullRequest: pullRequest,
                engineArtifacts: engineArtifacts,
              );
            } else {
              log.fine('Rescheduling postsubmit build.');
              firestoreService = await config.createFirestoreService();
              final checkName = checkRunEvent.checkRun!.name!;
              final task = await Task.fromDatastore(
                datastore: datastore,
                commitKey: commitKey,
                name: checkName,
              );
              // Query the lastest run of the `checkName` againt commit `sha`.
              final taskDocuments = await firestoreService.queryCommitTasks(
                commit.sha!,
              );
              final taskDocument =
                  taskDocuments
                      .where(
                        (taskDocument) => taskDocument.taskName == checkName,
                      )
                      .toList()
                      .first;
              log.fine('Latest firestore task is $taskDocument');
              final ciYaml = await getCiYaml(commit);
              final target = ciYaml.postsubmitTargets().singleWhere(
                (Target target) => target.value.name == task.name,
              );
              await luciBuildService
                  .reschedulePostsubmitBuildUsingCheckRunEvent(
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
          } on FormatException catch (e) {
            // See https://github.com/flutter/flutter/issues/165018.
            log.info('CheckName: $name failed due to user error: $e');
            return ProcessCheckRunResult.userError('$e');
          }
        }

        log.fine('CheckName: $name State: $success');

        // TODO(matanlurey): It would be better to early return above where it is not a success.
        if (!success) {
          return const ProcessCheckRunResult.internalError(
            'Not successful. See previous log messages',
          );
        }
    }

    return const ProcessCheckRunResult.success();
  }

  /// Push [Commit] to BigQuery as part of the infra metrics dashboards.
  Future<void> _uploadToBigQuery(Commit commit) async {
    const projectId = 'flutter-dashboard';
    const dataset = 'cocoon';
    const table = 'Checklist';

    log.info('Uploading commit ${commit.sha} info to bigquery.');

    final tabledataResource = await config.createTabledataResourceApi();
    final tableDataInsertAllRequestRows = <Map<String, Object>>[];

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
    final rows = TableDataInsertAllRequest.fromJson(<String, Object>{
      'rows': tableDataInsertAllRequestRows,
    });

    /// Insert [commits] to [BigQuery]
    try {
      if (rows.rows == null) {
        log.warning('Rows to be inserted is null');
      } else {
        log.info(
          'Inserting ${rows.rows!.length} into big query for ${commit.sha}',
        );
      }
      await tabledataResource.insertAll(rows, projectId, dataset, table);
    } on ApiRequestError {
      log.warning('Failed to add commits to BigQuery: $ApiRequestError');
    }
  }

  /// Returns the tip of tree [Commit] using specified [branch] and [RepositorySlug].
  ///
  /// A tip of tree [Commit] is used to help generate the tip of tree [CiYamlSet].
  /// The generated tip of tree [CiYamlSet] will be compared against Presubmit Targets in current [CiYamlSet],
  /// to ensure new targets without `bringup: true` label are not added into the build.
  Future<Commit> generateTotCommit({
    required String branch,
    required RepositorySlug slug,
  }) async {
    datastore = datastoreProvider(config.db);
    firestoreService = await config.createFirestoreService();
    final buildStatusService = buildStatusProvider(datastore, firestoreService);
    final totCommit =
        (await buildStatusService
                .retrieveCommitStatus(limit: 1, branch: branch, slug: slug)
                .map<Commit>((CommitStatus status) => status.commit)
                .toList())
            .single;

    return totCommit;
  }

  /// Parses CheckRun from a previously json string encode
  CheckRun checkRunFromString(String input) {
    final checkRunJson = json.decode(input) as Map<String, dynamic>;
    // Workaround for https://github.com/SpinlockLabs/github.dart/issues/412
    if (checkRunJson['conclusion'] == 'null') {
      checkRunJson.remove('conclusion');
    }
    return CheckRun.fromJson(checkRunJson);
  }
}

/// Describes in `flutter/flutter` which tests to schedule.
enum _FlutterRepoTestsToRun {
  /// Run tests _of_ the engine, and tests in the framework (that use an engine).
  engineTestsAndFrameworkTests,

  /// Run only tests in the framework (that use an engine), skpping engine tests.
  frameworkTestsOnly,
}
