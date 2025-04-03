// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// @docImport 'commit.dart';
library;

import 'package:buildbucket/buildbucket_pb.dart' as bbv2;
import 'package:googleapis/firestore/v1.dart' hide Status;
import 'package:meta/meta.dart';
import 'package:path/path.dart' as p;

import '../../../cocoon_service.dart';
import '../../request_handling/exceptions.dart';
import '../../service/firestore.dart';
import '../appengine/task.dart' as datastore;
import 'base.dart';

const String kTaskCollectionId = 'tasks';

/// Represents the [documentName] of a Firestore document.
@immutable
final class TaskId extends AppDocumentId<Task> {
  TaskId({
    required this.commitSha,
    required this.taskName,
    required this.currentAttempt,
  }) {
    if (currentAttempt < 1) {
      throw RangeError.value(
        currentAttempt,
        'currentAttempt',
        'Must be at least 1',
      );
    }
  }

  /// Parse the inverse of [TaskId.documentName].
  factory TaskId.parse(String documentName) {
    final result = tryParse(documentName);
    if (result == null) {
      throw FormatException(
        'Unexpected firestore task document name',
        documentName,
      );
    }
    return result;
  }

  /// Tries to parse the inverse of [TaskId.documentName].
  ///
  /// If could not be parsed, returns `null`.
  static TaskId? tryParse(String documentName) {
    if (_parseDocumentName.matchAsPrefix(documentName) case final match?) {
      final commitSha = match.group(1)!;
      final taskName = match.group(2)!;
      final currentAttempt = int.tryParse(match.group(3)!);
      if (currentAttempt != null) {
        return TaskId(
          commitSha: commitSha,
          taskName: taskName,
          currentAttempt: currentAttempt,
        );
      }
    }
    return null;
  }

  /// Parses `{commitSha}_{taskName}_{currentAttempt}`.
  ///
  /// This is gross because the [taskName] could also include underscores.
  static final _parseDocumentName = RegExp(r'([a-z0-9]+)_(.*)_([0-9]+)$');

  /// The commit SHA of the code being built.
  final String commitSha;

  /// The task name (i.e. from `.ci.yaml`).
  final String taskName;

  /// Which run (or re-run) attempt, starting at 1, this is.
  final int currentAttempt;

  @override
  String get documentId {
    return [commitSha, taskName, currentAttempt].join('_');
  }

  @override
  AppDocumentMetadata<Task> get runtimeMetadata => Task.metadata;
}

/// Representation of each task (column) per _row_ on https://flutter-dashboard.appspot.com/#/build.
///
/// Provides enough information to render a build status without querying LUCI,
/// and is also used to do some light analysis-based tasks (based on recent
/// tasks). Each [commitSha] is associated with a [Commit.sha].
///
/// This documents layout is currently:
/// ```
///  /projects/flutter-dashboard/databases/cocoon/commits/
///    document: <this.commitSha>_<this.taskName>_<this.attempt>
///
/// See also: [TaskId].
final class Task extends Document with AppDocument<Task> {
  static const fieldBringup = 'bringup';
  static const fieldBuildNumber = 'buildNumber';
  static const fieldCommitSha = 'commitSha';
  static const fieldCreateTimestamp = 'createTimestamp';
  static const fieldEndTimestamp = 'endTimestamp';
  static const fieldName = 'name';
  static const fieldStartTimestamp = 'startTimestamp';
  static const fieldStatus = 'status';
  static const fieldTestFlaky = 'testFlaky';
  static const fieldAttempt = 'attempt';

  /// Returns a document ID for a task from the given parameters.
  static AppDocumentId<Task> documentIdFor({
    required String commitSha,
    required String taskName,
    required int currentAttempt,
  }) {
    return TaskId(
      commitSha: commitSha,
      taskName: taskName,
      currentAttempt: currentAttempt,
    );
  }

  @override
  AppDocumentMetadata<Task> get runtimeMetadata => metadata;

  /// Description of the document in Firestore.
  static final metadata = AppDocumentMetadata<Task>(
    collectionId: kTaskCollectionId,
    fromDocument: Task.fromDocument,
  );

  /// Lookup [Task] from Firestore.
  ///
  /// `documentName` follows `/projects/{project}/databases/{database}/documents/{document_path}`
  static Future<Task> fromFirestore(
    FirestoreService firestoreService,
    AppDocumentId<Task> id,
  ) async {
    final document = await firestoreService.getDocument(
      p.posix.join(kDatabase, 'documents', kTaskCollectionId, id.documentId),
    );
    return Task.fromDocument(document);
  }

  factory Task({
    required String builderName,
    required int currentAttempt,
    required String commitSha,
    required bool bringup,
    required int createTimestamp,
    required int startTimestamp,
    required int endTimestamp,
    required String status,
    required bool testFlaky,
    required int? buildNumber,
  }) {
    final name = TaskId(
      taskName: builderName,
      currentAttempt: currentAttempt,
      commitSha: commitSha,
    );
    return Task._(
      {
        fieldName: Value(stringValue: builderName),
        fieldCommitSha: Value(stringValue: commitSha),
        fieldBringup: Value(booleanValue: bringup),
        if (buildNumber != null)
          fieldBuildNumber: Value(integerValue: '$buildNumber'),
        fieldCreateTimestamp: Value(integerValue: '$createTimestamp'),
        fieldStartTimestamp: Value(integerValue: '$startTimestamp'),
        fieldEndTimestamp: Value(integerValue: '$endTimestamp'),
        fieldStatus: Value(stringValue: status),
        fieldTestFlaky: Value(booleanValue: testFlaky),
        fieldAttempt: Value(integerValue: '$currentAttempt'),
      },
      name: p.posix.join(
        kDatabase,
        'documents',
        kTaskCollectionId,
        name.documentId,
      ),
    );
  }

  /// Create [Task] from a task Document.
  factory Task.fromDocument(Document document) {
    return Task._(document.fields!, name: document.name!);
  }

  factory Task.fromDatastore(datastore.Task task) {
    final commitSha = task.commitKey!.id!.split('/').last;
    final int? buildNumber;
    if (task.buildNumberList case final list? when list.isNotEmpty) {
      buildNumber = int.parse(list.split(',').last);
    } else {
      buildNumber = null;
    }
    return Task(
      builderName: task.builderName!,
      currentAttempt: task.attempts!,
      commitSha: commitSha,
      bringup: task.isFlaky!,
      buildNumber: buildNumber,
      createTimestamp: task.createTimestamp!,
      startTimestamp: task.startTimestamp!,
      endTimestamp: task.endTimestamp!,
      status: task.status,
      testFlaky: task.isTestFlaky!,
    );
  }

  Task._(Map<String, Value> fields, {required String name}) {
    this
      ..fields = fields
      ..name = name;
  }

  /// The task was cancelled.
  static const String statusCancelled = 'Cancelled';

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

  static const Set<String> taskFailStatusSet = <String>{
    Task.statusInfraFailure,
    Task.statusFailed,
    Task.statusCancelled,
  };

  /// The list of legal values for the [status] property.
  static const List<String> legalStatusValues = <String>[
    statusCancelled,
    statusFailed,
    statusInfraFailure,
    statusInProgress,
    statusNew,
    statusSkipped,
    statusSucceeded,
  ];

  static const List<String> finishedStatusValues = <String>[
    statusCancelled,
    statusFailed,
    statusInfraFailure,
    statusSkipped,
    statusSucceeded,
  ];

  /// The timestamp (in milliseconds since the Epoch) that this task was
  /// created.
  ///
  /// This is _not_ when the task first started running, as tasks start out in
  /// the 'New' state until they've been picked up by an [Agent].
  int get createTimestamp =>
      int.parse(fields![fieldCreateTimestamp]!.integerValue!);

  /// The timestamp (in milliseconds since the Epoch) that this task started
  /// running.
  ///
  /// Tasks may be run more than once. If this task has been run more than
  /// once, this timestamp represents when the task was most recently started.
  int get startTimestamp =>
      int.parse(fields![fieldStartTimestamp]!.integerValue!);

  /// The timestamp (in milliseconds since the Epoch) that this task last
  /// finished running.
  int get endTimestamp => int.parse(fields![fieldEndTimestamp]!.integerValue!);

  /// The name of the task.
  ///
  /// This is a human-readable name, typically a test name (e.g.
  /// "hello_world__memory").
  String get taskName => fields![fieldName]!.stringValue!;

  /// The sha of the task commit.
  String get commitSha => fields![fieldCommitSha]!.stringValue!;

  /// The number of attempts that have been made to run this task successfully.
  ///
  /// New tasks that have not yet been picked up by an [Agent] will have zero
  /// attempts.
  int get currentAttempt {
    // TODO(matanlurey): Simplify this when existing documents are backfilled.
    if (fields!.containsKey(fieldAttempt)) {
      return int.parse(fields![fieldAttempt]!.integerValue!);
    }

    // Read the attempts from the document name.
    return TaskId.parse(name!).currentAttempt;
  }

  /// Whether this task has been marked flaky by .ci.yaml.
  ///
  /// See also:
  ///
  ///  * <https://github.com/flutter/flutter/blob/master/.ci.yaml>
  ///
  /// A flaky (`bringup: true`) task will not block the tree.
  bool get bringup => fields![fieldBringup]!.booleanValue!;

  /// Whether the test execution of this task shows flake.
  ///
  /// Test runner supports rerun, and this flag tracks if a flake happens.
  ///
  /// See also:
  ///  * <https://github.com/flutter/flutter/blob/master/dev/devicelab/lib/framework/runner.dart>
  bool get testFlaky => fields![fieldTestFlaky]!.booleanValue!;

  /// The build number of luci build: https://chromium.googlesource.com/infra/luci/luci-go/+/master/buildbucket/proto/build.proto#146
  int? get buildNumber =>
      fields!.containsKey(fieldBuildNumber)
          ? int.parse(fields![fieldBuildNumber]!.integerValue!)
          : null;

  /// The status of the task.
  ///
  /// Legal values and their meanings are defined in [legalStatusValues].
  String get status {
    final taskStatus = fields![fieldStatus]!.stringValue!;
    if (!legalStatusValues.contains(taskStatus)) {
      throw ArgumentError('Invalid state: "$taskStatus"');
    }
    return taskStatus;
  }

  String setStatus(String value) {
    if (!legalStatusValues.contains(value)) {
      throw ArgumentError('Invalid state: "$value"');
    }
    fields![fieldStatus] = Value(stringValue: value);
    return value;
  }

  void setEndTimestamp(int endTimestamp) {
    fields![fieldEndTimestamp] = Value(integerValue: endTimestamp.toString());
  }

  void setTestFlaky(bool testFlaky) {
    fields![fieldTestFlaky] = Value(booleanValue: testFlaky);
  }

  void updateFromBuild(bbv2.Build build) {
    fields![fieldBuildNumber] = Value(integerValue: build.number.toString());

    fields![fieldCreateTimestamp] = Value(
      integerValue:
          build.createTime.toDateTime().millisecondsSinceEpoch.toString(),
    );
    fields![fieldStartTimestamp] = Value(
      integerValue:
          build.startTime.toDateTime().millisecondsSinceEpoch.toString(),
    );
    fields![fieldEndTimestamp] = Value(
      integerValue:
          build.endTime.toDateTime().millisecondsSinceEpoch.toString(),
    );

    _setStatusFromLuciStatus(build);
  }

  void resetAsRetry({int attempt = 1}) {
    name =
        '$kDatabase/documents/$kTaskCollectionId/${commitSha}_${taskName}_$attempt';
    fields = <String, Value>{
      fieldCreateTimestamp: Value(
        integerValue: DateTime.now().millisecondsSinceEpoch.toString(),
      ),
      fieldEndTimestamp: Value(integerValue: '0'),
      fieldBringup: Value(booleanValue: bringup),
      fieldName: Value(stringValue: taskName),
      fieldStartTimestamp: Value(integerValue: '0'),
      fieldStatus: Value(stringValue: Task.statusNew),
      fieldTestFlaky: Value(booleanValue: false),
      fieldCommitSha: Value(stringValue: commitSha),
      fieldAttempt: Value(integerValue: '$attempt'),
    };
  }

  String _setStatusFromLuciStatus(bbv2.Build build) {
    // Updates can come out of order. Ensure completed statuses are kept.
    if (_isStatusCompleted()) {
      return status;
    }

    if (build.status == bbv2.Status.STARTED) {
      return setStatus(statusInProgress);
    } else if (build.status == bbv2.Status.SUCCESS) {
      return setStatus(statusSucceeded);
    } else if (build.status == bbv2.Status.CANCELED) {
      return setStatus(statusCancelled);
    } else if (build.status == bbv2.Status.FAILURE) {
      return setStatus(statusFailed);
    } else if (build.status == bbv2.Status.INFRA_FAILURE) {
      return setStatus(statusInfraFailure);
    } else {
      throw BadRequestException('${build.status} is unknown');
    }
  }

  bool _isStatusCompleted() {
    const completedStatuses = <String>[
      statusCancelled,
      statusFailed,
      statusInfraFailure,
      statusSucceeded,
    ];
    return completedStatuses.contains(status);
  }
}
