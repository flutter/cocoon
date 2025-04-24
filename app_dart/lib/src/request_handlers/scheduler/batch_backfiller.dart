// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math';

import 'package:cocoon_common/is_release_branch.dart';
import 'package:cocoon_server/logging.dart';
import 'package:github/github.dart';
import 'package:meta/meta.dart';

import '../../../cocoon_service.dart';
import '../../model/ci_yaml/ci_yaml.dart';
import '../../model/firestore/task.dart' as fs;
import '../../request_handling/exceptions.dart';
import '../../service/firestore/commit_and_tasks.dart';
import '../../service/luci_build_service/commit_task_ref.dart';
import '../../service/luci_build_service/pending_task.dart';
import '../../service/scheduler/ci_yaml_fetcher.dart';
import '../../service/scheduler/policy.dart';
import 'backfill_grid.dart';
import 'backfill_strategy.dart';

/// Cron request handler for scheduling targets when capacity becomes available.
///
/// Targets that have a [BatchPolicy] need to have backfilling enabled to ensure that ToT is always being tested.
@immutable
final class BatchBackfiller extends RequestHandler {
  /// Creates a subscription for sending BuildBucket requests.
  const BatchBackfiller({
    required super.config,
    required CiYamlFetcher ciYamlFetcher,
    required LuciBuildService luciBuildService,
    required FirestoreService firestore,
    required BranchService branchService,
    BackfillStrategy backfillerStrategy = const DefaultBackfillStrategy(),
  }) : _ciYamlFetcher = ciYamlFetcher,
       _luciBuildService = luciBuildService,
       _backfillerStrategy = backfillerStrategy,
       _firestore = firestore,
       _branchService = branchService;

  final LuciBuildService _luciBuildService;
  final CiYamlFetcher _ciYamlFetcher;
  final BackfillStrategy _backfillerStrategy;
  final FirestoreService _firestore;
  final BranchService _branchService;

  @override
  Future<Body> get() async {
    await Future.forEach(config.supportedRepos, _backfillDefaultBranch);
    await _backfillReleaseBranch(Config.flutterSlug);
    return Body.empty;
  }

  Future<void> _backfillReleaseBranch(RepositorySlug slug) async {
    log.debug('Running release branch backfiller for "$slug"');

    // TODO(matanlurey): This is a tad inefficient, as it means we will make
    // X calls to GitHub every invocation of the Batch Backfiller, which as of
    // 2025-04-23 is every 5 minutes, so this is `3 * 5 * 12` or 180 calls to
    // GitHub per hour.
    //
    // We could possibly do one of the following to mitigate:
    // - Use `githubFileContent`, which doesn't use the GitHub API (uses CDN);
    // - Cache the result and read this less often (it does change, but rarely);
    // - Have some sort of job that periodically updates a Firestore document:
    //   collectionId="release_branches"
    //   [
    //     {"channel": "...", "reference: "..."},
    //     {"channel": "...", "reference: "..."},
    //     {"channel": "...", "reference: "..."},
    //   ]
    final branches = await _branchService.getReleaseBranches(slug: slug);
    for (final branch in branches) {
      if (!isReleaseCandidateBranch(branchName: branch.reference)) {
        continue;
      }
      final fsGrid = await _firestore.queryRecentCommitsAndTasks(
        slug,
        commitLimit: config.backfillerCommitLimit,
        branch: branch.reference,
      );
      await _doBackfillFrom(slug, fsGrid);
    }
  }

  Future<void> _backfillDefaultBranch(RepositorySlug slug) async {
    log.debug('Running default branch backfiller for "$slug"');
    final fsGrid = await _firestore.queryRecentCommitsAndTasks(
      slug,
      commitLimit: config.backfillerCommitLimit,
      branch: Config.defaultBranch(slug),
    );
    return await _doBackfillFrom(slug, fsGrid);
  }

  Future<void> _doBackfillFrom(
    RepositorySlug slug,
    List<CommitAndTasks> fsGrid,
  ) async {
    if (fsGrid.isEmpty) {
      log.warn('No commits to backfill');
      return;
    }

    // Fetch and build a "grid" of List<(OpaqueCommit, List<OpaqueTask>>).
    final BackfillGrid grid;
    {
      log.debug(
        'Fetched ${fsGrid.length} commits and '
        '${fsGrid.map((i) => i.tasks).expand((i) => i).length} tasks',
      );

      // Download the ToT .ci.yaml targets.
      final ciYaml = await _ciYamlFetcher.getCiYaml(
        slug: slug,
        commitSha: fsGrid.first.commit.sha,
        commitBranch: Config.defaultBranch(slug),
      );

      final totTargets = [
        ...ciYaml.postsubmitTargets(),
        if (ciYaml.isFusion)
          ...ciYaml.postsubmitTargets(type: CiType.fusionEngine),
      ];
      log.debug('Fetched ${totTargets.length} tip-of-tree targets');

      grid = BackfillGrid.from([
        for (final CommitAndTasks(:commit, :tasks) in fsGrid)
          (
            CommitRef.fromFirestore(commit),
            [...tasks.map(TaskRef.fromFirestore)],
          ),
      ], tipOfTreeTargets: totTargets);
    }
    log.debug('Built a grid of ${grid.targets.length} target columns');

    // Produce a list of tasks, ordered from highest to lowest, to backfill.
    // ... but only take the top N tasks, at most.
    final toBackfillTasks = _backfillerStrategy.determineBackfill(grid);
    final beforePruning = toBackfillTasks.length;

    // Reduce the list to at most the backfill capacity.
    ///
    // Note this doesn't do exactly what it seems - it just means *per API call*
    // we at most consider this many targets, not that we limit ourselves to
    // that many targets running at once. For example, even with a capacity of
    // 75, we can run 150+ targets, the first API call will be 75, the next one
    // 75 more, and so on.
    toBackfillTasks.length = min(
      toBackfillTasks.length,
      config.backfillerTargetLimit,
    );
    log.debug(
      'Backfilling ${toBackfillTasks.length} tasks (pruned from $beforePruning)',
    );

    // Update the database first before we schedule builds.
    await _updateFirestore(toBackfillTasks);
    log.info('Wrote updates to ${toBackfillTasks.length} tasks for backfill');

    await _scheduleWithRetries(toBackfillTasks);
    log.info('Scheduled ${toBackfillTasks.length} tasks with LUCI');
  }

  Future<void> _updateFirestore(List<BackfillTask> tasks) async {
    log.debug('Querying ${tasks.length} tasks in Firestore...');
    await _firestore.writeViaTransaction([
      ...tasks.map((toUpdate) {
        final BackfillTask(:task) = toUpdate;
        return fs.Task.patchStatus(
          fs.TaskId(
            commitSha: task.commitSha,
            taskName: task.name,
            currentAttempt: task.currentAttempt,
          ),
          fs.Task.statusInProgress,
        );
      }),
    ]);
    log.debug('Wrote to Firestore for backfill');
  }

  /// Schedules tasks with retry when hitting pub/sub server errors.
  Future<void> _scheduleWithRetries(List<BackfillTask> backfill) async {
    const retryOptions = Config.schedulerRetry;
    try {
      await retryOptions.retry(() async {
        if (await Future.wait(_backfillRequestList(backfill))
            case final pendingTasks
            when pendingTasks.any((pending) => pending.isNotEmpty)) {
          final didNotBackfill = pendingTasks.where(
            (element) => element.isNotEmpty,
          );
          log.info(
            'Backfill fails and retry backfilling ${didNotBackfill.length} targets.',
          );
          backfill = _updateBackfill(backfill, pendingTasks);
          throw InternalServerError(
            'Failed to backfill ${backfill.length} targets.',
          );
        }
      }, retryIf: (e) => e is InternalServerError);
    } catch (e, s) {
      log.error(
        'Failed to backfill ${backfill.length} targets due to error',
        e,
        s,
      );
      rethrow;
    }
  }

  /// Updates the [backfill] list with those that fail to get scheduled.
  ///
  /// [tupleLists] maintains the same tuple order as those in [backfill].
  /// Each element from [backfill] is encapsulated as a list in [tupleLists] to prepare for
  /// [scheduler.luciBuildService.schedulePostsubmitBuilds].
  List<BackfillTask> _updateBackfill(
    List<BackfillTask> backfill,
    List<List<PendingTask>> tupleLists,
  ) {
    final updatedBackfill = <BackfillTask>[];
    for (var i = 0; i < tupleLists.length; i++) {
      if (tupleLists[i].isNotEmpty) {
        updatedBackfill.add(backfill[i]);
      }
    }
    return updatedBackfill;
  }

  /// Creates a list of backfill requests.
  @useResult
  List<Future<List<PendingTask>>> _backfillRequestList(
    List<BackfillTask> backfill,
  ) {
    return [
      for (final item in backfill)
        _luciBuildService.schedulePostsubmitBuilds(
          commit: item.commit,
          toBeScheduled: [item.toPendingTask()],
        ),
    ];
  }
}
