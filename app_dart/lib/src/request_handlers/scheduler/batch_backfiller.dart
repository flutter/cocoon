// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_server/logging.dart';
import 'package:github/github.dart';
import 'package:meta/meta.dart';

import '../../../cocoon_service.dart';
import '../../model/appengine/task.dart';
import '../../model/ci_yaml/ci_yaml.dart';
import '../../model/ci_yaml/target.dart';
import '../../model/firestore/task.dart' as firestore;
import '../../request_handling/exceptions.dart';
import '../../service/datastore.dart';
import '../../service/luci_build_service/pending_task.dart';
import '../../service/scheduler/ci_yaml_fetcher.dart';
import '../../service/scheduler/policy.dart';

/// Cron request handler for scheduling targets when capacity becomes available.
///
/// Targets that have a [BatchPolicy] need to have backfilling enabled to ensure that ToT is always being tested.
@immutable
class BatchBackfiller extends RequestHandler {
  /// Creates a subscription for sending BuildBucket requests.
  const BatchBackfiller({
    required super.config,
    required this.scheduler,
    required this.ciYamlFetcher,
    @visibleForTesting
    this.datastoreProvider = DatastoreService.defaultProvider,
  });

  final DatastoreServiceProvider datastoreProvider;
  final Scheduler scheduler;
  final CiYamlFetcher ciYamlFetcher;

  @override
  Future<Body> get() async {
    final futures = <Future<void>>[];

    for (var slug in config.supportedRepos) {
      futures.add(backfillRepository(slug));
    }

    // Process all repos asynchronously
    await Future.wait<void>(futures);

    return Body.empty;
  }

  Future<void> backfillRepository(RepositorySlug slug) async {
    final datastore = datastoreProvider(config.db);
    final tasks =
        await datastore
            .queryRecentTasks(
              slug: slug,
              commitLimit: config.backfillerCommitLimit,
            )
            .toList();

    // Construct Task columns to scan for backfilling
    final taskMap = <String, List<FullTask>>{};
    for (var fullTask in tasks) {
      if (taskMap.containsKey(fullTask.task.name)) {
        taskMap[fullTask.task.name]!.add(fullTask);
      } else {
        taskMap[fullTask.task.name!] = <FullTask>[fullTask];
      }
    }

    // Check if should be scheduled (there is no yellow runs). Run the most recent gray.
    var backfill = <Tuple<Target, FullTask, int>>[];
    for (var taskColumn in taskMap.values) {
      final task = taskColumn.first;

      final ciYaml = await ciYamlFetcher.getCiYamlByDatastoreCommit(
        task.commit,
      );
      final ciYamlTargets = [
        ...ciYaml.backfillTargets(),
        if (ciYaml.isFusion)
          ...ciYaml.backfillTargets(type: CiType.fusionEngine),
      ];

      // Skips scheduling if the task is not in TOT commit anymore.
      final taskInToT = ciYamlTargets
          .map((Target target) => target.value.name)
          .toList()
          .contains(task.task.name);
      if (!taskInToT) {
        continue;
      }
      final target = ciYamlTargets.singleWhere(
        (target) => target.value.name == task.task.name,
      );
      if (target.schedulerPolicy is! BatchPolicy) {
        continue;
      }
      final backfillTask = _backfillTask(target, taskColumn);
      final priority = backfillPriority(taskColumn.map((e) => e.task).toList());
      if (priority != null && backfillTask != null) {
        backfill.add(
          Tuple<Target, FullTask, int>(target, backfillTask, priority),
        );
      }
    }

    // Get the number of targets to be backfilled in each cycle.
    backfill = getFilteredBackfill(backfill);

    log.debug('Backfilling ${backfill.length} builds');
    log.debug(backfill.map((tuple) => tuple.first.value.name).toString());

    // Update tasks status as in progress to avoid duplicate scheduling.
    final backfillTasks = backfill.map((tuple) => tuple.second.task).toList();
    try {
      await datastore.withTransaction<void>((transaction) async {
        transaction.queueMutations(inserts: backfillTasks);
        await transaction.commit();
        log.debug(
          'Updated ${backfillTasks.length} tasks: '
          '${backfillTasks.map((e) => e.name).toList()} when backfilling.',
        );
      });
      // TODO(keyonghan): remove try catch logic after validated to work.
      try {
        await updateTaskDocuments(backfillTasks);
      } catch (e) {
        log.warn(
          'Failed to update batch backfilled task documents in Firestore',
          e,
        );
      }

      // Schedule all builds asynchronously.
      // Schedule after db updates to avoid duplicate scheduling when db update fails.
      await _scheduleWithRetries(backfill);
    } catch (e) {
      log.error('Failed to update tasks when backfilling', e);
    }
  }

  /// Updates task documents in Firestore.
  Future<void> updateTaskDocuments(List<Task> tasks) async {
    if (tasks.isEmpty) {
      return;
    }
    final writes = documentsToWrites([
      ...tasks.map(firestore.Task.fromDatastore),
    ], exists: true);
    final firestoreService = await config.createFirestoreService();
    await firestoreService.writeViaTransaction(writes);
  }

  /// Filters [config.backfillerTargetLimit] targets to backfill.
  ///
  /// High priority targets will be guranteed to get back filled first. If more targets
  /// than [config.backfillerTargetLimit], pick the limited number of targets after a
  /// shuffle. This is to make sure all targets are picked with the same chance.
  List<Tuple<Target, FullTask, int>> getFilteredBackfill(
    List<Tuple<Target, FullTask, int>> backfill,
  ) {
    if (backfill.length <= config.backfillerTargetLimit) {
      return backfill;
    }
    final filteredBackfill = <Tuple<Target, FullTask, int>>[];
    final highPriorityBackfill =
        backfill
            .where(
              (element) => element.third == LuciBuildService.kRerunPriority,
            )
            .toList();
    final normalPriorityBackfill =
        backfill
            .where(
              (element) => element.third != LuciBuildService.kRerunPriority,
            )
            .toList();
    if (highPriorityBackfill.length >= config.backfillerTargetLimit) {
      highPriorityBackfill.shuffle();
      filteredBackfill.addAll(
        highPriorityBackfill.sublist(0, config.backfillerTargetLimit),
      );
    } else {
      filteredBackfill.addAll(highPriorityBackfill);
      normalPriorityBackfill.shuffle();
      filteredBackfill.addAll(
        normalPriorityBackfill.sublist(
          0,
          config.backfillerTargetLimit - highPriorityBackfill.length,
        ),
      );
    }
    return filteredBackfill;
  }

  /// Schedules tasks with retry when hitting pub/sub server errors.
  Future<void> _scheduleWithRetries(
    List<Tuple<Target, FullTask, int>> backfill,
  ) async {
    const retryOptions = Config.schedulerRetry;
    try {
      await retryOptions.retry(() async {
        final pendingTasks = await Future.wait<List<PendingTask>>(
          backfillRequestList(backfill),
        );
        if (pendingTasks.any(
          (List<PendingTask> tupleList) => tupleList.isNotEmpty,
        )) {
          final nonEmptyListLenght =
              pendingTasks
                  .where((element) => element.isNotEmpty)
                  .toList()
                  .length;
          log.info(
            'Backfill fails and retry backfilling $nonEmptyListLenght targets.',
          );
          backfill = _updateBackfill(backfill, pendingTasks);
          throw InternalServerError(
            'Failed to backfill ${backfill.length} targets.',
          );
        }
      }, retryIf: (Exception e) => e is InternalServerError);
    } catch (e) {
      log.error(
        'Failed to backfill ${backfill.length} targets due to error',
        e,
      );
    }
  }

  /// Updates the [backfill] list with those that fail to get scheduled.
  ///
  /// [tupleLists] maintains the same tuple order as those in [backfill].
  /// Each element from [backfill] is encapsulated as a list in [tupleLists] to prepare for
  /// [scheduler.luciBuildService.schedulePostsubmitBuilds].
  List<Tuple<Target, FullTask, int>> _updateBackfill(
    List<Tuple<Target, FullTask, int>> backfill,
    List<List<PendingTask>> tupleLists,
  ) {
    final updatedBackfill = <Tuple<Target, FullTask, int>>[];
    for (var i = 0; i < tupleLists.length; i++) {
      if (tupleLists[i].isNotEmpty) {
        updatedBackfill.add(backfill[i]);
      }
    }
    return updatedBackfill;
  }

  /// Creates a list of backfill requests.
  List<Future<List<PendingTask>>> backfillRequestList(
    List<Tuple<Target, FullTask, int>> backfill,
  ) {
    final futures = <Future<List<PendingTask>>>[];
    for (var tuple in backfill) {
      // TODO(chillers): The backfill priority is always going to be low. If this is a ToT task, we should run it at the default priority.
      final toBeScheduled = PendingTask(
        target: tuple.first,
        task: tuple.second.task,
        priority: tuple.third,
      );
      futures.add(
        // ignore: discarded_futures
        scheduler.luciBuildService.schedulePostsubmitBuilds(
          commit: tuple.second.commit,
          toBeScheduled: [toBeScheduled],
        ),
      );
    }

    return futures;
  }

  /// Returns priority for back filled targets.
  ///
  /// Skips scheduling newly created targets whose available entries are
  /// less than `BatchPolicy.kBatchSize`.
  ///
  /// Uses a higher priority if there is an earlier failed build. Otherwise,
  /// uses default `LuciBuildService.kBackfillPriority`
  int? backfillPriority(List<Task> tasks) {
    if (tasks.length < BatchPolicy.kBatchSize) {
      return null;
    }

    // TODO(matanlurey): This was duplicated as part of (incrementally) removing
    // datastore to prioritize firestore in other parts of the codebase; keep
    // this in sync with "shouldRerunPriority" in scheduler/policy.dart.
    if (_shouldRerunPriorityDatastore(tasks, BatchPolicy.kBatchSize)) {
      return LuciBuildService.kRerunPriority;
    }
    return LuciBuildService.kBackfillPriority;
  }

  // TODO(matanlurey): This was duplicated as part of (incrementally) removing
  // datastore to prioritize firestore in other parts of the codebase; keep
  // this in sync with "shouldRerunPriority" in scheduler/policy.dart.
  //
  // See https://github.com/flutter/flutter/issues/142951.
  static bool _shouldRerunPriorityDatastore(
    List<Task> tasks,
    int pastTaskNumber,
  ) {
    // Prioritize tasks that recently failed.
    var hasRecentFailure = false;
    for (var i = 0; i < pastTaskNumber && i < tasks.length; i++) {
      final task = tasks[i];
      if (task.status == Task.statusFailed ||
          task.status == Task.statusInfraFailure) {
        hasRecentFailure = true;
        break;
      }
    }
    return hasRecentFailure;
  }

  /// Returns the most recent [FullTask] to backfill.
  ///
  /// A [FullTask] is only returned iff:
  ///   1. There are no running builds (yellow)
  ///   2. There are tasks that haven't been run (gray)
  ///
  /// This is naive, and doesn't rely on knowing the actual Flutter infra capacity.
  ///
  /// Otherwise, returns null indicating nothing should be backfilled.
  FullTask? _backfillTask(Target target, List<FullTask> tasks) {
    final relevantTasks =
        tasks
            .where((FullTask task) => task.task.name == target.value.name)
            .toList();
    if (relevantTasks.any(
      (FullTask task) => task.task.status == Task.statusInProgress,
    )) {
      // Don't schedule more builds where there is already a running task
      return null;
    }

    final backfillTask =
        relevantTasks
            .where((FullTask task) => task.task.status == Task.statusNew)
            .toList();
    if (backfillTask.isEmpty) {
      return null;
    }

    // First item in the list is guranteed to be most recent.
    // Mark task as in progress to ensure it isn't scheduled over
    backfillTask.first.task.status = Task.statusInProgress;
    return backfillTask.first;
  }
}
