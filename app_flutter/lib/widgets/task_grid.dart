// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:cocoon_service/protos.dart' show CommitStatus, Commit, Stage, Task;

import '../logic/qualified_task.dart';
import '../state/build.dart';
import 'commit_box.dart';
import 'lattice.dart';
import 'task_box.dart';
import 'task_icon.dart';
import 'task_overlay.dart';

/// Container that manages the layout and data handling for [TaskGrid].
///
/// If there's no data for [TaskGrid], it shows [CircularProgressIndicator].
class TaskGridContainer extends StatelessWidget {
  const TaskGridContainer({Key key}) : super(key: key);

  @visibleForTesting
  static const String errorFetchCommitStatus = 'An error occurred fetching commit statuses';
  @visibleForTesting
  static const String errorFetchTreeStatus = 'An error occurred fetching tree build status';
  @visibleForTesting
  static const Duration errorSnackbarDuration = Duration(seconds: 8);

  @override
  Widget build(BuildContext context) {
    final BuildState buildState = Provider.of<BuildState>(context);
    return AnimatedBuilder(
      animation: buildState,
      builder: (BuildContext context, Widget child) {
        final List<CommitStatus> commitStatuses = buildState.statuses;

        // Assume if there is no data that it is loading.
        if (commitStatuses.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        return TaskGrid(
          buildState: buildState,
          commitStatuses: commitStatuses,
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
    Key key,
    // TODO(ianh): We really shouldn't take both of these, since buildState exposes status as well;
    // it's asking for trouble because the tests can (and do) describe a mutually inconsistent state.
    @required this.buildState,
    @required this.commitStatuses,
  }) : super(key: key);

  /// The build status data to display in the grid.
  final List<CommitStatus> commitStatuses;

  /// Reference to the build state to perform actions on [TaskMatrix], like rerunning tasks.
  final BuildState buildState;

  @override
  State<TaskGrid> createState() => _TaskGridState();
}

class _TaskGridState extends State<TaskGrid> {
  // TODO(ianh): Cache the lattice cells. Right now we are regenerating the entire
  // lattice matrix each time the task grid has to update, regardless of whether
  // we've received new data or not.

  @override
  Widget build(BuildContext context) {
    return LatticeScrollView(
      // TODO(ianh): Provide some vertical scroll physics that disable
      // the clamping in the vertical direction, so that you can keep
      // scrolling past the end instead of hitting a wall every time
      // we load.
      // TODO(ianh): Trigger the loading from the scroll offset,
      // rather than the current hack of loading during build.
      cells: _processCommitStatuses(widget.commitStatuses),
      cellSize: const Size.square(TaskBox.cellSize),
    );
  }

  static const Map<String, double> _statusScores = <String, double>{
    TaskBox.statusFailed: 5.0,
    TaskBox.statusInProgress: 1.0,
    TaskBox.statusNew: 1.0,
    TaskBox.statusSkipped: 0.0,
    TaskBox.statusSucceeded: 0.0,
  };

  /// This is the logic for turning the raw data from the [BuildState] object, a list of
  /// [CommitStatus] objects, into the data that describes the rendering as used by the
  /// [LatticeScrollView], a list of lists of [LatticeCell]s.
  ///
  /// The process is as follows:
  ///
  /// 1. We create `rows`, a list of [_Row] objects which are used to temporarily
  ///    represent each row in the data, where a row basically represents a [Commit].
  ///
  ///    These are derived from th `commitStatuses` directly -- each [CommitStatus] is one
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
  List<List<LatticeCell>> _processCommitStatuses(List<CommitStatus> commitStatuses) {
    // 1: PREPARE ROWS
    final List<_Row> rows = commitStatuses.map<_Row>((CommitStatus commitStatus) => _Row(commitStatus.commit)).toList();
    // 2: WALK ALL TASKS
    final Map<QualifiedTask, double> scores = <QualifiedTask, double>{};
    int commitCount = 0;
    for (final CommitStatus status in commitStatuses) {
      commitCount += 1;
      for (final Stage stage in status.stages) {
        for (final Task task in stage.tasks) {
          final QualifiedTask qualifiedTask = QualifiedTask.fromTask(task);
          if (commitCount <= 25) {
            double score = 0.0;
            if (task.attempts > 1) {
              score += 1.0;
            }
            if (_statusScores.containsKey(task.status)) {
              score += _statusScores[task.status];
            }
            if (task.isFlaky) {
              score /= 2.0;
            }
            score /= commitCount;
            scores.update(
              qualifiedTask,
              (double value) => value += score,
              ifAbsent: () => score,
            );
          } else {
            // In case we have a task that doesn't exist in the first 25 rows,
            // we still push the task into the table of scores. Otherwise, we
            // won't know how to sort the task later.
            scores.putIfAbsent(
              qualifiedTask,
              () => 0.0,
            );
          }
          rows[commitCount - 1].cells[qualifiedTask] = LatticeCell(
            painter: _painterFor(task),
            builder: _builderFor(task),
            onTap: _tapHandlerFor(status.commit, task),
          );
        }
      }
    }
    // 3: SORT
    final List<QualifiedTask> tasks = scores.keys.toList()
      ..sort((QualifiedTask a, QualifiedTask b) {
        final int scoreComparison = scores[b].compareTo(scores[a]);
        if (scoreComparison != 0) {
          return scoreComparison;
        }
        // If the scores are identical, break ties on the name of the task.
        // We do that because otherwise the sort order isn't stable.
        if (a.stage != b.stage) {
          return a.stage.compareTo(b.stage);
        }
        return a.task.compareTo(b.task);
      });
    // 4: GENERATE RESULTING LIST OF LISTS
    return <List<LatticeCell>>[
      <LatticeCell>[
        const LatticeCell(),
        ...tasks.map<LatticeCell>((QualifiedTask task) => LatticeCell(
              builder: (BuildContext context) => TaskIcon(qualifiedTask: task),
            )),
      ],
      ...rows.map<List<LatticeCell>>(
        (_Row row) => <LatticeCell>[
          LatticeCell(
            builder: (BuildContext context) => CommitBox(commit: row.commit),
          ),
          ...tasks.map<LatticeCell>((QualifiedTask task) => row.cells[task] ?? const LatticeCell()),
        ],
      ),
      if (widget.buildState.moreStatusesExist) _generateLoadingRow(tasks.length + 1),
    ];
  }

  Painter _painterFor(Task task) {
    final Paint backgroundPaint = Paint()..color = Theme.of(context).canvasColor;
    final Paint paint = Paint()
      ..color = TaskBox.statusColor.containsKey(task.status) ? TaskBox.statusColor[task.status] : Colors.black;
    if (task.isFlaky) {
      paint.style = PaintingStyle.stroke;
      paint.strokeWidth = 2.0;
      return (Canvas canvas, Rect rect) {
        canvas.drawRect(rect.deflate(6.0), paint);
      };
    }
    return (Canvas canvas, Rect rect) {
      canvas.drawRect(rect.deflate(2.0), paint);
      if (task.attempts > 1) {
        canvas.drawCircle(rect.center, (rect.shortestSide / 2.0) - 6.0, backgroundPaint);
      }
    };
  }

  WidgetBuilder _builderFor(Task task) {
    if (task.attempts > 1) {
      return (BuildContext context) => Padding(
            padding: const EdgeInsets.all(4.0),
            child: Icon(Icons.priority_high),
          );
    }
    return null;
  }

  static final List<String> _loadingMessage =
      'LOADING... '.runes.map<String>((int codepoint) => String.fromCharCode(codepoint)).toList();

  static const TextStyle loadingStyle = TextStyle(
    fontSize: TaskBox.cellSize * 0.9,
    fontWeight: FontWeight.w900,
  );

  List<LatticeCell> _generateLoadingRow(int length) {
    return List<LatticeCell>.generate(length, (int index) {
      final String character = _loadingMessage[index % _loadingMessage.length];
      return LatticeCell(
        builder: (BuildContext context) {
          widget.buildState.fetchMoreCommitStatuses(); // This is safe to call many times.
          return Text(
            character,
            style: loadingStyle,
            textAlign: TextAlign.center,
          );
        },
      );
    });
  }

  OverlayEntry _taskOverlay;

  LatticeTapCallback _tapHandlerFor(Commit commit, Task task) {
    return (Offset localPosition) {
      _taskOverlay?.remove();
      _taskOverlay = OverlayEntry(
        builder: (BuildContext context) => TaskOverlayEntry(
          position: (this.context.findRenderObject() as RenderBox)
              .localToGlobal(localPosition, ancestor: Overlay.of(context).context.findRenderObject()),
          task: task,
          showSnackBarCallback: Scaffold.of(this.context).showSnackBar,
          closeCallback: _closeOverlay,
          buildState: widget.buildState,
          commit: commit,
        ),
      );
      Overlay.of(context).insert(_taskOverlay);
    };
  }

  void _closeOverlay() {
    _taskOverlay.remove();
    _taskOverlay = null;
  }
}

class _Row {
  _Row(this.commit);
  final Commit commit;
  final Map<QualifiedTask, LatticeCell> cells = <QualifiedTask, LatticeCell>{};
}
