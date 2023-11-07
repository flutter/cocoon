// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';

import '../model/task.pb.dart';

/// [Task.stageName] that maps to StageName enums.
// TODO(chillers): Remove these and use StageName enum when available. https://github.com/flutter/cocoon/issues/441
class StageName {
  static const String cocoon = 'cocoon';
  static const String dartInternal = 'dart-internal';
}

/// Base URLs for various endpoints that can relate to a [Task].
const String _luciUrl = 'https://ci.chromium.org/p/flutter';
const String _dartInternalUrl = 'https://ci.chromium.org/p/dart-internal';

@immutable
class QualifiedTask {
  const QualifiedTask({this.stage, this.task, this.pool});

  QualifiedTask.fromTask(Task task)
      : stage = task.stageName,
        task = task.name,
        pool = task.isFlaky ? 'luci.flutter.staging' : 'luci.flutter.prod';

  final String? pool;
  final String? stage;
  final String? task;

  /// Get the URL for the configuration of this task.
  ///
  /// Luci tasks are stored on Luci.
  String get sourceConfigurationUrl {
    assert(isLuci || isDartInternal);
    if (isLuci) {
      return '$_luciUrl/builders/$pool/$task';
    } else if (isDartInternal) {
      return '$_dartInternalUrl/builders/$pool/$task';
    }
    throw Exception('Failed to get source configuration url for $stage.');
  }

  /// Whether the task was run on the LUCI infrastructure.
  bool get isLuci => stage == StageName.cocoon;

  /// Whether this task was run on internal infrastructure (example: luci dart-internal).
  bool get isDartInternal => stage == StageName.dartInternal;

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType) {
      return false;
    }

    if (isLuci) {
      return other is QualifiedTask && other.task == task;
    }

    return other is QualifiedTask && other.stage == stage && other.task == task;
  }

  @override
  int get hashCode {
    // Ensure tasks from Cocoon or LUCI share the same columns.
    if (isLuci) {
      return StageName.cocoon.hashCode ^ task.hashCode;
    }

    return stage.hashCode ^ task.hashCode;
  }
}
