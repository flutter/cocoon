// Copyright 2022 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:json_annotation/json_annotation.dart';

part 'big_query_revert_request_record.g.dart';

@JsonSerializable()
class RevertRequestRecord {
  RevertRequestRecord({
    this.organization,
    this.repository,
    this.revertingPrAuthor,
    this.revertingPrNumber,
    this.revertingPrCommit,
    this.revertingPrUrl,
    this.revertingPrCreatedTimestamp,
    this.revertingPrLandedTimestamp,
    this.originalPrAuthor,
    this.originalPrNumber,
    this.originalPrCommit,
    this.originalPrUrl,
    this.originalPrCreatedTimestamp,
    this.originalPrLandedTimestamp,
  });

  String? organization;
  String? repository;

  String? revertingPrAuthor;
  int? revertingPrNumber;
  String? revertingPrCommit;
  String? revertingPrUrl;
  DateTime? revertingPrCreatedTimestamp;
  DateTime? revertingPrLandedTimestamp;

  String? originalPrAuthor;
  int? originalPrNumber;
  String? originalPrCommit;
  String? originalPrUrl;
  DateTime? originalPrCreatedTimestamp;
  DateTime? originalPrLandedTimestamp;

  @override
  String toString() => jsonEncode(toJson());

  factory RevertRequestRecord.fromJson(Map<String, dynamic> json) => _$RevertRequestRecordFromJson(json);

  Map<String, dynamic> toJson() => _$RevertRequestRecordToJson(this);
}
