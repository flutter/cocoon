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

  @override
  Widget build(BuildContext context) {
    final bool attempted = widget.task.attempts > 1;
    String status = widget.task.status;
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
      builder: (_) => CommitOverlayContents(
          parentContext: context,
          task: widget.task,
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
class CommitOverlayContents extends StatelessWidget {
  const CommitOverlayContents({
    Key key,
    @required this.parentContext,
    @required this.task,
    @required this.closeCallback,
  })  : assert(parentContext != null),
        assert(task != null),
        assert(closeCallback != null),
        super(key: key);

  /// The parent context that has the size of the whole screen
  final BuildContext parentContext;

  /// The commit data to display in the overlay
  final Task task;

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
          width: 300,
          // Move this overlay to be where the parent is
          top: offsetLeft.dy + (renderBox.size.height / 2),
          left: offsetLeft.dx + (renderBox.size.width / 2),
          child: Card(
            child: Column(
              mainAxisSize: MainAxisSize.max,
              children: <Widget>[
                ListTile(
                  title: Text(task.name),
                  subtitle: Text('Attempts: ${task.attempts}'),
                ),
                ButtonBar(
                  children: <Widget>[
                    IconButton(
                      icon: const Icon(Icons.repeat),
                      onPressed: () {
                        // TODO(chillers): rerun all tests for this commit
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.open_in_new),
                      onPressed: () async {},
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
