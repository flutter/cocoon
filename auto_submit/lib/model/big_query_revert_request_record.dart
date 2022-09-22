// Copyright 2022 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:auto_submit/model/big_query_pull_request_record.dart';
import 'package:json_annotation/json_annotation.dart';

part 'big_query_revert_request_record.g.dart';

@JsonSerializable()
class RevertRequestRecord extends PullRequestRecord {
  const RevertRequestRecord({
    super.organization,
    super.repository,
    super.author,
    super.prNumber,
    super.prCommit,
    super.prCreatedTimestamp,
    super.prLandedTimestamp,
    this.originalPrAuthor,
    this.originalPrNumber,
    this.originalPrCommit,
    this.originalPrCreatedTimestamp,
    this.originalPrLandedTimestamp,
    this.reviewIssueAssignee,
    this.reviewIssueNumber,
    this.reviewIssueCreatedTimestamp,
    this.reviewIssueLandedTimestamp,
    this.reviewIssueClosedBy,
  });

  final String? originalPrAuthor;
  final int? originalPrNumber;
  final String? originalPrCommit;
  final DateTime? originalPrCreatedTimestamp;
  final DateTime? originalPrLandedTimestamp;
  final String? reviewIssueAssignee;
  final int? reviewIssueNumber;
  final DateTime? reviewIssueCreatedTimestamp;
  final DateTime? reviewIssueLandedTimestamp;
  final String? reviewIssueClosedBy;

  @override
  String toString() => jsonEncode(toJson());

  factory RevertRequestRecord.fromJson(Map<String, dynamic> json) => _$RevertRequestRecordFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$RevertRequestRecordToJson(this);
}
