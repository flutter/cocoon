// Copyright 2022 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:json_annotation/json_annotation.dart';

part 'big_query_pull_request_record.g.dart';

@JsonSerializable()
class PullRequestRecord {
  PullRequestRecord({
    this.prCreatedTimestamp,
    this.prLandedTimestamp,
    this.organization,
    this.repository,
    this.author,
    this.prNumber,
    this.prCommit,
    this.prRequestType,
  });

  int? prCreatedTimestamp;
  int? prLandedTimestamp;
  String? organization;
  String? repository;
  String? author;
  int? prNumber;
  String? prCommit;
  String? prRequestType;

  @override
  String toString() {
    return """
{
  "prCreatedTimestamp": $prCreatedTimestamp,
  "prLandedTimestamp": $prLandedTimestamp,
  "organization": "$organization",
  "repository": "$repository",
  "author": "$author",
  "prNumber": $prNumber,
  "prCommit": "$prCommit",
  "prRequestType": "$prRequestType"
}
""";
  }

  factory PullRequestRecord.fromJson(Map<String, dynamic> json) => _$PullRequestRecordFromJson(json);

  Map<String, dynamic> toJson() => _$PullRequestRecordToJson(this);
}
