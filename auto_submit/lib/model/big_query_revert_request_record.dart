// Copyright 2022 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

class RevertRequestRecord {
  RevertRequestRecord({
    this.organization,
    this.repository,
    this.revertingPrAuthor,
    this.revertingPrId,
    this.revertingPrCommit,
    this.revertingPrUrl,
    this.revertingPrCreatedTimestamp,
    this.revertingPrLandedTimestamp,
    this.originalPrAuthor,
    this.originalPrId,
    this.originalPrCommit,
    this.originalPrUrl,
    this.originalPrCreatedTimestamp,
    this.originalPrLandedTimestamp,
  });

  String? organization;
  String? repository;

  String? revertingPrAuthor;
  int? revertingPrId;
  String? revertingPrCommit;
  String? revertingPrUrl;
  int? revertingPrCreatedTimestamp;
  int? revertingPrLandedTimestamp;

  String? originalPrAuthor;
  int? originalPrId;
  String? originalPrCommit;
  String? originalPrUrl;
  int? originalPrCreatedTimestamp;
  int? originalPrLandedTimestamp;

  @override
  String toString() {
    return """
{
  "organization": "$organization",
  "repository": "$repository",
  "revertingPrAuthor": "$revertingPrAuthor",
  "revertingPrId": $revertingPrId,
  "revertingPrCommit": "$revertingPrCommit",
  "revertingPrUrl": "$revertingPrUrl",
  "revertingPrCreatedTimestamp": $revertingPrCreatedTimestamp,
  "revertingPrLandedTimestamp": $revertingPrLandedTimestamp,
  "originalPrAuthor": "$originalPrAuthor",
  "originalPrId": $originalPrId,
  "originalPrCommit": "$originalPrCommit",
  "originalPrUrl": "$originalPrUrl",
  "originalPrCreatedTimestamp": $originalPrCreatedTimestamp,
  "originalPrLandedTimestamp": $originalPrLandedTimestamp
}""";
  }

  static RevertRequestRecord fromJson(Map<String, dynamic> json) {
    return RevertRequestRecord(
      organization: json['organization'] as String,
      repository: json['repository'] as String,
      revertingPrAuthor: json['revertingPrAuthor'] as String,
      revertingPrId: json['revertingPrId'] as int,
      revertingPrCommit: json['revertingPrCommit'] as String,
      revertingPrUrl: json['revertingPrUrl'] as String,
      revertingPrCreatedTimestamp: json['revertingPrCreatedTimestamp'] as int,
      revertingPrLandedTimestamp: json['revertingPrLandedTimestamp'] as int,
      originalPrAuthor: json['originalPrAuthor'] as String,
      originalPrId: json['originalPrId'] as int,
      originalPrCommit: json['originalPrCommit'] as String,
      originalPrUrl: json['originalPrUrl'] as String,
      originalPrCreatedTimestamp: json['originalPrCreatedTimestamp'] as int,
      originalPrLandedTimestamp: json['originalPrLandedTimestamp'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'orgianization': organization,
      'repository': repository,
      'revertingPrAuthor': revertingPrAuthor,
      'revertingPrId': revertingPrId,
      'revertingPrCommit': revertingPrCommit,
      'revertingPrUrl': revertingPrUrl,
      'revertingPrCreatedTimestamp': revertingPrCreatedTimestamp,
      'revertingPrLandedTimestamp': revertingPrLandedTimestamp,
      'originalPrAuthor': originalPrAuthor,
      'originalPrId': originalPrId,
      'originalPrCommit': originalPrCommit,
      'originalPrUrl': originalPrUrl,
      'originalPrCreatedTimestamp': originalPrCreatedTimestamp,
      'originalPrLandedTimestamp': originalPrLandedTimestamp,
    };
  }
}