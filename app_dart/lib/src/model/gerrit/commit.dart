// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:json_annotation/json_annotation.dart';

import '../../request_handling/body.dart';

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

  static GerritCommit fromJson(Map<String, dynamic> json) => _$GerritCommitFromJson(json);

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
  const GerritUser({
    this.name,
    this.email,
    this.time,
  });

  static GerritUser fromJson(Map<String, dynamic> json) => _$GerritUserFromJson(json);

  final String? name;
  final String? email;

  @JsonKey(fromJson: _dateTimeFromGerritTime)
  final DateTime? time;

  /// Gerrit uses a non ISO-8601 time format, which requires manual translation.
  ///
  /// Example: `Tue Jul 12 17:21:25 2022 +0000`
  static DateTime _dateTimeFromGerritTime(String date) {
    final List<String> parts = date.split(' ');
    final int day = int.parse(parts[2]);
    final int year = int.parse(parts[4]);
    final String monthStr = parts[1].toLowerCase();
    final Map<String, int> monthLookup = <String, int>{
      'jan': 1,
      'feb': 2,
      'mar': 3,
      'apr': 4,
      'may': 5,
      'jun': 6,
      'jul': 7,
      'aug': 8,
      'sep': 9,
      'oct': 10,
      'nov': 11,
      'dec': 12,
    };
    final int month = monthLookup[monthStr]!;
    final List<String> timeParts = parts[3].split(':');
    final int hours = int.parse(timeParts[0]);
    final int minutes = int.parse(timeParts[1]);
    final int seconds = int.parse(timeParts[2]);

    // Gerrit timezones are in +0000 which is UTC time.
    return DateTime.utc(year, month, day, hours, minutes, seconds);
  }

  @override
  Map<String, dynamic> toJson() => _$GerritUserToJson(this);

  @override
  String toString() => jsonEncode(toJson());
}
