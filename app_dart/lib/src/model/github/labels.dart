// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:json_annotation/json_annotation.dart';

part 'labels.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class LabeledEvent {
  LabeledEvent({required this.label});
  factory LabeledEvent.fromJson(Map<String, Object?> input) =>
      _$LabeledEventFromJson(input);

  final Label label;

  Map<String, Object?> toJson() => _$LabeledEventToJson(this);

  @override
  String toString() {
    return '$LabeledEvent ${const JsonEncoder.withIndent('  ').convert(toJson())}';
  }
}

@JsonSerializable(fieldRename: FieldRename.snake)
class Label {
  Label({
    required this.id,
    required this.name,
    required this.nodeId,
    required this.url,
    required this.color,
    required this.description,
  });
  factory Label.fromJson(Map<String, Object?> input) => _$LabelFromJson(input);

  /// id: 4232992339
  final int id;

  /// name: autosubmit
  final String name;

  /// node_id: LA_kwDOAeUeuM78TlZT
  final String nodeId;

  /// url: https://api.github.com/repos/flutter/flutter/labels/autosubmit
  final Uri url;

  /// color: 008820
  final String color;

  // description: Merge PR when tree becomes green via auto submit App
  final String description;

  Map<String, Object?> toJson() => _$LabelToJson(this);

  @override
  String toString() {
    return '$Label ${const JsonEncoder.withIndent('  ').convert(toJson())}';
  }
}
