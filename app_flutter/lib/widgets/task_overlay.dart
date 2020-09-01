// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:cocoon_service/protos.dart' show Commit, Task;

import '../agent_dashboard_page.dart';
import '../logic/qualified_task.dart';
import '../state/build.dart';
import 'luci_task_attempt_summary.dart';
import 'progress_button.dart';
import 'task_attempt_summary.dart';
import 'task_box.dart';

class TaskOverlayEntryPositionDelegate extends SingleChildLayoutDelegate {
  TaskOverlayEntryPositionDelegate(this.target);

  /// The offset of the target the tooltip is positioned near in the global
  /// coordinate system.
  final Offset target;

  static Offset positionDependentBox({
    @required Size size,
    @required Size childSize,
    @required Offset target,
  }) {
    assert(size != null);
    assert(childSize != null);
    assert(target != null);
    const double margin = 10.0;
    const double verticalOffset = TaskBox.cellSize * .9;

    // VERTICAL DIRECTION
    final bool fitsBelow = target.dy + verticalOffset + childSize.height <= size.height - margin;
    // final bool fitsAbove = target.dy - verticalOffset - childSize.height >= margin;
    // final bool tooltipBelow = fitsBelow || !fitsAbove;
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
      final double normalizedTargetX = (target.dx).clamp(margin, size.width - margin) as double;
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
    Key key,
    @required this.position,
    @required this.task,
    @required this.showSnackBarCallback,
    @required this.closeCallback,
    @required this.buildState,
    @required this.commit,
  })  : assert(position != null),
        assert(buildState != null),
        assert(task != null),
        assert(showSnackBarCallback != null),
        assert(closeCallback != null),
        super(key: key);

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

  /// [Commit] for cirrus tasks to show log.
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
          width: TaskBox.cellSize,
          height: TaskBox.cellSize,
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
            delegate: TaskOverlayEntryPositionDelegate(position),
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
    Key key,
    @required this.showSnackBarCallback,
    @required this.buildState,
    @required this.task,
    @required this.closeCallback,
    this.commit,
  })  : assert(showSnackBarCallback != null),
        assert(buildState != null),
        assert(task != null),
        super(key: key);

  final ShowSnackBarCallback showSnackBarCallback;

  /// A reference to the [BuildState] for performing operations on this [Task].
  final BuildState buildState;

  /// The [Task] to display in the overlay
  final Task task;

  /// [Commit] for cirrus tasks to show log.
  final Commit commit;

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
  @visibleForTesting
  static const String downloadLogErrorMessage = 'Failed to download task log.';
  @visibleForTesting
  static const Duration downloadLogSnackBarDuration = Duration(seconds: 15);

  /// A lookup table to define the [Icon] for this task, based on
  /// the values returned by [TaskBox.effectiveTaskStatus].
  static const Map<String, Icon> statusIcon = <String, Icon>{
    TaskBox.statusFailed: Icon(Icons.clear, color: Colors.red, size: 32),
    TaskBox.statusNew: Icon(Icons.new_releases, color: Colors.blue, size: 32),
    TaskBox.statusInProgress: Icon(Icons.autorenew, color: Colors.blue, size: 32),
    TaskBox.statusSucceeded: Icon(Icons.check_circle, color: Colors.green, size: 32),
    TaskBox.statusSucceededButFlaky: Icon(Icons.check_circle_outline, size: 32),
    TaskBox.statusUnderperformed: Icon(Icons.new_releases, color: Colors.orange, size: 32),
    TaskBox.statusUnderperformedInProgress: Icon(Icons.autorenew, color: Colors.orange, size: 32),
  };

  @override
  Widget build(BuildContext context) {
    final DateTime createTime = DateTime.fromMillisecondsSinceEpoch(task.createTimestamp.toInt());
    final DateTime startTime = DateTime.fromMillisecondsSinceEpoch(task.startTimestamp.toInt());
    final DateTime endTime = DateTime.fromMillisecondsSinceEpoch(task.endTimestamp.toInt());

    final Duration queueDuration = startTime.difference(createTime);
    final Duration runDuration = endTime.difference(startTime);

    final String taskStatus = TaskBox.effectiveTaskStatus(task);
    final QualifiedTask qualifiedTask = QualifiedTask.fromTask(task);

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
                      message: taskStatus,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 8.0, top: 10.0, right: 12.0),
                        child: statusIcon[taskStatus],
                      ),
                    ),
                    Expanded(
                      child: ListBody(
                        children: <Widget>[
                          SelectableText(
                            task.name,
                            style: Theme.of(context).textTheme.bodyText1,
                          ),
                          if (qualifiedTask.isDevicelab)
                            Text(
                              'Attempts: ${task.attempts}\n'
                              'Run time: ${runDuration.inMinutes} minutes\n'
                              'Queue time: ${queueDuration.inSeconds} seconds\n'
                              'Flaky: ${task.isFlaky}',
                              style: Theme.of(context).textTheme.bodyText2,
                            )
                          else
                            Text(
                              'Task was run outside of devicelab',
                              style: Theme.of(context).textTheme.bodyText2,
                            ),
                          if (QualifiedTask.fromTask(task).isDevicelab) TaskAttemptSummary(task: task),
                          if (QualifiedTask.fromTask(task).isLuci) LuciTaskAttemptSummary(task: task),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  if (qualifiedTask.isDevicelab)
                    RaisedButton(
                      child: Text.rich(
                        TextSpan(
                          text: 'SHOW ',
                          children: <TextSpan>[
                            TextSpan(
                              text: task.reservedForAgentId,
                              style: const TextStyle(fontStyle: FontStyle.italic),
                            ),
                          ],
                        ),
                      ),
                      onPressed: () {
                        // Close the current overlay
                        closeCallback();

                        // Open the agent dashboard
                        Navigator.pushNamed(
                          context,
                          AgentDashboardPage.routeName,
                          arguments: task.reservedForAgentId,
                        );
                      },
                    ),
                  Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: ProgressButton(
                      child: const Text('DOWNLOAD ALL LOGS'),
                      onPressed: _viewLog,
                    ),
                  ),
                  if (qualifiedTask.isDevicelab || qualifiedTask.isLuci)
                    Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: ProgressButton(
                        child: const Text('RERUN'),
                        onPressed: _rerunTask,
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
    final bool success = await buildState.rerunTask(task);
    final Text snackBarText = success ? const Text(rerunSuccessMessage) : const Text(rerunErrorMessage);
    showSnackBarCallback(
      SnackBar(
        content: snackBarText,
        duration: rerunSnackBarDuration,
      ),
    );
  }

  /// If [task] is in the devicelab, download the log. Otherwise, open the
  /// url closest to where the log will be.
  ///
  /// If a devicelab log fails to download, show an error snack bar.
  Future<void> _viewLog() async {
    if (QualifiedTask.fromTask(task).isDevicelab) {
      final bool success = await buildState.downloadLog(task, commit);

      if (!success) {
        /// Only show [SnackBar] on failure since the user's device will
        /// indicate a download has been made.
        showSnackBarCallback(
          const SnackBar(
            content: Text(downloadLogErrorMessage),
            duration: rerunSnackBarDuration,
          ),
        );
      }

      return;
    }

    /// Tasks outside of devicelab have public logs that we just redirect to.
    launch(logUrl(task, commit: commit));
  }
}
