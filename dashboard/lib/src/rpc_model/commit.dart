// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:json_annotation/json_annotation.dart';
import 'package:meta/meta.dart';

import 'base.dart';

part 'commit.g.dart';

@JsonSerializable(checked: true)
@immutable
final class Commit extends Model {
  /// Creates a commit with the given properties.
  Commit({
    required this.timestamp,
    required this.sha,
    required this.author,
    required this.message,
    required this.repository,
    required this.branch,
  });

  /// Creates a commit from [json] representation.
  factory Commit.fromJson(Map<String, Object?> json) {
    try {
      return _$CommitFromJson(json);
    } on CheckedFromJsonException catch (e) {
      throw FormatException('Invalid Commit: $e', json);
    }
  }

  /// When the commit was created.
  @JsonKey(name: 'CreateTimestamp')
  final int timestamp;

  /// The commit hash.
  @JsonKey(name: 'Sha')
  final String sha;

  /// The commit author.
  @JsonKey(name: 'Author')
  final CommitAuthor author;

  /// The commit message.
  @JsonKey(name: 'Message', includeIfNull: false)
  final String message;

  /// The commit repository path.
  @JsonKey(name: 'FlutterRepositoryPath')
  final String repository;

  /// The commit branch.
  @JsonKey(name: 'Branch')
  final String branch;

  @override
  Map<String, Object?> toJson() => _$CommitToJson(this);
}

@JsonSerializable(checked: true)
@immutable
final class CommitAuthor extends Model {
  /// Creates a commit author with the given properties.
  CommitAuthor({required this.login, required this.avatarUrl});

  /// Creates a commit author from [json] representation.
  factory CommitAuthor.fromJson(Map<String, Object?> json) {
    try {
      return _$CommitAuthorFromJson(json);
    } on CheckedFromJsonException catch (e) {
      throw FormatException('Invalid CommitAuthor: $e', json);
    }
  }

  @JsonKey(name: 'Login')
  final String login;

  @JsonKey(name: 'avatar_url')
  final String avatarUrl;

  @override
  Map<String, Object?> toJson() => _$CommitAuthorToJson(this);
}
