// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:json_annotation/json_annotation.dart';

part 'manifest.g.dart';

@JsonSerializable(anyMap: true)
class Manifest {
  const Manifest({this.tasks});

  /// Create a new [ManifestTask] object from its JSON representation.
  factory Manifest.fromJson(Map<dynamic, dynamic> json) => _$ManifestFromJson(json);

  @JsonKey()
  final Map<String, ManifestTask> tasks;

  /// Serializes this object to a JSON primitive.
  Map<String, dynamic> toJson() => _$ManifestToJson(this);
}

@JsonSerializable(anyMap: true)
class ManifestTask {
  /// Creates a new [ManifestTask] object.
  const ManifestTask({
    this.description,
    this.stage,
    this.requiredAgentCapabilities,
    this.isFlaky,
    this.timeoutInMinutes,
  });

  /// Create a new [ManifestTask] object from its JSON representation.
  factory ManifestTask.fromJson(Map<dynamic, dynamic> json) => _$ManifestTaskFromJson(json);

  @JsonKey()
  final String description;

  @JsonKey(required: true, disallowNullValue: true)
  final String stage;

  @JsonKey(name: 'required_agent_capabilities', defaultValue: <String>[])
  final List<String> requiredAgentCapabilities;

  @JsonKey(name: 'flaky', defaultValue: false)
  final bool isFlaky;

  @JsonKey(name: 'timeout_in_minutes', defaultValue: 0)
  final int timeoutInMinutes;

  /// Serializes this object to a JSON primitive.
  Map<String, dynamic> toJson() => _$ManifestTaskToJson(this);
}
