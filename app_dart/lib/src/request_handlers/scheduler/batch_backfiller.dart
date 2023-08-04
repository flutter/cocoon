// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_service/src/foundation/utils.dart';
import 'package:cocoon_service/src/model/appengine/task.dart';
import 'package:cocoon_service/src/request_handling/body.dart';
import 'package:cocoon_service/src/service/datastore.dart';
import 'package:cocoon_service/src/service/scheduler/policy.dart';
import 'package:gcloud/db.dart';
import 'package:github/github.dart';
import 'package:meta/meta.dart';
import 'package:retry/retry.dart';

import '../../model/ci_yaml/ci_yaml.dart';
import '../../model/ci_yaml/target.dart';
import '../../request_handling/exceptions.dart';
import '../../request_handling/request_handler.dart';
import '../../service/config.dart';
import '../../service/logging.dart';
import '../../service/luci_build_service.dart';
import '../../service/scheduler.dart';

/// Cron request handler for scheduling targets when capacity becomes available.
///
/// Targets that have a [BatchPolicy] need to have backfilling enabled to ensure that ToT is always being tested.
@immutable
class BatchBackfiller extends RequestHandler {
  /// Creates a subscription for sending BuildBucket requests.
  const BatchBackfiller({
    required super.config,
    required this.scheduler,
    @visibleForTesting this.datastoreProvider = DatastoreService.defaultProvider,
  });

  final DatastoreServiceProvider datastoreProvider;
  final Scheduler scheduler;

  @override
  Future<Body> get() async {
    final List<Future<void>> futures = <Future<void>>[];

    for (RepositorySlug slug in config.supportedRepos) {
      futures.add(backfillRepository(slug));
    }

    // Process all repos asynchronously
    await Future.wait<void>(futures);

    return Body.empty;
  }

  Future<void> backfillRepository(RepositorySlug slug) async {
    final DatastoreService datastore = datastoreProvider(config.db);
    final List<FullTask> tasks =
        await (datastore.queryRecentTasks(slug: slug, commitLimit: config.backfillerCommitLimit)).toList();

    // Construct Task columns to scan for backfilling
    final Map<String, List<FullTask>> taskMap = <String, List<FullTask>>{};
    for (FullTask fullTask in tasks) {
      if (taskMap.containsKey(fullTask.task.name)) {
        taskMap[fullTask.task.name]!.add(fullTask);
      } else {
        taskMap[fullTask.task.name!] = <FullTask>[fullTask];
      }
    }

    // Check if should be scheduled (there is no yellow runs). Run the most recent gray.
    List<Tuple<Target, FullTask, int>> backfill = <Tuple<Target, FullTask, int>>[];
    for (List<FullTask> taskColumn in taskMap.values) {
      final FullTask task = taskColumn.first;
      final CiYaml ciYaml = await scheduler.getCiYaml(task.commit);
      final List<Target> ciYamlTargets = ciYaml.backfillTargets;
      // Skips scheduling if the task is not in TOT commit anymore.
      final bool taskInToT = ciYamlTargets.map((Target target) => target.value.name).toList().contains(task.task.name);
      if (!taskInToT) {
        continue;
      }
      final Target target = ciYamlTargets.singleWhere((target) => target.value.name == task.task.name);
      if (target.schedulerPolicy is! BatchPolicy) {
        continue;
      }
      final FullTask? backfillTask = _backfillTask(target, taskColumn);
      final int priority = backfillPriority(taskColumn.map((e) => e.task).toList(), BatchPolicy.kBatchSize);
      if (backfillTask != null) {
        backfill.add(Tuple<Target, FullTask, int>(target, backfillTask, priority));
      }
    }

    // Get the number of targets to be backfilled in each cycle.
    backfill = getFilteredBackfill(backfill);

    log.fine('Backfilling ${backfill.length} builds');
    log.fine(backfill.map<String>((Tuple<Target, FullTask, int> tuple) => tuple.first.value.name));

    // Update tasks status as in progress to avoid duplicate scheduling.
    final List<Task> backfillTasks = backfill.map((Tuple<Target, FullTask, int> tuple) => tuple.second.task).toList();
    try {
      await datastore.withTransaction<void>((Transaction transaction) async {
        transaction.queueMutations(inserts: backfillTasks);
        await transaction.commit();
        log.fine(
          'Updated ${backfillTasks.length} tasks: ${backfillTasks.map((e) => e.name).toList()} when backfilling.',
        );
      });
      // Schedule all builds asynchronously.
      // Schedule after db updates to avoid duplicate scheduling when db update fails.
      await _scheduleWithRetries(backfill);
    } catch (error) {
      log.severe('Failed to update tasks when backfilling: $error');
    }
  }

  /// Filters [config.backfillerTargetLimit] targets to backfill.
  ///
  /// High priority targets will be guranteed to get back filled first. If more targets
  /// than [config.backfillerTargetLimit], pick the limited number of targets after a
  /// shuffle. This is to make sure all targets are picked with the same chance.
  List<Tuple<Target, FullTask, int>> getFilteredBackfill(List<Tuple<Target, FullTask, int>> backfill) {
    if (backfill.length <= config.backfillerTargetLimit) {
      return backfill;
    }
    final List<Tuple<Target, FullTask, int>> filteredBackfill = <Tuple<Target, FullTask, int>>[];
    final List<Tuple<Target, FullTask, int>> highPriorityBackfill =
        backfill.where((element) => element.third == LuciBuildService.kRerunPriority).toList();
    final List<Tuple<Target, FullTask, int>> normalPriorityBackfill =
        backfill.where((element) => element.third != LuciBuildService.kRerunPriority).toList();
    if (highPriorityBackfill.length >= config.backfillerTargetLimit) {
      highPriorityBackfill.shuffle();
      filteredBackfill.addAll(highPriorityBackfill.sublist(0, config.backfillerTargetLimit));
    } else {
      filteredBackfill.addAll(highPriorityBackfill);
      normalPriorityBackfill.shuffle();
      filteredBackfill
          .addAll(normalPriorityBackfill.sublist(0, config.backfillerTargetLimit - highPriorityBackfill.length));
    }
    return filteredBackfill;
  }

  /// Schedules tasks with retry when hitting pub/sub server errors.
  Future<void> _scheduleWithRetries(List<Tuple<Target, FullTask, int>> backfill) async {
    const RetryOptions retryOptions = Config.schedulerRetry;
    try {
      await retryOptions.retry(
        () async {
          final List<List<Tuple<Target, Task, int>>> tupleLists =
              await Future.wait<List<Tuple<Target, Task, int>>>(backfillRequestList(backfill));
          if (tupleLists.any((List<Tuple<Target, Task, int>> tupleList) => tupleList.isNotEmpty)) {
            final int nonEmptyListLenght = tupleLists.where((element) => element.isNotEmpty).toList().length;
            log.info('Backfill fails and retry backfilling $nonEmptyListLenght targets.');
            backfill = _updateBackfill(backfill, tupleLists);
            throw InternalServerError('Failed to backfill ${backfill.length} targets.');
          }
        },
        retryIf: (Exception e) => e is InternalServerError,
      );
    } catch (error) {
      log.severe('Failed to backfill ${backfill.length} targets due to error: $error');
    }
  }

  /// Updates the [backfill] list with those that fail to get scheduled.
  ///
  /// [tupleLists] maintains the same tuple order as those in [backfill].
  /// Each element from [backfill] is encapsulated as a list in [tupleLists] to prepare for
  /// [scheduler.luciBuildService.schedulePostsubmitBuilds].
  List<Tuple<Target, FullTask, int>> _updateBackfill(
    List<Tuple<Target, FullTask, int>> backfill,
    List<List<Tuple<Target, Task, int>>> tupleLists,
  ) {
    final List<Tuple<Target, FullTask, int>> updatedBackfill = <Tuple<Target, FullTask, int>>[];
    for (int i = 0; i < tupleLists.length; i++) {
      if (tupleLists[i].isNotEmpty) {
        updatedBackfill.add(backfill[i]);
      }
    }
    return updatedBackfill;
  }

  /// Creates a list of backfill requests.
  List<Future<List<Tuple<Target, Task, int>>>> backfillRequestList(List<Tuple<Target, FullTask, int>> backfill) {
    final List<Future<List<Tuple<Target, Task, int>>>> futures = <Future<List<Tuple<Target, Task, int>>>>[];
    for (Tuple<Target, FullTask, int> tuple in backfill) {
      // TODO(chillers): The backfill priority is always going to be low. If this is a ToT task, we should run it at the default priority.
      final Tuple<Target, Task, int> toBeScheduled = Tuple(
        tuple.first,
        tuple.second.task,
        tuple.third,
      );
      futures.add(
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
  /// Uses a higher priority if there is an earlier failed build. Otherwise,
  /// uses default `LuciBuildService.kBackfillPriority`
  int backfillPriority(List<Task> tasks, int pastTaskNumber) {
    if (shouldRerunPriority(tasks, pastTaskNumber)) {
      return LuciBuildService.kRerunPriority;
    }
    return LuciBuildService.kBackfillPriority;
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
    final List<FullTask> relevantTasks = tasks.where((FullTask task) => task.task.name == target.value.name).toList();
    if (relevantTasks.any((FullTask task) => task.task.status == Task.statusInProgress)) {
      // Don't schedule more builds where there is already a running task
      return null;
    }

    final List<FullTask> backfillTask =
        relevantTasks.where((FullTask task) => task.task.status == Task.statusNew).toList();
    if (backfillTask.isEmpty) {
      return null;
    }

    // First item in the list is guranteed to be most recent.
    // Mark task as in progress to ensure it isn't scheduled over
    backfillTask.first.task.status = Task.statusInProgress;
    return backfillTask.first;
  }
}
