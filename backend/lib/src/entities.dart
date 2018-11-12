// Copyright (c) 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:googleapis/datastore/v1.dart';

/// CocoonConfig table stores global configuration parameters.
///
/// It is keyed by parameter name and therefore must use named datastore keys.
/// The values can be edited using the datastore explorer in the GAE console.
class CocoonConfig {
  const CocoonConfig(this.parameterValue);

  final String parameterValue;
}

/// Contain information about a GitHub commit.
class CommitInfo {
  const CommitInfo(this.sha, this.author);

  final String sha;
  final AuthorInfo author;
}

/// Contains information about the author of a commit.
class AuthorInfo {
  const AuthorInfo(this.login, this.avatarUrl);

  final String login;
  final String avatarUrl;
}

/// ChecklistEntity contains storage data on a Checklist.
class ChecklistEntity {
  ChecklistEntity(this.key, this.checklist);

  final Key key;
  final Checklist checklist;
}

/// Represents a list of tasks for our bots to run.
class Checklist {
  Checklist(this.flutterRepositoryPath, this.commit, this.createTimestamp);

  final String flutterRepositoryPath;
  final CommitInfo commit;
  final DateTime createTimestamp;
}

/// A group of tasks with the same StageName.
///
/// A Stage doesn't get its own database record. The grouping is purely
/// virtual. A stage is considered uccessful when all tasks in it are
/// successful. Stages are used to organize tasks into a pipeline, where tasks
/// in some stages only run _after_ a previous stage is successful.
class Stage {
  const Stage(this.name, this.status, this.tasks);

	final String name;

  /// Aggregated status of the stage, computed as follows:
	///
	/// - TaskSucceeded if all tasks in this stage succeeded
	/// - TaskFailed if at least one task in this stage failed
	/// - TaskInProgress if at least one task is in progress and others are New
	/// - Same as Task.Status if all tasks have the same status
	/// - TaskFailed otherwise
	final TaskStatus status;
  final List<TaskEntity> tasks;
}

/// Storage data on a Task.
class TaskEntity {
  const TaskEntity(this.key, this.task);

  final Key key;
  final Task task;
}

// Task is a unit of work that our bots perform that can fail or succeed
// independently. Different tasks belonging to the same Checklist can run in
// parallel.
class Task {
  const Task(
    this.checklistKey,
    this.stageName,
    this.name,
    this.requiredCapabilities,
    this.status,
    this.reason,
    this.attempts,
    this.reservedForAgentId,
    this.createTimestamp,
    this.startTimestamp,
    this.endTimestamp,
    this.flaky,
    this.timeoutInMinutes,
  );

  final Key checklistKey;
  final String stageName;
  final String name;
  /// Capabilities an agent must have to be able to perform this task.
  final List<String> requiredCapabilities;
  final TaskStatus status;
  final String reason;
  /// The number of times Cocoon attempted to run the Task.
  final int attempts;
  final String reservedForAgentId;
  final DateTime createTimestamp;
  final DateTime startTimestamp;
  final DateTime endTimestamp;
  final bool flaky;
  /// Optional custom timeout for this task. The default value of 0 means 'use default timeout'.
  final int timeoutInMinutes;
}

/// Contains build status information about a particular checklist.
class BuildStatus {
  BuildStatus(this.checklist, this.stages, this.result);

  final ChecklistEntity checklist;
  final List<Stage> stages;
  final BuildResult result;
}

class BuildResult {
  const BuildResult._(this._value);

  /// Return the [BuildResult] corresponding to `value`.
  ///
  /// If `value` does not match one of the predetermined string, throws an
  /// [ArgumentError].
  factory BuildResult(String value) {
    switch (value) {
      case 'New':
        return buildNew;
      case 'In Progress':
        return buildInProgress;
      case 'Build Will Fail':
        return buildWillFail;
      case 'Succeeded':
        return buildSucceeded;
      case 'Failed':
        return buildFailed;
      case 'Stuck':
        return buildStuck;
    }
    throw ArgumentError(value);
  }

  /// Indicates that the build for the given checklist has not started yet.
  static const BuildResult buildNew = BuildResult._('New');

  /// Indicates that the build is still in progress.
  static const BuildResult buildInProgress = BuildResult._('In Progress');

  /// Indicates that the build is still in progress but some tasks
  /// are already known to have failed.Depending on the situation an immediate
  /// action may be taken without waiting until the build completes.
  static const BuildResult buildWillFail = BuildResult._('Build Will Fail');

  /// Indicates that the build succeeded.
  static const BuildResult buildSucceeded = BuildResult._('Succeeded');

  /// Indicates that the build failed.
  static const BuildResult buildFailed = BuildResult._('Failed');

  /// Indicates that the build is failing to progress due to build system issues.
  static const BuildResult buildStuck = BuildResult._('Stuck');

  final String _value;

  @override
  String toString() => _value;
}

/// Timeseries contains a history of values of a certain performance metric.
class Timeseries {
  const Timeseries(this.id, this.taskName, this.label, this.unit, this.goal, this.baseline, this.archived,);

	// Unique ID for computer consumption.
	final String id;

  /// Name of task that submits values for this series.
  final String taskName;

  /// A name used to display the series to humans.
  final String label;

  /// The unit used for the values, e.g. 'ms', 'kg', 'pumpkins'.
  final String unit;

  /// The current goal we want to reach for this metric.
  ///
  /// As of today, all our metrics are smaller is better.
  final double goal;

  /// The value higher than which (in the smaller-is-better sense) we consider
  /// the result as a regression that must be fixed as soon as possible.
  final double baseline;

  /// Indicates that this series contains old data that's no longer interesting.
  ///
  /// (e.g. it will be hidden from the UI).
  final bool archived;
}

/// TimeseriesEntity contains storage data on a Timeseries.
class TimeseriesEntity {
  const TimeseriesEntity(this.key, this.timeseries);

  final Key key;
  final Timeseries timeseries;
}

// TimeseriesValue is a single value collected at a certain point in time at
// a certain revision of Flutter.
//
// Entities of this type are stored as children of Timeseries and indexed by
// CreateTimestamp in descencing order for faster access.
class TimeseriesValue {
  const TimeseriesValue(this.createTimestamp, this.revision, this.taskKey, this.value, this.dataMissing);

  final DateTime createTimestamp;

  /// Flutter revision (git commit SHA)
	final String revision;

  /// The task that submitted the value.
	final Object taskKey;

  final double value;

  final bool dataMissing;
}

/// MaxAttempts is the maximum number of times a single task will be attempted
// before giving up on it.
const int maxAttempts = 2;

/// The status of a task.
class TaskStatus {
  const TaskStatus._(this._value);

  /// Returns the [TaskStatus] corresponding to the raw `value`.
  ///
  /// Returns [taskNoStatus] if a matching value is not found.
  factory TaskStatus(String value) {
    switch (value) {
      case 'New':
        return taskNew;
      case 'In Progress':
        return taskInProgress;
      case 'Succeeded':
        return taskSucceeded;
      case 'Failed':
        return taskFailed;
      case 'Skipped':
        return taskSkipped;
      default:
        return taskNoStatus;
    }
  }

  // TaskNoStatus is the zero value, meaning no status value. It is not a valid
  // status value and should only be used as a temporary variable value in
  // algorithms that need it.
  static const TaskStatus taskNoStatus = TaskStatus._('');

  // TaskNew indicates that the task was created but not acted upon.
  static const TaskStatus taskNew = TaskStatus._('New');

  // TaskInProgress indicates that the task is being performed.
  static const TaskStatus taskInProgress = TaskStatus._('In Progress');

  // TaskSucceeded indicates that the task succeeded.
  static const TaskStatus taskSucceeded = TaskStatus._('Succeeded');

  // TaskFailed indicates that the task failed.
  static const TaskStatus taskFailed = TaskStatus._('Failed');

  // TaskSkipped indicates that the task was skipped.
  static const TaskStatus taskSkipped = TaskStatus._('Skipped');

  final String _value;

  @override
  String toString() => _value;
}

// Agent is a record of registration for a particular build agent. Only
// registered agents are allowed to perform build tasks, ensured by having
// agents sign in with AgentID and authToken hashed to AuthTokenHash.
class Agent {
  const Agent(this.agentId, this.isHealthy, this.healthCheckTimestamp, this.healthDetails, this.authTokenHash, this.hidden);

  final String agentId;
  final bool isHealthy;
  final DateTime healthCheckTimestamp;
  /// A human-readable printout of health details
  final String healthDetails;
  final List<int> authTokenHash;
  // Whether this agent is visible on the dashboard. Use this for testing without polluting the
	// screen.
  final bool hidden;
}

/// AgentStatus contains agent health status.
class AgentStatus {
  const AgentStatus(this.agentId, this.isHealthy, this.healthCheckTimestamp, this.healthDetails, this.capabilities);

  final String agentId;
  final bool isHealthy;
  final DateTime healthCheckTimestamp;
  final String healthDetails;
  final List<String> capabilities;
}


/// WhitelistedAccount gives permission to access the dashboard to a specific
/// Google account.
///
/// In production an account can be added by an administrator using the
/// Datastore web UI.
///
/// The Datastore UI on the dev server is limited. To add an account make a
/// HTTP GET call to:
///
/// http://localhost:8080/api/whitelist-account?email=ACCOUNT_EMAIL
class WhitelistedAccount {
  WhitelistedAccount(this.email);

	final String email;
}

/// LogChunk stores a raw chunk of log file indexed by file owner entity and
/// timestamp.
class LogChunk {
  const LogChunk(this.ownerkey, this.createTimestamp, this.data);

  /// Points to the entity that owns this log chunk.
  final Object ownerkey;

	/// The time the chunk was logged. To get a complete log chunks are sorted
	/// by this field in descending order.
  final DateTime createTimestamp;

  /// Log data. Must not exceed 1MB (enforced by Datastore).
  final List<int> data;
}