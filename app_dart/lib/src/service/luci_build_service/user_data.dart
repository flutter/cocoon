// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:json_annotation/json_annotation.dart';
import 'package:meta/meta.dart';

part 'user_data.g.dart';

/// Represents the data passed per-buid by Buildbucket pubsub.
///
/// See https://chromium.googlesource.com/infra/luci/luci-go/+/main/buildbucket/proto/notification.proto#41.
@JsonSerializable(includeIfNull: false, checked: true)
@immutable
final class BuildBucketPubSubUserData {
  const BuildBucketPubSubUserData({
    required this.checkRunId,
    required this.builderName,
    required this.commitSha,
    required this.commitBranch,
    required this.repoOwner,
    required this.repoName,
    required this.userAgent,
    this.firestoreTaskDocumentName,
  });

  factory BuildBucketPubSubUserData.fromJson(Map<String, Object?> object) {
    try {
      return _$BuildBucketPubSubUserDataFromJson(object);
    } on CheckedFromJsonException catch (e) {
      throw FormatException('Invalid UserData object: ${e.message}.\n${e.innerStack}', object.toString());
    }
  }

  /// Which GitHub check run this build reports status to.
  @JsonKey(name: 'check_run_id')
  final int checkRunId;

  /// The name of the builder being executed.
  @JsonKey(name: 'builder_name')
  final String builderName;

  /// The commit SHA being built at.
  @JsonKey(name: 'commit_sha')
  final String commitSha;

  /// The branch the [commitSha] is on.
  @JsonKey(name: 'commit_branch')
  final String commitBranch;

  /// The owner of the GitHub repo, i.e. `flutter` or `matanlurey`.
  @JsonKey(name: 'repo_owner')
  final String repoOwner;

  /// The name of the GitHub repo, i.e. `flutter` or `packages`.
  @JsonKey(name: 'repo_name')
  final String repoName;

  /// Where this build originated from.
  @JsonKey(name: 'user_agent')
  final String userAgent;

  /// The firestore task document name storing results of this build.
  @JsonKey(
    name: 'firestore_task_document_name',
    fromJson: FirestoreTaskDocumentName._parse,
    toJson: FirestoreTaskDocumentName._toJson,
  )
  final FirestoreTaskDocumentName? firestoreTaskDocumentName;

  @override
  int get hashCode {
    return Object.hash(
      checkRunId,
      builderName,
      commitSha,
      commitBranch,
      repoOwner,
      repoName,
      userAgent,
      firestoreTaskDocumentName,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is BuildBucketPubSubUserData &&
        checkRunId == other.checkRunId &&
        builderName == other.builderName &&
        commitSha == other.commitSha &&
        commitBranch == other.commitBranch &&
        repoOwner == other.repoOwner &&
        repoName == other.repoName &&
        userAgent == other.userAgent &&
        firestoreTaskDocumentName == other.firestoreTaskDocumentName;
  }

  /// Returns a JSON representation of this object.
  Map<String, Object?> toJson() => _$BuildBucketPubSubUserDataToJson(this);

  @override
  String toString() {
    return 'BuildBucketPubSubUserData ${const JsonEncoder.withIndent('  ').convert(toJson())}';
  }
}

/// Represents the name of a Firestore document.
@immutable
final class FirestoreTaskDocumentName {
  FirestoreTaskDocumentName({
    required this.commitSha,
    required this.taskName,
    required this.currentAttempt,
  }) {
    if (currentAttempt < 1) {
      throw RangeError.value(currentAttempt, 'currentAttempt', 'Must be at least 1');
    }
  }

  static FirestoreTaskDocumentName? _parse(String? documentName) {
    if (documentName == null) {
      return null;
    }
    if (_parseDocumentName.matchAsPrefix(documentName) case final match?) {
      final commitSha = match.group(1)!;
      final taskName = match.group(2)!;
      final currentAttempt = int.tryParse(match.group(3)!);
      if (currentAttempt != null) {
        return FirestoreTaskDocumentName(
          commitSha: commitSha,
          taskName: taskName,
          currentAttempt: currentAttempt,
        );
      }
    }
    throw FormatException('Unexpected firestore task document name', documentName);
  }

  static String? _toJson(FirestoreTaskDocumentName? object) {
    return object?.toString();
  }

  /// Parses `{commitSha}_{taskName}_{currentAttempt}`.
  ///
  /// This is gross because the [taskName] could also include underscores.
  static final _parseDocumentName = RegExp(r'([^_]*)_((?:[^_]+_)*[^_]+)_([^_]*)');

  /// The commit SHA of the code being built.
  final String commitSha;

  /// The task name (i.e. from `.ci.yaml`).
  final String taskName;

  /// Which run (or re-run) attempt, starting at 1, this is.
  final int currentAttempt;

  @override
  int get hashCode => Object.hash(commitSha, taskName, currentAttempt);

  @override
  bool operator ==(Object other) {
    return other is FirestoreTaskDocumentName &&
        commitSha == other.commitSha &&
        taskName == other.taskName &&
        currentAttempt == other.currentAttempt;
  }

  @override
  String toString() => '${commitSha}_${taskName}_$currentAttempt';
}
