// Copyright 2026 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:github/github.dart'
    show PullRequest, PullRequestReview, Repository, User;
import 'package:github/hooks.dart' show HookEvent;
import 'package:json_annotation/json_annotation.dart';

part 'pull_request_review.g.dart';

/// Data models for JSON messages coming from GitHub Pull Request Review webhooks.
///
/// See more:
///  * https://docs.github.com/en/webhooks/webhook-events-and-payloads#pull_request_review
@JsonSerializable(fieldRename: FieldRename.snake)
final class PullRequestReviewEvent extends HookEvent {
  PullRequestReviewEvent({
    this.action,
    this.review,
    this.pullRequest,
    this.repository,
    this.sender,
  });

  factory PullRequestReviewEvent.fromJson(Map<String, dynamic> input) =>
      _$PullRequestReviewEventFromJson(input);

  String? action;
  PullRequestReview? review;
  PullRequest? pullRequest;
  Repository? repository;
  User? sender;

  Map<String, dynamic> toJson() => _$PullRequestReviewEventToJson(this);

  @override
  String toString() {
    return 'PullRequestReviewEvent ${const JsonEncoder.withIndent('  ').convert(toJson())}';
  }
}
