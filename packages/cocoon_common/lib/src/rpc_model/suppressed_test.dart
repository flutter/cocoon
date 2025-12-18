// Copyright 2025 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:json_annotation/json_annotation.dart';
import 'package:meta/meta.dart';

import 'base.dart';

part 'suppressed_test.g.dart';

/// A test that is currently suppressed in the build system.
@JsonSerializable(checked: true)
@immutable
final class SuppressedTest extends Model {
  /// Creates a suppressed test entry.
  SuppressedTest({
    required this.name,
    required this.repository,
    required this.issueLink,
    required this.createTimestamp,
    this.updates = const [],
  });

  /// Creates a [SuppressedTest] from [json] representation.
  factory SuppressedTest.fromJson(Map<String, Object?> json) {
    try {
      return _$SuppressedTestFromJson(json);
    } on CheckedFromJsonException catch (e) {
      throw FormatException('Invalid SuppressedTest: $e', json);
    }
  }

  /// The name of the test, e.g. "linux_android".
  @JsonKey(name: 'name')
  final String name;

  /// The repository slug, e.g. "flutter/flutter".
  @JsonKey(name: 'repository')
  final String repository;

  /// The GitHub issue link tracking this suppression.
  @JsonKey(name: 'issueLink')
  final String issueLink;

  /// When the suppression was created (in milliseconds since epoch).
  @JsonKey(name: 'createTimestamp')
  final int createTimestamp;

  /// List of updates (audit log).
  @JsonKey(name: 'updates', defaultValue: [])
  final List<SuppressionUpdate> updates;

  @override
  Map<String, Object?> toJson() => _$SuppressedTestToJson(this);
}

/// An update event for a suppressed test.
@JsonSerializable(checked: true)
@immutable
final class SuppressionUpdate {
  /// Creates a suppression update.
  const SuppressionUpdate({
    required this.user,
    required this.action,
    required this.updateTimestamp,
    this.note,
  });

  /// Creates a [SuppressionUpdate] from [json] representation.
  factory SuppressionUpdate.fromJson(Map<String, Object?> json) {
    try {
      return _$SuppressionUpdateFromJson(json);
    } on CheckedFromJsonException catch (e) {
      throw FormatException('Invalid SuppressionUpdate: $e', json);
    }
  }

  /// The user who performed the action (email or username).
  @JsonKey(name: 'user')
  final String user;

  /// The action performed (SUPPRESS, UNSUPPRESS).
  @JsonKey(name: 'action')
  final String action;

  /// When the update occurred (in milliseconds since epoch).
  @JsonKey(name: 'updateTimestamp')
  final int updateTimestamp;

  /// Optional note explaining the action.
  @JsonKey(name: 'note')
  final String? note;

  /// Converts this object to a JSON map.
  Map<String, Object?> toJson() => _$SuppressionUpdateToJson(this);
}
