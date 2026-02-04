// Copyright 2026 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:collection/collection.dart';

/// Represents different states of a presubmit guard.
enum GuardStatus {
  /// The guard is waiting for backfill.
  waitingForBackfill('New'),

  /// The guard is in progress.
  inProgress('In Progress'),

  /// The guard has failed.
  failed('Failed'),

  /// The guard ran successfully.
  succeeded('Succeeded');

  const GuardStatus(this._schemaValue);
  final String _schemaValue;

  /// Returns the status represented by the provided [value].
  factory GuardStatus.from(String value) {
    return tryFrom(value) ?? (throw ArgumentError.value(value, 'value'));
  }

  /// Returns the guard status represented by the provided [value].
  static GuardStatus? tryFrom(String value) {
    return values.firstWhereOrNull((v) => v.value == value);
  }

  /// The canonical string value representing `this`.
  String get value => _schemaValue;

  /// Returns the JSON representation of `this`.
  Object? toJson() => _schemaValue;

  @override
  String toString() => _schemaValue;
}
