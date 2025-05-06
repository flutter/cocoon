// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// @docImport 'commit.dart';
library;

import 'package:buildbucket/buildbucket_pb.dart' as bbv2;
import 'package:cocoon_common/task_status.dart';
import 'package:googleapis/firestore/v1.dart' hide Status;
import 'package:meta/meta.dart';
import 'package:path/path.dart' as p;

import '../../../cocoon_service.dart';
import '../../service/firestore.dart';
import '../bbv2_extension.dart';
import '../ci_yaml/target.dart';
import '../task_ref.dart';
import 'base.dart';
import 'commit.dart' as fs;

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
        'Unexpected firestore task document name: "$documentName"',
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
final class Task extends AppDocument<Task> {
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
    required TaskStatus status,
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
        fieldName: builderName.toValue(),
        fieldCommitSha: commitSha.toValue(),
        fieldBringup: bringup.toValue(),
        if (buildNumber != null) fieldBuildNumber: buildNumber.toValue(),
        fieldCreateTimestamp: createTimestamp.toValue(),
        fieldStartTimestamp: startTimestamp.toValue(),
        fieldEndTimestamp: endTimestamp.toValue(),
        fieldStatus: status.value.toValue(),
        fieldTestFlaky: testFlaky.toValue(),
        fieldAttempt: currentAttempt.toValue(),
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

  factory Task.initialFromTarget(Target target, {required fs.Commit commit}) {
    return Task(
      currentAttempt: 1,
      createTimestamp: commit.createTimestamp,
      bringup: target.isBringup,
      status: TaskStatus.waitingForBackfill,
      commitSha: commit.sha,
      builderName: target.name,
      buildNumber: null,
      startTimestamp: 0,
      endTimestamp: 0,
      testFlaky: false,
    );
  }

  Task._(Map<String, Value> fields, {required String name}) {
    this
      ..fields = fields
      ..name = name;
  }

  /// Returns a Firestore [Write] that patches the [status] field for [id].
  @useResult
  static Write patchStatus(AppDocumentId<Task> id, TaskStatus status) {
    return Write(
      currentDocument: Precondition(exists: true),
      update: Document(
        name: p.posix.join(
          kDatabase,
          'documents',
          kTaskCollectionId,
          id.documentId,
        ),
        fields: {fieldStatus: Value(stringValue: status.value)},
      ),
      updateMask: DocumentMask(fieldPaths: [fieldStatus]),
    );
  }

  /// The task was run successfully.
  static const statusSucceeded = TaskStatus.succeeded;

  /// The timestamp (in milliseconds since the Epoch) that this task was
  /// created.
  ///
  /// This is _not_ when the task first started running, as tasks start out in
  /// the 'New' state until they've been picked up by an [Agent].
  int get createTimestamp =>
      int.parse(fields[fieldCreateTimestamp]!.integerValue!);

  /// The timestamp (in milliseconds since the Epoch) that this task started
  /// running.
  ///
  /// Tasks may be run more than once. If this task has been run more than
  /// once, this timestamp represents when the task was most recently started.
  int get startTimestamp =>
      int.parse(fields[fieldStartTimestamp]!.integerValue!);

  /// The timestamp (in milliseconds since the Epoch) that this task last
  /// finished running.
  int get endTimestamp => int.parse(fields[fieldEndTimestamp]!.integerValue!);

  /// The name of the task.
  ///
  /// This is a human-readable name, typically a test name (e.g.
  /// "hello_world__memory").
  String get taskName => fields[fieldName]!.stringValue!;

  /// The sha of the task commit.
  String get commitSha => fields[fieldCommitSha]!.stringValue!;

  /// The number of attempts that have been made to run this task successfully.
  ///
  /// New tasks that have not yet been picked up by an [Agent] will have zero
  /// attempts.
  int get currentAttempt {
    // TODO(matanlurey): Simplify this when existing documents are backfilled.
    if (fields.containsKey(fieldAttempt)) {
      return int.parse(fields[fieldAttempt]!.integerValue!);
    }

    // Read the attempts from the document name.
    final documentId = p.basename(name!);
    return TaskId.parse(documentId).currentAttempt;
  }

  ///
  /// See also:
  ///
  ///  * <https://github.com/flutter/flutter/blob/master/.ci.yaml>
  ///
  /// A flaky (`bringup: true`) task will not block the tree.
  bool get bringup => fields[fieldBringup]!.booleanValue!;

  /// Whether the test execution of this task shows flake.
  ///
  /// Test runner supports rerun, and this flag tracks if a flake happens.
  ///
  /// See also:
  ///  * <https://github.com/flutter/flutter/blob/master/dev/devicelab/lib/framework/runner.dart>
  bool get testFlaky => fields[fieldTestFlaky]!.booleanValue!;

  /// The build number of luci build: https://chromium.googlesource.com/infra/luci/luci-go/+/master/buildbucket/proto/build.proto#146
  int? get buildNumber =>
      fields.containsKey(fieldBuildNumber)
          ? int.parse(fields[fieldBuildNumber]!.integerValue!)
          : null;

  /// The status of the task.
  TaskStatus get status {
    final rawValue = fields[fieldStatus]!.stringValue!;
    return TaskStatus.from(rawValue);
  }

  void setStatus(TaskStatus status) {
    fields[fieldStatus] = status.value.toValue();
  }

  void setEndTimestamp(int endTimestamp) {
    fields[fieldEndTimestamp] = endTimestamp.toValue();
  }

  void setTestFlaky(bool testFlaky) {
    fields[fieldTestFlaky] = testFlaky.toValue();
  }

  void updateFromBuild(bbv2.Build build) {
    fields[fieldBuildNumber] = build.number.toValue();

    fields[fieldCreateTimestamp] =
        build.createTime.toDateTime().millisecondsSinceEpoch.toValue();
    fields[fieldStartTimestamp] =
        build.startTime.toDateTime().millisecondsSinceEpoch.toValue();
    fields[fieldEndTimestamp] =
        build.endTime.toDateTime().millisecondsSinceEpoch.toValue();

    _setStatusFromLuciStatus(build);
  }

  void resetAsRetry({int? attempt, DateTime? now}) {
    attempt ??= currentAttempt + 1;
    name = p.posix.join(
      kDatabase,
      'documents',
      kTaskCollectionId,
      Task.documentIdFor(
        commitSha: commitSha,
        currentAttempt: attempt,
        taskName: taskName,
      ).documentId,
    );
    now ??= DateTime.now();
    fields = <String, Value>{
      fieldCreateTimestamp: now.millisecondsSinceEpoch.toValue(),
      fieldEndTimestamp: 0.toValue(),
      fieldBringup: bringup.toValue(),
      fieldName: taskName.toValue(),
      fieldStartTimestamp: 0.toValue(),
      fieldStatus: TaskStatus.waitingForBackfill.value.toValue(),
      fieldTestFlaky: false.toValue(),
      fieldCommitSha: commitSha.toValue(),
      fieldAttempt: attempt.toValue(),
    };
  }

  void setBuildNumber(int buildNumber) {
    fields[fieldBuildNumber] = buildNumber.toValue();
  }

  void _setStatusFromLuciStatus(bbv2.Build build) {
    // Updates can come out of order. Ensure completed statuses are kept.
    if (status.isComplete) {
      return;
    }

    setStatus(build.status.toTaskStatus());
  }

  /// Returns an immutable reference to the commit modeled by `this`.
  ///
  /// Changes to `this` are not reflected on the result.
  TaskRef toRef() {
    return TaskRef(
      name: taskName,
      currentAttempt: currentAttempt,
      status: status,
      commitSha: commitSha,
    );
  }
}
