// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:gcloud/db.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:meta/meta.dart';

import '../../service/luci.dart';
import 'commit.dart';
import 'key_converter.dart';

part 'task.g.dart';

/// Class that represents the intersection of a test at a particular [Commit].
///
/// Tasks are tests that have been run N (possibly zero) times against a
/// particular commit.
@JsonSerializable(createFactory: false, ignoreUnannotated: true)
@Kind(name: 'Task', idType: IdType.String)
class Task extends Model<String> {
  /// Creates a new [Task].
  Task({
    Key<String> key,
    this.commitKey,
    this.createTimestamp = 0,
    this.startTimestamp = 0,
    this.endTimestamp = 0,
    this.name,
    this.attempts = 0,
    this.isFlaky = false,
    this.timeoutInMinutes,
    this.reason = '',
    this.requiredCapabilities,
    this.reservedForAgentId = '',
    this.stageName,
    this.buildNumber,
    this.buildNumberList,
    this.builderName,
    this.luciBucket,
    String status,
  }) : _status = status {
    if (status != null && !legalStatusValues.contains(status)) {
      throw ArgumentError('Invalid state: "$status"');
    }
    parentKey = key?.parent;
    id = key?.id;
  }

  /// Construct [Task] from a [LuciBuilder].
  factory Task.chromebot({
    @required Key<String> commitKey,
    @required int createTimestamp,
    @required LuciBuilder builder,
  }) {
    assert(builder.flaky != null);
    return Task(
      attempts: 1,
      builderName: builder.name,
      commitKey: commitKey,
      createTimestamp: createTimestamp,
      isFlaky: builder.flaky ?? false,
      key: commitKey.append(Task, id: builder.name),
      // The task name of a builder is what Cocoon uses for the name.
      name: builder.taskName,
      requiredCapabilities: <String>['can-update-github'],
      stageName: 'chromebot',
      status: Task.statusNew,
      timeoutInMinutes: 0,
    );
  }

  /// The task is yet to be run.
  static const String statusNew = 'New';

  /// The task failed to run due to an unexpected issue.
  static const String statusInfraFailure = 'Infra Failure';

  /// The task is currently running.
  static const String statusInProgress = 'In Progress';

  /// The task was run successfully.
  static const String statusSucceeded = 'Succeeded';

  /// The task failed to run successfully.
  static const String statusFailed = 'Failed';

  /// The task was skipped or canceled while running.
  ///
  /// This status is only used by LUCI tasks.
  static const String statusSkipped = 'Skipped';

  /// The list of legal values for the [status] property.
  static const List<String> legalStatusValues = <String>[
    statusNew,
    statusInfraFailure,
    statusInProgress,
    statusSucceeded,
    statusFailed,
    statusSkipped,
  ];

  /// The key of the commit that owns this task.
  @ModelKeyProperty(propertyName: 'ChecklistKey', required: true)
  @JsonKey(name: 'ChecklistKey')
  @StringKeyConverter()
  Key<String> commitKey;

  /// The timestamp (in milliseconds since the Epoch) that this task was
  /// created.
  ///
  /// This is _not_ when the task first started running, as tasks start out in
  /// the 'New' state until they've been picked up by an [Agent].
  @IntProperty(propertyName: 'CreateTimestamp', required: true)
  @JsonKey(name: 'CreateTimestamp')
  int createTimestamp;

  /// The timestamp (in milliseconds since the Epoch) that this task started
  /// running.
  ///
  /// Tasks may be run more than once. If this task has been run more than
  /// once, this timestamp represents when the task was most recently started.
  @IntProperty(propertyName: 'StartTimestamp', required: true)
  @JsonKey(name: 'StartTimestamp')
  int startTimestamp;

  /// The timestamp (in milliseconds since the Epoch) that this task last
  /// finished running.
  @IntProperty(propertyName: 'EndTimestamp', required: true)
  @JsonKey(name: 'EndTimestamp')
  int endTimestamp;

  /// The name of the task.
  ///
  /// This is a human-readable name, typically a test name (e.g.
  /// "hello_world__memory").
  @StringProperty(propertyName: 'Name', required: true)
  @JsonKey(name: 'Name')
  String name;

  /// The number of attempts that have been made to run this task successfully.
  ///
  /// New tasks that have not yet been picked up by an [Agent] will have zero
  /// attempts.
  @IntProperty(propertyName: 'Attempts', required: true)
  @JsonKey(name: 'Attempts')
  int attempts;

  /// Whether this task has been marked flaky by the devicelab manifest.
  ///
  /// See also:
  ///
  ///  * <https://github.com/flutter/flutter/blob/master/dev/devicelab/manifest.yaml>
  @BoolProperty(propertyName: 'Flaky')
  @JsonKey(name: 'Flaky')
  bool isFlaky;

  /// The timeout of the task, or zero if the task has no timeout.
  @IntProperty(propertyName: 'TimeoutInMinutes', required: true)
  @JsonKey(name: 'TimeoutInMinutes')
  int timeoutInMinutes;

  /// Currently unset and unused.
  @StringProperty(propertyName: 'Reason')
  @JsonKey(name: 'Reason')
  String reason;

  /// The build number of luci build: https://chromium.googlesource.com/infra/luci/luci-go/+/master/buildbucket/proto/build.proto#146
  @IntProperty(propertyName: 'BuildNumber')
  @JsonKey(name: 'BuildNumber')
  int buildNumber;

  /// The build number list of luci builds: comma joined string of
  /// different build numbers.
  ///
  /// For the case with single run 123, [buildNumberList] = '123';
  /// For the case with multiple reruns 123, 456, 789,
  /// [buildNumberList] = '123,456,789'.
  @StringProperty(propertyName: 'BuildNumberList')
  @JsonKey(name: 'BuildNumberList')
  String buildNumberList;

  /// The builder name of luci build.
  @StringProperty(propertyName: 'BuilderName')
  @JsonKey(name: 'BuilderName')
  String builderName;

  /// The luci pool where the luci task runs.
  @StringProperty(propertyName: 'LuciBucket')
  @JsonKey(name: 'luciBucket')
  String luciBucket;

  /// The list of capabilities that agents are required to have to run this
  /// task.
  ///
  /// See also:
  ///
  ///  * [Agent.capabilities], which list the capabilities of an agent.
  @StringListProperty(propertyName: 'RequiredCapabilities')
  @JsonKey(name: 'RequiredCapabilities')
  List<String> requiredCapabilities;

  /// Set to the ID of the agent that's responsible for running this task.
  ///
  /// This will be null until an agent has reserved this task.
  @StringProperty(propertyName: 'ReservedForAgentID')
  @JsonKey(name: 'ReservedForAgentID')
  String reservedForAgentId;

  /// The name of the [Stage] that groups this task with other tasks that are
  /// related to it.
  @StringProperty(propertyName: 'StageName', required: true)
  @JsonKey(name: 'StageName')
  String stageName;

  /// The status of the task.
  ///
  /// Legal values and their meanings are defined in [legalStatusValues].
  @StringProperty(propertyName: 'Status', required: true)
  @JsonKey(name: 'Status')
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

  /// Serializes this object to a JSON primitive.
  Map<String, dynamic> toJson() => _$TaskToJson(this);

  @override
  String toString() {
    final StringBuffer buf = StringBuffer()
      ..write('$runtimeType(')
      ..write('id: $id')
      ..write(', parentKey: ${parentKey?.id}')
      ..write(', key: ${parentKey == null ? null : key.id}')
      ..write(', commitKey: ${commitKey?.id}')
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
      ..write(', buildNumber: $buildNumber')
      ..write(', buildNumberList: $buildNumberList')
      ..write(', builderName: $builderName')
      ..write(', luciBucket: $luciBucket')
      ..write(')');
    return buf.toString();
  }
}

/// The serialized representation of a [Task].
// TODO(tvolkert): Directly serialize [Task] once frontends migrate to new serialization format.
@JsonSerializable(createFactory: false)
class SerializableTask {
  const SerializableTask(this.task);

  @JsonKey(name: 'Task')
  final Task task;

  @JsonKey(name: 'Key')
  @StringKeyConverter()
  Key<String> get key => task.key;

  /// Serializes this object to a JSON primitive.
  Map<String, dynamic> toJson() => _$SerializableTaskToJson(this);
}

/// A [Task], paired with its associated parent [Commit].
///
/// The [Task] model object references its parent [Commit] through the
/// [Task.commitKey] field, but it does not hold a reference to the associated
/// [Commit] object (just the relational mapping). This class exists for those
/// times when the caller has loaded the associated commit from the datastore
/// and would like to pass both the task its commit around.
class FullTask {
  /// Creates a new [FullTask].
  const FullTask(this.task, this.commit)
      : assert(task != null),
        assert(commit != null);

  /// The [Task] object.
  final Task task;

  ///  The [Commit] object references by this [task]'s [Task.commitKey].
  final Commit commit;
}
