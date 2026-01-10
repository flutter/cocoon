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
import '../../service/firestore.dart';
import 'base.dart';

final class PresubmitGuardId extends AppDocumentId<PresubmitGuard> {
  PresubmitGuardId({
    required this.slug,
    required this.pullRequestId,
    required this.checkRunId,
    required this.stage,
  });

  /// The repository owner/name.
  final RepositorySlug slug;

  /// The pull request id.
  final int pullRequestId;

  /// The Check Run Id.
  final int checkRunId;

  /// The stage of the CI process.
  final CiStage stage;

  @override
  String get documentId =>
      [slug.owner, slug.name, pullRequestId, checkRunId, stage].join('_');

  @override
  AppDocumentMetadata<PresubmitGuard> get runtimeMetadata =>
      PresubmitGuard.metadata;
}

final class PresubmitGuard extends AppDocument<PresubmitGuard> {
  static const collectionId = 'presubmit_guards';
  static const fieldCheckRun = 'check_run';
  static const fieldCommitSha = 'commit_sha';
  static const fieldAuthor = 'author';
  static const fieldCreationTime = 'creation_time';
  static const fieldRemainingBuilds = 'remaining_builds';
  static const fieldFailedBuilds = 'failed_builds';
  static const fieldBuilds = 'builds';

  static AppDocumentId<PresubmitGuard> documentIdFor({
    required RepositorySlug slug,
    required int pullRequestId,
    required int checkRunId,
    required CiStage stage,
  }) => PresubmitGuardId(
    slug: slug,
    pullRequestId: pullRequestId,
    checkRunId: checkRunId,
    stage: stage,
  );

  /// Returns a firebase documentName used in [fromFirestore].
  static String documentNameFor({
    required RepositorySlug slug,
    required int pullRequestId,
    required int checkRunId,
    required CiStage stage,
  }) {
    // Document names cannot cannot have '/' in the document id.
    final docId = documentIdFor(
      slug: slug,
      pullRequestId: pullRequestId,
      checkRunId: checkRunId,
      stage: stage,
    );
    return '$kDocumentParent/$collectionId/${docId.documentId}';
  }

  /// Returns the document ID for the given parameters.
  // static String documentId({
  //   required RepositorySlug slug,
  //   required int pullRequestId,
  //   required int checkRunId,
  //   required CiStage stage,
  // }) =>
  //     '${slug.owner}_${slug.name}_${pullRequestId}_${checkRunId}_${stage.name}';

  @override
  AppDocumentMetadata<PresubmitGuard> get runtimeMetadata => metadata;

  static final metadata = AppDocumentMetadata<PresubmitGuard>(
    collectionId: collectionId,
    fromDocument: PresubmitGuard.fromDocument,
  );

  factory PresubmitGuard.init({
    required RepositorySlug slug,
    required int pullRequestId,
    required CheckRun checkRun,
    required CiStage stage,
    required String commitSha,
    required int creationTime,
    required String author,
    required int buildCount,
  }) {
    return PresubmitGuard(
      checkRun: checkRun,
      commitSha: commitSha,
      slug: slug,
      pullRequestId: pullRequestId,
      stage: stage,
      author: author,
      creationTime: creationTime,
      remainingBuilds: buildCount,
      failedBuilds: 0,
    );
  }

  factory PresubmitGuard.fromDocument(Document document) {
    return PresubmitGuard._(document.fields!, name: document.name!);
  }

  factory PresubmitGuard({
    required CheckRun checkRun,
    required String commitSha,
    required RepositorySlug slug,
    required int pullRequestId,
    required CiStage stage,
    required int creationTime,
    required String author,
    int? remainingBuilds,
    int? failedBuilds,
    Map<String, TaskStatus>? builds,
  }) {
    return PresubmitGuard._(
      {
        fieldCommitSha: commitSha.toValue(),
        fieldCreationTime: creationTime.toValue(),
        fieldAuthor: author.toValue(),
        fieldCheckRun: json.encode(checkRun.toJson()).toValue(),
        fieldRemainingBuilds: ?remainingBuilds?.toValue(),
        fieldFailedBuilds: ?failedBuilds?.toValue(),
        if (builds != null)
          fieldBuilds: Value(
            mapValue: MapValue(
              fields: builds.map((k, v) => MapEntry(k, v.value.toValue())),
            ),
          ),
      },
      name: documentNameFor(
        slug: slug,
        pullRequestId: pullRequestId,
        checkRunId: checkRun.id!,
        stage: stage,
      ),
    );
  }

  PresubmitGuard._(Map<String, Value> fields, {required String name}) {
    this.fields = fields;
    this.name = name;
  }

  String get commitSha => fields[fieldCommitSha]!.stringValue!;
  String get author => fields[fieldAuthor]!.stringValue!;
  int get creationTime => int.parse(fields[fieldCreationTime]!.integerValue!);
  int? get remainingBuilds => fields[fieldRemainingBuilds] != null
      ? int.parse(fields[fieldRemainingBuilds]!.integerValue!)
      : null;
  int? get failedBuilds => fields[fieldFailedBuilds] != null
      ? int.parse(fields[fieldFailedBuilds]!.integerValue!)
      : null;
  Map<String, TaskStatus>? get builds =>
      fields[fieldBuilds]?.mapValue?.fields?.map<String, TaskStatus>(
        (k, v) => MapEntry(k, TaskStatus.from(v.stringValue!)),
      );
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
    // Read it from the document name.
    final [owner, repo, _, _, _] = p.posix.basename(name!).split('_');
    return RepositorySlug(owner, repo);
  }

  /// The pull request for which this stage is recorded for.
  int get pullRequestId {
    // Read it from the document name.
    final [_, _, pullRequestId, _, _] = p.posix.basename(name!).split('_');
    return int.parse(pullRequestId);
  }

  /// Which commit this stage is recorded for.
  int get checkRunId {
    // Read it from the document name.
    final [_, _, _, checkRunId, _] = p.posix.basename(name!).split('_');
    return int.parse(checkRunId);
  }

  /// The stage of the CI process.
  CiStage get stage {
    // Read it from the document name.
    final [_, _, _, _, stageName] = p.posix.basename(name!).split('_');
    return CiStage.values.firstWhere((e) => e.name == stageName);
  }

  set remainingBuilds(int remainingBuilds) {
    fields[fieldRemainingBuilds] = remainingBuilds.toValue();
  }

  set failedBuilds(int failedBuilds) {
    fields[fieldFailedBuilds] = failedBuilds.toValue();
  }

  set builds(Map<String, TaskStatus> builds) {
    fields[fieldBuilds] = Value(
      mapValue: MapValue(
        fields: builds.map((k, v) => MapEntry(k, v.value.toValue())),
      ),
    );
  }
}
