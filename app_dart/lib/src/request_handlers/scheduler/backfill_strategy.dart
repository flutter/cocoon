// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math';

import 'package:cocoon_common/is_release_branch.dart';
import 'package:meta/meta.dart';

import '../../model/firestore/task.dart' as fs;
import '../../service/luci_build_service.dart';
import '../../service/luci_build_service/commit_task_ref.dart';
import '../../service/scheduler/policy.dart';
import 'backfill_grid.dart';

/// Defines an interface for determining what tasks to backfill in which order.
///
/// _Backfilling_ is the act of incrementally, and in batch via a cron job,
/// (slowly) scheduling tasks marked [fs.Task.statusNew] (waiting for backfill),
/// potentially skipping certain tasks.
///
/// For example, in the following dashboard "grid":
/// ```txt
/// 🧑‍💼 🟩 🟩 🟩 🟩 🟩 ⬜ ⬜ ⬜ ⬜
/// 🧑‍💼 ⬜ ⬜ ⬜ 🟨 🟨 🟥 🟩 🟩 🟩
/// ```
///
/// A backfilling strategy would decide which `⬜` boxes to schedule (turning
/// them to `🟨` ),
@immutable
abstract base class BackfillStrategy {
  const BackfillStrategy();

  /// Given a grid of (\~50) commits to (\~20) tasks, returns tasks to backfill.
  ///
  /// Each commit reflects something like the following:
  /// ```txt
  /// 🧑‍💼 ⬜ ⬜ ⬜ 🟨 🟨 🟥 🟩 🟩 🟩
  /// ```
  ///
  /// The returned list of tasks are `⬜` tasks that should be prioritized, in
  /// order of most important to least important. That is, implementations may
  /// only (due to capacity) backfill the top `N` tasks returned by this method.
  List<BackfillTask> determineBackfill(BackfillGrid grid);
}

/// The "original" backfiller strategy ported from `BatchBackfiller`.
///
/// It prioritizes targets with the following rules:
/// - [LuciBuildService.kRerunPriority] prioritizes tasks that recently[^1] failed;
/// - [LuciBuildService.kRerunPriority] > other priorities;
/// - Both high and low priority targets are shuffled (using [List.shuffle])
///
/// [^1]: As determined by [BatchPolicy.kBatchSize] tasks after a given task
final class DefaultBackfillStrategy extends BackfillStrategy {
  /// Creates a default backfiller strategy.
  ///
  /// If [Random] is provided, it used for [List.shuffle] determinism.
  const DefaultBackfillStrategy([@visibleForTesting this._random]);
  final Random? _random;

  @override
  List<BackfillTask> determineBackfill(BackfillGrid grid) {
    // Remove entire columns where any of the following is true.
    grid.removeColumnWhere((tasks) {
      // At least one task in progress;
      if (tasks.any((t) => t.status == fs.Task.statusInProgress)) {
        return true;
      }

      // Retain.
      return false;
    });

    // Now, create three lists
    // 1. Rerun existing failure
    final higherPriorityReruns = <TaskRef>[];
    // 2. Tip of tree
    final mediumPriorityReruns = <TaskRef>[];
    // 3. Everything else
    final lowerPriorityReruns = <TaskRef>[];

    for (final (_, column) in grid.eligibleTasks) {
      for (var i = 0; i < column.length; i++) {
        final row = column[i];
        if (row.status != fs.Task.statusNew) {
          continue;
        }

        // Determine relative priority.
        if (_indexOfTreeRedCause(column) case final index? when index > i) {
          // ⬜ i
          // 🟥 index
          // ^^ Use high priority, this is turning the tree red.
          //
          // ⬜ i
          // 🟩
          // 🟥 index will return as `null`
          // ^^ Uses default (or backfill) priority, next commit passed.
          higherPriorityReruns.add(row);
        } else if (isReleaseCandidateBranch(
          branchName: grid.getCommit(row).branch,
        )) {
          // Release candidates should take priority over normal backfill.
          mediumPriorityReruns.add(row);
        } else if (row.commitSha == grid.getCommit(column[0]).sha) {
          // Tip of tree should take priority over normal backfill.
          mediumPriorityReruns.add(row);
        } else {
          // Everything else.
          lowerPriorityReruns.add(row);
        }

        // If we made it this far, we scheduled an item in the column.
        break;
      }
    }

    // Shuffle each sublist.
    for (final list in [
      higherPriorityReruns,
      mediumPriorityReruns,
      lowerPriorityReruns,
    ]) {
      list.shuffle(_random);
    }

    // Return each list concatted in order.
    return [
      ...higherPriorityReruns.map(
        (t) => grid.createBackfillTask(
          t,
          priority: LuciBuildService.kRerunPriority,
        ),
      ),
      ...mediumPriorityReruns.map(
        (t) => grid.createBackfillTask(
          t,
          priority: LuciBuildService.kDefaultPriority,
        ),
      ),
      ...lowerPriorityReruns.map(
        (t) => grid.createBackfillTask(
          t,
          priority: LuciBuildService.kBackfillPriority,
        ),
      ),
    ];
  }

  static int? _indexOfTreeRedCause(Iterable<TaskRef> tasks) {
    for (final (i, task) in tasks.indexed) {
      // Only evaluate completed tasks.
      if (!fs.Task.finishedStatusValues.contains(task.status)) {
        continue;
      }

      // Returns true for failed tasks, and false for successful.
      if (fs.Task.taskFailStatusSet.contains(task.status)) {
        return i;
      } else {
        return null;
      }
    }
    return null;
  }
}
