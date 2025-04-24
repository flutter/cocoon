// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:math' as math;

import 'package:cocoon_common/rpc_model.dart';
import 'package:flutter/material.dart';

import '../logic/qualified_task.dart';
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
    const margin = 10.0;
    final verticalOffset = cellSize * .9;

    // VERTICAL DIRECTION
    final fitsBelow =
        target.dy + verticalOffset + childSize.height <= size.height - margin;
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
      final normalizedTargetX = target.dx.clamp(margin, size.width - margin);
      final edge = normalizedTargetX + childSize.width;
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
  final Task task;

  final ShowSnackBarCallback showSnackBarCallback;

  /// This callback removes the parent overlay from the widget tree.
  ///
  /// On a click that is outside the area of the overlay (the rest of the screen),
  /// this callback is called closing the overlay.
  final VoidCallback closeCallback;

  /// A reference to the [BuildState] for performing operations on this [Task].
  final BuildState buildState;

  /// [Commit] for tasks to show log.
  final Commit commit;

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
            delegate: TaskOverlayEntryPositionDelegate(
              position,
              cellSize: TaskBox.of(context),
            ),
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
    required this.commit,
  });

  final ShowSnackBarCallback showSnackBarCallback;

  /// A reference to the [BuildState] for performing operations on this [Task].
  final BuildState buildState;

  /// The [Task] to display in the overlay
  final Task task;

  /// [Commit] for tasks to show log.
  final Commit commit;

  /// This callback removes the parent overlay from the widget tree.
  ///
  /// This is used in this scope to close this overlay on redirection to view
  /// the agent for this task in the agent dashboard.
  final void Function() closeCallback;

  @visibleForTesting
  static const String rerunErrorMessage = 'Failed to rerun task.';
  @visibleForTesting
  static const String rerunSuccessMessage =
      'Devicelab is rerunning the task. This can take a minute to propagate.';
  @visibleForTesting
  static const Duration rerunSnackBarDuration = Duration(seconds: 15);

  /// A lookup table to define the [Icon] for this task, based on
  /// the values returned by [TaskBox.effectiveTaskStatus].
  static const Map<String, Icon> statusIcon = <String, Icon>{
    TaskBox.statusFailed: Icon(Icons.clear, color: Colors.red, size: 32),
    TaskBox.statusNew: Icon(Icons.new_releases, color: Colors.blue, size: 32),
    TaskBox.statusInProgress: Icon(
      Icons.autorenew,
      color: Colors.blue,
      size: 32,
    ),
    TaskBox.statusSucceeded: Icon(
      Icons.check_circle,
      color: Colors.green,
      size: 32,
    ),
  };

  static String _describeTaskRunning(Task task, {required DateTime now}) {
    final buffer = StringBuffer();

    final createTime = DateTime.fromMillisecondsSinceEpoch(
      task.createTimestamp.toInt(),
    );
    final startTime = DateTime.fromMillisecondsSinceEpoch(
      task.startTimestamp.toInt(),
    );

    // Q1: Is the task queuing (waiting to be scheduled, or waiting for LUCI)?
    // If yes, explain how long it is has been waiting
    // If no, explain how long it did wait
    var wasQueued = false;
    if (task.status == TaskBox.statusNew) {
      final queuedFor = now.difference(createTime);
      buffer.writeln('Waiting for backfill for ${queuedFor.inMinutes} minutes');
    } else if (task.status == TaskBox.statusInProgress &&
        (task.buildNumberList.isEmpty ||
            task.attempts > task.buildNumberList.length)) {
      final queuedFor = now.difference(createTime);
      buffer.writeln('Queuing for ${queuedFor.inMinutes} minutes');
    } else if (task.status != TaskBox.statusSkipped) {
      wasQueued = true;
      final queuedFor = startTime.difference(createTime);
      buffer.writeln('Queued for ${queuedFor.inMinutes} minutes');
    }

    final endTime = DateTime.fromMillisecondsSinceEpoch(
      task.endTimestamp.toInt(),
    );

    switch (task.status) {
      case TaskBox.statusInProgress when wasQueued:
        final ranFor = now.difference(startTime);
        buffer.write('Running for ${ranFor.inMinutes} minutes');
      case TaskBox.statusSkipped:
        buffer.write('Skipped');
      case TaskBox.statusCancelled:
        buffer.write('Cancelled');
      case TaskBox.statusSucceeded:
      case TaskBox.statusFailed:
      case TaskBox.statusInfraFailure:
        final ranFor = endTime.difference(startTime);
        buffer.write('Ran for ${ranFor.inMinutes} minutes');
    }

    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    final qualifiedTask = QualifiedTask.fromTask(task);
    final now = Now.of(context);

    final summaryText = [
      'Attempts: ${task.attempts}',
      _describeTaskRunning(task, now: now!),
      if (task.isBringup) 'Flaky: ${task.isBringup}',
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
                        padding: const EdgeInsets.only(
                          left: 8.0,
                          top: 10.0,
                          right: 12.0,
                        ),
                        child: statusIcon[task.status],
                      ),
                    ),
                    Expanded(
                      child: ListBody(
                        children: <Widget>[
                          SelectableText(
                            task.builderName,
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                          Text(
                            summaryText,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          if (QualifiedTask.fromTask(task).isLuci ||
                              QualifiedTask.fromTask(task).isDartInternal)
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
                          final isAuthenticated =
                              buildState.authService.isAuthenticated;
                          return ProgressButton(
                            onPressed: isAuthenticated ? _rerunTask : null,
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

  Future<void> _rerunTask() async {
    final rerunResponse = await buildState.rerunTask(task, commit);
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
