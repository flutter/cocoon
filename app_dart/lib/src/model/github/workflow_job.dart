// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:github/github.dart' show Repository, User;
import 'package:json_annotation/json_annotation.dart';

part 'workflow_job.g.dart';

/// Data models for json messages coming from GitHub Workflow Jobs API.
///
/// See more:
///  * https://docs.github.com/en/webhooks/webhook-events-and-payloads#workflow_job.
@JsonSerializable(fieldRename: FieldRename.snake)
class WorkflowJobEvent {
  WorkflowJobEvent({
    this.workflowJob,
    this.action,
    this.sender,
    this.repository,
  });

  factory WorkflowJobEvent.fromJson(Map<String, Object?> input) =>
      _$WorkflowJobEventFromJson(input);

  WorkflowJob? workflowJob;

  /// The action for this webhook_job event; either completed or in_progress.
  String? action;
  User? sender;
  Repository? repository;

  Map<String, Object?> toJson() => _$WorkflowJobEventToJson(this);

  @override
  String toString() {
    return '$WorkflowJobEvent ${const JsonEncoder.withIndent('  ').convert(toJson())}';
  }
}

@JsonSerializable(fieldRename: FieldRename.snake)
class WorkflowJob {
  const WorkflowJob({
    this.id,
    this.runId,
    this.workflowName,
    this.headBranch,
    this.runUrl,
    this.runAttempt,
    this.nodeId,
    this.headSha,
    this.url,
    this.status,
    this.conclusion,
    this.name,
    this.checkRunUrl,
    this.steps,
  });

  factory WorkflowJob.fromJson(Map<String, Object?> input) =>
      _$WorkflowJobFromJson(input);
  final int? id;
  final int? runId;
  final String? workflowName;
  final String? headBranch;
  final String? runUrl;
  final int? runAttempt;
  final String? nodeId;
  final String? headSha;
  final String? url;
  final String? status;
  final String? conclusion;
  final String? name;
  final String? checkRunUrl;

  @JsonKey(name: 'steps', defaultValue: <Steps>[])
  final List<Steps>? steps;

  Map<String, Object?> toJson() => _$WorkflowJobToJson(this);

  @override
  String toString() {
    return '$WorkflowJob ${const JsonEncoder.withIndent('  ').convert(toJson())}';
  }
}

@JsonSerializable(fieldRename: FieldRename.snake)
class Steps {
  const Steps({this.name, this.status, this.conclusion, this.number});

  factory Steps.fromJson(Map<String, Object?> input) => _$StepsFromJson(input);

  final String? name;
  final String? status;
  final String? conclusion;
  final int? number;

  Map<String, Object?> toJson() => _$StepsToJson(this);

  @override
  String toString() {
    return '$Steps ${const JsonEncoder.withIndent('  ').convert(toJson())}';
  }
}
