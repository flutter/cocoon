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

    // for (RepositorySlug slug in config.supportedRepos) {
      futures.add(backfillRepository(RepositorySlug('flutter', 'flutter')));
    // }

    // Process all repos asynchronously
    await Future.wait<void>(futures);

    return Body.empty;
  }

  Future<void> backfillRepository(RepositorySlug slug) async {
    final DatastoreService datastore = datastoreProvider(config.db);
    final List<FullTask> tasks =
        await (datastore.queryRecentTasks(slug: slug, commitLimit: config.backfillerCommitLimit)).toList();

    print(tasks.length);
    final Set<String> shaList = <String>{};
    tasks.forEach((element) {shaList.add(element.commit.sha!);});
    final List<Task> inProgressTasks = <Task>[];
    for (String sha in shaList) {
      final List<Task> onlyTasks = tasks.where((element) => element.commit.sha == sha).map((e) => e.task).toList();
      inProgressTasks.addAll(onlyTasks.where((element) => element.status == Task.statusInProgress && element.buildNumber == null).toList());
    }

    // final List<Task> onlyTasks = tasks.where((element) => element.commit.sha == 'f6c20db64bb896bdec6a8883fae5b956e33b3860').map((e) => e.task).toList();
    // print(onlyTasks.length);
    // final List<Task> inProgressTasks = onlyTasks.where((element) => element.status == Task.statusInProgress && element.buildNumber == null).toList();
    print(inProgressTasks.length);
    for (Task inProgressTask in inProgressTasks) {
      print (inProgressTask.builderName);
      inProgressTask.status = Task.statusNew;
    }
    await datastore.insert(inProgressTasks);

    // await datastore.withTransaction<void>((Transaction transaction) async {
    //     transaction.queueMutations(inserts: inProgressTasks);
    //   });
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
