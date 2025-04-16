// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math';

import 'package:meta/meta.dart';

import '../../model/ci_yaml/target.dart';
import '../../model/firestore/task.dart' as fs;
import '../../service/luci_build_service.dart';
import '../../service/luci_build_service/opaque_commit.dart';
import '../../service/scheduler/policy.dart';

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
abstract interface class BackfillerStrategy {
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
  List<(OpaqueTask, int)> determineBackfill(
    List<Target> targets,
    List<(OpaqueCommit, List<OpaqueTask>)> recent,
  );
}

/// The "original" backfiller strategy ported from `BatchBackfiller`.
///
/// It prioritizes targets with the following rules:
/// - [LuciBuildService.kRerunPriority] prioritizes tasks that recently[^1] failed;
/// - [LuciBuildService.kRerunPriority] > other priorities;
/// - Both high and low priority targets are shuffled (using [List.shuffle])
///
/// [^1]: As determined by [BatchPolicy.kBatchSize] tasks after a given task
final class DefaultBackfillerStrategy implements BackfillerStrategy {
  /// Creates a default backfiller strategy.
  ///
  /// If [Random] is provided, it used for [List.shuffle] determinism.
  const DefaultBackfillerStrategy(@visibleForTesting this._random);
  final Random? _random;

  @override
  List<(OpaqueTask, int)> determineBackfill(
    List<Target> targets,
    List<(OpaqueCommit, List<OpaqueTask>)> recent,
  ) {
    // First, index the tasks by "column": Map<{Name}, List<OpaqueTask>.
    final tasksByName = <String, List<OpaqueTask>>{};
    for (final (_, tasks) in recent) {
      for (final task in tasks) {
        tasksByName.update(
          task.name,
          (list) => list..add(task),
          ifAbsent: () => [task],
        );
      }
    }

    // Next index the targets as well.
    final targetsByName = {for (final target in targets) target.name: target};

    // Next, remove entire columns where any of the following is true.
    tasksByName.removeWhere((_, tasks) {
      // 1. The target is not supposed to be run by the backfilling process.
      if (targetsByName[tasks.first.name]?.schedulerPolicy is! BatchPolicy) {
        return true;
      }

      // 2. At least one task in progress;
      if (!tasks.any((t) => t.status == fs.Task.statusInProgress)) {
        return true;
      }

      // Retain.
      return false;
    });

    // Now, create two lists: high priority (recent failure) and regular.
    final hadRecentFailure = <OpaqueTask>[];
    final noRecentFailures = <OpaqueTask>[];

    for (final column in tasksByName.values) {
      for (var i = 0; i < column.length; i++) {
        final row = column[i];
        if (row.status != fs.Task.statusNew) {
          continue;
        }

        // Determine whether it is high priority or regular priority.
        if (column
            .getRange(i, min(i + BatchPolicy.kBatchSize, column.length))
            .any((t) => fs.Task.taskFailStatusSet.contains(t.status))) {
          hadRecentFailure.add(row);
        } else {
          noRecentFailures.add(row);
        }
      }
    }

    // Shuffle both sublists.
    hadRecentFailure.shuffle(_random);
    noRecentFailures.shuffle(_random);

    // Return both of these lists, concatted.
    return [
      ...hadRecentFailure.map((t) => (t, LuciBuildService.kRerunPriority)),
      ...noRecentFailures.map((t) => (t, LuciBuildService.kBackfillPriority)),
    ];
  }
}
