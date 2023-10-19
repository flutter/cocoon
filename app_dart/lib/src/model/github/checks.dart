// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// Data models for json messages coming from GitHub Checks API.
///
/// See more:
///  * https://developer.com/v3/checks/.
library;

import 'package:github/github.dart' show CheckSuite, PullRequest, User, Repository;
import 'package:github/hooks.dart' show HookEvent;
import 'package:json_annotation/json_annotation.dart';

part 'checks.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class CheckRunEvent extends HookEvent {
  CheckRunEvent({
    this.action,
    this.checkRun,
    this.sender,
    this.repository,
  });

  factory CheckRunEvent.fromJson(Map<String, dynamic> input) => _$CheckRunEventFromJson(input);
  CheckRun? checkRun;
  String? action;
  User? sender;
  Repository? repository;

  Map<String, dynamic> toJson() => _$CheckRunEventToJson(this);
}

@JsonSerializable(fieldRename: FieldRename.snake)
class CheckRun {
  const CheckRun({
    this.conclusion,
    this.headSha,
    this.id,
    this.pullRequests,
    this.name,
    this.checkSuite,
  });

  factory CheckRun.fromJson(Map<String, dynamic> input) => _$CheckRunFromJson(input);
  final int? id;
  final String? headSha;
  final String? conclusion;
  final String? name;
  final CheckSuite? checkSuite;
  @JsonKey(name: 'pull_requests', defaultValue: <PullRequest>[])
  final List<PullRequest>? pullRequests;

  Map<String, dynamic> toJson() => _$CheckRunToJson(this);
}
