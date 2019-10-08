// Copyright (c) 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

import 'package:cocoon_service/protos.dart' show Task;

/// Displays information from a [Task].
///
/// If [Task.status] is "In Progress", it will show as a "New" task
/// with a [CircularProgressIndicator] in the box.
/// Shows a black box for unknown statuses.
class TaskBox extends StatefulWidget {
  const TaskBox({Key key, @required this.task}) : super(key: key);

  /// [Task] to show information from.
  final Task task;

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

    return GestureDetector(
      onTap: _handleTap,
      child: Container(
        margin: const EdgeInsets.all(1.0),
        color: TaskBox.statusColor.containsKey(status)
            ? TaskBox.statusColor[status]
            : Colors.black,
        child: (status == TaskBox.statusInProgress ||
                status == TaskBox.statusUnderperformedInProgress)
            ? const Padding(
                padding: EdgeInsets.all(15.0),
                child: CircularProgressIndicator(
                  strokeWidth: 3.0,
                  backgroundColor: Colors.white70,
                ),
              )
            : null,
        width: 20,
        height: 20,
      ),
    );
  }

  void _handleTap() {
    _taskOverlay = OverlayEntry(
      builder: (_) => TaskOverlayContents(
          parentContext: context,
          task: widget.task,
          taskStatus: status,
          closeCallback: _closeOverlay),
    );

    Overlay.of(context).insert(_taskOverlay);
  }

  void _closeOverlay() => _taskOverlay.remove();
}

/// Displays the information from [Task] and allows interacting with a [Task].
///
/// This is intended to be inserted in an [OverlayEntry] as it requires
/// [closeCallback] that will remove the widget from the tree.
///
/// Offers the functionality of opening the log for this [Task] and rerunning
/// this [Task] through the build system.
class TaskOverlayContents extends StatelessWidget {
  const TaskOverlayContents({
    Key key,
    @required this.parentContext,
    @required this.task,
    @required this.taskStatus,
    @required this.closeCallback,
  })  : assert(parentContext != null),
        assert(task != null),
        assert(closeCallback != null),
        super(key: key);

  /// The parent context that has the size of the whole screen
  final BuildContext parentContext;

  /// The [Task] to display in the overlay
  final Task task;

  /// [Task.status] modified to take into account [Task.attempts] to create
  /// a more descriptive status.
  final String taskStatus;

  /// This callback removes the parent overlay from the widget tree.
  ///
  /// On a click that is outside the area of the overlay (the rest of the screen),
  /// this callback is called closing the overlay.
  final void Function() closeCallback;

  /// A lookup table to define the [Icon] for this [Overlay].
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
          child: Card(
            child: Column(
              mainAxisSize: MainAxisSize.max,
              children: <Widget>[
                ListTile(
                  leading: Tooltip(
                      message: taskStatus, child: statusIcon[taskStatus]),
                  title: Text(task.name),
                  subtitle: Text(
                      'Attempts: ${task.attempts}\nDuration: ${task.endTimestamp - task.startTimestamp} seconds\nAgent: ${task.reservedForAgentId}'),
                ),
                ButtonBar(
                  children: <Widget>[
                    IconButton(
                      icon: const Icon(Icons.receipt),
                      onPressed: () {
                        // TODO(chillers): Open log in new window. https://github.com/flutter/cocoon/issues/436
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.redo),
                      onPressed: () {
                        // TODO(chillers): Rerun task. https://github.com/flutter/cocoon/issues/424
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
