// Copyright 2025 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// @docImport 'presubmit_job.dart';
library;

import 'package:buildbucket/buildbucket_pb.dart' as bbv2;
import 'package:cocoon_common/task_status.dart';
import 'package:github/github.dart';
import 'package:googleapis/firestore/v1.dart' hide Status;
import 'package:meta/meta.dart';
import 'package:path/path.dart' as p;

import '../../service/firestore.dart';
import '../bbv2_extension.dart';
import 'base.dart';

@immutable
final class PresubmitJobId extends AppDocumentId<PresubmitJob> {
  PresubmitJobId({
    required this.slug,
    required this.checkRunId,
    required this.jobName,
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
      final owner = match.group(1)!;
      final repo = match.group(2)!;
      final checkRunId = int.tryParse(match.group(3)!);
      final jobName = match.group(4)!;
      final attemptNumber = int.tryParse(match.group(5)!);
      if (checkRunId != null && attemptNumber != null) {
        return PresubmitJobId(
          slug: RepositorySlug(owner, repo),
          checkRunId: checkRunId,
          jobName: jobName,
          attemptNumber: attemptNumber,
        );
      }
    }
    return null;
  }

  /// Parses `{owner}_{repo}_{check_run_id}_{job_name}_{attempt_number}`.
  ///
  /// [jobName] could also include underscores which led us to use regexp .
  /// But we dont have job number at the moment of creating the document and
  /// we need to query by check_run_id and job_name for updating the document.
  static final _parseDocumentName = RegExp(
    r'^([a-zA-Z0-9_-]+)_([a-zA-Z0-9_-]+)_([0-9]+)_(.*)_([0-9]+)$',
  );

  final RepositorySlug slug;
  final int checkRunId;
  final String jobName;
  final int attemptNumber;

  @override
  String get documentId {
    return [
      slug.owner,
      slug.name,
      checkRunId,
      jobName,
      attemptNumber,
    ].join('_');
  }

  @override
  AppDocumentMetadata<PresubmitJob> get runtimeMetadata =>
      PresubmitJob.metadata;
}

final class PresubmitJob extends AppDocument<PresubmitJob> {
  static const collectionId = 'presubmit_jobs';
  static const fieldCheckRunId = 'check_run_id';
  static const fieldSlug = 'slug';
  static const fieldJobName = 'job_name';
  static const fieldBuildNumber = 'build_number';
  static const fieldStatus = 'status';
  static const fieldAttemptNumber = 'attempt_number';
  static const fieldCreationTime = 'creation_time';
  static const fieldStartTime = 'start_time';
  static const fieldEndTime = 'end_time';
  static const fieldSummary = 'summary';

  static AppDocumentId<PresubmitJob> documentIdFor({
    required RepositorySlug slug,
    required int checkRunId,
    required String jobName,
    required int attemptNumber,
  }) {
    return PresubmitJobId(
      slug: slug,
      checkRunId: checkRunId,
      jobName: jobName,
      attemptNumber: attemptNumber,
    );
  }

  /// Returns a firebase documentName used in [fromFirestore].
  static String documentNameFor({
    required RepositorySlug slug,
    required int checkRunId,
    required String jobName,
    required int attemptNumber,
  }) {
    // Document names cannot cannot have '/' in the document id.
    final docId = documentIdFor(
      slug: slug,
      checkRunId: checkRunId,
      jobName: jobName,
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
    required RepositorySlug slug,
    required int checkRunId,
    required String jobName,
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
        fieldSlug: slug.fullName.toValue(),
        fieldCheckRunId: checkRunId.toValue(),
        fieldJobName: jobName.toValue(),
        fieldBuildNumber: ?buildNumber?.toValue(),
        fieldStatus: status.value.toValue(),
        fieldAttemptNumber: attemptNumber.toValue(),
        fieldCreationTime: creationTime.toValue(),
        fieldStartTime: ?startTime?.toValue(),
        fieldEndTime: ?endTime?.toValue(),
        fieldSummary: ?summary?.toValue(),
      },
      name: documentNameFor(
        slug: slug,
        checkRunId: checkRunId,
        jobName: jobName,
        attemptNumber: attemptNumber,
      ),
    );
  }

  factory PresubmitJob.fromDocument(Document document) {
    return PresubmitJob._(document.fields!, name: document.name!);
  }

  factory PresubmitJob.init({
    required RepositorySlug slug,
    required String jobName,
    required int checkRunId,
    required int creationTime,
    int? attemptNumber,
  }) {
    return PresubmitJob(
      slug: slug,
      jobName: jobName,
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

  RepositorySlug get slug {
    if (fields[fieldSlug] != null) {
      return RepositorySlug.full(fields[fieldSlug]!.stringValue!);
    }
    // Read it from the document name.
    return PresubmitJobId.parse(p.posix.basename(name!)).slug;
  }

  int get checkRunId => int.parse(fields[fieldCheckRunId]!.integerValue!);
  String get jobName => fields[fieldJobName]!.stringValue!;
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
