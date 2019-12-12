// Copyright (c) 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:app_flutter/stackdriver_log_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_progress_button/flutter_progress_button.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:cocoon_service/protos.dart' show Commit, Task;

import 'state/flutter_build.dart';
import 'status_grid.dart';
import 'task_helper.dart';

/// Displays information from a [Task].
///
/// If [Task.status] is "In Progress", it will show as a "New" task
/// with a [CircularProgressIndicator] in the box.
/// Shows a black box for unknown statuses.
class TaskBox extends StatefulWidget {
  const TaskBox(
      {Key key,
      @required this.buildState,
      @required this.task,
      @required this.commit})
      : assert(task != null),
        assert(buildState != null),
        assert(commit != null),
        super(key: key);

  /// Reference to the build state to perform actions on this [Task], like rerunning or viewing the log.
  final FlutterBuildState buildState;

  /// [Task] to show information from.
  final Task task;

  /// [Commit] for cirrus tasks to show log.
  final Commit commit;

  /// Status messages that map to TaskStatus enums.
  // TODO(chillers): Remove these and use TaskStatus enum when available. https://github.com/flutter/cocoon/issues/441
  static const String statusFailed = 'Failed';
  static const String statusNew = 'New';
  static const String statusSkipped = 'Skipped';
  static const String statusSucceeded = 'Succeeded';
  static const String statusSucceededButFlaky = 'Succeeded Flaky';
  static const String statusUnderperformed = 'Underperformed';
  static const String statusUnderperformedInProgress =
      'Underperfomed In Progress';
  static const String statusInProgress = 'In Progress';

  /// A lookup table to define the background color for this TaskBox.
  ///
  /// The status messages are based on the messages the backend sends.
  static const Map<String, Color> statusColor = <String, Color>{
    statusFailed: Colors.red,
    statusNew: Colors.blue,
    statusInProgress: Colors.blue,
    statusSkipped: Colors.transparent,
    statusSucceeded: Colors.green,
    statusSucceededButFlaky: Colors.yellow,
    statusUnderperformed: Colors.orange,
    statusUnderperformedInProgress: Colors.orange,
  };

  @override
  _TaskBoxState createState() => _TaskBoxState();
}

class _TaskBoxState extends State<TaskBox> {
  OverlayEntry _taskOverlay;

  /// [Task.status] modified to take into account [Task.attempts] to create
  /// a more descriptive status.
  ///
  /// For example, [Task.status] = "In Progress" and [Task.attempts] > 1 results
  /// in the status of [statusUnderperformedInProgress].
  String status;

  @override
  Widget build(BuildContext context) {
    final bool attempted = widget.task.attempts > 1;

    status = widget.task.status;
    if (attempted) {
      if (status == TaskBox.statusSucceeded) {
        status = TaskBox.statusSucceededButFlaky;
      } else if (status == TaskBox.statusNew) {
        status = TaskBox.statusUnderperformed;
      } else if (status == TaskBox.statusInProgress) {
        status = TaskBox.statusUnderperformedInProgress;
      }
    }

    return SizedBox(
      width: StatusGrid.cellSize,
      height: StatusGrid.cellSize,
      child: GestureDetector(
        onTap: _handleTap,
        child: Container(
          margin: const EdgeInsets.all(1.0),
          color: TaskBox.statusColor.containsKey(status)
              ? TaskBox.statusColor[status]
              : Colors.black,
          child: taskIndicators(widget.task, status),
        ),
      ),
    );
  }

  /// Compiles a stack of indicators to show on a [TaskBox].
  ///
  /// If [Task.isFlaky], show a question mark.
  /// If [status] is in progress, show an in progress indicator.
  Stack taskIndicators(Task task, String status) {
    return Stack(
      children: <Widget>[
        if (task.isFlaky)
          const Padding(
            padding: EdgeInsets.all(12.0),
            child: Icon(
              Icons.help,
              color: Colors.white60,
              size: 25,
            ),
          ),
        if (status == TaskBox.statusInProgress ||
            status == TaskBox.statusUnderperformedInProgress)
          const Padding(
            padding: EdgeInsets.all(12.0),
            child: Icon(
              Icons.timelapse,
              color: Colors.white60,
              size: 25,
            ),
          ),
      ],
    );
  }

  void _handleTap() {
    _taskOverlay = OverlayEntry(
      builder: (_) => TaskOverlayEntry(
        buildState: widget.buildState,
        parentContext: context,
        task: widget.task,
        taskStatus: status,
        closeCallback: _closeOverlay,
        commit: widget.commit,
      ),
    );

    Overlay.of(context).insert(_taskOverlay);
  }

  void _closeOverlay() => _taskOverlay.remove();
}

/// Displays the information from [Task] and allows interacting with a [Task].
///
/// This is intended to be inserted in an [OverlayEntry] as it requires
/// [closeCallback] that will remove the widget from the tree.
class TaskOverlayEntry extends StatelessWidget {
  const TaskOverlayEntry({
    Key key,
    @required this.parentContext,
    @required this.task,
    @required this.taskStatus,
    @required this.closeCallback,
    @required this.buildState,
    this.commit,
  })  : assert(parentContext != null),
        assert(buildState != null),
        assert(task != null),
        assert(closeCallback != null),
        super(key: key);

  /// The parent context that has the size of the whole screen
  final BuildContext parentContext;

  /// A reference to the [FlutterBuildState] for performing operations on this [Task].
  final FlutterBuildState buildState;

  /// The [Task] to display in the overlay
  final Task task;

  /// [Commit] for cirrus tasks to show log.
  final Commit commit;

  /// [Task.status] modified to take into account [Task.attempts] to create
  /// a more descriptive status.
  final String taskStatus;

  /// This callback removes the parent overlay from the widget tree.
  ///
  /// On a click that is outside the area of the overlay (the rest of the screen),
  /// this callback is called closing the overlay.
  final void Function() closeCallback;

  @override
  Widget build(BuildContext context) {
    final RenderBox renderBox = parentContext.findRenderObject();
    final Offset offsetLeft = renderBox.localToGlobal(Offset.zero);

    return Stack(
      children: <Widget>[
        /// This is a focus container to emphasize the [TaskBox] that this
        /// [Overlay] is currently showing information from.
        Positioned(
          top: offsetLeft.dy,
          left: offsetLeft.dx,
          width: renderBox.size.width,
          height: renderBox.size.height,
          child: Container(
            color: Colors.white70,
            key: const Key('task-overlay-key'),
          ),
        ),
        // This is the area a user can click (the rest of the screen) to close the overlay.
        GestureDetector(
          onTap: closeCallback,
          child: Container(
            width: MediaQuery.of(parentContext).size.width,
            height: MediaQuery.of(parentContext).size.height,
            // Color must be defined otherwise the container can't be clicked on
            color: Colors.transparent,
          ),
        ),
        Positioned(
          width: 350,
          // Move this overlay to be where the parent is
          top: offsetLeft.dy + (renderBox.size.height / 2),
          left: offsetLeft.dx + (renderBox.size.width / 2),
          child: TaskOverlayContents(
            showSnackbarCallback: Scaffold.of(parentContext).showSnackBar,
            buildState: buildState,
            task: task,
            taskStatus: taskStatus,
            commit: commit,
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
    @required this.showSnackbarCallback,
    @required this.buildState,
    @required this.task,
    @required this.taskStatus,
    this.commit,
  })  : assert(showSnackbarCallback != null),
        assert(buildState != null),
        assert(task != null),
        super(key: key);

  final ScaffoldFeatureController<SnackBar, SnackBarClosedReason> Function(
      SnackBar) showSnackbarCallback;

  /// A reference to the [FlutterBuildState] for performing operations on this [Task].
  final FlutterBuildState buildState;

  /// The [Task] to display in the overlay
  final Task task;

  /// [Task.status] modified to take into account [Task.attempts] to create
  /// a more descriptive status.
  final String taskStatus;

  /// [Commit] for cirrus tasks to show log.
  final Commit commit;

  @visibleForTesting
  static const String rerunErrorMessage = 'Failed to rerun task.';
  @visibleForTesting
  static const String rerunSuccessMessage =
      'Devicelab is rerunning the task. This can take a minute to propagate.';
  @visibleForTesting
  static const Duration rerunSnackbarDuration = Duration(seconds: 15);
  @visibleForTesting
  static const String downloadLogErrorMessage = 'Failed to download task log.';
  @visibleForTesting
  static const Duration downloadLogSnackbarDuration = Duration(seconds: 15);

  /// A lookup table to define the [Icon] for this [taskStatus].
  static const Map<String, Icon> statusIcon = <String, Icon>{
    TaskBox.statusFailed: Icon(Icons.clear, color: Colors.red, size: 32),
    TaskBox.statusNew: Icon(Icons.new_releases, color: Colors.blue, size: 32),
    TaskBox.statusInProgress:
        Icon(Icons.autorenew, color: Colors.blue, size: 32),
    TaskBox.statusSucceeded:
        Icon(Icons.check_circle, color: Colors.green, size: 32),
    TaskBox.statusSucceededButFlaky: Icon(Icons.check_circle_outline, size: 32),
    TaskBox.statusUnderperformed:
        Icon(Icons.new_releases, color: Colors.orange, size: 32),
    TaskBox.statusUnderperformedInProgress:
        Icon(Icons.autorenew, color: Colors.orange, size: 32),
  };

  @override
  Widget build(BuildContext context) {
    final DateTime createTime =
        DateTime.fromMillisecondsSinceEpoch(task.createTimestamp.toInt());
    final DateTime startTime =
        DateTime.fromMillisecondsSinceEpoch(task.startTimestamp.toInt());
    final DateTime endTime =
        DateTime.fromMillisecondsSinceEpoch(task.endTimestamp.toInt());

    final Duration queueDuration = startTime.difference(createTime);
    final Duration runDuration = endTime.difference(startTime);

    return Card(
      child: Column(
        mainAxisSize: MainAxisSize.max,
        children: <Widget>[
          ListTile(
            leading:
                Tooltip(message: taskStatus, child: statusIcon[taskStatus]),
            title: Text(task.name),
            subtitle: isDevicelab(task)
                ? Text('Attempts: ${task.attempts}\n'
                    'Run time: ${runDuration.inMinutes} minutes\n'
                    'Queue time: ${queueDuration.inSeconds} seconds\n'
                    'Agent: ${task.reservedForAgentId}\n'
                    'Flaky: ${task.isFlaky}')
                : const Text('Task was run outside of devicelab'),
            contentPadding: const EdgeInsets.all(16.0),
          ),
          if (isDevicelab(task)) TaskAttemptSummary(task: task),
          ButtonBar(
            children: <Widget>[
              ProgressButton(
                defaultWidget: const Text('Log'),
                progressWidget: const CircularProgressIndicator(),
                width: 60,
                height: 50,
                onPressed: _viewLog,
                animate: false,
              ),
              if (isDevicelab(task))
                ProgressButton(
                  defaultWidget: const Text('Rerun'),
                  progressWidget: const CircularProgressIndicator(),
                  width: 70,
                  height: 50,
                  onPressed: _rerunTask,
                  animate: false,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _rerunTask() async {
    final bool success = await buildState.rerunTask(task);
    final Text snackbarText = success
        ? const Text(rerunSuccessMessage)
        : const Text(rerunErrorMessage);
    showSnackbarCallback(
      SnackBar(
        content: snackbarText,
        duration: rerunSnackbarDuration,
      ),
    );
  }

  /// If [task] is in the devicelab, download the log. Otherwise, open the
  /// url closest to where the log will be.
  ///
  /// If a devicelab log fails to download, show an error snackbar.
  Future<void> _viewLog() async {
    if (isDevicelab(task)) {
      final bool success = await buildState.downloadLog(task, commit);

      if (!success) {
        /// Only show [Snackbar] on failure since the user's device will
        /// indicate a download has been made.
        showSnackbarCallback(
          const SnackBar(
            content: Text(downloadLogErrorMessage),
            duration: rerunSnackbarDuration,
          ),
        );
      }

      return;
    }

    /// Tasks outside of devicelab have public logs that we just redirect to.
    launch(logUrl(task, commit: commit));
  }
}
