// Copyright 2021 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:math';

import 'package:cocoon_common/task_status.dart';
import 'package:cocoon_server/logging.dart';
import 'package:collection/collection.dart';
import 'package:github/github.dart';
import 'package:github/hooks.dart';
import 'package:googleapis/bigquery/v2.dart';
import 'package:googleapis/firestore/v1.dart' as g;
import 'package:meta/meta.dart';
import 'package:retry/retry.dart';

import '../foundation/utils.dart';
import '../model/ci_yaml/ci_yaml.dart';
import '../model/ci_yaml/target.dart';
import '../model/commit_ref.dart';
import '../model/common/checks_extension.dart';
import '../model/common/presubmit_check_state.dart';
import '../model/common/presubmit_completed_check.dart';
import '../model/common/presubmit_guard_conclusion.dart';
import '../model/firestore/base.dart';
import '../model/firestore/ci_staging.dart';
import '../model/firestore/commit.dart' as fs;
import '../model/firestore/pr_check_runs.dart';
import '../model/firestore/presubmit_guard.dart';
import '../model/firestore/task.dart' as fs;
import '../model/github/checks.dart' as cocoon_checks;
import '../model/github/checks.dart' show MergeGroup;
import '../model/github/workflow_job.dart';
import '../model/proto/internal/scheduler.pb.dart' as pb;
import '../request_handling/http_utils.dart';
import 'big_query.dart';
import 'cache_service.dart';
import 'config.dart';
import 'content_aware_hash_service.dart';
import 'exceptions.dart';
import 'firestore.dart';
import 'firestore/unified_check_run.dart';
import 'get_files_changed.dart';
import 'github_checks_service.dart';
import 'luci_build_service.dart';
import 'luci_build_service/engine_artifacts.dart';
import 'luci_build_service/pending_task.dart';
import 'scheduler/ci_yaml_fetcher.dart';
import 'scheduler/files_changed_optimization.dart';
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
    required FirestoreService firestore,
    required BigQueryService bigQuery,
  }) : _luciBuildService = luciBuildService,
       _githubChecksService = githubChecksService,
       _config = config,
       _getFilesChanged = getFilesChanged,
       _ciYamlFetcher = ciYamlFetcher,
       _contentAwareHash = contentAwareHash,
       _firestore = firestore,
       _bigQuery = bigQuery,
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
  final FirestoreService _firestore;
  final BigQueryService _bigQuery;

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

    final sha = pr.mergeCommitSha!;
    if (await _commitExistsInFirestore(sha: sha)) {
      log.debug('$sha already exists in Firestore. Scheduling skipped.');
      return;
    }

    log.debug('Scheduling $sha via GitHub webhook');
    final mergedCommit = fs.Commit.fromGithubPullRequest(pr);
    await _addCommit(mergedCommit);
  }

  /// Processes postsubmit tasks.
  Future<void> _addCommit(fs.Commit commit) async {
    if (!_config.supportedRepos.contains(commit.slug)) {
      log.debug('Skipping ${commit.sha} as repo is not supported');
      return;
    }
    final contentHash = await _contentAwareHash.getHashByCommitSha(commit.sha);

    final _TaskCommitScheduling scheduling;
    if (Config.defaultBranch(commit.slug) == commit.branch) {
      scheduling = _TaskCommitScheduling.defaultUseTargetSchedulingPolicy;
    } else {
      scheduling = _TaskCommitScheduling.nonDefaultBranchSkipTestsByDefault;
    }

    final ciYaml = await _ciYamlFetcher.getCiYamlByCommit(
      commit.toRef(),
      postsubmit: true,
    );
    final targets = ciYaml.postsubmitTargets();
    final isFusion = commit.slug == Config.flutterSlug;
    if (isFusion) {
      final fusionPostTargets = ciYaml.postsubmitTargets(
        type: CiType.fusionEngine,
      );
      targets.addAll(fusionPostTargets);
      // Note on post submit targets: CiYaml filters out release_true for release branches and fusion trees
    }

    final tasks = [
      ...targets.map((t) => fs.Task.initialFromTarget(t, commit: commit)),
    ];
    final toBeScheduled = <PendingTask>[];
    for (var target in targets) {
      final task = tasks.singleWhere((task) => task.taskName == target.name);
      // For flutter/flutter builds (non-master branch), we mark all builds that
      // do not build the engine as "skipped" for later manual scheduling. Most
      // branches won't have any release builds at this stage, but experimental
      // branches *will*, which is why "!target.isReleaseBuild" is used.
      //
      // See https://github.com/flutter/flutter/issues/169088.
      if (scheduling.skipPostsubmitTasks && !target.isReleaseBuild) {
        task.setStatus(TaskStatus.skipped);
        continue;
      }
      final priority = await target.schedulerPolicy.triggerPriority(
        taskName: task.taskName,
        commitSha: commit.sha,
        recentTasks: await _firestore.queryRecentTasks(name: task.taskName),
      );
      if (priority != null) {
        // Mark task as in progress to ensure it isn't scheduled over
        task.setStatus(TaskStatus.inProgress);
        toBeScheduled.add(
          PendingTask(
            target: target,
            taskName: task.taskName,
            priority: priority,
            currentAttempt: 1,
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
    await _batchScheduleBuilds(
      commit.toRef(),
      toBeScheduled,
      contentHash: contentHash,
    );
    await _uploadToBigQuery(commit);
  }

  Future<void> _addCommitFirestore(
    fs.Commit commit,
    List<fs.Task> tasks,
  ) async {
    await _firestore.writeViaTransaction(
      documentsToWrites([...tasks, commit], exists: false),
    );
  }

  /// Schedule all builds in batch requests instead of a single request.
  ///
  /// Each batch request contains [Config.batchSize] builds to be scheduled.
  Future<void> _batchScheduleBuilds(
    CommitRef commit,
    List<PendingTask> toBeScheduled, {
    String? contentHash,
  }) async {
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
          contentHash: contentHash,
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
    final commit = await fs.Commit.tryFromFirestoreBySha(_firestore, sha: sha);
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
    final lock = await lockMergeGroupChecks(
      slug,
      pullRequest.head!.sha!,
      // Override details url of merge queue guard check for users with unified
      // check run flow enabled
      detailsUrl:
          _config.flags.isUnifiedCheckRunFlowEnabledForUser(
            pullRequest.user!.login!,
          )
          ? 'https://flutter-dashboard.appspot.com/#/presubmit?repo=${slug.name}&sha=${pullRequest.head!.sha}'
          : null,
    );

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

          await UnifiedCheckRun.initializeCiStagingDocument(
            firestoreService: _firestore,
            slug: slug,
            sha: sha,
            stage: CiStage.fusionEngineBuild,
            tasks: [],
            pullRequest: pullRequest,
            config: _config,
          );

          await _runCiTestingStage(
            pullRequest: pullRequest,
            checkRunGuard: lock,
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
        final presubmitTargets = isFusion
            ? await _getTestsForStage(pullRequest, CiStage.fusionEngineBuild)
            : await getPresubmitTargets(pullRequest);
        final presubmitTriggerTargets = filterTargets(
          presubmitTargets,
          builderTriggerList,
        );

        // When running presubmits for a fusion PR; create a new staging document to track tasks needed
        // to complete before we can schedule more tests (i.e. build engine artifacts before testing against them).
        final EngineArtifacts engineArtifacts;
        if (isFusion) {
          await UnifiedCheckRun.initializeCiStagingDocument(
            firestoreService: _firestore,
            slug: slug,
            sha: sha,
            stage: CiStage.fusionEngineBuild,
            tasks: [...presubmitTriggerTargets.map((t) => t.name)],
            pullRequest: pullRequest,
            config: _config,
            checkRun: lock,
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
          checkRunGuard: lock,
          stage: CiStage.fusionEngineBuild,
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
        if (e is g.DetailedApiRequestError && e.status == HttpStatus.conflict) {
          rethrow;
        }
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

  Future<void> handleMergeGroupEvent({
    required cocoon_checks.MergeGroupEvent mergeGroupEvent,
  }) async {
    final MergeGroup(:headSha, :headRef, :baseRef) = mergeGroupEvent.mergeGroup;
    final slug = mergeGroupEvent.repository!.slug();
    final isFusion = slug == Config.flutterSlug;

    final logCrumb =
        'triggerTargetsForMergeGroup($slug, $headSha, ${isFusion ? 'real' : 'simulated'})';

    if (isFusion) {
      // Temporarily trigger content-aware-hash for merge groups.
      // We will not actually wait for the results yet.
      try {
        await _contentAwareHash.triggerWorkflow(headRef);
      } catch (e, s) {
        log.warn('contentAwareHash unexpectedly threw', e, s);
      }
      if (_config.flags.contentAwareHashing.waitOnContentHash) {
        log.info(
          '$logCrumb: content hashing requested; waiting on job to complete',
        );
        return;
      }
    }
    log.info('$logCrumb: scheduling merge group checks');
    return await triggerTargetsForMergeGroup(
      baseRef: baseRef,
      headSha: headSha,
      headRef: headRef,
      slug: slug,
    );
  }

  Future<void> triggerTargetsForMergeGroup({
    required String headSha,
    required String headRef,
    required String baseRef,
    required RepositorySlug slug,
    String? contentHash,
  }) async {
    // Behave similar to addPullRequest, except we're not yet merged into master.
    //   - We are mirrored in to GoB
    //   - We want PROD builds
    //   - We want check_runs as well
    //   - We want updates on check_runs to the presubmit pubsub.
    // We do not want "Task" objects because these are for flutter-dashboard tracking (post submit)
    // final mergeGroup = mergeGroupEvent.mergeGroup;
    final isFusion = slug == Config.flutterSlug;

    final logCrumb =
        'triggerTargetsForMergeGroup($slug, $headSha, ${isFusion ? 'real' : 'simulated'}'
        '${contentHash != null ? ', contentHash: $contentHash' : ''})';
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
          '$logCrumb: missing builders for targets: '
          '${mergeGroupTargets.difference(availableTargets)}',
        );
      }

      // Create the staging doc that will track our engine progress and allow us to unlock
      // the merge group lock later.
      await UnifiedCheckRun.initializeCiStagingDocument(
        firestoreService: _firestore,
        slug: slug,
        sha: headSha,
        stage: CiStage.fusionEngineBuild,
        tasks: [...availableTargets.map((t) => t.name)],
        config: _config,
        checkRun: lock,
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
        contentHash: contentHash,
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
        slug: slug,
        lock: lock,
        headSha: headSha,
        summary: 'Failed to schedule checks for merge group',
        details:
            '''
$logCrumb

ERROR: $e
$s
''',
      );
    }
  }

  // Work in progress - Content Aware hash retrieval.
  Future<void> processWorkflowJob(WorkflowJobEvent event) async {
    try {
      final artifactStatus = await _contentAwareHash.processWorkflowJob(event);
      log.info(
        'scheduler.processWorkflowJob(): artifacts status: $artifactStatus '
        'for ${event.workflowJob?.checkRunUrl}',
      );

      // TODO: MergeQueueHashStatus
      //   - .build: trigger targets!
      //   - .wait: something is building.
      //   - .completed: hash already built, complete!
      //   - .*: do nothing
      // FOR NOW: trigger builds for build/wait/completed because they are also
      //          building for SHA.
      switch (artifactStatus.status) {
        case MergeQueueHashStatus.build ||
                MergeQueueHashStatus.wait ||
                MergeQueueHashStatus.complete
            when _config.flags.contentAwareHashing.waitOnContentHash &&
                artifactStatus.contentHash.isNotEmpty:
          // Note from codefu: We do not have the merge queue lock yet.
          // It was short-circuited if the waitOnContentHash is set. The
          // CAH document _has_ been created. In the future, "wait" will need
          // to create the lock - and auto complete it - to let the merge
          // group complete.
          final job = event.workflowJob!;
          log.info(
            'triggering merge group targets for $artifactStatus / ${job.headSha}',
          );
          await triggerTargetsForMergeGroup(
            headSha: job.headSha!,
            headRef: 'refs/heads/${job.headBranch!}',
            baseRef:
                'refs/heads/${tryParseGitHubMergeQueueBranch(job.headBranch!).branch}',
            slug: event.repository!.slug(),
            contentHash: artifactStatus.status == MergeQueueHashStatus.build
                ? artifactStatus.contentHash
                : null,
          );

        default:
          break;
      }
    } catch (e, s) {
      log.debug(
        'scheduler.processWorkflowJob(${event.workflowJob?.checkRunUrl}) failed (no-op)',
        e,
        s,
      );
    }
  }

  Future<List<Target>> getMergeGroupTargetsForStage(
    String baseRef,
    RepositorySlug slug,
    String headSha,
    CiStage stage,
  ) async {
    final mergeGroupTargets =
        [
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
    final ciYaml = await _ciYamlFetcher.getCiYamlByCommit(
      CommitRef(sha: headSha, branch: branch, slug: slug),
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
    // Mark content hash as invalid (if it exists)
    await _completeArtifacts(headSha, false);
  }

  /// Pushes the required "Merge Queue Guard" check to the merge queue, which
  /// serves as a "lock".
  ///
  /// While this check is still in progress, the merge queue will not merge the
  /// respective PR onto the target branch (e.g. main or master), because this
  /// check is "required".
  Future<CheckRun> lockMergeGroupChecks(
    RepositorySlug slug,
    String headSha, {
    String? detailsUrl,
  }) async {
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
  Future<void> failGuardForMergeGroup({
    required RepositorySlug slug,
    required CheckRun lock,
    required String headSha,
    required String summary,
    required String details,
    String? detailsUrl,
  }) async {
    log.info('Failing merge group guard for merge group $headSha in $slug');
    await _githubChecksService.githubChecksUtil.updateCheckRun(
      _config,
      slug,
      lock,
      status: CheckRunStatus.completed,
      conclusion: CheckRunConclusion.failure,
      output: CheckRunOutput(
        title: Config.kMergeQueueLockName,
        summary: summary,
        text: details,
      ),
      detailsUrl: detailsUrl,
    );
  }

  Future<void> _requireActionForGuard({
    required RepositorySlug slug,
    required CheckRun lock,
    required String headSha,
    required String summary,
    required String details,
    String? detailsUrl,
  }) async {
    log.info('''
Require action for merge group guard ${lock.id} for:
head sha: $headSha
slug: $slug
summary: $summary
details: $details
detailsUrl: $detailsUrl
''');
    await _githubChecksService.githubChecksUtil.updateCheckRun(
      _config,
      slug,
      lock,
      status: CheckRunStatus.completed,
      conclusion: CheckRunConclusion.actionRequired,
      output: CheckRunOutput(
        title: Config.kMergeQueueLockName,
        summary: summary,
        text: details,
      ),
      detailsUrl: detailsUrl,
      actions: [
        const CheckRunAction(
          label: 'Re-run Failed',
          description: 'Re-run failed tests',
          identifier: 're_run_failed',
        ),
      ],
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
    final ciYaml = await _ciYamlFetcher.getCiYamlByCommit(
      CommitRef(slug: slug, branch: branch, sha: pullRequest.head!.sha!),
    );

    log.info('ci.yaml loaded successfully.');
    log.info('Collecting presubmit targets for ${pullRequest.number}');

    final inner = ciYaml.ciYamlFor(type);

    // Filter out schedulers targets with schedulers different than luci or cocoon.
    final presubmitTargets = inner.presubmitTargets
        .where(
          (Target target) =>
              target.scheduler == pb.SchedulerSystem.luci ||
              target.scheduler == pb.SchedulerSystem.cocoon,
        )
        .toList();

    log.info('Collected ${presubmitTargets.length} presubmit targets.');
    // Release branches should run every test.
    if (pullRequest.base!.ref !=
        Config.defaultBranch(pullRequest.base!.repo!.slug())) {
      log.info(
        'Release branch found, scheduling all targets for ${pullRequest.number}',
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

  /// Process a completed GitHub `check_run`.
  ///
  /// Handles both fusion engine build and test stages, and both pull requests
  /// and merge groups.
  Future<bool> processCheckRunCompleted(PresubmitCompletedCheck check) async {
    if (kCheckRunsToIgnore.contains(check.name)) {
      return true;
    }
    final flow = check.isUnifiedCheckRun ? 'unified' : 'github';
    final requestor = check.isMergeGroup ? 'merge group' : 'pull request';
    final logCrumb =
        'checkCompleted(${check.name}, $flow, $requestor, ${check.slug}, ${check.sha}, ${check.status})';

    final isFusion = check.slug == Config.flutterSlug;
    if (!isFusion) {
      return true;
    }

    late CiStage stage;
    late PresubmitGuardConclusion stagingConclusion;

    if (check.isUnifiedCheckRun) {
      stage = check.stage!;
      stagingConclusion = await _markUnifiedCheckRunConclusion(
        guardId: check.guardId,
        state: check.state,
      );
    } else {
      // for github flow check runs are processed only if the build succeeded or
      // some kind of failure occurred.
      if (!check.status.isBuildCompleted) {
        return true;
      }
      // Check runs are fired at every stage. However, at this point it is unknown
      // if this check run belongs in the engine build stage or in the test stage.
      // So first look for it in the engine stage, and if it's missing, look for
      // it in the test stage.
      stage = CiStage.fusionEngineBuild;
      stagingConclusion = await _recordCurrentCiStage(
        slug: check.slug,
        sha: check.sha,
        stage: stage,
        name: check.name,
        conclusion: check.status.toTaskConclusion(),
      );

      if (stagingConclusion.result == PresubmitGuardConclusionResult.missing) {
        // Check run not found in the engine stage. Look for it in the test stage.
        stage = CiStage.fusionTests;
        stagingConclusion = await _recordCurrentCiStage(
          slug: check.slug,
          sha: check.sha,
          stage: stage,
          name: check.name,
          conclusion: check.status.toTaskConclusion(),
        );
      }
    }
    // First; check if we even recorded anything. This can occur if we've already passed the check_run and
    // have moved on to running more tests (which wouldn't be present in our document).
    if (!stagingConclusion.isOk) {
      return false;
    }

    // If an internal error happened in Cocoon, we need human assistance to
    // figure out next steps.
    if (stagingConclusion.result ==
        PresubmitGuardConclusionResult.internalError) {
      // If an internal error happened in the merge group, there may be no further
      // signals from GitHub that would cause the merge group to either land or
      // fail. The safest thing to do is to kick the pull request out of the queue
      // and let humans sort it out. If the group is left hanging in the queue, it
      // will hold up all other PRs that are trying to land.
      if (check.isMergeGroup) {
        await _completeArtifacts(check.sha, false);
        final guard = checkRunFromString(stagingConclusion.checkRunGuard!);
        await failGuardForMergeGroup(
          slug: check.slug,
          lock: guard,
          headSha: check.sha,
          summary: stagingConclusion.summary,
          details: stagingConclusion.details,
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
      // If its a unified check run we need to require action on the guard.
      if (check.isMergeGroup) {
        await _completeArtifacts(check.sha, false);
        final guard = checkRunFromString(stagingConclusion.checkRunGuard!);
        await failGuardForMergeGroup(
          slug: check.slug,
          lock: guard,
          headSha: check.sha,
          summary: stagingConclusion.summary,
          details: stagingConclusion.details,
        );
      } else if (check.isUnifiedCheckRun) {
        final guard = checkRunFromString(stagingConclusion.checkRunGuard!);
        final detailsUrl =
            'https://flutter-dashboard.appspot.com/#/presubmit?repo=${check.slug.name}&sha=${check.sha}';
        await _requireActionForGuard(
          slug: check.slug,
          lock: guard,
          headSha: check.sha,
          summary: _githubChecksService.getGithubSummaryWithHeader('''
**[Failed Checks Details]($detailsUrl)**

''', kMergeQueueLockDescription),
          details:
              'For CI stage ${check.stage} ${stagingConclusion.failed} checks failed',
          detailsUrl: detailsUrl,
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
        if (check.isMergeGroup) {
          await _completeArtifacts(check.sha, true);
          await _closeMergeQueue(
            mergeQueueGuard: stagingConclusion.checkRunGuard!,
            slug: check.slug,
            sha: check.sha,
            stage: CiStage.fusionEngineBuild,
            logCrumb: logCrumb,
          );
        } else {
          await _closeSuccessfulEngineBuildStage(
            checkRun: check.checkRun,
            mergeQueueGuard: stagingConclusion.checkRunGuard!,
            slug: check.slug,
            sha: check.sha,
            logCrumb: logCrumb,
          );
        }
      case CiStage.fusionTests:
        await _closeSuccessfulTestStage(
          mergeQueueGuard: stagingConclusion.checkRunGuard!,
          slug: check.slug,
          sha: check.sha,
          logCrumb: logCrumb,
        );
    }
    return true;
  }

  Future<void> _completeArtifacts(String commitSha, bool successful) async {
    try {
      await _contentAwareHash.completeArtifacts(
        commitSha: commitSha,
        successful: successful,
      );
    } catch (e, s) {
      log.warn(
        'failed to simulate completing artifacts with successful:$successful',
        e,
        s,
      );
    }
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
    final presubmitTargets =
        [
          ...await getPresubmitTargets(pullRequest),
          if (!skipEngine)
            ...await getPresubmitTargets(
              pullRequest,
              type: CiType.fusionEngine,
            ),
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
    required CheckRun checkRunGuard,
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

        await UnifiedCheckRun.initializeCiStagingDocument(
          firestoreService: _firestore,
          slug: pullRequest.base!.repo!.slug(),
          sha: pullRequest.head!.sha!,
          stage: CiStage.fusionTests,
          tasks: tasks,
          config: _config,
          pullRequest: pullRequest,
          checkRun: checkRunGuard,
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
          checkRunGuard: checkRunGuard,
          stage: CiStage.fusionTests,
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

    final pullRequest = await findPullRequestCached(
      checkRun.id!,
      checkRun.name!,
      slug,
      sha,
      checkRun.checkSuite!.id!,
    );

    // We cannot make any forward progress. Abandon all hope, Check runs who enter here.
    if (pullRequest == null) {
      throw 'No PR found matching this check_run(${checkRun.id}, ${checkRun.name})';
    }

    try {
      await _runCiTestingStage(
        pullRequest: pullRequest,
        checkRunGuard: checkRunGuard,
        logCrumb: logCrumb,
        testsToRun: _FlutterRepoTestsToRun.engineTestsAndFrameworkTests,
      );
    } catch (error, stacktrace) {
      final githubService = await _config.createDefaultGitHubService();
      await githubService.createComment(
        slug,
        issueNumber: pullRequest.number!,
        body:
            '''
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

  Future<PresubmitGuardConclusion> _recordCurrentCiStage({
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

    return r.retry(() {
      return CiStaging.markConclusion(
        firestoreService: _firestore,
        slug: slug,
        sha: sha,
        stage: stage,
        checkRun: name,
        conclusion: conclusion,
      );
    });
  }

  Future<PresubmitGuardConclusion> _markUnifiedCheckRunConclusion({
    required PresubmitGuardId guardId,
    required PresubmitCheckState state,
  }) async {
    final logCrumb =
        'checkCompleted(${state.buildName}, ${guardId.stage}, ${guardId.slug}, ${state.status})';

    log.info('$logCrumb: ${guardId.documentId}');
    // We're doing a transactional update, which could fail if multiple tasks
    // are running at the same time so retry a sane amount of times before
    // giving up.
    const r = RetryOptions(maxAttempts: 5, delayFactor: Duration(seconds: 5));

    try {
      return await r.retry(() {
        return UnifiedCheckRun.markConclusion(
          firestoreService: _firestore,
          guardId: guardId,
          state: state,
        );
      });
    } on Exception catch (e, s) {
      log.warn('$logCrumb: Failed to mark unified check run conclusion', e, s);
      rethrow;
    }
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
        if (!_config.flags.closeMqGuardAfterPresubmit) {
          await processCheckRunCompleted(
            PresubmitCompletedCheck.fromCheckRun(
              checkRunEvent.checkRun!,
              checkRunEvent.repository!.slug(),
            ),
          );
        }
        break;
      case 'rerequested':
        return await _reRun(checkRunEvent);
      case 'requested_action':
        switch (checkRunEvent.requestedAction?.identifier) {
          case 're_run_failed':
            return await _reRunFailed(checkRunEvent);
          default:
            log.debug(
              'Requested unexpected action identifier: ${checkRunEvent.requestedAction?.identifier} for ${checkRunEvent.checkRun!.id} check-run id',
            );
            break;
        }
        break;
      default:
        log.debug(
          'Requested unexpected action: ${checkRunEvent.action} for ${checkRunEvent.checkRun!.id} check-run id',
        );
        break;
    }

    return const ProcessCheckRunResult.success();
  }

  Future<ProcessCheckRunResult> _reRun(
    cocoon_checks.CheckRunEvent checkRunEvent,
  ) async {
    final logCrumb = 'reRun(${checkRunEvent.checkRun!.id})';
    log.debug(
      '$logCrumb: Rerun requested by GitHub user: ${checkRunEvent.sender?.login}',
    );
    final name = checkRunEvent.checkRun!.name;
    var success = false;
    if (name == Config.kMergeQueueLockName) {
      final slug = checkRunEvent.repository!.slug();
      final checkSuiteId = checkRunEvent.checkRun!.checkSuite!.id!;
      log.debug(
        '$logCrumb: Requested re-run of "${Config.kMergeQueueLockName}" for '
        '$slug / $checkSuiteId - ignoring',
      );
      success = true;
    } else if (name == Config.kCiYamlCheckName) {
      // The CheckRunEvent.checkRun.pullRequests array is empty for this
      // event, so we need to find the matching pull request.
      final slug = checkRunEvent.repository!.slug();
      final headSha = checkRunEvent.checkRun!.headSha!;
      final checkSuiteId = checkRunEvent.checkRun!.checkSuite!.id!;
      final pullRequest = await _githubChecksService.findMatchingPullRequest(
        slug,
        headSha,
        checkSuiteId,
      );
      if (pullRequest != null) {
        log.debug('Matched PR: ${pullRequest.number} Repo: ${slug.fullName}');
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
        final fsCommit = await fs.Commit.tryFromFirestoreBySha(
          _firestore,
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
            _firestore,
            checkRunEvent.checkRun!.headSha!,
          );
          if (pullRequest == null) {
            return ProcessCheckRunResult.userError(
              'Asked to reschedule presubmits for unknown sha/PR: ${checkRunEvent.checkRun!.headSha!}',
            );
          }

          final (presubmitTargets, engineArtifacts) =
              await _getAllTargetsForPullRequest(slug, pullRequest);

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
            checkRunGuard: null,
            stage: null,
          );
        } else {
          log.debug('Rescheduling postsubmit build.');

          final checkName = checkRunEvent.checkRun!.name!;
          final fs.Task fsTask;
          {
            // Query the lastest run of the `checkName` againt commit `sha`.
            final fsTasks = await _firestore.queryRecentTasks(
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
          final ciYaml = await _ciYamlFetcher.getCiYamlByCommit(
            fsCommit.toRef(),
            postsubmit: true,
          );
          final target = ciYaml.postsubmitTargets().singleWhere(
            (target) => target.name == fsTask.taskName,
          );
          await _luciBuildService.reschedulePostsubmitBuildUsingCheckRunEvent(
            checkRunEvent,
            commit: fsCommit.toRef(),
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
    return const ProcessCheckRunResult.success();
  }

  Future<PullRequest?> findPullRequestCached(
    int checkRunId,
    String checkRunName,
    RepositorySlug slug,
    String headSha,
    int checkSuiteId,
  ) async {
    final logCrumb = 'findPullRequestCached($checkRunId)';
    PullRequest? pullRequest;
    // Look up the PR in our cache first. This reduces github quota and requires less calls.
    try {
      pullRequest = await PrCheckRuns.findPullRequestFor(
        _firestore,
        checkRunId,
        checkRunName,
      );
    } catch (e, s) {
      log.info('$logCrumb: unable to find PR in PrCheckRuns', e, s);
    }
    // We've failed to find the pull request; try a reverse look it from the check suite.

    pullRequest ??= await _githubChecksService.findMatchingPullRequest(
      slug,
      headSha,
      checkSuiteId,
    );
    if (pullRequest == null) {
      log.warn('$logCrumb: No pull request found');
    }
    return pullRequest;
  }

  Future<ProcessCheckRunResult> _reRunFailed(
    cocoon_checks.CheckRunEvent checkRunEvent,
  ) async {
    final logCrumb = 'reRunFailed(${checkRunEvent.checkRun!.id})';
    log.info('$logCrumb: Requested to re-run failed tests');

    // The CheckRunEvent.checkRun.pullRequests array is empty for this
    // event, so we need to find the matching pull request.
    final slug = checkRunEvent.repository!.slug();

    final pullRequest = await findPullRequestCached(
      checkRunEvent.checkRun!.id!,
      checkRunEvent.checkRun!.name!,
      checkRunEvent.repository!.slug(),
      checkRunEvent.checkRun!.headSha!,
      checkRunEvent.checkRun!.checkSuite!.id!,
    );

    final failedChecks = await UnifiedCheckRun.reInitializeFailedChecks(
      firestoreService: _firestore,
      slug: slug,
      pullRequestId: pullRequest!.number!,
      checkRunId: checkRunEvent.checkRun!.id!,
    );

    if (failedChecks == null) {
      log.error('$logCrumb: No failed targets found');
      return const ProcessCheckRunResult.missingEntity(
        'No failed targets found',
      );
    }

    final (targets, artifacts) = await _getAllTargetsForPullRequest(
      slug,
      pullRequest,
    );

    final failedTargets = targets
        .where((target) => failedChecks.checkNames.contains(target.name))
        .toList();
    if (failedTargets.length != failedChecks.checkNames.length) {
      log.error(
        '$logCrumb: Failed to find all failed targets in presubmit targets',
      );
      return const ProcessCheckRunResult.missingEntity(
        'Failed to find all failed targets in presubmit targets',
      );
    }

    await _luciBuildService.scheduleTryBuilds(
      targets: failedTargets,
      pullRequest: pullRequest,
      engineArtifacts: artifacts,
      checkRunGuard: failedChecks.checkRunGuard,
      stage: failedChecks.stage,
    );

    log.info(
      '$logCrumb: Successfully rescheduled ${failedTargets.length} targets',
    );
    return const ProcessCheckRunResult.success();
  }

  Future<(List<Target>, EngineArtifacts)> _getAllTargetsForPullRequest(
    RepositorySlug slug,
    PullRequest pullRequest,
  ) async {
    final isFusion = slug == Config.flutterSlug;
    final List<Target> presubmitTargets;
    final EngineArtifacts engineArtifacts;
    if (isFusion) {
      // Fusion repos have presubmits split across two .ci.yaml files.
      // /ci.yaml
      // /engine/src/flutter/.ci.yaml
      presubmitTargets = [
        ...await getPresubmitTargets(pullRequest),
        ...await getPresubmitTargets(pullRequest, type: CiType.fusionEngine),
      ];
      final opt = await _filesChangedOptimizer.checkPullRequest(pullRequest);
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
    return (presubmitTargets, engineArtifacts);
  }

  /// Push [Commit] to BigQuery as part of the infra metrics dashboards.
  Future<void> _uploadToBigQuery(fs.Commit commit) async {
    const projectId = 'flutter-dashboard';
    const dataset = 'cocoon';
    const table = 'Checklist';

    log.info('Uploading commit ${commit.sha} info to bigquery.');

    final tabledataResource = _bigQuery.tabledata;
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

enum _TaskCommitScheduling {
  /// Schedule according to how [Target.schedulerPolicy] is computed.
  defaultUseTargetSchedulingPolicy,

  /// Non-default branches skip tests by default for later (manual) scheduling.
  nonDefaultBranchSkipTestsByDefault;

  /// Whether postsubmit tasks should be initially skipped.
  bool get skipPostsubmitTasks {
    return this == nonDefaultBranchSkipTestsByDefault;
  }
}
