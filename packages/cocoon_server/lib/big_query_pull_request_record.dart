// Copyright 2022 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:json_annotation/json_annotation.dart';
import 'package:meta/meta.dart';

part 'big_query_pull_request_record.g.dart';

@immutable
@JsonSerializable()
class PullRequestRecord {
  const PullRequestRecord({
    this.prCreatedTimestamp,
    this.prLandedTimestamp,
    this.organization,
    this.repository,
    this.author,
    this.prNumber,
    this.prCommit,
    this.prRequestType,
  });

  final DateTime? prCreatedTimestamp;
  final DateTime? prLandedTimestamp;
  final String? organization;
  final String? repository;
  final String? author;
  final int? prNumber;
  final String? prCommit;
  final String? prRequestType;

  @override
  String toString() => jsonEncode(toJson());

  factory PullRequestRecord.fromJson(Map<String, dynamic> json) =>
      _$PullRequestRecordFromJson(json);

  Map<String, dynamic> toJson() => _$PullRequestRecordToJson(this);
}
