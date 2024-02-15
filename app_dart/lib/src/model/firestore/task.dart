// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:googleapis/firestore/v1.dart' hide Status;

import '../../request_handling/exceptions.dart';
import '../../service/firestore.dart';
import '../../service/logging.dart';
import '../luci/push_message.dart';

class Task extends Document {
  /// Lookup [Task] from Firestore.
  ///
  /// `documentName` follows `/projects/{project}/databases/{<}database}/documents/{document_path}`
  static Future<Task> fromFirestore({
    required FirestoreService firestoreService,
    required String documentName,
  }) async {
    final Document document = await firestoreService.getDocument(documentName);
    return Task.fromDocument(taskDocument: document);
  }

  /// Create [Task] from a task Document.
  static Task fromDocument({
    required Document taskDocument,
  }) {
    return Task()
      ..fields = taskDocument.fields!
      ..name = taskDocument.name!;
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
  int? get createTimestamp => int.parse(fields!['createTimestamp']!.integerValue!);

  /// The timestamp (in milliseconds since the Epoch) that this task started
  /// running.
  ///
  /// Tasks may be run more than once. If this task has been run more than
  /// once, this timestamp represents when the task was most recently started.
  int? get startTimestamp => int.parse(fields!['startTimestamp']!.integerValue!);

  /// The timestamp (in milliseconds since the Epoch) that this task last
  /// finished running.
  int? get endTimestamp => int.parse(fields!['endTimestamp']!.integerValue!);

  /// The name of the task.
  ///
  /// This is a human-readable name, typically a test name (e.g.
  /// "hello_world__memory").
  String? get taskName => fields!['endTimestamp']!.stringValue!;

  /// The number of attempts that have been made to run this task successfully.
  ///
  /// New tasks that have not yet been picked up by an [Agent] will have zero
  /// attempts.
  int? get attempts => int.parse(name!.split('_').last);

  /// Whether this task has been marked flaky by .ci.yaml.
  ///
  /// See also:
  ///
  ///  * <https://github.com/flutter/flutter/blob/master/.ci.yaml>
  ///
  /// A flaky (`bringup: true`) task will not block the tree.
  bool? get bringup => fields!['bringup']!.booleanValue!;

  /// Whether the test execution of this task shows flake.
  ///
  /// Test runner supports rerun, and this flag tracks if a flake happens.
  ///
  /// See also:
  ///  * <https://github.com/flutter/flutter/blob/master/dev/devicelab/lib/framework/runner.dart>
  bool? get testFlaky => fields!['testFlaky']!.booleanValue!;

  /// The build number of luci build: https://chromium.googlesource.com/infra/luci/luci-go/+/master/buildbucket/proto/build.proto#146
  int? get buildNumber => fields!.containsKey('buildNumber') ? int.parse(fields!['buildNumber']!.integerValue!) : null;

  /// The status of the task.
  ///
  /// Legal values and their meanings are defined in [legalStatusValues].
  String get status {
    final String taskStatus = fields!['status']!.stringValue!;
    if (!legalStatusValues.contains(taskStatus)) {
      throw ArgumentError('Invalid state: "$taskStatus"');
    }
    return taskStatus;
  }

  String setStatus(String value) {
    if (!legalStatusValues.contains(value)) {
      throw ArgumentError('Invalid state: "$value"');
    }
    fields!['status'] = Value(stringValue: value);
    return value;
  }

  /// Update [Task] fields based on a LUCI [Build].
  void updateFromBuild(Build build) {
    final List<String>? tags = build.tags;
    // Example tag: build_address:luci.flutter.prod/Linux Cocoon/271
    final String? buildAddress = tags?.firstWhere((String tag) => tag.contains('build_address'));
    if (buildAddress == null) {
      log.warning('Tags: $tags');
      throw const BadRequestException('build_address does not contain build number');
    }
    fields!['buildNumber'] = Value(integerValue: buildAddress.split('/').last);
    fields!['createTimestamp'] = Value(integerValue: (build.createdTimestamp?.millisecondsSinceEpoch ?? 0).toString());
    fields!['startTimestamp'] = Value(integerValue: (build.startedTimestamp?.millisecondsSinceEpoch ?? 0).toString());
    fields!['endTimestamp'] = Value(integerValue: (build.completedTimestamp?.millisecondsSinceEpoch ?? 0).toString());

    _setStatusFromLuciStatus(build);
  }

  /// Get a [Task] status from a LUCI [Build] status/result.
  String _setStatusFromLuciStatus(Build build) {
    // Updates can come out of order. Ensure completed statuses are kept.
    if (_isStatusCompleted()) {
      return status;
    }

    if (build.status == Status.started) {
      return setStatus(statusInProgress);
    }
    switch (build.result) {
      case Result.success:
        return setStatus(statusSucceeded);
      case Result.canceled:
        return setStatus(statusCancelled);
      case Result.failure:
        // Note that `Result` does not support `infraFailure`:
        // https://github.com/luci/luci-go/blob/main/common/api/buildbucket/buildbucket/v1/buildbucket-gen.go#L247-L251
        // To determine an infra failure status, we need to combine `Result.failure` and `FailureReason.infraFailure`.
        if (build.failureReason == FailureReason.infraFailure) {
          return setStatus(statusInfraFailure);
        } else {
          return setStatus(statusFailed);
        }
      default:
        throw BadRequestException('${build.result} is unknown');
    }
  }

  bool _isStatusCompleted() {
    const List<String> completedStatuses = <String>[
      statusCancelled,
      statusFailed,
      statusInfraFailure,
      statusSucceeded,
    ];
    return completedStatuses.contains(status);
  }

  @override
  String toString() {
    final StringBuffer buf = StringBuffer()
      ..write('$runtimeType(')
      ..write(', createTimestamp: $createTimestamp')
      ..write(', startTimestamp: $startTimestamp')
      ..write(', endTimestamp: $endTimestamp')
      ..write(', name: $name')
      ..write(', bringup: $bringup')
      ..write(', testRunFlaky: $testFlaky')
      ..write(', status: $status')
      ..write(')');
    return buf.toString();
  }
}
