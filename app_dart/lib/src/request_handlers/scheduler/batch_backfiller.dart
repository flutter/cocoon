// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math';

import 'package:cocoon_server/logging.dart';
import 'package:github/github.dart';
import 'package:meta/meta.dart';

import '../../../cocoon_service.dart';
import '../../model/appengine/commit.dart' as ds;
import '../../model/appengine/task.dart' as ds;
import '../../model/ci_yaml/ci_yaml.dart';
import '../../model/firestore/task.dart' as fs;
import '../../request_handling/exceptions.dart';
import '../../service/datastore.dart';
import '../../service/firestore/commit_and_tasks.dart';
import '../../service/luci_build_service/opaque_commit.dart';
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
    BackfillStrategy backfillerStrategy = const DefaultBackfillStrategy(),
  }) : _ciYamlFetcher = ciYamlFetcher,
       _luciBuildService = luciBuildService,
       _backfillerStrategy = backfillerStrategy;

  final LuciBuildService _luciBuildService;
  final CiYamlFetcher _ciYamlFetcher;
  final BackfillStrategy _backfillerStrategy;

  @override
  Future<Body> get() async {
    await Future.forEach(config.supportedRepos, _backfillRepository);
    return Body.empty;
  }

  Future<void> _backfillRepository(RepositorySlug slug) async {
    log.debug('Running backfiller for "$slug"');

    // Fetch and build a "grid" of List<(OpaqueCommit, List<OpaqueTask>>).
    final BackfillGrid grid;
    {
      // TODO(matanlurey): Switch this to use Firestore.
      final firestore = await config.createFirestoreService();
      final fsGrid = await firestore.queryRecentCommitsAndTasks(
        slug,
        commitLimit: config.backfillerCommitLimit,
      );
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
        ...ciYaml.backfillTargets(),
        if (ciYaml.isFusion)
          ...ciYaml.backfillTargets(type: CiType.fusionEngine),
      ];
      log.debug('Fetched ${totTargets.length} tip-of-tree targets');

      grid = BackfillGrid.from([
        for (final CommitAndTasks(:commit, :tasks) in fsGrid)
          (
            OpaqueCommit.fromFirestore(commit),
            [...tasks.map(OpaqueTask.fromFirestore)],
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
    await Future.wait([
      _updateDatastore(toBackfillTasks),
      _updateFirestore(toBackfillTasks),
    ]);
    log.info('Wrote updates to ${toBackfillTasks.length} tasks for backfill');

    await _scheduleWithRetries(toBackfillTasks);
    log.info('Scheduled ${toBackfillTasks.length} tasks with LUCI');
  }

  // ⚠️ WARNING ⚠️ This function makes up to ~75 sequential reads in a row.
  //
  // There is no batch query functionality in Datastore, and since we don't
  // want to rely on Datastore-first reads (for example, if the tasks origiante
  // from Firestore), this will read/write in a transaction.
  //
  // There is a chance this is too slow, or is error-prone due to the QPS to
  // Datastore. If that happens, it could be augmented where we make a call to
  // datastoreService.queryRecentTasks, and turn it into Map<String, dsTask>,
  // and look those up in the loop instead of making 75 sequential reads.
  Future<void> _updateDatastore(List<BackfillTask> tasks) async {
    if (!config.useLegacyDatastore) {
      return;
    }
    final datastore = DatastoreService.defaultProvider(config.db);
    await datastore.withTransaction<void>((tx) async {
      log.debug('Querying ${tasks.length} tasks in Datastore...');
      for (final BackfillTask(:commit, :task) in tasks) {
        final commitKey = ds.Commit.createKey(
          db: config.db,
          slug: commit.slug,
          gitBranch: commit.branch,
          sha: commit.sha,
        );

        final query = tx.db.query<ds.Task>(ancestorKey: commitKey);
        query.filter('name =', task.name);

        final dsTasks = await query.run().toList();
        if (dsTasks.length != 1) {
          throw InternalServerError(
            'Expected to find 1 task for ${task.name}, but found '
            '${dsTasks.length}',
          );
        }
        final dsTask = dsTasks.first;
        dsTask.status = ds.Task.statusInProgress;
        tx.queueMutations(inserts: [dsTask]);
      }

      await tx.commit();
      log.debug('Wrote to Datastore for backfill');
    });
  }

  Future<void> _updateFirestore(List<BackfillTask> tasks) async {
    final firestore = await config.createFirestoreService();
    log.debug('Querying ${tasks.length} tasks in Firestore...');
    await firestore.writeViaTransaction([
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
