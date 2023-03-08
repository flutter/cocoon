// Copyright 2023 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'package:github/github.dart';
import 'package:json_annotation/json_annotation.dart';

part 'merge_comment_message.g.dart';

@JsonSerializable()
class MergeCommentMessage {
  const MergeCommentMessage({
    this.issue,
    this.comment,
    this.repository,
  });

  final Issue? issue;
  final IssueComment? comment;
  final Repository? repository;

  @override
  String toString() => jsonEncode(toJson());

  factory MergeCommentMessage.fromJson(Map<String, dynamic> json) => _$MergeCommentMessageFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$MergeCommentMessageToJson(this);
}
