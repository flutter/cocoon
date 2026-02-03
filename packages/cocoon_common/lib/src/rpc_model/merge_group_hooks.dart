// Copyright 2024 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:json_annotation/json_annotation.dart';
import 'package:meta/meta.dart';

import 'base.dart';

part 'merge_group_hooks.g.dart';

@JsonSerializable(includeIfNull: false)
@immutable
final class MergeGroupHooks extends Model {
  MergeGroupHooks({required this.hooks});

  factory MergeGroupHooks.fromJson(Map<String, dynamic> json) =>
      _$MergeGroupHooksFromJson(json);

  final List<MergeGroupHook> hooks;

  @override
  Map<String, dynamic> toJson() => _$MergeGroupHooksToJson(this);
}

@JsonSerializable(includeIfNull: false, fieldRename: FieldRename.snake)
@immutable
final class MergeGroupHook extends Model {
  MergeGroupHook({
    required this.id,
    required this.timestamp,
    required this.action,
    required this.headRef,
    required this.headCommitId,
    required this.headCommitMessage,
  });

  factory MergeGroupHook.fromJson(Map<String, dynamic> json) =>
      _$MergeGroupHookFromJson(json);

  final String id;
  final int timestamp;
  final String action;
  final String? headRef;
  final String? headCommitId;
  final String? headCommitMessage;

  @override
  Map<String, dynamic> toJson() => _$MergeGroupHookToJson(this);
}
