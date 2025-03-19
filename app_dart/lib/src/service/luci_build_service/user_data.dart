// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:typed_data';

import 'package:cocoon_server/logging.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:meta/meta.dart';

part 'user_data.g.dart';

/// A base type for classes that are serialized as part of Buildbucket pubsub.
///
/// See https://chromium.googlesource.com/infra/luci/luci-go/+/main/buildbucket/proto/notification.proto#41.
@immutable
sealed class PubSubUserData {
  const PubSubUserData({required this.repoOwner, required this.repoName});

  static Map<String, Object?> _fromJsonBytes(List<int> bytes) {
    Map<String, Object?> jsonObject;
    try {
      jsonObject = json.decode(utf8.decode(bytes)) as Map<String, dynamic>;
    } on FormatException {
      // TODO(matanlurey): Remove legacy cases. https://github.com/flutter/flutter/issues/164568.
      log.warn(
        'Expected JSON encoding. See https://github.com/flutter/flutter/issues/164568.',
      );
      final encodedBytes = String.fromCharCodes(bytes);
      final base64Decoded = base64.decode(encodedBytes);
      jsonObject =
          json.decode(String.fromCharCodes(base64Decoded))
              as Map<String, dynamic>;
    }
    return jsonObject;
  }

  /// The owner of the GitHub repo, i.e. `flutter` or `matanlurey`.
  @JsonKey(name: 'repo_owner')
  final String repoOwner;

  /// The name of the GitHub repo, i.e. `flutter` or `packages`.
  @JsonKey(name: 'repo_name')
  final String repoName;

  /// Returns a JSON representation of this object.
  Map<String, Object?> toJson();

  /// Returns a byte-serialized representation of this object.
  ///
  /// The format is intended to be reinterpreted by a `*.fromBytes` method.
  @nonVirtual
  Uint8List toBytes() => utf8.encode(json.encode(toJson()));

  @override
  @nonVirtual
  String toString() {
    return '$runtimeType ${const JsonEncoder.withIndent('  ').convert(toJson())}';
  }
}

/// Represents the data passed per presubmit-build.
@JsonSerializable(includeIfNull: false, checked: true)
final class PresubmitUserData extends PubSubUserData {
  const PresubmitUserData({
    required this.checkRunId,
    required super.repoOwner,
    required super.repoName,
    required this.builderName,
    required this.commitSha,
    required this.commitBranch,
    required this.userAgent,
  });

  factory PresubmitUserData.fromJson(Map<String, Object?> object) {
    try {
      return _$PresubmitUserDataFromJson(object);
    } on CheckedFromJsonException catch (e) {
      throw FormatException(
        'Invalid UserData object: ${e.message}.\n${e.innerStack}',
        object.toString(),
      );
    }
  }

  /// Decodes [PresubmitUserData.toBytes].
  ///
  /// Throws a [FormatException] if the data is not in the expected format.
  factory PresubmitUserData.fromBytes(List<int> bytes) {
    return PresubmitUserData.fromJson(PubSubUserData._fromJsonBytes(bytes));
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

  /// Where this build originated from.
  @JsonKey(name: 'user_agent')
  final String userAgent;

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
    );
  }

  @override
  bool operator ==(Object other) {
    return other is PresubmitUserData &&
        checkRunId == other.checkRunId &&
        builderName == other.builderName &&
        commitSha == other.commitSha &&
        commitBranch == other.commitBranch &&
        repoOwner == other.repoOwner &&
        repoName == other.repoName &&
        userAgent == other.userAgent;
  }

  @override
  Map<String, Object?> toJson() => _$PresubmitUserDataToJson(this);
}

/// Represents the data passed per postsubmit-build.
@JsonSerializable(includeIfNull: false, checked: true)
final class PostsubmitUserData extends PubSubUserData {
  const PostsubmitUserData({
    required this.checkRunId,
    required super.repoName,
    required super.repoOwner,
    required this.taskKey,
    required this.commitKey,
    required this.firestoreTaskDocumentName,
  });

  factory PostsubmitUserData.fromJson(Map<String, Object?> object) {
    try {
      return _$PostsubmitUserDataFromJson(object);
    } on CheckedFromJsonException catch (e) {
      throw FormatException(
        'Invalid UserData object: ${e.message}.\n${e.innerStack}',
        object.toString(),
      );
    }
  }

  /// Decodes [PostsubmitUserData.toBytes].
  ///
  /// Throws a [FormatException] if the data is not in the expected format.
  factory PostsubmitUserData.fromBytes(List<int> bytes) {
    return PostsubmitUserData.fromJson(PubSubUserData._fromJsonBytes(bytes));
  }

  /// Which GitHub check run this build reports status to.
  ///
  /// If this postsubmit is marked bringup (`bringup: true`) there is no associated ID.
  @JsonKey(name: 'check_run_id', includeIfNull: false)
  final int? checkRunId;

  @JsonKey(name: 'task_key')
  final String taskKey;

  @JsonKey(name: 'commit_key')
  final String commitKey;

  /// The firestore task document name storing results of this build.
  @JsonKey(
    name: 'firestore_task_document_name',
    fromJson: FirestoreTaskDocumentName._parse,
    toJson: FirestoreTaskDocumentName._toJson,
  )
  final FirestoreTaskDocumentName firestoreTaskDocumentName;

  @override
  int get hashCode {
    return Object.hash(
      checkRunId,
      repoOwner,
      repoName,
      taskKey,
      commitKey,
      firestoreTaskDocumentName,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is PostsubmitUserData &&
        checkRunId == other.checkRunId &&
        repoOwner == other.repoOwner &&
        repoName == other.repoName &&
        taskKey == other.taskKey &&
        commitKey == other.commitKey &&
        firestoreTaskDocumentName == other.firestoreTaskDocumentName;
  }

  @override
  Map<String, Object?> toJson() => _$PostsubmitUserDataToJson(this);
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
      throw RangeError.value(
        currentAttempt,
        'currentAttempt',
        'Must be at least 1',
      );
    }
  }

  static FirestoreTaskDocumentName _parse(String documentName) {
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
    throw FormatException(
      'Unexpected firestore task document name',
      documentName,
    );
  }

  static String? _toJson(FirestoreTaskDocumentName? object) {
    return object?.toString();
  }

  /// Parses `{commitSha}_{taskName}_{currentAttempt}`.
  ///
  /// This is gross because the [taskName] could also include underscores.
  static final _parseDocumentName = RegExp(
    r'([^_]*)_((?:[^_]+_)*[^_]+)_([^_]*)',
  );

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
