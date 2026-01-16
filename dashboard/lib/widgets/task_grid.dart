// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:math';

import 'package:cocoon_common/is_dart_internal.dart';
import 'package:cocoon_common/rpc_model.dart';
import 'package:cocoon_common/task_status.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../logic/qualified_task.dart';
import '../logic/task_grid_filter.dart';
import '../state/build.dart';
import 'commit_box.dart';
import 'lattice.dart';
import 'task_box.dart';
import 'task_icon.dart';
import 'task_overlay.dart';
import 'test_details_popover.dart';

/// Container that manages the layout and data handling for [TaskGrid].
///
/// If there's no data for [TaskGrid], it shows [CircularProgressIndicator].
class TaskGridContainer extends StatelessWidget {
  const TaskGridContainer({
    super.key,
    this.filter,
    this.useAnimatedLoading = false,
    this.schedulePostsubmitBuildForReleaseBranch,
  });

  /// A notifier to hold a [TaskGridFilter] object to control the visibility of various
  /// rows and columns of the task grid. This filter may be updated dynamically through
  /// this notifier from elsewhere if the user starts editing the filter parameters in
  /// the settings dialog.
  final TaskGridFilter? filter;

  final Future<void> Function(Commit commit)?
  schedulePostsubmitBuildForReleaseBranch;

  final bool useAnimatedLoading;

  @visibleForTesting
  static const String errorFetchCommitStatus =
      'An error occurred fetching commit statuses';
  @visibleForTesting
  static const String errorFetchTreeStatus =
      'An error occurred fetching tree build status';
  @visibleForTesting
  static const Duration errorSnackbarDuration = Duration(seconds: 8);

  @override
  Widget build(BuildContext context) {
    final buildState = Provider.of<BuildState>(context);
    return AnimatedBuilder(
      animation: buildState,
      builder: (BuildContext context, Widget? child) {
        final commitStatuses = buildState.statuses;

        if (commitStatuses.isEmpty) {
          if (buildState.moreStatusesExist) {
            return const Center(child: CircularProgressIndicator());
          } else {
            return const Center(child: Text('No commits found.'));
          }
        }

        return TaskGrid(
          buildState: buildState,
          commitStatuses: commitStatuses,
          filter: filter,
          useAnimatedLoading: useAnimatedLoading,
          schedulePostsubmitBuildForReleaseBranch:
              schedulePostsubmitBuildForReleaseBranch,
        );
      },
    );
  }
}

/// Display results from flutter/flutter repository's continuous integration.
///
/// Results are displayed in a matrix format. Rows are commits and columns
/// are the results from tasks.
class TaskGrid extends StatefulWidget {
  const TaskGrid({
    super.key,
    // TODO(ianh): We really shouldn't take both of these, since buildState exposes status as well;
    // it's asking for trouble because the tests can (and do) describe a mutually inconsistent state.
    required this.buildState,
    required this.commitStatuses,
    this.schedulePostsubmitBuildForReleaseBranch,
    this.filter,
    this.useAnimatedLoading = false,
  });

  /// The build status data to display in the grid.
  final List<CommitStatus> commitStatuses;

  /// Reference to the build state to perform actions on [TaskMatrix], like rerunning tasks.
  final BuildState buildState;

  final Future<void> Function(Commit commit)?
  schedulePostsubmitBuildForReleaseBranch;

  final bool useAnimatedLoading;

  /// A [TaskGridFilter] object to control the visibility of various rows and columns of
  /// the task grid. This filter may be updated dynamically from elsewhere if the user
  /// starts editing the filter parameters in the settings dialog.
  final TaskGridFilter? filter;

  @override
  State<TaskGrid> createState() => _TaskGridState();
}

/// Look up table for task status weights in the grid.
///
/// Weights should be in the range [0, 1.0] otherwise too much emphasis is placed on the first N rows, where N is the
/// largest integer weight.
const Map<String, double> _statusScores = <String, double>{
  'Release Builder': 1.0,
  'Failed - Rerun': 1.0,
  'In Progress - Broke Tree': 0.7,
  'Failed': 0.7,
  'Infra Failure - Rerun': 0.69,
  'Infra Failure': 0.68,
  'Failed - Flaky': 0.67,
  'Infra Failure - Flaky': 0.65,
  'In Progress - Flaky': 0.64,
  'New - Flaky': 0.63,
  'Succeeded - Flaky': 0.61,
  'New - Rerun': 0.5,
  'In Progress - Rerun': 0.4,
  'Unknown': 0.2,
  'In Progress': 0.1,
  'New': 0.1,
  'Succeeded': 0.01,
  'Skipped': 0.0,
};

class _TaskGridState extends State<TaskGrid> {
  // TODO(ianh): Cache the lattice cells. Right now we are regenerating the entire
  // lattice matrix each time the task grid has to update, regardless of whether
  // we've received new data or not.

  ScrollController? verticalController;
  ScrollController? horizontalController;

  @override
  void initState() {
    super.initState();
    verticalController ??= ScrollController();
    horizontalController ??= ScrollController();
    widget.filter?.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    verticalController?.dispose();
    horizontalController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LatticeScrollView(
      // TODO(ianh): Provide some vertical scroll physics that disable
      // the clamping in the vertical direction, so that you can keep
      // scrolling past the end instead of hitting a wall every time
      // we load.
      // TODO(ianh): Trigger the loading from the scroll offset,
      // rather than the current hack of loading during build.
      cells: _processCommitStatuses(widget),
      verticalController: verticalController,
      horizontalController: horizontalController,
    );
  }

  /// This is the logic for turning the raw data from the [BuildState] object, a list of
  /// [CommitStatus] objects, into the data that describes the rendering as used by the
  /// [LatticeScrollView], a list of lists of [LatticeCell]s.
  ///
  /// The process is as follows:
  ///
  /// 1. We create `rows`, a list of [_Row] objects which are used to temporarily
  ///    represent each row in the data, where a row basically represents a [Commit].
  ///
  ///    These are derived from the `commitStatuses` directly -- each [CommitStatus] is one
  ///    row, representing one [Commit] and all its [Task]s.
  ///
  /// 2. We walk the `commitStatuses` again, examining each [Task] of each [CommitStatus],
  ///
  ///    For the first 25 rows, we compute a score for each task, one commit at a time, so
  ///    that we'll be able to sort the tasks later. The score is based on [_statusScores]
  ///    (the map defined above). Each row is weighted in the score proportional to how
  ///    far from the first row it is, so the first row has a weight of 1.0, the second a
  ///    weight of 1/2, the third a weight of 1/3, etc.
  ///
  ///    Then, we update the `rows` list to contain a [LatticeCell] for this task on this
  ///    commit. The color of the square is derived from [_painterFor], the builder, if
  ///    any, is derived from [_builderFor], and the tap handler from [_tapHandlerFor].
  ///
  /// 3. We create a list that represents all the tasks we've seen so far, sorted by
  ///    their score (tie-breaking on task names).
  ///
  /// 4. Finally, we generate the output, by putting together all the data collected in
  ///    the second step, walking the tasks in the order determined in the third step.
  //
  // TODO(ianh): Find a way to save the majority of the work done each time we build the
  // matrix. If you've scrolled down several thousand rows, you don't want to have to
  // rebuild the entire matrix each time you load another 25 rows.
  List<List<LatticeCell>> _processCommitStatuses(TaskGrid taskGrid) {
    var filter = taskGrid.filter;
    filter ??= TaskGridFilter();

    // Pre-compute suppressed task names for faster lookup
    final suppressedTasks = {
      for (final s in taskGrid.buildState.suppressedTests) s.name: s,
    };

    // 1: PREPARE ROWS
    final filteredStatuses = taskGrid.commitStatuses
        .where(
          (CommitStatus commitStatus) => filter!.matchesCommit(commitStatus),
        )
        .toList();
    final rows = filteredStatuses
        .map<_Row>((CommitStatus commitStatus) => _Row(commitStatus.commit))
        .toList();
    // 2: WALK ALL TASKS
    final scores = <QualifiedTask, double>{};
    final taskLookupMap = <QualifiedTask, Task>{};

    var commitCount = 0;
    for (final status in filteredStatuses) {
      commitCount += 1;
      for (final task in status.tasks) {
        final qualifiedTask = QualifiedTask.fromTask(task);
        if (!filter.matchesTask(qualifiedTask)) {
          continue;
        }
        taskLookupMap[qualifiedTask] = task;
        if (commitCount <= 25) {
          var weightStatus = task.status.value;
          if (isTaskFromDartInternalBuilder(builderName: task.builderName)) {
            weightStatus = 'Release Builder';
          } else if (task.lastAttemptFailed) {
            weightStatus += ' - Broke Tree';
          } else if (task.isBringup) {
            // Flaky tasks should be shown after failures and reruns as they take up infra capacity.
            weightStatus += ' - Flaky';
          } else if (task.isFlaky) {
            // Reruns take up extra infra capacity and should be prioritized.
            weightStatus += ' - Rerun';
          }
          // Make the score relative to how long ago it was run.
          final score = _statusScores.containsKey(weightStatus)
              ? _statusScores[weightStatus]! / commitCount
              : _statusScores['Unknown']! / commitCount;
          scores.update(
            qualifiedTask,
            (double value) => value += score,
            ifAbsent: () => score,
          );
        } else {
          // In case we have a task that doesn't exist in the first 25 rows,
          // we still push the task into the table of scores. Otherwise, we
          // won't know how to sort the task later.
          scores.putIfAbsent(qualifiedTask, () => 0.0);
        }
        final isSuppressed = suppressedTasks.containsKey(task.builderName);
        rows[commitCount - 1].cells[qualifiedTask] = LatticeCell(
          painter: _painterFor(task, isSuppressed),
          builder: _builderFor(task, isSuppressed),
          onTap: _tapHandlerFor(status.commit, task),
        );
      }
    }
    // 3: SORT
    final tasks = scores.keys.toList()
      ..sort((QualifiedTask a, QualifiedTask b) {
        // Suppressed tests go first (far left)
        final aSuppressed = suppressedTasks.containsKey(a.task);
        final bSuppressed = suppressedTasks.containsKey(b.task);
        if (aSuppressed && !bSuppressed) {
          return -1;
        }
        if (!aSuppressed && bSuppressed) {
          return 1;
        }

        final scoreComparison = scores[b]!.compareTo(scores[a]!);
        if (scoreComparison != 0) {
          return scoreComparison;
        }
        return a.task.compareTo(b.task);
      });

    // 4: GENERATE RESULTING LIST OF LISTS
    return <List<LatticeCell>>[
      <LatticeCell>[
        const LatticeCell(),
        ...tasks.map<LatticeCell>((QualifiedTask task) {
          return LatticeCell(
            builder: (BuildContext context) {
              final suppressedTest = suppressedTasks[task.task];
              final icon = TaskIcon(
                qualifiedTask: task,
                onTap: (BuildContext context) => _showTestDetails(context, task),
              );
              if (suppressedTest != null) {
                // Format audit log
                return Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    Opacity(opacity: 0.3, child: icon),
                    const IgnorePointer(
                      child: Icon(
                        Icons.snooze,
                        fontWeight: FontWeight.bold,
                        size: 20,
                        color: Colors.red,
                      ),
                    ),
                  ],
                );
              }
              return icon;
            },
            taskName: task.task,
          );
        }),
      ],
      ...rows.map<List<LatticeCell>>(
        (_Row row) => <LatticeCell>[
          LatticeCell(
            builder: (BuildContext context) => CommitBox(
              commit: row.commit,
              schedulePostsubmitBuild: () {
                if (widget.schedulePostsubmitBuildForReleaseBranch
                    case final schedule?) {
                  return () async => schedule(row.commit);
                }
                return null;
              }(),
            ),
          ),
          ...tasks.map<LatticeCell>(
            (QualifiedTask task) => row.cells[task] ?? const LatticeCell(),
          ),
        ],
      ),
      if (widget.buildState.moreStatusesExist)
        _generateLoadingRow(tasks.length),
    ];
  }

  Painter _painterFor(Task task, bool isSuppressed) {
    final backgroundPaint = Paint()..color = Theme.of(context).canvasColor;

    assert(
      TaskBox.statusColor.containsKey(task.status),
      'Unknown or unexpected status: ${task.status}',
    );

    var color = TaskBox.statusColor.containsKey(task.status)
        ? TaskBox.statusColor[task.status]!
        : Colors.transparent;
    if (task.status == TaskStatus.inProgress) {
      if (task.lastAttemptFailed) {
        color = TaskBox.statusColorFailedAndRerunning;
      } else if (task.currentBuildNumber == null) {
        color = TaskBox.statusColorInProgressButQueued;
      }
    }

    // Apply "Ghost Mode" for suppressed tests
    if (isSuppressed) {
      // Apply "ghost mode" to the color.
      color = color.withValues(alpha: 0.5);
    }

    final paint = Paint()..color = color;
    if (task.isBringup) {
      paint.style = PaintingStyle.stroke;
      paint.strokeWidth = 2.0;
      return (Canvas canvas, Rect rect) {
        canvas.drawRect(rect.deflate(6.0), paint);
      };
    }
    return (Canvas canvas, Rect rect) {
      canvas.drawRect(rect.deflate(2.0), paint);
      if (task.isFlaky) {
        canvas.drawCircle(
          rect.center,
          (rect.shortestSide / 2.0) - 6.0,
          backgroundPaint,
        );
      }
    };
  }

  WidgetBuilder? _builderFor(Task task, bool isSuppressed) {
    if (task.isFlaky) {
      return (BuildContext context) {
        final icon = Padding(
          padding: const EdgeInsets.all(4.0),
          child: Icon(Icons.priority_high, size: TaskBox.of(context) * 0.4),
        );
        return isSuppressed ? Opacity(opacity: 0.5, child: icon) : icon;
      };
    }
    if (task.status == TaskStatus.skipped) {
      return (BuildContext context) {
        final icon = Padding(
          padding: const EdgeInsets.all(4.0),
          child: Icon(Icons.network_ping, size: TaskBox.of(context) * 0.6),
        );
        return isSuppressed ? Opacity(opacity: 0.5, child: icon) : icon;
      };
    }
    return null;
  }

  static final List<String> _loadingMessage = 'LOADING...'.runes
      .map<String>(String.fromCharCode)
      .toList();

  List<LatticeCell> _generateLoadingRow(int length) {
    return <LatticeCell>[
      LatticeCell(
        builder: (BuildContext context) {
          return FittedBox(
            fit: BoxFit.contain,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: widget.useAnimatedLoading
                  ? const RepaintBoundary(child: CircularProgressIndicator())
                  : const Icon(Icons.refresh),
            ),
          );
        },
      ),
      for (int index = 0; index < max(length, _loadingMessage.length); index++)
        LatticeCell(
          builder: (BuildContext context) {
            unawaited(
              widget.buildState.fetchMoreCommitStatuses(),
            ); // This is safe to call many times.
            return Text(
              _loadingMessage[index % _loadingMessage.length],
              style: TextStyle(
                fontSize: TaskBox.of(context) * 0.9,
                fontWeight: FontWeight.w900,
              ),
              textAlign: TextAlign.center,
            );
          },
        ),
    ];
  }

  OverlayEntry? _taskOverlay;

  LatticeTapCallback _tapHandlerFor(Commit commit, Task task) {
    return (Offset? localPosition) {
      _taskOverlay?.remove();
      _taskOverlay = OverlayEntry(
        builder: (BuildContext context) => TaskOverlayEntry(
          position: (this.context.findRenderObject() as RenderBox)
              .localToGlobal(
                localPosition!,
                ancestor: Overlay.of(context).context.findRenderObject(),
              ),
          task: task,
          showSnackBarCallback: ScaffoldMessenger.of(context).showSnackBar,
          closeCallback: _closeOverlay,
          buildState: widget.buildState,
          commit: commit,
        ),
      );
      Overlay.of(context).insert(_taskOverlay!);
    };
  }

  void _showTestDetails(BuildContext context, QualifiedTask task) {
    _taskOverlay?.remove();

    final renderBox = context.findRenderObject() as RenderBox;
    final position = renderBox.localToGlobal(Offset.zero);

    print('_showTestDetails: $position');
    _taskOverlay = OverlayEntry(
      builder: (BuildContext context) => Stack(
        children: <Widget>[
          GestureDetector(
            onTap: _closeOverlay,
            behavior: HitTestBehavior.opaque,
            child: const SizedBox.expand(),
          ),
          Positioned(
            child: CustomSingleChildLayout(
              delegate: TaskOverlayEntryPositionDelegate(
                position,
                cellSize: TaskBox.of(context),
              ),
              child: TestDetailsPopover(
                qualifiedTask: task,
                buildState: widget.buildState,
                showSnackBarCallback: ScaffoldMessenger.of(
                  context,
                ).showSnackBar,
                closeCallback: _closeOverlay,
              ),
            ),
          ),
        ],
      ),
    );
    Overlay.of(context).insert(_taskOverlay!);
  }

  void _closeOverlay() {
    _taskOverlay!.remove();
    _taskOverlay = null;
  }
}

class _Row {
  _Row(this.commit);
  final Commit commit;
  final Map<QualifiedTask, LatticeCell> cells = <QualifiedTask, LatticeCell>{};
}
