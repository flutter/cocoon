// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:typed_data';

import 'package:cocoon_server/logging.dart';
import 'package:collection/collection.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:meta/meta.dart';

import 'firestore_task_document_name.dart';

part 'user_data.g.dart';

/// A base type for classes that are serialized as part of Buildbucket pubsub.
///
/// See https://chromium.googlesource.com/infra/luci/luci-go/+/main/buildbucket/proto/notification.proto#41.
@immutable
sealed class BuildBucketUserData {
  const BuildBucketUserData();

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
      final decodedJson = json.decode(String.fromCharCodes(base64Decoded));
      jsonObject = decodedJson as Map<String, Object?>;
    }
    return jsonObject;
  }

  static const _deepEq = DeepCollectionEquality();

  @override
  @nonVirtual
  bool operator ==(Object other) {
    if (runtimeType != other.runtimeType || other is! BuildBucketUserData) {
      return false;
    }
    return _deepEq.equals(toJson(), other.toJson());
  }

  @override
  @nonVirtual
  int get hashCode => _deepEq.hash(toJson());

  /// Returns a JSON object representation of this object.
  Map<String, Object?> toJson();

  /// Returns a byte-serialzied representation of this object.
  ///
  /// This format can be reinterpreted by a `*.fromBytes` constructor.
  @nonVirtual
  Uint8List toBytes() => utf8.encode(json.encode(toJson()));

  @override
  @nonVirtual
  String toString() {
    return '$runtimeType ${const JsonEncoder.withIndent('  ').convert(toJson())}';
  }
}

/// Represents the data passed to Buildbucket as part of a presubmit build.
@JsonSerializable(checked: true)
final class PresubmitUserData extends BuildBucketUserData {
  PresubmitUserData({
    required this.repoOwner,
    required this.repoName,
    required this.commitBranch,
    required this.commitSha,
    required this.checkRunId,
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
    return PresubmitUserData.fromJson(
      BuildBucketUserData._fromJsonBytes(bytes),
    );
  }

  /// The owner of the GitHub repo, i.e. `flutter` or `matanlurey`.
  @JsonKey(name: 'repo_owner')
  final String repoOwner;

  /// The name of the GitHub repo, i.e. `flutter` or `packages`.
  @JsonKey(name: 'repo_name')
  final String repoName;

  /// The branch the [commitSha] is on.
  @JsonKey(name: 'commit_branch')
  final String commitBranch;

  /// The commit SHA being built at.
  @JsonKey(name: 'commit_sha')
  final String commitSha;

  /// Which GitHub check run this build reports status to.
  @JsonKey(name: 'check_run_id')
  final int checkRunId;

  @override
  Map<String, Object?> toJson() => _$PresubmitUserDataToJson(this);
}

/// Represents the data passed to Buildbucket as part of a postsubmit build.
@JsonSerializable(checked: true, includeIfNull: false)
final class PostsubmitUserData extends BuildBucketUserData {
  PostsubmitUserData({
    required this.checkRunId,
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
    return PostsubmitUserData.fromJson(
      BuildBucketUserData._fromJsonBytes(bytes),
    );
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
    fromJson: FirestoreTaskDocumentName.parse,
    toJson: _documentToString,
  )
  final FirestoreTaskDocumentName firestoreTaskDocumentName;
  static String _documentToString(FirestoreTaskDocumentName firestoreTask) {
    return firestoreTask.documentName;
  }

  @override
  Map<String, Object?> toJson() => _$PostsubmitUserDataToJson(this);
}
