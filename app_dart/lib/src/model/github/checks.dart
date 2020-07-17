// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// Data models to serialize/deserialize json messages coming from github
/// checks api. For more information please read:
///   https://developer.github.com/v3/checks/.

import 'package:github/github.dart' hide CheckSuite, CheckRun;
import 'package:github/hooks.dart';
import 'package:json_annotation/json_annotation.dart';

part 'checks.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class CheckSuiteEvent extends HookEvent {
  CheckSuiteEvent({
    this.action,
    this.checkSuite,
    this.sender,
    this.repository,
  });

  factory CheckSuiteEvent.fromJson(Map<String, dynamic> input) => _$CheckSuiteEventFromJson(input);
  CheckSuite checkSuite;
  String action;
  User sender;
  Repository repository;

  Map<String, dynamic> toJson() => _$CheckSuiteEventToJson(this);
}

@JsonSerializable(fieldRename: FieldRename.snake)
class CheckSuite {
  const CheckSuite({
    this.conclusion,
    this.headSha,
    this.id,
    this.pullRequests,
    this.headBranch,
  });

  factory CheckSuite.fromJson(Map<String, dynamic> input) => _$CheckSuiteFromJson(input);
  final int id;
  final String headSha;
  final String conclusion;
  final String headBranch;
  @JsonKey(name: 'pull_requests', defaultValue: <PullRequest>[])
  final List<PullRequest> pullRequests;

  Map<String, dynamic> toJson() => _$CheckSuiteToJson(this);
}

@JsonSerializable(fieldRename: FieldRename.snake)
class CheckRunEvent extends HookEvent {
  CheckRunEvent({
    this.action,
    this.checkRun,
    this.sender,
    this.repository,
  });

  factory CheckRunEvent.fromJson(Map<String, dynamic> input) => _$CheckRunEventFromJson(input);
  CheckRun checkRun;
  String action;
  User sender;
  Repository repository;

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
  final int id;
  final String headSha;
  final String conclusion;
  final String name;
  final CheckSuite checkSuite;
  @JsonKey(name: 'pull_requests', defaultValue: <PullRequest>[])
  final List<PullRequest> pullRequests;

  Map<String, dynamic> toJson() => _$CheckRunToJson(this);
}
