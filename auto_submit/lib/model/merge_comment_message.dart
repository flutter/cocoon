// Copyright 2023 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'package:github/github.dart';
import 'package:json_annotation/json_annotation.dart';

part 'merge_comment_message.g.dart';

/// This class is a data holder for the important parts of the issue_comment
/// request event payload that is sent by github. Each data member here holds a
/// part of the request that we need for validation.
@JsonSerializable()
class MergeCommentMessage {
  const MergeCommentMessage({
    this.issue,
    this.comment,
    this.repository,
  });

  // Issue represents the pull request issue.
  final Issue? issue;
  // IssueComment is the comment we want from the issue.
  final IssueComment? comment;
  // Repository is present if the comment was done on a pull request which is
  // what we want.
  final Repository? repository;

  @override
  String toString() => jsonEncode(toJson());

  factory MergeCommentMessage.fromJson(Map<String, dynamic> json) => _$MergeCommentMessageFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$MergeCommentMessageToJson(this);
}
