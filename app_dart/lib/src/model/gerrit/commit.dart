// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:json_annotation/json_annotation.dart';

import '../../request_handling/body.dart';
import '../common/json_converters.dart';

part 'commit.g.dart';

/// Representation of a commit on Gerrit.
///
/// See more:
///   * https://gerrit-review.googlesource.com/Documentation/rest-api-changes.html#commit-info
@JsonSerializable()
class GerritCommit extends JsonBody {
  const GerritCommit({
    this.commit,
    this.tree,
    this.author,
    this.committer,
    this.message,
  });

  static GerritCommit fromJson(Map<String, dynamic> json) =>
      _$GerritCommitFromJson(json);

  final String? commit;
  final String? tree;
  final GerritUser? author;
  final GerritUser? committer;
  final String? message;

  @override
  Map<String, dynamic> toJson() => _$GerritCommitToJson(this);

  @override
  String toString() => jsonEncode(toJson());
}

/// Gerrit info containing the author/comitter of a commit.
///
/// See more:
///   * https://gerrit-review.googlesource.com/Documentation/rest-api-changes.html#git-person-info
@JsonSerializable()
class GerritUser extends JsonBody {
  const GerritUser({this.name, this.email, this.time});

  static GerritUser fromJson(Map<String, dynamic> json) =>
      _$GerritUserFromJson(json);

  final String? name;
  final String? email;

  @GerritDateTimeConverter()
  final DateTime? time;

  @override
  Map<String, dynamic> toJson() => _$GerritUserToJson(this);

  @override
  String toString() => jsonEncode(toJson());
}
