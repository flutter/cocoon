// Copyright 2021 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:buildbucket/buildbucket_pb.dart' as bbv2;
import 'package:cocoon_server/logging.dart';
import 'package:cocoon_service/src/model/firestore/ci_staging.dart';
import 'package:cocoon_service/src/model/firestore/pr_check_runs.dart';
import 'package:cocoon_service/src/service/build_status_provider.dart';
import 'package:cocoon_service/src/service/exceptions.dart';
import 'package:cocoon_service/src/service/scheduler/policy.dart';
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
import '../model/firestore/commit.dart' as firestore_commmit;
import '../model/firestore/task.dart' as firestore;
import '../model/github/checks.dart' as cocoon_checks;
import '../model/proto/internal/scheduler.pb.dart' as pb;
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
    required this.fusionTester,
    this.datastoreProvider = DatastoreService.defaultProvider,
    this.httpClientProvider = Providers.freshHttpClient,
    this.buildStatusProvider = BuildStatusService.defaultProvider,
    @visibleForTesting this.markCheckRunConclusion = CiStaging.markConclusion,
    @visibleForTesting this.initializeCiStagingDocument = CiStaging.initializeDocument,
    @visibleForTesting this.findPullRequestFor = PrCheckRuns.findPullRequestFor,
  });

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
  }) markCheckRunConclusion;

  Future<Document> Function({
    required FirestoreService firestoreService,
    required RepositorySlug slug,
    required String sha,
    required CiStage stage,
    required List<String> tasks,
    required String checkRunGuard,
  }) initializeCiStagingDocument;

  final Future<PullRequest> Function(
    FirestoreService firestoreService,
    int checkRunId,
    String checkRunName,
  ) findPullRequestFor;

  /// Name of the subcache to store scheduler related values in redis.
  static const String subcacheName = 'scheduler';

  /// Validates that CI tasks were successfully created from the .ci.yaml file.
  ///
  /// If this check fails, it means Cocoon failed to fully populate the list of
  /// CI checks and the PR/commit should be treated as failing.
  static const String kCiYamlCheckName = 'ci.yaml validation';

  /// A required check that stays in pending state until a sufficient subset of
  /// checks pass.
  ///
  /// This check is "required", meaning that it must pass before Github will
  /// allow a PR to land in the merge queue, or a merge group to land on the
  /// target branch (main or master).
  ///
  /// IMPORTANT: the name of this task - "Merge Queue Guard" - must strictly
  /// match the name of the required check configured in the repo settings.
  /// Changing the name here or in the settings alone will break the PR
  /// workflow.
  static const String kMergeQueueLockName = 'Merge Queue Guard';

  /// List of check runs that do not need to be tracked or looked up in
  /// any staging logic.
  static const kCheckRunsToIgnore = [kMergeQueueLockName, kCiYamlCheckName];

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

    final CiYamlSet ciYaml = await getCiYaml(commit);

    // TODO(codefu): support fusion engine
    final List<Target> initialTargets = ciYaml.getInitialTargets(ciYaml.postsubmitTargets());
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
  Future<CiYamlSet> getCiYaml(
    Commit commit, {
    bool validate = false,
  }) async {
    final isFusion = await fusionTester.isFusionBasedRef(commit.slug, commit.sha!);
    final Commit totCommit = await generateTotCommit(slug: commit.slug, branch: Config.defaultBranch(commit.slug));
    final CiYamlSet totYaml = await _getCiYaml(totCommit, isFusionCommit: isFusion);
    return _getCiYaml(commit, totCiYaml: totYaml, validate: validate, isFusionCommit: isFusion);
  }

  /// Load in memory the `.ci.yaml`.
  Future<CiYamlSet> _getCiYaml(
    Commit commit, {
    CiYamlSet? totCiYaml,
    bool validate = false,
    RetryOptions retryOptions = const RetryOptions(delayFactor: Duration(seconds: 2), maxAttempts: 4),
    bool isFusionCommit = false,
  }) async {
    Future<pb.SchedulerConfig> getSchedulerConfig(String ciPath) async {
      final Uint8List ciYamlBytes = (await cache.getOrCreate(
        subcacheName,
        // This is a key for a cache; not a path - so its needs to be 'unique'
        '${commit.repository}/${commit.sha!}/$ciPath',
        createFn: () async => (await _downloadCiYaml(
          commit,
          // actual path to go and fetch
          ciPath,
          retryOptions: retryOptions,
        ))
            .writeToBuffer(),
        ttl: const Duration(hours: 1),
      ))!;
      final pb.SchedulerConfig schedulerConfig = pb.SchedulerConfig.fromBuffer(ciYamlBytes);
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
    final String configContent = await githubFileContent(
      commit.slug,
      ciPath,
      httpClientProvider: httpClientProvider,
      ref: commit.sha!,
      retryOptions: retryOptions,
    );
    final YamlMap configYaml = loadYaml(configContent) as YamlMap;
    final pb.SchedulerConfig schedulerConfig = pb.SchedulerConfig()..mergeFromProto3Json(configYaml);
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
    log.info('Attempting to cancel existing presubmit targets for ${pullRequest.number}');
    await cancelPreSubmitTargets(
      pullRequest: pullRequest,
      reason: reason,
    );

    final slug = pullRequest.base!.repo!.slug();

    // The MQ only waits for "required status checks" before deciding whether to
    // merge the PR into the target branch. This required check added to both
    // the PR and to the merge group, and so it must be completed in both cases.
    final lock = await lockMergeGroupChecks(slug, pullRequest.head!.sha!);

    final ciValidationCheckRun = await createCiYamlCheckRun(pullRequest, slug);

    log.info('Creating presubmit targets for ${pullRequest.number}');
    Object? exception;
    bool isFusion = false;
    try {
      final sha = pullRequest.head!.sha!;
      isFusion = await fusionTester.isFusionBasedRef(slug, sha);

      // Both the author and label should be checked to make sure that no one is
      // attempting to get a pull request without check through.
      if (pullRequest.user!.login == config.autosubmitBot &&
          pullRequest.labels!.any((element) => element.name == Config.revertOfLabel)) {
        log.info('Skipping generating the full set of checks for revert request.');
      } else {
        final presubmitTargets = isFusion
            ? await getTestsForStage(pullRequest, CiStage.fusionEngineBuild)
            : await getPresubmitTargets(pullRequest);
        final presubmitTriggerTargets = filterTargets(presubmitTargets, builderTriggerList);

        // When running presubmits for a fusion PR; create a new staging document to track tasks needed
        // to complete before we can schedule more tests (i.e. build engine artifacts before testing against them).
        if (isFusion) {
          await initializeCiStagingDocument(
            firestoreService: firestoreService,
            slug: slug,
            sha: sha,
            stage: CiStage.fusionEngineBuild,
            tasks: [...presubmitTriggerTargets.map((t) => t.value.name)],
            checkRunGuard: '$lock',
          );
        }
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
    await closeCiYamlCheckRun('PR ${pullRequest.number}', exception, slug, ciValidationCheckRun);

    // The 'lock' will be unlocked later in processCheckRunCompletion after all engine builds are processed.
    if (!isFusion) {
      await unlockMergeGroupChecks(slug, pullRequest.head!.sha!, lock, exception);
    }
    log.info(
      'Finished triggering builds for: pr ${pullRequest.number}, commit ${pullRequest.base!.sha}, branch ${pullRequest.head!.ref} and slug $slug}',
    );
  }

  Future<void> closeCiYamlCheckRun(
    String description,
    exception,
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
      log.warning('Marking $description $kCiYamlCheckName as failed', e);
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
  }

  Future<CheckRun> createCiYamlCheckRun(PullRequest pullRequest, RepositorySlug slug) async {
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
    return ciValidationCheckRun;
  }

  static Duration debugCheckPretendDelay = const Duration(minutes: 1);

  Future<void> triggerMergeGroupTargets({
    required cocoon_checks.MergeGroupEvent mergeGroupEvent,
  }) async {
    /*
      Behave similar to addPullRequest, except we're not yet merged into master.
        - We are mirrored in to GoB
        - We want PROD builds
        - We want check_runs as well
          - this might mean we want a different pubsub?
      
      We don't need "Task" objects because I beleive these are used by flutter-dashboard,
      we're tracking with github. So really we need _batchScheduleBuilds

      batchSCheduleBuilds just calls schedulePostsubmitBuilds - which creates but doesn't
      return the check run?

      CODEFU - left off here.
    */
    final mergeGroup = mergeGroupEvent.mergeGroup;
    final headSha = mergeGroup.headSha;
    final slug = mergeGroupEvent.repository!.slug();
    final isFusion = await fusionTester.isFusionBasedRef(slug, headSha);

    final logCrumb = 'triggerMergeGroupTargets($slug, $headSha, ${isFusion ? 'real' : 'simulated'})';

    log.info('$logCrumb: Scheduling merge group checks');

    final lock = await lockMergeGroupChecks(slug, headSha);

    final ciValidationCheckRun = await githubChecksService.githubChecksUtil.createCheckRun(
      config,
      slug,
      headSha,
      'Merge queue check',
      output: const CheckRunOutput(
        title: 'Merge queue check',
        summary: 'If this check is stuck pending, push an empty commit to retrigger the checks',
      ),
    );

    if (!isFusion) {
      await simulateMergeGroupUnlock(mergeGroup, slug, ciValidationCheckRun, headSha, lock);
      return;
    }

    final mergeGroupTargets = await getMergeGroupTargetsForStage(
      mergeGroup.baseRef,
      slug,
      headSha,
      CiStage.fusionEngineBuild,
    );

    Object? exception;
    try {
      // Create the staging doc that will track our engine progress and allow us to unlock
      // the merge group lock later.
      await initializeCiStagingDocument(
        firestoreService: firestoreService,
        slug: slug,
        sha: headSha,
        stage: CiStage.fusionEngineBuild,
        tasks: [...mergeGroupTargets.map((t) => t.value.name)],
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
        targets: mergeGroupTargets,
        commit: commit,
      );
    } catch (e, s) {
      log.warning('$logCrumb: error encountered when scheduling presubmit targets', e, s);
      exception = e;
    }

    await closeCiYamlCheckRun('MQ $slug/$headSha', exception, slug, ciValidationCheckRun);

    // Do not unlock the merge group `lock` - that will be done by staging checks.

    log.info('$logCrumb: Finished merge group checks');
  }

  Future<List<Target>> getMergeGroupTargetsForStage(
    String baseRef,
    RepositorySlug slug,
    String headSha,
    CiStage stage,
  ) async {
    final mergeGroupTargets = [
      ...await getMergeGroupTargets(baseRef, slug, headSha),
      ...await getMergeGroupTargets(baseRef, slug, headSha, type: CiType.fusionEngine),
    ].where(
      (Target target) => switch (stage) {
        CiStage.fusionEngineBuild => target.value.properties['release_build'] == 'true',
        CiStage.fusionTests => target.value.properties['release_build'] != 'true'
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
    log.info('Attempting to read merge group targets from ci.yaml for $headSha');

    final Commit commit = Commit(
      branch: baseRef,
      repository: slug.fullName,
      sha: headSha,
    );
    final ciYaml = await getCiYaml(commit, validate: true);
    log.info('ci.yaml loaded successfully.');
    log.info('Collecting merge group targets for $headSha');
    final inner = ciYaml.ciYamlFor(type);
    final List<Target> postSubmitTargets = [
      ...inner.postsubmitTargets.where(
        (Target target) =>
            target.value.scheduler == pb.SchedulerSystem.luci || target.value.scheduler == pb.SchedulerSystem.cocoon,
      ),
    ];

    log.info('Collected ${postSubmitTargets.length} merge group targets.');
    return postSubmitTargets;
  }

  // Pretend the check took 1 minute to run
  Future<void> simulateMergeGroupUnlock(
    cocoon_checks.MergeGroup mergeGroup,
    RepositorySlug slug,
    CheckRun ciValidationCheckRun,
    String headSha,
    CheckRun lock,
  ) async {
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
      lock,
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

  /// Pushes the required "Merge Queue Guard" check to the merge queue, which
  /// serves as a "lock".
  ///
  /// While this check is still in progress, the merge queue will not merge the
  /// respective PR onto the target branch (e.g. main or master), because this
  /// check is "required".
  Future<CheckRun> lockMergeGroupChecks(RepositorySlug slug, String headSha) async {
    return githubChecksService.githubChecksUtil.createCheckRun(
      config,
      slug,
      headSha,
      kMergeQueueLockName,
      output: const CheckRunOutput(
        title: kMergeQueueLockName,
        summary: kMergeQueueLockDescription,
      ),
    );
  }

  /// Completes the "Merge Queue Guard" check that was scheduled using
  /// [lockMergeGroupChecks] with either success or failure.
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
      log.info('All required tests passed for $headSha');
      await githubChecksService.githubChecksUtil.updateCheckRun(
        config,
        slug,
        lock,
        status: CheckRunStatus.completed,
        conclusion: CheckRunConclusion.success,
      );
    } else {
      // Some checks failed. Unlocking Github with failure.
      log.info('Some required tests failed for $headSha');
      log.warning(exception.toString());
      await githubChecksService.githubChecksUtil.updateCheckRun(
        config,
        slug,
        lock,
        status: CheckRunStatus.completed,
        conclusion: CheckRunConclusion.failure,
        output: CheckRunOutput(
          title: kCiYamlCheckName,
          summary: 'Some required tests failed for $headSha',
          text: exception.toString(),
        ),
      );
    }
  }

  /// If [builderTriggerList] is specificed, return only builders that are contained in [presubmitTarget].
  /// Otherwise, return [presubmitTarget].
  List<Target> filterTargets(
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
  @visibleForTesting
  Future<List<Target>> getPresubmitTargets(PullRequest pullRequest, {CiType type = CiType.any}) async {
    final Commit commit = Commit(
      branch: pullRequest.base!.ref,
      repository: pullRequest.base!.repo!.fullName,
      sha: pullRequest.head!.sha,
    );
    late CiYamlSet ciYaml;
    log.info('Attempting to read presubmit targets from ci.yaml for ${pullRequest.number}');
    if (commit.branch == Config.defaultBranch(commit.slug)) {
      ciYaml = await getCiYaml(commit, validate: true);
    } else {
      ciYaml = await getCiYaml(commit);
    }
    log.info('ci.yaml loaded successfully.');
    log.info('Collecting presubmit targets for ${pullRequest.number}');

    final inner = ciYaml.ciYamlFor(type);

    // Filter out schedulers targets with schedulers different than luci or cocoon.
    final List<Target> presubmitTargets = inner.presubmitTargets
        .where(
          (Target target) =>
              target.value.scheduler == pb.SchedulerSystem.luci || target.value.scheduler == pb.SchedulerSystem.cocoon,
        )
        .toList();

    // See https://github.com/flutter/flutter/issues/138430.
    final includePostsubmitAsPresubmit = _includePostsubmitAsPresubmit(inner, pullRequest);
    if (includePostsubmitAsPresubmit) {
      log.info('Including postsubmit targets as presubmit for ${pullRequest.number}');

      for (Target target in inner.postsubmitTargets) {
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

  /// Process completed GitHub `check_run` to enable fusion engine builds.
  Future<bool> processCheckRunCompletion(cocoon_checks.CheckRunEvent checkRunEvent) async {
    final name = checkRunEvent.checkRun?.name;
    final sha = checkRunEvent.checkRun?.headSha;
    final slug = checkRunEvent.repository?.slug();
    final conclusion = checkRunEvent.checkRun?.conclusion;

    if (name == null || sha == null || slug == null || conclusion == null || kCheckRunsToIgnore.contains(name)) {
      return true;
    }

    final isFusion = await fusionTester.isFusionBasedRef(slug, sha);
    if (!isFusion) {
      return true;
    }
    final logCrumb = 'checkCompleted($name, $slug, $sha, $conclusion)';

    firestoreService = await config.createFirestoreService();

    // Check runs are fired at every stage; but this code is only interested in check runs during the engine-build
    // stage. Once this stage passes, the document will still exist, but there won't be any valid updates.
    const stage = CiStage.fusionEngineBuild;
    final stagingConclusion =
        await _recordCurrentCiStage(slug: slug, sha: sha, stage: stage, name: name, conclusion: conclusion);

    // First; check if we even recorded anything. This can occur if we've already passed the check_run and
    // have moved on to running more tests (which wouldn't be present in our document).
    if (stagingConclusion == null || !stagingConclusion.valid) {
      return false;
    }

    // Are their tests remaining? Then we shouldn't unblock guard yet.
    if (stagingConclusion.isPending) {
      log.info('$logCrumb: not progressing, remaining work count: ${stagingConclusion.remaining}');
      return false;
    }

    if (stagingConclusion.isFailed) {
      await _reportCiStageFailure(
        conclusion: stagingConclusion,
        slug: slug,
        sha: sha,
        stage: stage,
        logCrumb: logCrumb,
      );
      return true;
    }

    // We know that we're in a fusion repo; now we need to figure out if we are
    //   1) in a presubmit test or
    //   2) in the merge queue
    final headBranch = checkRunEvent.checkRun?.checkSuite?.headBranch;
    final isInMergeQueue = headBranch?.startsWith('gh-readonly-queue/') ?? false;
    if (isInMergeQueue) {
      await _closeMergeQueue(
        conclusion: stagingConclusion,
        slug: slug,
        sha: sha,
        stage: stage,
        logCrumb: logCrumb,
      );
      return true;
    }

    // TODO: track newer stages.
    await _proceedToCiTestingStage(
      checkRunEvent: checkRunEvent,
      conclusion: stagingConclusion,
      slug: slug,
      sha: sha,
      stage: stage,
      logCrumb: logCrumb,
    );

    return true;
  }

  /// Returns the presubmit targets for the fusion repo [pullRequest] that should run for the given [stage].
  Future<List<Target>> getTestsForStage(PullRequest pullRequest, CiStage stage) async {
    final presubmitTargets = [
      ...await getPresubmitTargets(pullRequest),
      ...await getPresubmitTargets(pullRequest, type: CiType.fusionEngine),
    ].where(
      (Target target) => switch (stage) {
        CiStage.fusionEngineBuild => target.value.properties['release_build'] == 'true',
        CiStage.fusionTests => target.value.properties['release_build'] != 'true'
      },
    );
    return [...presubmitTargets];
  }

  Future<void> _closeMergeQueue({
    required StagingConclusion conclusion,
    required RepositorySlug slug,
    required String sha,
    required CiStage stage,
    required String logCrumb,
  }) async {
    log.info('$logCrumb: Merge Queue finished successfully');

    // Unlock the guarding check_run.
    final checkRunGuard = checkRunFromString(conclusion.checkRunGuard!);
    await unlockMergeGroupChecks(slug, sha, checkRunGuard, null);
  }

  Future<void> _reportCiStageFailure({
    required RepositorySlug slug,
    required String sha,
    required StagingConclusion conclusion,
    required CiStage stage,
    required String logCrumb,
  }) async {
    log.info('$logCrumb: Stage failed: $stage with failed=${conclusion.failed}');

    // Unlock the guarding check_run.
    final checkRunGuard = checkRunFromString(conclusion.checkRunGuard!);
    await unlockMergeGroupChecks(slug, sha, checkRunGuard, 'failed ${conclusion.failed} test');
  }

  Future<void> _proceedToCiTestingStage({
    required cocoon_checks.CheckRunEvent checkRunEvent,
    required RepositorySlug slug,
    required String sha,
    required StagingConclusion conclusion,
    required CiStage stage,
    required String logCrumb,
  }) async {
    log.info('$logCrumb: Stage completed: $stage with failed=${conclusion.failed}');

    final checkRunGuard = checkRunFromString(conclusion.checkRunGuard!);

    // Look up the PR in our cache first. This reduces github quota and requires less calls.
    PullRequest? pullRequest;
    final id = checkRunEvent.checkRun!.id!;
    final name = checkRunEvent.checkRun!.name!;
    try {
      pullRequest = await findPullRequestFor(
        firestoreService,
        id,
        name,
      );
    } catch (e, s) {
      log.warning('$logCrumb: unable to find PR in PrCheckRuns', e, s);
    }

    // We'va failed to find the pull request; try a reverse look it from the check suite.
    if (pullRequest == null) {
      final int checkSuiteId = checkRunEvent.checkRun!.checkSuite!.id!;
      pullRequest = await githubChecksService.findMatchingPullRequest(slug, sha, checkSuiteId);
    }

    // We cannot make any forward progress. Abandon all hope, Check runs who enter here.
    if (pullRequest == null) {
      throw 'No PR found matching this check_run($id, $name)';
    }

    Object? exception;
    try {
      // Both the author and label should be checked to make sure that no one is
      // attempting to get a pull request without check through.
      if (pullRequest.user!.login == config.autosubmitBot &&
          pullRequest.labels!.any((element) => element.name == Config.revertOfLabel)) {
        log.info('$logCrumb: skipping generating the full set of checks for revert request.');
      } else {
        // Schedule the tests that would have run in a call to triggerPresubmitTargets - but for both the
        // engine and the framework.
        final presubmitTargets = await getTestsForStage(pullRequest, CiStage.fusionTests);

        await luciBuildService.scheduleTryBuilds(
          targets: presubmitTargets,
          pullRequest: pullRequest,
        );
      }
    } on FormatException catch (error, backtrace) {
      log.warning(
        '$logCrumb: FormatException encountered when scheduling presubmit targets for ${pullRequest.number}',
        error,
        backtrace,
      );
      exception = error;
    } catch (error, backtrace) {
      log.warning(
        '$logCrumb: Exception encountered when scheduling presubmit targets for ${pullRequest.number}',
        error,
        backtrace,
      );
      exception = error;
    }

    // Unlock the guarding check_run.
    await unlockMergeGroupChecks(slug, sha, checkRunGuard, exception);
  }

  Future<StagingConclusion?> _recordCurrentCiStage({
    required RepositorySlug slug,
    required String sha,
    required CiStage stage,
    required String name,
    required String conclusion,
  }) async {
    final logCrumb = 'checkCompleted($name, $slug, $sha, $conclusion)';
    final documentName = CiStaging.documentNameFor(slug: slug, sha: sha, stage: stage);
    log.info('$logCrumb: $documentName');
    StagingConclusion stagingConclusion;
    try {
      // We're doing a transactional update, which could fail if multiple tasks are running at the same time; so retry
      // a sane amount of times before giving up.
      const RetryOptions r = RetryOptions(
        maxAttempts: 3,
        delayFactor: Duration(seconds: 2),
      );
      stagingConclusion = await r.retry(
        () => markCheckRunConclusion(
          firestoreService: firestoreService,
          slug: slug,
          sha: sha,
          stage: stage,
          checkRun: name,
          conclusion: conclusion,
        ),
      );
    } catch (e, s) {
      // Ignore for now; we're testing
      log.warning('$logCrumb: error processing check_run', e, s);
      return null;
    }

    return stagingConclusion;
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
    // TODO(codefu): Figure out if we're in fusion or not.
    switch (checkRunEvent.action) {
      case 'completed':
        await processCheckRunCompletion(checkRunEvent);
        return true;

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
              final CiYamlSet ciYaml = await getCiYaml(commit);
              final Target target =
                  ciYaml.postsubmitTargets().singleWhere((Target target) => target.value.name == task.name);
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
  /// A tip of tree [Commit] is used to help generate the tip of tree [CiYamlSet].
  /// The generated tip of tree [CiYamlSet] will be compared against Presubmit Targets in current [CiYamlSet],
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
