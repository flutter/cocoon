// Copyright 2021 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:math';

import 'package:cocoon_server/logging.dart';
import 'package:collection/collection.dart';
import 'package:github/github.dart';
import 'package:github/hooks.dart';
import 'package:googleapis/bigquery/v2.dart';
import 'package:meta/meta.dart';
import 'package:retry/retry.dart';

import '../foundation/utils.dart';
import '../model/ci_yaml/ci_yaml.dart';
import '../model/ci_yaml/target.dart';
import '../model/firestore/ci_staging.dart';
import '../model/firestore/commit.dart' as fs;
import '../model/firestore/pr_check_runs.dart';
import '../model/firestore/task.dart' as fs;
import '../model/github/checks.dart' as cocoon_checks;
import '../model/github/checks.dart' show MergeGroup;
import '../model/github/workflow_job.dart';
import '../model/proto/internal/scheduler.pb.dart' as pb;
import 'cache_service.dart';
import 'config.dart';
import 'content_aware_hash_service.dart';
import 'exceptions.dart';
import 'firestore.dart';
import 'get_files_changed.dart';
import 'github_checks_service.dart';
import 'luci_build_service.dart';
import 'luci_build_service/commit_task_ref.dart';
import 'luci_build_service/engine_artifacts.dart';
import 'luci_build_service/pending_task.dart';
import 'scheduler/ci_yaml_fetcher.dart';
import 'scheduler/files_changed_optimization.dart';
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
    required CacheService cache,
    required Config config,
    required GithubChecksService githubChecksService,
    required LuciBuildService luciBuildService,
    required GetFilesChanged getFilesChanged,
    required CiYamlFetcher ciYamlFetcher,
    required ContentAwareHashService contentAwareHash,
  }) : _luciBuildService = luciBuildService,
       _githubChecksService = githubChecksService,
       _config = config,
       _getFilesChanged = getFilesChanged,
       _ciYamlFetcher = ciYamlFetcher,
       _contentAwareHash = contentAwareHash,
       _filesChangedOptimizer = FilesChangedOptimizer(
         getFilesChanged: getFilesChanged,
         ciYamlFetcher: ciYamlFetcher,
         config: config,
       );

  final GetFilesChanged _getFilesChanged;
  final Config _config;
  final GithubChecksService _githubChecksService;
  final CiYamlFetcher _ciYamlFetcher;
  final ContentAwareHashService _contentAwareHash;
  final LuciBuildService _luciBuildService;
  final FilesChangedOptimizer _filesChangedOptimizer;

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
      'The merge queue guard is a GitHub check that prevents a PR from being '
      'merged or enqueued before it is ready. It becomes green automatically '
      'when all tests pass. No manual action is required. If you suspect that '
      'this check is not working correctly, contact #hackers-infra on Discord. '
      'If you need to merge your PR without tests (a rare situation, typically '
      'an emergency), then you can use the `emergency` label.';

  /// Ensure [commits] exist in Cocoon.
  ///
  /// If the commit already exists, it is ignored.
  ///
  /// Otherwise it is stored in Firestore, and scheduled, if appropriate.
  Future<void> addCommits(List<fs.Commit> commits) async {
    final newCommits = await _getMissingCommits(commits);
    log.debug('Found ${newCommits.length} new commits on GitHub');
    for (final commit in newCommits) {
      await _addCommit(commit);
    }
  }

  /// Schedule tasks against [PullRequest].
  ///
  /// If [PullRequest] was merged, schedule prod tasks against it.
  /// Otherwise if it is presubmit, schedule try tasks against it.
  Future<void> addPullRequest(PullRequest pr) async {
    // TODO(chillers): Support triggering on presubmit. https://github.com/flutter/flutter/issues/77858
    if (!pr.merged!) {
      log.warn(
        'Only pull requests that were closed and merged should have tasks scheduled',
      );
      return;
    }

    final branch = pr.base!.ref;
    final sha = pr.mergeCommitSha!;

    // TODO(matanlurey): Expand to every release candidate branch instead of a test branch.
    // See https://github.com/flutter/flutter/issues/163896.
    var markAllTasksSkipped = false;
    if (branch == 'flutter-0.42-candidate.0' ||
        branch == 'flutter-3.32-candidate.0') {
      markAllTasksSkipped = true;
      log.info(
        '[release-candidate-postsubmit-skip] For merged PR ${pr.number}, SHA=$sha, skipping all post-submit tasks',
      );
    }

    final mergedCommit = fs.Commit.fromGithubPullRequest(pr);
    if (await _commitExistsInFirestore(sha: mergedCommit.sha)) {
      log.debug('$sha already exists in Firestore. Scheduling skipped.');
      return;
    }

    log.debug('Scheduling $sha via GitHub webhook');
    await _addCommit(mergedCommit, skipAllTasks: markAllTasksSkipped);
  }

  /// Processes postsubmit tasks.
  Future<void> _addCommit(fs.Commit commit, {bool skipAllTasks = false}) async {
    if (!_config.supportedRepos.contains(commit.slug)) {
      log.debug('Skipping ${commit.sha} as repo is not supported');
      return;
    }

    final ciYaml = await _ciYamlFetcher.getCiYamlByFirestoreCommit(commit);
    final targets = ciYaml.getInitialTargets(ciYaml.postsubmitTargets());
    final isFusion = commit.slug == Config.flutterSlug;
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

    final tasks = [
      ...targets.map((t) => fs.Task.initialFromTarget(t, commit: commit)),
    ];
    final firestoreService = await _config.createFirestoreService();
    final toBeScheduled = <PendingTask>[];
    for (var target in targets) {
      final task = tasks.singleWhere((task) => task.taskName == target.name);
      var policy = target.schedulerPolicy;

      // TODO(matanlurey): Clean up the logic below, we actually do *not* want
      // release branches to run every task automatically, and instead defer to
      // manual scheduling.
      //
      // See https://github.com/flutter/flutter/issues/163896.
      if (skipAllTasks) {
        task.setStatus(fs.Task.statusSkipped);
        continue;
      }

      // Release branches should run every task
      if (Config.defaultBranch(commit.slug) != commit.branch) {
        policy = const GuaranteedPolicy();
      }
      final priority = await policy.triggerPriority(
        taskName: task.taskName,
        commitSha: commit.sha,
        recentTasks: await firestoreService.queryRecentTasks(
          name: task.taskName,
        ),
      );
      if (priority != null) {
        // Mark task as in progress to ensure it isn't scheduled over
        task.setStatus(fs.Task.statusInProgress);
        toBeScheduled.add(
          PendingTask(
            target: target,
            taskName: task.taskName,
            priority: priority,
          ),
        );
      }
    }

    log.info(
      'Initial targets created for $commit: '
      '${targets.map((t) => '"${t.name}"').join(', ')}',
    );
    await _addCommitFirestore(commit, tasks);

    log.info(
      'Immediately scheduled tasks for $commit: '
      '${toBeScheduled.map((t) => '"${t.taskName}"').join(', ')}',
    );
    await _batchScheduleBuilds(CommitRef.fromFirestore(commit), toBeScheduled);
    await _uploadToBigQuery(commit);
  }

  Future<void> _addCommitFirestore(
    fs.Commit commit,
    List<fs.Task> tasks,
  ) async {
    final firestore = await _config.createFirestoreService();
    await firestore.writeViaTransaction(
      documentsToWrites([...tasks, commit], exists: false),
    );
  }

  /// Schedule all builds in batch requests instead of a single request.
  ///
  /// Each batch request contains [Config.batchSize] builds to be scheduled.
  Future<void> _batchScheduleBuilds(
    CommitRef commit,
    List<PendingTask> toBeScheduled,
  ) async {
    final batchLog = StringBuffer(
      'Scheduling ${toBeScheduled.length} tasks in batches for ${commit.sha} as follows:\n',
    );
    final futures = <Future<void>>[];
    for (var i = 0; i < toBeScheduled.length; i += _config.batchSize) {
      final batch = toBeScheduled.sublist(
        i,
        min(i + _config.batchSize, toBeScheduled.length),
      );
      batchLog.writeln('  - ${batch.map((t) => '"${t.taskName}"').join(', ')}');
      futures.add(
        _luciBuildService.schedulePostsubmitBuilds(
          commit: commit,
          toBeScheduled: batch,
        ),
      );
    }
    log.info('$batchLog');
    await Future.wait<void>(futures);
  }

  /// Return subset of [commits] not stored in Firestore.
  Future<List<fs.Commit>> _getMissingCommits(List<fs.Commit> commits) async {
    final newCommits = <fs.Commit>[];
    // Ensure commits are sorted from newest to oldest (descending order)
    commits.sort((a, b) => b.createTimestamp.compareTo(a.createTimestamp));
    for (final commit in commits) {
      // Cocoon may randomly drop commits, so check the entire list.
      if (!await _commitExistsInFirestore(sha: commit.sha)) {
        newCommits.add(commit);
      }
    }

    // Reverses commits to be in order of oldest to newest.
    return newCommits;
  }

  /// Whether [Commit] already exists in Firestore.
  ///
  /// Firestore is Cocoon's source of truth for what commits have been
  /// scheduled. Since webhooks or cron jobs can schedule commits, we must
  /// verify a commit has not already been scheduled.
  Future<bool> _commitExistsInFirestore({required String sha}) async {
    final commit = await fs.Commit.tryFromFirestoreBySha(
      await _config.createFirestoreService(),
      sha: sha,
    );
    return commit != null;
  }

  /// Cancel all incomplete targets against a pull request.
  Future<void> cancelPreSubmitTargets({
    required PullRequest pullRequest,
    String reason = 'Newer commit available',
  }) async {
    log.info('Cancelling presubmit targets with buildbucket v2.');
    await _luciBuildService.cancelBuilds(
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
    final isFusion = slug == Config.flutterSlug;
    do {
      try {
        final sha = pullRequest.head!.sha!;
        if (!isFusion) {
          unlockMergeGroup = true;
        }

        // Both the author and label should be checked to make sure that no one is
        // attempting to get a pull request without check through.
        if (pullRequest.user!.login == _config.autosubmitBot &&
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
        if (await _filesChangedOptimizer.checkPullRequest(pullRequest)
            case final opt when opt.shouldUsePrebuiltEngine) {
          final logCrumb =
              'triggerPresubmitTargets($slug, $sha){frameworkOnly}';
          log.info('$logCrumb: FRAMEWORK_ONLY_TESTING_PR');

          await CiStaging.initializeDocument(
            firestoreService: await _config.createFirestoreService(),
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
            testsToRun: switch (opt) {
              FilesChangedOptimization.skipPresubmitAllExceptFlutterAnalyze =>
                _FlutterRepoTestsToRun.frameworkFlutterAnalyzeOnly,
              FilesChangedOptimization.skipPresubmitEngine =>
                _FlutterRepoTestsToRun.frameworkTestsOnly,
              FilesChangedOptimization.none => throw StateError('Unreachable'),
            },
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
          await CiStaging.initializeDocument(
            firestoreService: await _config.createFirestoreService(),
            slug: slug,
            sha: sha,
            stage: CiStage.fusionEngineBuild,
            tasks: [...presubmitTriggerTargets.map((t) => t.name)],
            checkRunGuard: '$lock',
          );

          // Even though this appears to be an engine build, it could be a
          // release candidate build, where the engine artifacts are built
          // via the dart-internal builder.
          //
          // In either case, providing FLUTTER_PREBUILT_ENGINE_VERSION has no
          // consequences for engine builds, as it just won't be used (it is
          // only understood by the Flutter CLI).
          //
          // See https://github.com/flutter/flutter/issues/165810.
          engineArtifacts = EngineArtifacts.usingExistingEngine(commitSha: sha);
        } else {
          engineArtifacts = const EngineArtifacts.noFrameworkTests(
            reason: 'This is not the flutter/flutter repository',
          );
        }
        await _luciBuildService.scheduleTryBuilds(
          targets: presubmitTriggerTargets,
          pullRequest: pullRequest,
          engineArtifacts: engineArtifacts,
        );
      } on FormatException catch (e, s) {
        log.warn(
          'FormatException encountered when scheduling presubmit targets for '
          '${pullRequest.number}',
          e,
          s,
        );
        exception = e;
      } catch (e, s) {
        log.warn(
          'Exception encountered when scheduling presubmit targets for '
          '${pullRequest.number}',
          e,
          s,
        );
        exception = e;
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
      await _githubChecksService.githubChecksUtil.updateCheckRun(
        _config,
        slug,
        ciValidationCheckRun,
        status: CheckRunStatus.completed,
        conclusion: CheckRunConclusion.success,
      );
    } else {
      log.warn('Marking $description ${Config.kCiYamlCheckName} as failed', e);
      // Failure when validating ci.yaml
      await _githubChecksService.githubChecksUtil.updateCheckRun(
        _config,
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
    final ciValidationCheckRun = await _githubChecksService.githubChecksUtil
        .createCheckRun(
          _config,
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
    // final mergeGroup = mergeGroupEvent.mergeGroup;
    final MergeGroup(:headSha, :headRef, :baseRef) = mergeGroupEvent.mergeGroup;
    final slug = mergeGroupEvent.repository!.slug();
    final isFusion = slug == Config.flutterSlug;

    final logCrumb =
        'triggerMergeGroupTargets($slug, $headSha, ${isFusion ? 'real' : 'simulated'})';

    // Temporarily trigger content-aware-hash for merge groups.
    // We will not actually wait for the results yet.
    try {
      await _contentAwareHash.triggerWorkflow(headRef);
    } catch (e, s) {
      log.warn('contentAwareHash unexpectedly threw', e, s);
    }
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
        baseRef,
        slug,
        headSha,
        CiStage.fusionEngineBuild,
      ),
    };

    try {
      // Filter out targets missing builders - we cannot wait to complete the merge group if we will never complete.
      final availableBuilders = await _luciBuildService.getAvailableBuilderSet(
        project: 'flutter',
        bucket: 'prod',
      );
      final availableTargets = {
        ...mergeGroupTargets.where(
          (target) => availableBuilders.contains(target.name),
        ),
      };
      if (availableTargets.length != mergeGroupTargets.length) {
        log.warn(
          '$logCrumb: missing builders for targtets: '
          '${mergeGroupTargets.difference(availableTargets)}',
        );
      }

      // Create the staging doc that will track our engine progress and allow us to unlock
      // the merge group lock later.
      await CiStaging.initializeDocument(
        firestoreService: await _config.createFirestoreService(),
        slug: slug,
        sha: headSha,
        stage: CiStage.fusionEngineBuild,
        tasks: [...availableTargets.map((t) => t.name)],
        checkRunGuard: '$lock',
      );

      // Create the minimal Commit needed to pass the next stage.
      // Note: headRef encodes refs/heads/... and what we want is the branch
      await _luciBuildService.scheduleMergeGroupBuilds(
        targets: [...availableTargets],
        commit: CommitRef(
          branch: headRef.substring('refs/heads/'.length),
          slug: slug,
          sha: headSha,
        ),
      );

      // Do not unlock the merge group guard in successful case - that will be done by staging checks.
      log.info('$logCrumb: successfully scheduled merge group checks');
    } catch (e, s) {
      log.warn(
        '$logCrumb: error encountered when scheduling merge group checks',
        e,
        s,
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

ERROR: $e
$s
''',
        lock,
      );
    }
  }

  // Work in progress - Content Aware hash retrieval.
  Future<void> processWorkflowJob(WorkflowJobEvent job) async {
    try {
      final hash = await _contentAwareHash.hashFromWorkflowJobEvent(job);
      log.debug(
        'scheduler.processWorkflowJob(): Content-Aware-Hash = $hash for $job',
      );
    } catch (e) {
      log.debug('scheduler.processWorkflowJob($job) failed (no-op)', e);
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
        CiStage.fusionEngineBuild => target.isReleaseBuild,
        CiStage.fusionTests => !target.isReleaseBuild,
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

    final branch = baseRef.substring('refs/heads/'.length);
    final ciYaml = await _ciYamlFetcher.getCiYaml(
      slug: slug,
      commitBranch: branch,
      commitSha: headSha,
      validate: branch == Config.defaultBranch(slug),
    );
    log.info(
      'ci.yaml loaded successfully; collecting merge group targets for $headSha',
    );

    final inner = ciYaml.ciYamlFor(type);

    // Filter out targets with schedulers different than luci or cocoon.
    bool filter(Target target) =>
        target.scheduler == pb.SchedulerSystem.luci ||
        target.scheduler == pb.SchedulerSystem.cocoon;
    return [...inner.presubmitTargets.where(filter)];
  }

  /// Cancels builds for a destroyed merge group.
  Future<void> cancelDestroyedMergeGroupTargets({
    required String headSha,
  }) async {
    log.info('Cancelling merge group targets for $headSha');
    await _luciBuildService.cancelBuildsBySha(
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
    return _githubChecksService.githubChecksUtil.createCheckRun(
      _config,
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
    await _githubChecksService.githubChecksUtil.updateCheckRun(
      _config,
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
    await _githubChecksService.githubChecksUtil.updateCheckRun(
      _config,
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
          .where((Target target) => builderTriggerList.contains(target.name))
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
    log.info(
      'Attempting to read presubmit targets from ci.yaml for ${pullRequest.number}',
    );

    final branch = pullRequest.base!.ref!;
    final slug = pullRequest.base!.repo!.slug();
    final ciYaml = await _ciYamlFetcher.getCiYaml(
      commitBranch: branch,
      commitSha: pullRequest.head!.sha!,
      slug: slug,
      validate: branch == Config.defaultBranch(slug),
    );

    log.info('ci.yaml loaded successfully.');
    log.info('Collecting presubmit targets for ${pullRequest.number}');

    final inner = ciYaml.ciYamlFor(type);

    // Filter out schedulers targets with schedulers different than luci or cocoon.
    final presubmitTargets =
        inner.presubmitTargets
            .where(
              (Target target) =>
                  target.scheduler == pb.SchedulerSystem.luci ||
                  target.scheduler == pb.SchedulerSystem.cocoon,
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
        if (!target.presubmit &&
            !target.getProperties().containsKey('cache_name')) {
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
    final filesChanged = await _getFilesChanged.get(
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
    final conclusion = TaskConclusion.fromName(checkRun.conclusion);

    if (name == null ||
        sha == null ||
        slug == null ||
        conclusion == TaskConclusion.unknown ||
        kCheckRunsToIgnore.contains(name)) {
      return true;
    }

    final logCrumb = 'checkCompleted($name, $slug, $sha, $conclusion)';

    final isFusion = slug == Config.flutterSlug;
    if (!isFusion) {
      return true;
    }

    final isMergeGroup = detectMergeGroup(checkRun);

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
        CiStage.fusionEngineBuild => target.isReleaseBuild,
        CiStage.fusionTests => !target.isReleaseBuild,
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
      if (pullRequest.user!.login == _config.autosubmitBot &&
          pullRequest.labels!.any(
            (element) => element.name == Config.revertOfLabel,
          )) {
        log.info(
          '$logCrumb: skipping generating the full set of checks for revert request.',
        );
      } else {
        // Schedule the tests that would have run in a call to triggerPresubmitTargets - but for both the
        // engine and the framework.
        var presubmitTargets = await _getTestsForStage(
          pullRequest,
          CiStage.fusionTests,
          skipEngine:
              testsToRun != _FlutterRepoTestsToRun.engineTestsAndFrameworkTests,
        );

        // Create the document for tracking test check runs.
        final List<String> tasks;
        if (testsToRun == _FlutterRepoTestsToRun.frameworkFlutterAnalyzeOnly) {
          const linuxAnalyze = 'Linux analyze';
          final singleTarget = presubmitTargets.firstWhereOrNull(
            (t) => t.name == linuxAnalyze,
          );
          if (singleTarget == null) {
            log.warn('No target found named "$linuxAnalyze"');
            tasks = [];
            presubmitTargets = [];
          } else {
            log.info('Only running target "$linuxAnalyze"');
            tasks = [linuxAnalyze];
            presubmitTargets = [singleTarget];
          }
        } else {
          tasks = [...presubmitTargets.map((t) => t.name)];
        }

        await CiStaging.initializeDocument(
          firestoreService: await _config.createFirestoreService(),
          slug: pullRequest.base!.repo!.slug(),
          sha: pullRequest.head!.sha!,
          stage: CiStage.fusionTests,
          tasks: tasks,
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
        if (testsToRun != _FlutterRepoTestsToRun.engineTestsAndFrameworkTests) {
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

        await _luciBuildService.scheduleTryBuilds(
          targets: presubmitTargets,
          pullRequest: pullRequest,
          engineArtifacts: engineArtifacts,
        );
      }
    } on FormatException catch (e, s) {
      log.warn(
        '$logCrumb: FormatException encountered when scheduling presubmit '
        'targets for ${pullRequest.number}',
        e,
        s,
      );
      rethrow;
    } catch (e, s) {
      log.warn(
        '$logCrumb: Exception encountered when scheduling presubmit targets '
        'for ${pullRequest.number}',
        e,
        s,
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
      pullRequest = await PrCheckRuns.findPullRequestFor(
        await _config.createFirestoreService(),
        id,
        name,
      );
    } catch (e, s) {
      log.warn('$logCrumb: unable to find PR in PrCheckRuns', e, s);
    }

    // We've failed to find the pull request; try a reverse look it from the check suite.
    if (pullRequest == null) {
      final checkSuiteId = checkRun.checkSuite!.id!;
      pullRequest = await _githubChecksService.findMatchingPullRequest(
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
      final githubService = await _config.createDefaultGitHubService();
      await githubService.createComment(
        slug,
        issueNumber: pullRequest.number!,
        body: '''
CI had a failure that stopped further tests from running.  We need to investigate to determine the root cause.

SHA at time of execution: $sha.

Possible causes:
* **Configuration Changes:** The `.ci.yaml` file might have been modified between the creation of this pull request and the start of this test run. This can lead to ci yaml validation errors.
* **Infrastructure Issues:** Problems with the CI environment itself (e.g., quota) could have caused the failure.

A blank commit, or merging to head, will be required to resume running CI for this PR.

**Error Details:**

```
$error
```

Stack trace:

```
$stacktrace
```
''',
      );
    }
  }

  Future<StagingConclusion> _recordCurrentCiStage({
    required RepositorySlug slug,
    required String sha,
    required CiStage stage,
    required String name,
    required TaskConclusion conclusion,
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

    final firestoreService = await _config.createFirestoreService();
    return r.retry(() {
      return CiStaging.markConclusion(
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
        log.debug(
          'Rerun requested by GitHub user: ${checkRunEvent.sender?.login}',
        );
        final name = checkRunEvent.checkRun!.name;
        var success = false;
        if (name == Config.kMergeQueueLockName) {
          final slug = checkRunEvent.repository!.slug();
          final checkSuiteId = checkRunEvent.checkRun!.checkSuite!.id!;
          log.debug(
            'Requested re-run of "${Config.kMergeQueueLockName}" for '
            '$slug / $checkSuiteId - ignoring',
          );
          success = true;
        } else if (name == Config.kCiYamlCheckName) {
          // The CheckRunEvent.checkRun.pullRequests array is empty for this
          // event, so we need to find the matching pull request.
          final slug = checkRunEvent.repository!.slug();
          final headSha = checkRunEvent.checkRun!.headSha!;
          final checkSuiteId = checkRunEvent.checkRun!.checkSuite!.id!;
          final pullRequest = await _githubChecksService
              .findMatchingPullRequest(slug, headSha, checkSuiteId);
          if (pullRequest != null) {
            log.debug(
              'Matched PR: ${pullRequest.number} Repo: ${slug.fullName}',
            );
            await triggerPresubmitTargets(pullRequest: pullRequest);
            success = true;
          } else {
            log.warn('No matching PR found for head_sha in check run event.');
          }
        } else {
          try {
            final slug = checkRunEvent.repository!.slug();
            final sha = checkRunEvent.checkRun!.headSha!;

            // Only merged commits are added to the Database.
            // If a commit is found, this must be a postsubmit checkrun.
            final firestore = await _config.createFirestoreService();
            final fsCommit = await fs.Commit.tryFromFirestoreBySha(
              firestore,
              sha: sha,
            );

            // TODO(matanlurey): Refactor into its own branch.
            // https://github.com/flutter/flutter/issues/167211.
            final isPresubmit = fsCommit == null;
            if (isPresubmit) {
              log.debug(
                'Rescheduling presubmit build for ${checkRunEvent.checkRun?.name}',
              );
              final pullRequest = await PrCheckRuns.findPullRequestForSha(
                await _config.createFirestoreService(),
                checkRunEvent.checkRun!.headSha!,
              );
              if (pullRequest == null) {
                return ProcessCheckRunResult.userError(
                  'Asked to reschedule presubmits for unknown sha/PR: ${checkRunEvent.checkRun!.headSha!}',
                );
              }

              final isFusion = slug == Config.flutterSlug;
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
                final opt = await _filesChangedOptimizer.checkPullRequest(
                  pullRequest,
                );
                if (opt.shouldUsePrebuiltEngine) {
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
                (target) => checkRunEvent.checkRun!.name == target.name,
              );
              if (target == null) {
                return ProcessCheckRunResult.missingEntity(
                  'Could not reschedule checkRun "${checkRunEvent.checkRun!.name}", '
                  'not found in list of presubmit targets: ${presubmitTargets.map((t) => t.name).toList()}',
                );
              }
              await _luciBuildService.scheduleTryBuilds(
                targets: [target],
                pullRequest: pullRequest,
                engineArtifacts: engineArtifacts,
              );
            } else {
              log.debug('Rescheduling postsubmit build.');

              final checkName = checkRunEvent.checkRun!.name!;
              final fs.Task fsTask;
              {
                // Query the lastest run of the `checkName` againt commit `sha`.
                final fsTasks = await firestore.queryRecentTasks(
                  limit: 1,
                  commitSha: fsCommit.sha,
                  name: checkName,
                );
                if (fsTasks.isEmpty) {
                  throw StateError('Expected 1+ tasks for $checkName');
                }
                fsTask = fsTasks.first;
              }
              log.debug('Latest firestore task is $fsTask');
              final ciYaml = await _ciYamlFetcher.getCiYamlByFirestoreCommit(
                fsCommit,
              );
              final target = ciYaml.postsubmitTargets().singleWhere(
                (target) => target.name == fsTask.taskName,
              );
              await _luciBuildService
                  .reschedulePostsubmitBuildUsingCheckRunEvent(
                    checkRunEvent,
                    commit: CommitRef.fromFirestore(fsCommit),
                    task: fsTask,
                    target: target,
                  );
            }

            success = true;
          } on NoBuildFoundException {
            log.warn('No build found to reschedule.');
          } on FormatException catch (e) {
            // See https://github.com/flutter/flutter/issues/165018.
            log.info('CheckName: $name failed due to user error: $e');
            return ProcessCheckRunResult.userError('$e');
          }
        }

        log.debug('CheckName: $name State: $success');

        // TODO(matanlurey): It would be better to early return above where it is not a success.
        if (!success) {
          return const ProcessCheckRunResult.unexpectedError(
            'Not successful. See previous log messages',
          );
        }
    }

    return const ProcessCheckRunResult.success();
  }

  /// Push [Commit] to BigQuery as part of the infra metrics dashboards.
  Future<void> _uploadToBigQuery(fs.Commit commit) async {
    const projectId = 'flutter-dashboard';
    const dataset = 'cocoon';
    const table = 'Checklist';

    log.info('Uploading commit ${commit.sha} info to bigquery.');

    final bigquery = await _config.createBigQueryService();
    final tabledataResource = bigquery.tabledata;
    final tableDataInsertAllRequestRows = <Map<String, Object>>[];

    /// Consolidate [commits] together
    ///
    /// Prepare for bigquery [insertAll]
    tableDataInsertAllRequestRows.add(<String, Object>{
      'json': <String, Object?>{
        'CreateTimestamp': commit.createTimestamp,
        'FlutterRepositoryPath': commit.repositoryPath,
        'CommitSha': commit.sha,
        'CommitAuthorLogin': commit.author,
        'CommitAuthorAvatarURL': commit.avatar,
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
        log.warn('Rows to be inserted is null');
      } else {
        log.info(
          'Inserting ${rows.rows!.length} into big query for ${commit.sha}',
        );
      }
      await tabledataResource.insertAll(rows, projectId, dataset, table);
    } on ApiRequestError catch (e) {
      log.warn('Failed to add commits to BigQuery', e);
    }
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

  /// No tests.
  frameworkFlutterAnalyzeOnly,
}
