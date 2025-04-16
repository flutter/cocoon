// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:meta/meta.dart';

import '../../model/firestore/task.dart' as fs;
import '../../service/luci_build_service/opaque_commit.dart';

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
abstract interface class BatchBackfillerStrategy {
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
  List<OpaqueTask> determineBackfill(
    List<(OpaqueCommit, List<OpaqueTask>)> recent,
  );
}
