// Copyright 2025 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// @docImport 'presubmit_job.dart';
library;

import 'package:buildbucket/buildbucket_pb.dart' as bbv2;
import 'package:cocoon_common/task_status.dart';
import 'package:googleapis/firestore/v1.dart' hide Status;
import 'package:meta/meta.dart';
import 'package:path/path.dart' as p;

import '../../service/firestore.dart';
import '../bbv2_extension.dart';
import 'base.dart';

@immutable
final class PresubmitJobId extends AppDocumentId<PresubmitJob> {
  PresubmitJobId({
    required this.checkRunId,
    required this.buildName,
    required this.attemptNumber,
  }) {
    if (checkRunId < 1) {
      throw RangeError.value(checkRunId, 'checkRunId', 'Must be at least 1');
    } else if (attemptNumber < 1) {
      throw RangeError.value(
        attemptNumber,
        'attemptNumber',
        'Must be at least 1',
      );
    }
  }

  /// Parse the inverse of [PresubmitJobId.documentName].
  factory PresubmitJobId.parse(String documentName) {
    final result = tryParse(documentName);
    if (result == null) {
      throw FormatException(
        'Unexpected firestore presubmit job document name: "$documentName"',
      );
    }
    return result;
  }

  /// Tries to parse the inverse of [PresubmitJobId.documentName].
  ///
  /// If could not be parsed, returns `null`.
  static PresubmitJobId? tryParse(String documentName) {
    if (_parseDocumentName.matchAsPrefix(documentName) case final match?) {
      final checkRunId = int.tryParse(match.group(1)!);
      final buildName = match.group(2)!;
      final attemptNumber = int.tryParse(match.group(3)!);
      if (checkRunId != null && attemptNumber != null) {
        return PresubmitJobId(
          checkRunId: checkRunId,
          buildName: buildName,
          attemptNumber: attemptNumber,
        );
      }
    }
    return null;
  }

  /// Parses `{checkRunId}_{buildName}_{attemptNumber}`.
  ///
  /// [buildName] could also include underscores which led us to use regexp .
  /// But we dont have build number at the moment of creating the document and
  /// we need to query by checkRunId and buildName for updating the document.
  static final _parseDocumentName = RegExp(r'([0-9]+)_(.*)_([0-9]+)$');

  final int checkRunId;
  final String buildName;
  final int attemptNumber;

  @override
  String get documentId {
    return [checkRunId, buildName, attemptNumber].join('_');
  }

  @override
  AppDocumentMetadata<PresubmitJob> get runtimeMetadata =>
      PresubmitJob.metadata;
}

final class PresubmitJob extends AppDocument<PresubmitJob> {
  static const collectionId = 'presubmit_jobs';
  static const fieldCheckRunId = 'checkRunId';
  static const fieldBuildName = 'buildName';
  static const fieldBuildNumber = 'buildNumber';
  static const fieldStatus = 'status';
  static const fieldAttemptNumber = 'attemptNumber';
  static const fieldCreationTime = 'creationTime';
  static const fieldStartTime = 'startTime';
  static const fieldEndTime = 'endTime';
  static const fieldSummary = 'summary';

  static AppDocumentId<PresubmitJob> documentIdFor({
    required int checkRunId,
    required String buildName,
    required int attemptNumber,
  }) {
    return PresubmitJobId(
      checkRunId: checkRunId,
      buildName: buildName,
      attemptNumber: attemptNumber,
    );
  }

  /// Returns a firebase documentName used in [fromFirestore].
  static String documentNameFor({
    required int checkRunId,
    required String buildName,
    required int attemptNumber,
  }) {
    // Document names cannot cannot have '/' in the document id.
    final docId = documentIdFor(
      checkRunId: checkRunId,
      buildName: buildName,
      attemptNumber: attemptNumber,
    );
    return '$kDocumentParent/$collectionId/${docId.documentId}';
  }

  @override
  AppDocumentMetadata<PresubmitJob> get runtimeMetadata => metadata;

  static final metadata = AppDocumentMetadata<PresubmitJob>(
    collectionId: collectionId,
    fromDocument: PresubmitJob.fromDocument,
  );

  static Future<PresubmitJob> fromFirestore(
    FirestoreService firestoreService,
    AppDocumentId<PresubmitJob> id,
  ) async {
    final document = await firestoreService.getDocument(
      p.posix.join(kDatabase, 'documents', collectionId, id.documentId),
    );
    return PresubmitJob.fromDocument(document);
  }

  factory PresubmitJob({
    required int checkRunId,
    required String buildName,
    required TaskStatus status,
    required int attemptNumber,
    required int creationTime,
    int? buildNumber,
    int? startTime,
    int? endTime,
    String? summary,
  }) {
    return PresubmitJob._(
      {
        fieldCheckRunId: checkRunId.toValue(),
        fieldBuildName: buildName.toValue(),
        fieldBuildNumber: ?buildNumber?.toValue(),
        fieldStatus: status.value.toValue(),
        fieldAttemptNumber: attemptNumber.toValue(),
        fieldCreationTime: creationTime.toValue(),
        fieldStartTime: ?startTime?.toValue(),
        fieldEndTime: ?endTime?.toValue(),
        fieldSummary: ?summary?.toValue(),
      },
      name: documentNameFor(
        checkRunId: checkRunId,
        buildName: buildName,
        attemptNumber: attemptNumber,
      ),
    );
  }

  factory PresubmitJob.fromDocument(Document document) {
    return PresubmitJob._(document.fields!, name: document.name!);
  }

  factory PresubmitJob.init({
    required String buildName,
    required int checkRunId,
    required int creationTime,
    int? attemptNumber,
  }) {
    return PresubmitJob(
      buildName: buildName,
      attemptNumber: attemptNumber ?? 1,
      checkRunId: checkRunId,
      creationTime: creationTime,
      status: TaskStatus.waitingForBackfill,
      buildNumber: null,
      startTime: null,
      endTime: null,
      summary: null,
    );
  }

  PresubmitJob._(Map<String, Value> fields, {required String name}) {
    this
      ..fields = fields
      ..name = name;
  }

  int get checkRunId => int.parse(fields[fieldCheckRunId]!.integerValue!);
  String get buildName => fields[fieldBuildName]!.stringValue!;
  int get attemptNumber => int.parse(fields[fieldAttemptNumber]!.integerValue!);
  int get creationTime => int.parse(fields[fieldCreationTime]!.integerValue!);
  int? get buildNumber => fields[fieldBuildNumber] != null
      ? int.parse(fields[fieldBuildNumber]!.integerValue!)
      : null;
  int? get startTime => fields[fieldStartTime] != null
      ? int.parse(fields[fieldStartTime]!.integerValue!)
      : null;
  int? get endTime => fields[fieldEndTime] != null
      ? int.parse(fields[fieldEndTime]!.integerValue!)
      : null;
  String? get summary => fields[fieldSummary]?.stringValue;

  TaskStatus get status {
    final rawValue = fields[fieldStatus]!.stringValue!;
    return TaskStatus.from(rawValue);
  }

  set status(TaskStatus status) {
    fields[fieldStatus] = status.value.toValue();
  }

  set startTime(int startTime) {
    fields[fieldStartTime] = startTime.toValue();
  }

  set endTime(int endTime) {
    fields[fieldEndTime] = endTime.toValue();
  }

  set buildNumber(int? buildNumber) {
    if (buildNumber == null) {
      fields.remove(fieldBuildNumber);
    } else {
      fields[fieldBuildNumber] = buildNumber.toValue();
    }
  }

  set summary(String? summary) {
    if (summary == null) {
      fields.remove(fieldSummary);
    } else {
      fields[fieldSummary] = summary.toValue();
    }
  }

  void updateFromBuild(bbv2.Build build) {
    fields[fieldBuildNumber] = build.number.toValue();
    fields[fieldCreationTime] = build.createTime
        .toDateTime()
        .millisecondsSinceEpoch
        .toValue();

    if (build.hasStartTime()) {
      fields[fieldStartTime] = build.startTime
          .toDateTime()
          .millisecondsSinceEpoch
          .toValue();
    }

    if (build.hasEndTime()) {
      fields[fieldEndTime] = build.endTime
          .toDateTime()
          .millisecondsSinceEpoch
          .toValue();
    }
    _setStatusFromLuciStatus(build);
  }

  void _setStatusFromLuciStatus(bbv2.Build build) {
    if (status.isComplete) {
      return;
    }
    status = build.status.toTaskStatus();
  }
}
