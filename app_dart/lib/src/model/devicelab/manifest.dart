// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:json_annotation/json_annotation.dart';

import '../appengine/agent.dart';
import '../appengine/task.dart';

part 'manifest.g.dart';

/// The devicelab manifest specifies the tasks (test suites and benchmarks)
/// that run in the Flutter devicelab.
///
/// A manifest exists in the Flutter repository as a YAML file. It is a
/// specification of tasks that should be run, along with their metadata.
///
/// See also:
///
///  * <https://github.com/flutter/flutter/blob/master/dev/devicelab/manifest.yaml>
@JsonSerializable(anyMap: true)
class Manifest {
  /// Creates a new [Manifest].
  const Manifest({this.tasks});

  /// Create a new [Manifest] object from its JSON representation.
  factory Manifest.fromJson(Map<dynamic, dynamic> json) => _$ManifestFromJson(json);

  /// The tasks that are run in the devicelab, indexed by task name.
  @JsonKey()
  final Map<String, ManifestTask> tasks;

  /// Serializes this object to a JSON primitive.
  Map<String, dynamic> toJson() => _$ManifestToJson(this);
}

/// An individual task (test suite or benchmark) that runs in the Flutter
/// devicelab.
@JsonSerializable(anyMap: true)
class ManifestTask {
  /// Creates a new [ManifestTask] object.
  const ManifestTask({
    this.description,
    this.stage,
    this.requiredAgentCapabilities,
    this.isFlaky,
    this.timeoutInMinutes,
  });

  /// Create a new [ManifestTask] object from its JSON representation.
  factory ManifestTask.fromJson(Map<dynamic, dynamic> json) => _$ManifestTaskFromJson(json);

  /// The human-readable description of the task.
  @JsonKey()
  final String description;

  /// The stage name of this task.
  ///
  /// A task's stage is the category (or bucket) that groups it with other
  /// tasks. Examples include "cirrus", "chromebot", and "devicelab_ios". On
  /// the Flutter build dashboard, each stage is represented by a distinct
  /// icon.
  @JsonKey(required: true, disallowNullValue: true)
  final String stage;

  /// The list of capabilities that an agent is required to have in order to
  /// run this task.
  ///
  /// Only agents that have all of these capabilities will be scheduled to run
  /// this task.
  ///
  /// See also:
  ///
  ///  * [Agent.capabilities]
  ///  * [Task.requiredCapabilities]
  @JsonKey(name: 'required_agent_capabilities', defaultValue: <String>[])
  final List<String> requiredAgentCapabilities;

  /// Whether this task is marked as flaky.
  ///
  /// A task that is marked as flaky is allowed to fail without turning the
  /// build red.
  @JsonKey(name: 'flaky', defaultValue: false)
  final bool isFlaky;

  /// This task's timeout, specified in minutes.
  ///
  /// If this is zero (the default), the task has no timeout. A non-zero
  /// timeout will cause the agent that runs the task to fail after the
  /// specified number of minutes.
  @JsonKey(name: 'timeout_in_minutes', defaultValue: 0)
  final int timeoutInMinutes;

  /// Serializes this object to a JSON primitive.
  Map<String, dynamic> toJson() => _$ManifestTaskToJson(this);
}
