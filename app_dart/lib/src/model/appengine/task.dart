// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:buildbucket/buildbucket_pb.dart' as bbv2;
import 'package:cocoon_server/logging.dart';
import 'package:gcloud/db.dart';
import 'package:github/github.dart';
import 'package:json_annotation/json_annotation.dart';

import '../../request_handling/exceptions.dart';
import '../../service/datastore.dart';
import '../../service/luci_build_service/opaque_commit.dart';
import '../ci_yaml/target.dart';
import 'commit.dart';
import 'key_converter.dart';

part 'task.g.dart';

/// Class that represents the intersection of a test at a particular [Commit].
///
/// Tasks are tests that have been run N (possibly zero) times against a
/// particular commit.
@JsonSerializable(createFactory: false, ignoreUnannotated: true)
@Kind(name: 'Task')
class Task extends Model<int> {
  /// Creates a new [Task].
  Task({
    Key<int>? key,
    this.commitKey,
    this.createTimestamp = 0,
    this.startTimestamp = 0,
    this.endTimestamp = 0,
    this.name,
    this.attempts = 0,
    this.isFlaky = false,
    this.isTestFlaky = false,
    this.timeoutInMinutes,
    this.reason = '',
    this.requiredCapabilities,
    this.reservedForAgentId = '',
    this.stageName,
    this.buildNumber,
    this.buildNumberList,
    this.builderName,
    this.luciBucket,
    String? status,
  }) : _status = status {
    if (status != null && !legalStatusValues.contains(status)) {
      throw ArgumentError('Invalid state: "$status"');
    }
    parentKey = key?.parent;
    id = key?.id;
  }

  /// Construct [Task] from a [Target].
  factory Task.fromTarget({required Commit commit, required Target target}) {
    return Task(
      attempts: 1,
      builderName: target.name,
      commitKey: commit.key,
      createTimestamp: commit.timestamp!,
      isFlaky: target.isBringup,
      key: commit.key.append(Task),
      name: target.name,
      requiredCapabilities: <String>[/*Unused anyway*/],
      stageName: target.scheduler.name,
      status: Task.statusNew,
      timeoutInMinutes: target.timeoutInMinutes,
    );
  }

  /// Lookup [Task] from Datastore from its parent key and name.
  static Future<Task> fromCommitKey({
    required DatastoreService datastore,
    required Key<String> commitKey,
    required String name,
  }) async {
    if (name.isEmpty) {
      throw const BadRequestException('task name is null');
    }
    final query = datastore.db.query<Task>(ancestorKey: commitKey)
      ..filter('name =', name);
    final tasks = await query.run().toList();
    if (tasks.length != 1) {
      log.error('Found ${tasks.length} entries for builder $name');
      throw InternalServerError(
        'Expected to find 1 task for $name, but found ${tasks.length}',
      );
    }
    return tasks.single;
  }

  /// Lookup [Task] from its [key].
  ///
  /// This is the fastest way to lookup [Task], but requires [id] to be passed
  /// as it is generated from Datastore.
  static Future<Task> fromKey({
    required DatastoreService datastore,
    required Key<String> commitKey,
    required int id,
  }) {
    log.debug('Looking up key...');
    final key = Key<int>(commitKey, Task, id);
    return datastore.lookupByValue<Task>(key);
  }

  /// Lookup [Task] from Datastore.
  ///
  /// Either name or id must be given to lookup [Task].
  ///
  /// Prefer passing [id] when possible as it is a faster lookup.
  static Future<Task> fromDatastore({
    required DatastoreService datastore,
    required Key<String> commitKey,
    String? name,
    String? id,
  }) {
    if (id == null) {
      return Task.fromCommitKey(
        datastore: datastore,
        commitKey: commitKey,
        name: name!,
      );
    }

    return Task.fromKey(
      datastore: datastore,
      commitKey: commitKey,
      id: int.parse(id),
    );
  }

  /// Creates a [Task] based on a buildbucket [bb.Build].
  static Future<Task> fromBuildbucketBuild(
    bbv2.Build build,
    DatastoreService datastore, {
    String? customName,
  }) async {
    log.debug('Creating task from buildbucket result: ${build.toString()}');
    // Example: Getting "flutter" from "mirrors/flutter".
    final repository = build.input.gitilesCommit.project.split('/')[1];
    log.debug('Repository: $repository');

    // Example: Getting "stable" from "refs/heads/stable".
    final branch = build.input.gitilesCommit.ref.split('/')[2];
    log.debug('Branch: $branch');

    final hash = build.input.gitilesCommit.id;
    log.debug('Hash: $hash');

    final slug = RepositorySlug('flutter', repository);
    log.debug('Slug: ${slug.toString()}');

    final startTime = build.startTime.toDateTime().millisecondsSinceEpoch;
    final endTime = build.endTime.toDateTime().millisecondsSinceEpoch;
    log.debug('Start/end time (ms): $startTime, $endTime');

    final id = '${slug.fullName}/$branch/$hash';
    final commitKey = datastore.db.emptyKey.append<String>(Commit, id: id);
    final commit = await datastore.db.lookupValue<Commit>(commitKey);
    final task = Task(
      attempts: 1,
      buildNumber: build.number,
      buildNumberList: build.number.toString(),
      builderName: build.builder.builder,
      commitKey: commitKey,
      createTimestamp: startTime,
      endTimestamp: endTime,
      luciBucket: build.builder.bucket,
      name: customName ?? build.builder.builder,
      stageName: build.builder.project,
      startTimestamp: startTime,
      status: convertBuildbucketStatusToString(build.status),
      key: commit.key.append(Task),
      timeoutInMinutes: 0,
      reason: '',
      requiredCapabilities: [],
      reservedForAgentId: '',
    );
    return task;
  }

  static String convertBuildbucketStatusToString(bbv2.Status status) {
    switch (status) {
      case bbv2.Status.SUCCESS:
        return statusSucceeded;
      case bbv2.Status.CANCELED:
        return statusCancelled;
      case bbv2.Status.INFRA_FAILURE:
        return statusInfraFailure;
      case bbv2.Status.STARTED:
        return statusInProgress;
      case bbv2.Status.SCHEDULED:
        return statusNew;
      default:
        return statusFailed;
    }
  }

  /// The task was cancelled.
  static const statusCancelled = 'Cancelled';

  /// The task is yet to be run.
  static const statusNew = 'New';

  /// The task failed to run due to an unexpected issue.
  static const statusInfraFailure = 'Infra Failure';

  /// The task is currently running.
  static const statusInProgress = 'In Progress';

  /// The task was run successfully.
  static const statusSucceeded = 'Succeeded';

  /// The task failed to run successfully.
  static const statusFailed = 'Failed';

  /// The task was skipped or canceled while running.
  ///
  /// This status is only used by LUCI tasks.
  static const statusSkipped = 'Skipped';

  static const taskFailStatusSet = {
    Task.statusInfraFailure,
    Task.statusFailed,
    Task.statusCancelled,
  };

  /// The list of legal values for the [status] property.
  static const legalStatusValues = {
    statusCancelled,
    statusFailed,
    statusInfraFailure,
    statusInProgress,
    statusNew,
    statusSkipped,
    statusSucceeded,
  };

  static const finishedStatusValues = {
    statusCancelled,
    statusFailed,
    statusInfraFailure,
    statusSkipped,
    statusSucceeded,
  };

  /// The key of the commit that owns this task.
  @ModelKeyProperty(propertyName: 'ChecklistKey')
  @JsonKey(name: 'ChecklistKey')
  @StringKeyConverter()
  Key<String>? commitKey;

  /// The timestamp (in milliseconds since the Epoch) that this task was
  /// created.
  ///
  /// This is _not_ when the task first started running, as tasks start out in
  /// the 'New' state until they've been picked up by an [Agent].
  @IntProperty(propertyName: 'CreateTimestamp', required: true)
  @JsonKey(name: 'CreateTimestamp')
  int? createTimestamp;

  /// The timestamp (in milliseconds since the Epoch) that this task started
  /// running.
  ///
  /// Tasks may be run more than once. If this task has been run more than
  /// once, this timestamp represents when the task was most recently started.
  @IntProperty(propertyName: 'StartTimestamp', required: true)
  @JsonKey(name: 'StartTimestamp')
  int? startTimestamp;

  /// The timestamp (in milliseconds since the Epoch) that this task last
  /// finished running.
  @IntProperty(propertyName: 'EndTimestamp', required: true)
  @JsonKey(name: 'EndTimestamp')
  int? endTimestamp;

  /// The name of the task.
  ///
  /// This is a human-readable name, typically a test name (e.g.
  /// "hello_world__memory").
  @StringProperty(propertyName: 'Name', required: true)
  @JsonKey(name: 'Name')
  String? name;

  /// The number of attempts that have been made to run this task successfully.
  ///
  /// New tasks that have not yet been picked up by an [Agent] will have zero
  /// attempts.
  @IntProperty(propertyName: 'Attempts', required: true)
  @JsonKey(name: 'Attempts')
  int? attempts;

  /// Whether this task has been marked flaky by .ci.yaml.
  ///
  /// See also:
  ///
  ///  * <https://github.com/flutter/flutter/blob/master/.ci.yaml>
  ///
  /// A flaky (`bringup: true`) task will not block the tree.
  @BoolProperty(propertyName: 'Flaky')
  @JsonKey(name: 'Flaky')
  bool? isFlaky;

  /// Whether the test execution of this task shows flake.
  ///
  /// Test runner supports rerun, and this flag tracks if a flake happens.
  ///
  /// See also:
  ///  * <https://github.com/flutter/flutter/blob/master/dev/devicelab/lib/framework/runner.dart>
  @BoolProperty(propertyName: 'TestFlaky')
  @JsonKey(name: 'TestFlaky')
  bool? isTestFlaky;

  /// The timeout of the task, or zero if the task has no timeout.
  @IntProperty(propertyName: 'TimeoutInMinutes', required: true)
  @JsonKey(name: 'TimeoutInMinutes')
  int? timeoutInMinutes;

  /// Currently unset and unused.
  @StringProperty(propertyName: 'Reason')
  @JsonKey(name: 'Reason')
  String? reason;

  /// The build number of luci build: https://chromium.googlesource.com/infra/luci/luci-go/+/master/buildbucket/proto/build.proto#146
  @IntProperty(propertyName: 'BuildNumber')
  @JsonKey(name: 'BuildNumber')
  int? buildNumber;

  /// The build number list of luci builds: comma joined string of
  /// different build numbers.
  ///
  /// For the case with single run 123, [buildNumberList] = '123';
  /// For the case with multiple reruns 123, 456, 789,
  /// [buildNumberList] = '123,456,789'.
  @StringProperty(propertyName: 'BuildNumberList')
  @JsonKey(name: 'BuildNumberList')
  String? buildNumberList;

  /// The builder name of luci build.
  @StringProperty(propertyName: 'BuilderName')
  @JsonKey(name: 'BuilderName')
  String? builderName;

  /// The luci pool where the luci task runs.
  @StringProperty(propertyName: 'LuciBucket')
  @JsonKey(name: 'luciBucket')
  String? luciBucket;

  /// The list of capabilities that agents are required to have to run this
  /// task.
  ///
  /// See also:
  ///
  ///  * [Agent.capabilities], which list the capabilities of an agent.
  @StringListProperty(propertyName: 'RequiredCapabilities')
  @JsonKey(name: 'RequiredCapabilities')
  List<String>? requiredCapabilities;

  /// Set to the ID of the agent that's responsible for running this task.
  ///
  /// This will be null until an agent has reserved this task.
  @StringProperty(propertyName: 'ReservedForAgentID')
  @JsonKey(name: 'ReservedForAgentID')
  String? reservedForAgentId;

  /// The name of the [Stage] that groups this task with other tasks that are
  /// related to it.
  @StringProperty(propertyName: 'StageName', required: true)
  @JsonKey(name: 'StageName')
  String? stageName;

  /// The status of the task.
  ///
  /// Legal values and their meanings are defined in [legalStatusValues].
  @StringProperty(propertyName: 'Status', required: true)
  @JsonKey(name: 'Status')
  String get status => _status ?? statusNew;
  String? _status;
  set status(String value) {
    if (!legalStatusValues.contains(value)) {
      throw ArgumentError('Invalid state: "$value"');
    }
    _status = value;
  }

  void updateFromBuildbucketBuild(bbv2.Build build) {
    buildNumber = build.number;

    if (buildNumberList == null) {
      buildNumberList = '$buildNumber';
    } else {
      final buildNumberSet = buildNumberList!.split(',').toSet();
      buildNumberSet.add(buildNumber.toString());
      buildNumberList = buildNumberSet.join(',');
    }

    createTimestamp = build.createTime.toDateTime().millisecondsSinceEpoch;
    startTimestamp = build.startTime.toDateTime().millisecondsSinceEpoch;
    endTimestamp = build.endTime.toDateTime().millisecondsSinceEpoch;

    attempts = buildNumberList!.split(',').length;

    status = convertBuildbucketStatusToString(build.status);
  }

  /// Comparator that sorts tasks by fewest attempts first.
  static int byAttempts(Task a, Task b) => a.attempts!.compareTo(b.attempts!);

  /// Serializes this object to a JSON primitive.
  Map<String, dynamic> toJson() => _$TaskToJson(this);

  @override
  String toString() {
    final buf =
        StringBuffer()
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
          ..write(', isTestRunFlaky: $isTestFlaky')
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

Iterable<Task> targetsToTasks(Commit commit, List<Target> targets) => targets
    .map((Target target) => Task.fromTarget(commit: commit, target: target));

/// The serialized representation of a [Task].
// TODO(tvolkert): Directly serialize [Task] once frontends migrate to new serialization format.
@JsonSerializable(createFactory: false)
class SerializableTask {
  const SerializableTask(this.task);

  @JsonKey(name: 'Task')
  final Task task;

  @JsonKey(name: 'Key')
  @IntKeyConverter()
  Key<int> get key => task.key;

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
  const FullTask(this.task, this.commit);

  /// The [Task] object.
  final Task task;

  ///  The [Commit] object references by this [task]'s [Task.commitKey].
  final OpaqueCommit commit;
}
