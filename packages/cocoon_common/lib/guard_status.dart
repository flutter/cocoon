// Copyright 2026 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// Represents different states of a presubmit guard.
library;

import 'package:json_annotation/json_annotation.dart';

@JsonEnum(valueField: 'value')
enum GuardStatus {
  /// The guard is waiting for backfill.
  waitingForBackfill('New'),

  /// The guard is in progress.
  inProgress('In Progress'),

  /// The guard has failed.
  failed('Failed'),

  /// The guard ran successfully.
  succeeded('Succeeded');

  const GuardStatus(this.value);
  final String value;

  /// Returns the JSON representation of `this`.
  Object? toJson() => value;
}
