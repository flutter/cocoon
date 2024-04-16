// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../logic/qualified_task.dart';
import '../model/commit.pb.dart';
import '../model/commit_firestore.pb.dart';
import '../model/task.pb.dart';
import '../model/task_firestore.pb.dart';
import '../state/build.dart';
import 'luci_task_attempt_summary.dart';
import 'now.dart';
import 'progress_button.dart';
import 'task_box.dart';

class TaskOverlayEntryPositionDelegate extends SingleChildLayoutDelegate {
  TaskOverlayEntryPositionDelegate(this.target, {required this.cellSize});

  final double cellSize;

  /// The offset of the target the tooltip is positioned near in the global
  /// coordinate system.
  final Offset target;

  static Offset positionDependentBox({
    required Size size,
    required Size childSize,
    required double cellSize,
    required Offset target,
  }) {
    const double margin = 10.0;
    final double verticalOffset = cellSize * .9;

    // VERTICAL DIRECTION
    final bool fitsBelow = target.dy + verticalOffset + childSize.height <= size.height - margin;
    double y;
    if (fitsBelow) {
      y = math.min(target.dy + verticalOffset, size.height - margin);
    } else {
      y = math.max(target.dy - childSize.height, margin);
    }
    // HORIZONTAL DIRECTION
    double x;
    // The whole size isn't big enough, just center it.
    if (size.width - margin * 2.0 < childSize.width) {
      x = (size.width - childSize.width) / 2.0;
    } else {
      final double normalizedTargetX = (target.dx).clamp(margin, size.width - margin);
      final double edge = normalizedTargetX + childSize.width;
      // Position the box as close to the left edge of the full size
      // without going over the margin.
      if (edge > size.width) {
        x = size.width - margin - childSize.width;
      } else {
        x = normalizedTargetX;
      }
    }
    return Offset(x, y);
  }

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    return positionDependentBox(
      size: size,
      childSize: childSize,
      cellSize: cellSize,
      target: target,
    );
  }

  @override
  bool shouldRelayout(TaskOverlayEntryPositionDelegate oldDelegate) {
    return oldDelegate.target != target;
  }
}

/// Displays the information from [Task] and allows interacting with a [Task].
///
/// This is intended to be inserted in an [OverlayEntry] as it requires
/// [closeCallback] that will remove the widget from the tree.
class TaskOverlayEntry extends StatelessWidget {
  const TaskOverlayEntry({
    super.key,
    required this.position,
    required this.task,
    required this.showSnackBarCallback,
    required this.closeCallback,
    required this.buildState,
    required this.commit,
  });

  /// The global position where to show the task overlay.
  final Offset position;

  /// The [Task] to display in the overlay.
  final TaskDocument task;

  final ShowSnackBarCallback showSnackBarCallback;

  /// This callback removes the parent overlay from the widget tree.
  ///
  /// On a click that is outside the area of the overlay (the rest of the screen),
  /// this callback is called closing the overlay.
  final VoidCallback closeCallback;

  /// A reference to the [BuildState] for performing operations on this [Task].
  final BuildState buildState;

  /// [Commit] for tasks to show log.
  final CommitDocument commit;

  @override
  Widget build(BuildContext context) {
    // If this is ever positioned not at the top-left of the viewport, then
    // we should make sure to convert the position to the Overlay's coordinate
    // space otherwise it'll be misaligned.
    return Stack(
      children: <Widget>[
        // This is a focus container to emphasize the cell that this
        // [Overlay] is currently showing information from.
        Positioned(
          top: position.dy,
          left: position.dx,
          width: TaskBox.of(context),
          height: TaskBox.of(context),
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.black, width: 4.0),
              color: Colors.white70,
            ),
          ),
        ),
        // This is the area a user can click (the rest of the screen) to close the overlay.
        GestureDetector(
          onTap: closeCallback,
          behavior: HitTestBehavior.opaque,
          child: const SizedBox.expand(),
        ),
        Positioned(
          // Move this overlay to be where the parent is
          child: CustomSingleChildLayout(
            delegate: TaskOverlayEntryPositionDelegate(position, cellSize: TaskBox.of(context)),
            child: TaskOverlayContents(
              showSnackBarCallback: showSnackBarCallback,
              buildState: buildState,
              task: task,
              commit: commit,
              closeCallback: closeCallback,
            ),
          ),
        ),
      ],
    );
  }
}

/// Displays the information from [Task] and allows interacting with a [Task].
///
/// This is intended to be inserted in [TaskOverlayEntry].
///
/// Offers the functionality of opening the log for this [Task] and rerunning
/// this [Task] through the build system.
class TaskOverlayContents extends StatelessWidget {
  const TaskOverlayContents({
    super.key,
    required this.showSnackBarCallback,
    required this.buildState,
    required this.task,
    required this.closeCallback,
    this.commit,
  });

  final ShowSnackBarCallback showSnackBarCallback;

  /// A reference to the [BuildState] for performing operations on this [Task].
  final BuildState buildState;

  /// The [Task] to display in the overlay
  final TaskDocument task;

  /// [Commit] for tasks to show log.
  final CommitDocument? commit;

  /// This callback removes the parent overlay from the widget tree.
  ///
  /// This is used in this scope to close this overlay on redirection to view
  /// the agent for this task in the agent dashboard.
  final void Function() closeCallback;

  @visibleForTesting
  static const String rerunErrorMessage = 'Failed to rerun task.';
  @visibleForTesting
  static const String rerunSuccessMessage = 'Devicelab is rerunning the task. This can take a minute to propagate.';
  @visibleForTesting
  static const Duration rerunSnackBarDuration = Duration(seconds: 15);

  /// A lookup table to define the [Icon] for this task, based on
  /// the values returned by [TaskBox.effectiveTaskStatus].
  static const Map<String, Icon> statusIcon = <String, Icon>{
    TaskBox.statusFailed: Icon(Icons.clear, color: Colors.red, size: 32),
    TaskBox.statusNew: Icon(Icons.new_releases, color: Colors.blue, size: 32),
    TaskBox.statusInProgress: Icon(Icons.autorenew, color: Colors.blue, size: 32),
    TaskBox.statusSucceeded: Icon(Icons.check_circle, color: Colors.green, size: 32),
  };

  @override
  Widget build(BuildContext context) {
    final QualifiedTask qualifiedTask = QualifiedTask.fromTask(task);

    final DateTime? now = Now.of(context);
    final DateTime createTime = DateTime.fromMillisecondsSinceEpoch(task.createTimestamp.toInt());
    final DateTime startTime = DateTime.fromMillisecondsSinceEpoch(task.startTimestamp.toInt());
    final DateTime endTime = DateTime.fromMillisecondsSinceEpoch(task.endTimestamp.toInt());

    final Duration queueDuration =
        task.startTimestamp == 0 ? now!.difference(createTime) : startTime.difference(createTime);
    final Duration runDuration = task.endTimestamp == 0 ? now!.difference(startTime) : endTime.difference(startTime);

    /// There are 2 possible states for queue time:
    ///   1. Task is waiting to be scheduled (in queue)
    ///   2. Task has been scheduled (out of queue)
    final String queueText = (task.status != TaskBox.statusNew)
        ? 'Queue time: ${queueDuration.inMinutes} minutes'
        : 'Queueing for ${queueDuration.inMinutes} minutes';

    /// There are 3 possible states for the runtime:
    ///   1. Task has not run yet (new)
    ///   2. Task is running (in progress)
    ///   3. Task ran (other status)
    final String runText = (task.status == TaskBox.statusInProgress)
        ? 'Running for ${runDuration.inMinutes} minutes'
        : (task.status != TaskBox.statusNew)
            ? 'Run time: ${runDuration.inMinutes} minutes'
            : '';

    final String summaryText = <String>[
      'Attempts: ${task.attempts}',
      if (runText.isNotEmpty) runText,
      queueText,
      if (task.bringup) 'Flaky: ${task.bringup}',
    ].join('\n');

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
        child: IntrinsicWidth(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Tooltip(
                      message: task.status,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 8.0, top: 10.0, right: 12.0),
                        child: statusIcon[task.status],
                      ),
                    ),
                    Expanded(
                      child: ListBody(
                        children: <Widget>[
                          SelectableText(
                            task.taskName,
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                          Text(
                            summaryText,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          if (QualifiedTask.fromTask(task).isLuci || QualifiedTask.fromTask(task).isDartInternal)
                            LuciTaskAttemptSummary(task: task),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  if (qualifiedTask.isLuci)
                    Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      // The RERUN button is only enabled if the user is authenticated.
                      child: AnimatedBuilder(
                        animation: buildState,
                        builder: (context, child) {
                          final bool isAuthenticated = buildState.authService.isAuthenticated;
                          return ProgressButton(
                            onPressed: isAuthenticated
                                ? () {
                                    return _rerunTask(task);
                                  }
                                : null,
                            child: child,
                          );
                        },
                        child: const Text('RERUN'),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _rerunTask(TaskDocument task) async {
    final bool rerunResponse = await buildState.rerunTask(task);
    if (rerunResponse) {
      showSnackBarCallback(
        const SnackBar(
          content: Text(rerunSuccessMessage),
          duration: rerunSnackBarDuration,
        ),
      );
    }
  }
}
