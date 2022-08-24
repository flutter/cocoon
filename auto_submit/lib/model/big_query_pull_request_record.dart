// Copyright 2022 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

class PullRequestRecord {

  PullRequestRecord({
    this.prCreatedTimestamp,
    this.prLandedTimestamp,
    this.organization,
    this.repository,
    this.author,
    this.prId,
    this.prCommit,
    this.prRequestType,
  });

  int? prCreatedTimestamp;
  int? prLandedTimestamp;
  String? organization;
  String? repository;
  String? author;
  int? prId;
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
  "prId": $prId,
  "prCommit": "$prCommit",
  "prRequestType": "$prRequestType"
}
""";
  }

  static PullRequestRecord fromJson(Map<String, dynamic> json) {
    return PullRequestRecord(
      prCreatedTimestamp: json['prCreatedTimestamp'] as int,
      prLandedTimestamp: json['prLandedTimestamp'] as int,
      organization: json['organization'] as String,
      repository: json['repository'] as String,
      author: json['author'] as String,
      prId: json['prId'] as int,
      prCommit: json['prCommit'] as String,
      prRequestType: json['prRequestType'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'prCreatedTimestamp': prCreatedTimestamp,
      'prLandedTimestamp': prLandedTimestamp,
      'organization': organization,
      'repository': repository,
      'author': author,
      'prId': prId,
      'prCommit': prCommit,
      'prRequestType': prRequestType,
    };
  }
}