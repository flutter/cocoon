// Copyright 2025 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// @docImport 'presubmit_guard.dart';
library;

import 'dart:convert';

import 'package:cocoon_common/task_status.dart';
import 'package:github/github.dart';
import 'package:googleapis/firestore/v1.dart' hide Status;
import 'package:path/path.dart' as p;

import '../../../cocoon_service.dart';
import 'base.dart';

final class PresubmitGuardId extends AppDocumentId<PresubmitGuard> {
  PresubmitGuardId({
    required this.slug,
    required this.prNum,
    required this.checkRunId,
    required this.stage,
  });

  /// The repository owner/name.
  final RepositorySlug slug;

  /// The pull request number.
  final int prNum;

  /// The Check Run Id.
  final int checkRunId;

  /// The stage of the CI process.
  final CiStage stage;

  @override
  String get documentId =>
      [slug.owner, slug.name, prNum, checkRunId, stage].join('_');

  @override
  AppDocumentMetadata<PresubmitGuard> get runtimeMetadata =>
      PresubmitGuard.metadata;
}

final class PresubmitGuard extends AppDocument<PresubmitGuard> {
  static const collectionId = 'presubmit_guards';
  static const fieldCheckRun = 'check_run';
  static const fieldCheckRunId = 'check_run_id';
  static const fieldPrNum = 'pr_num';
  static const fieldSlug = 'slug';
  static const fieldStage = 'stage';
  static const fieldHeadSha = 'head_sha';
  static const fieldAuthor = 'author';
  static const fieldCreationTime = 'creation_time';
  static const fieldRemainingJobs = 'remaining_jobs';
  static const fieldFailedJobs = 'failed_jobs';
  static const fieldJobs = 'jobs';

  static AppDocumentId<PresubmitGuard> documentIdFor({
    required RepositorySlug slug,
    required int prNum,
    required int checkRunId,
    required CiStage stage,
  }) {
    return PresubmitGuardId(
      slug: slug,
      prNum: prNum,
      checkRunId: checkRunId,
      stage: stage,
    );
  }

  /// Returns a firebase documentName used in [fromFirestore].
  static String documentNameFor({
    required RepositorySlug slug,
    required int prNum,
    required int checkRunId,
    required CiStage stage,
  }) {
    // Document names cannot cannot have '/' in the document id.
    final docId = documentIdFor(
      slug: slug,
      prNum: prNum,
      checkRunId: checkRunId,
      stage: stage,
    );
    return '$kDocumentParent/$collectionId/${docId.documentId}';
  }

  /// Returns the document ID for the given parameters.
  // static String documentId({
  //   required RepositorySlug slug,
  //   required int prNum,
  //   required int checkRunId,
  //   required CiStage stage,
  // }) =>
  //     '${slug.owner}_${slug.name}_${prNum}_${checkRunId}_${stage.name}';

  @override
  AppDocumentMetadata<PresubmitGuard> get runtimeMetadata => metadata;

  static final metadata = AppDocumentMetadata<PresubmitGuard>(
    collectionId: collectionId,
    fromDocument: PresubmitGuard.fromDocument,
  );

  factory PresubmitGuard.init({
    required RepositorySlug slug,
    required int prNum,
    required CheckRun checkRun,
    required CiStage stage,
    required String headSha,
    required int creationTime,
    required String author,
    required int jobCount,
  }) {
    return PresubmitGuard(
      checkRun: checkRun,
      headSha: headSha,
      slug: slug,
      prNum: prNum,
      stage: stage,
      author: author,
      creationTime: creationTime,
      remainingJobs: jobCount,
      failedJobs: 0,
    );
  }

  factory PresubmitGuard.fromDocument(Document document) {
    return PresubmitGuard._(document.fields!, name: document.name!);
  }

  factory PresubmitGuard({
    required CheckRun checkRun,
    required String headSha,
    required RepositorySlug slug,
    required int prNum,
    required CiStage stage,
    required int creationTime,
    required String author,
    required int remainingJobs,
    required int failedJobs,
    Map<String, TaskStatus>? jobs,
  }) {
    return PresubmitGuard._(
      {
        fieldCheckRunId: checkRun.id!.toValue(),
        fieldPrNum: prNum.toValue(),
        fieldSlug: slug.fullName.toValue(),
        fieldStage: stage.name.toValue(),
        fieldHeadSha: headSha.toValue(),
        fieldCreationTime: creationTime.toValue(),
        fieldAuthor: author.toValue(),
        fieldCheckRun: json.encode(checkRun.toJson()).toValue(),
        fieldRemainingJobs: remainingJobs.toValue(),
        fieldFailedJobs: failedJobs.toValue(),
        if (jobs != null)
          fieldJobs: Value(
            mapValue: MapValue(
              fields: jobs.map((k, v) => MapEntry(k, v.value.toValue())),
            ),
          ),
      },
      name: documentNameFor(
        slug: slug,
        prNum: prNum,
        checkRunId: checkRun.id!,
        stage: stage,
      ),
    );
  }

  PresubmitGuard._(Map<String, Value> fields, {required String name}) {
    this.fields = fields;
    this.name = name;
  }

  String get commitSha => fields[fieldHeadSha]!.stringValue!;
  String get author => fields[fieldAuthor]!.stringValue!;
  int get creationTime => int.parse(fields[fieldCreationTime]!.integerValue!);
  int get remainingJobs => int.parse(fields[fieldRemainingJobs]!.integerValue!);
  int get failedJobs => int.parse(fields[fieldFailedJobs]!.integerValue!);
  Map<String, TaskStatus> get jobs =>
      fields[fieldJobs]?.mapValue?.fields?.map<String, TaskStatus>(
        (k, v) => MapEntry(k, TaskStatus.from(v.stringValue!)),
      ) ??
      <String, TaskStatus>{};
  CheckRun get checkRun {
    final jsonData =
        jsonDecode(fields[fieldCheckRun]!.stringValue!) as Map<String, Object?>;
    // Workaround for https://github.com/SpinlockLabs/github.dart/issues/412
    if (jsonData['conclusion'] == 'null') {
      jsonData.remove('conclusion');
    }
    return CheckRun.fromJson(jsonData);
  }

  String get checkRunJson => fields[fieldCheckRun]!.stringValue!;

  /// The repository that this stage is recorded for.
  RepositorySlug get slug {
    if (fields[fieldSlug] != null) {
      return RepositorySlug.full(fields[fieldSlug]!.stringValue!);
    }
    // Read it from the document name.
    final [owner, repo, _, _, _] = p.posix.basename(name!).split('_');
    return RepositorySlug(owner, repo);
  }

  /// The pull request for which this stage is recorded for.
  int get prNum {
    if (fields[fieldPrNum] != null) {
      return int.parse(fields[fieldPrNum]!.integerValue!);
    }
    // Read it from the document name.
    final [_, _, prNum, _, _] = p.posix.basename(name!).split('_');
    return int.parse(prNum);
  }

  /// Which commit this stage is recorded for.
  int get checkRunId {
    if (fields[fieldCheckRunId] != null) {
      return int.parse(fields[fieldCheckRunId]!.integerValue!);
    }
    // Read it from the document name.
    final [_, _, _, checkRunId, _] = p.posix.basename(name!).split('_');
    return int.parse(checkRunId);
  }

  /// The stage of the CI process.
  CiStage get stage {
    if (fields[fieldStage] != null) {
      return CiStage.values.firstWhere(
        (e) => e.name == fields[fieldStage]!.stringValue!,
      );
    }
    // Read it from the document name.
    final [_, _, _, _, stageName] = p.posix.basename(name!).split('_');
    return CiStage.values.firstWhere((e) => e.name == stageName);
  }

  List<String> get failedJobNames => [
    for (final MapEntry(:key, :value) in jobs.entries)
      if (value.isFailure) key,
  ];

  set remainingJobs(int remainingJobs) {
    fields[fieldRemainingJobs] = remainingJobs.toValue();
  }

  set failedJobs(int failedJobs) {
    fields[fieldFailedJobs] = failedJobs.toValue();
  }

  set jobs(Map<String, TaskStatus> jobs) {
    fields[fieldJobs] = Value(
      mapValue: MapValue(
        fields: jobs.map((k, v) => MapEntry(k, v.value.toValue())),
      ),
    );
  }
}
