// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:gcloud/db.dart';

/// Class that represents the intersection of a test at a particular [Commit].
///
/// Tasks are tests that have been run N (possibly zero) times against a
/// particular commit.
@Kind(name: 'Task')
class Task extends Model {
  /// Creates a new [Task].
  Task({
    this.commitKey,
    this.createTimestamp,
    this.startTimestamp,
    this.name,
    this.attempts,
    this.isFlaky,
    this.timeoutInMinutes,
    this.reason,
    this.requiredCapabilities,
    this.reservedForAgentId,
    this.stageName,
    String status,
  })  : assert(status == null || legalStatusValues.contains(status)),
        _status = status;

  /// The list of legal values for the [status] property.
  static const List<String> legalStatusValues = <String>[
    /// The task is yet to be run.
    'New',

    /// The task is currently running.
    'In Progress',

    /// The task was run successfully.
    'Succeeded',

    /// The task failed to run successfully.
    'Failed',
  ];

  /// The key of the commit that owns this task.
  @ModelKeyProperty(propertyName: 'ChecklistKey', required: true)
  Key commitKey;

  /// The timestamp (in milliseconds since the Epoch) that this task was
  /// created.
  ///
  /// This is _not_ when the task first started running, as tasks start out in
  /// the 'New' state until they've been picked up by an [Agent].
  @IntProperty(propertyName: 'CreateTimestamp', required: true)
  int createTimestamp;

  /// The timestamp (in milliseconds since the Epoch) that this task started
  /// running.
  ///
  /// Tasks may be run more than once. If this task has been run more than
  /// once, this timestamp represents when the task was most recently started.
  @IntProperty(propertyName: 'StartTimestamp', required: true)
  int startTimestamp;

  /// The timestamp (in milliseconds since the Epoch) that this task last
  /// finished running.
  @IntProperty(propertyName: 'EndTimestamp', required: true)
  int endTimestamp;

  /// The name of the task.
  ///
  /// This is a human-readable name, typically a test name (e.g.
  /// "hello_world__memory").
  @StringProperty(propertyName: 'Name', required: true)
  String name;

  /// The number of attempts that have been made to run this task successfully.
  ///
  /// New tasks that have not yet been picked up by an [Agent] will have zero
  /// attempts.
  @IntProperty(propertyName: 'Attempts', required: true)
  int attempts;

  /// Whether this task has been marked flaky by the devicelab manifest.
  ///
  /// See also:
  ///
  ///  * <https://github.com/flutter/flutter/blob/master/dev/devicelab/manifest.yaml>
  @BoolProperty(propertyName: 'Flaky', required: true)
  bool isFlaky;

  /// The timeout of the task, or zero if the task has no timeout.
  @IntProperty(propertyName: 'TimeoutInMinutes', required: true)
  int timeoutInMinutes;

  /// Currently unset and unused.
  @StringProperty(propertyName: 'Reason')
  String reason;

  /// The list of capabilities that agents are required to have to run this
  /// task.
  ///
  /// See also:
  ///
  ///  * [Agent.capabilities], which list the capabilities of an agent.
  @StringListProperty(propertyName: 'RequiredCapabilities')
  List<String> requiredCapabilities;

  /// Set to the ID of the agent that's responsible for running this task.
  ///
  /// This will be null until an agent has reserved this task.
  @StringProperty(propertyName: 'ReservedForAgentID')
  String reservedForAgentId;

  /// The name of the [Stage] that groups this task with other tasks that are
  /// related to it.
  @StringProperty(propertyName: 'StageName', required: true)
  String stageName;

  /// The status of the task.
  ///
  /// Legal values and their meanings are defined in [legalStatusValues].
  @StringProperty(propertyName: 'Status', required: true)
  String get status => _status;
  String _status;
  set status(String value) {
    if (!legalStatusValues.contains(value)) {
      throw ArgumentError('Invalid state: "$value"');
    }
    _status = value;
  }

  /// Comparator that sorts tasks by fewest attempts first.
  static int byAttempts(Task a, Task b) => a.attempts.compareTo(b.attempts);

  @override
  String toString() {
    StringBuffer buf = StringBuffer();
    buf
      ..write('$runtimeType(')
      ..write('id: $id')
      ..write(', parentKey: ${parentKey.id}')
      ..write(', key: ${key.id}')
      ..write(', commitKey: ${commitKey.id}')
      ..write(', createTimestamp: $createTimestamp')
      ..write(', startTimestamp: $startTimestamp')
      ..write(', endTimestamp: $endTimestamp')
      ..write(', name: $name')
      ..write(', attempts: $attempts')
      ..write(', isFlaky: $isFlaky')
      ..write(', timeoutInMinutes: $timeoutInMinutes')
      ..write(', reason: $reason')
      ..write(', requiredCapabilities: $requiredCapabilities')
      ..write(', reservedForAgentId: $reservedForAgentId')
      ..write(', stageName: $stageName')
      ..write(', status: $status')
      ..write(')');
    return buf.toString();
  }
}
