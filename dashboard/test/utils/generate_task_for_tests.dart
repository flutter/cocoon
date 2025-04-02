// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_dashboard/src/rpc_model.dart';
import 'package:flutter_dashboard/widgets/task_box.dart';

/// A default [DateTime] used for [generateTaskForTest].
final utc$2020_9_1_12_30 = DateTime.utc(2020, 9, 1, 12, 30);

/// Generates a [Task] for use in a test fixture with as few fields as possible.
///
/// Based on the [status], fields are filled in automatically in order to make
/// the returned [Task] sementically valid. For example, a _started_ task (is
/// neither new or skipped) includes a [startTime] and a [buildNumberList],
/// while a _completed_ task (is not in progress) also includes a [finishTime].
///
/// ## Default Timestamps
///
/// If times are omitted, and filled in with defaults, they are created
/// relative to [nowTime]:
/// - [createTime] is 52 minutes before [nowTime];
/// - [startTime] is 50 minutes before [nowTime];
/// - [finishTime] is 10 minutes before [nowTime].
///
/// [nowTime], if omitted, defaults to `DateTime.utc(2020, 9, 1, 12, 30)`,
/// or [utc$2020_9_1_12_30].
///
/// ## Queued Tasks versus Running Tasks
///
/// To simulate a task that has been _scheduled_, so is "In Progress", but does
/// not have any active builds ( is queued), explicitly set [buildNumberList]
/// to an empty string (`''`), or a string containing less build numbers than
/// the amount of attempts:
/// ```dart
/// // .buildNumberList automatically has 1 build
/// generateTaskForTest(status: TaskBox.statusInProgress)
///
/// // .buildNumberList automatically has 3 builds
/// generateTaskForTest(status: TaskBox.statusInProgress, attempts: 3);
///
/// // .buildNumberList is explicitly empty, indicating a queued build.
/// generateTaskForTest(status: TaskBox.statusInProgress, buildNumberList: '')
///
/// // .buildNumberList has less builds than attempts.
/// generateTaskForTest(status: TaskBox.statusInProgress, buildNumberList: '1,2', attempts: 3)
/// ```
Task generateTaskForTest({
  required String status,
  String? buildNumberList,
  int attempts = 1,
  String builderName = 'Tasky McTaskFace',
  DateTime? nowTime,
  DateTime? createTime,
  DateTime? startTime,
  DateTime? finishTime,
  bool bringup = false,
}) {
  nowTime ??= utc$2020_9_1_12_30;

  // Tasks always have a create time.
  createTime ??= nowTime.subtract(const Duration(minutes: 52));

  final bool started;
  final bool completed;
  switch (status) {
    case TaskBox.statusCancelled:
    case TaskBox.statusFailed:
    case TaskBox.statusInfraFailure:
    case TaskBox.statusSucceeded:
      started = true;
      completed = true;
    case TaskBox.statusInProgress:
      started = true;
      completed = false;
    case TaskBox.statusNew:
    case TaskBox.statusSkipped:
      started = false;
      completed = false;
    default:
      throw UnsupportedError('status = "$status"');
  }

  // Tasks sometimes have a start and finish time.
  if (started) {
    startTime ??= nowTime.subtract(const Duration(minutes: 50));
    buildNumberList ??= List.generate(attempts, (i) => '$i').join(',');
  }
  if (completed) {
    finishTime ??= nowTime.subtract(const Duration(minutes: 2));
  }

  return Task(
    status: status,
    builderName: builderName,
    attempts: attempts,
    buildNumberList: buildNumberList ?? '',
    createTimestamp: createTime.millisecondsSinceEpoch,
    startTimestamp: startTime?.millisecondsSinceEpoch ?? 0,
    endTimestamp: finishTime?.millisecondsSinceEpoch ?? 0,
    isFlaky: bringup,
  );
}
