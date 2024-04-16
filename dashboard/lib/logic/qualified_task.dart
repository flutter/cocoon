// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';

import '../model/task_firestore.pb.dart';

class StageName {
  static const String luci = 'luci';
  static const String dartInternal = 'dart-internal';
}

const Set<String> dartInternalTasks = <String>{
  'Linux engine_release_builder',
  'Linux flutter_release',
  'Linux flutter_release_builder',
  'Linux packaging_release_builder',
  'Mac engine_release_builder',
  'Mac packaging_release_builder',
  'Windows engine_release_builder',
  'Windows packaging_release_builder',
};

/// Base URLs for various endpoints that can relate to a [Task].
const String _luciUrl = 'https://ci.chromium.org/p/flutter';
const String _dartInternalUrl = 'https://ci.chromium.org/p/dart-internal';

@immutable
class QualifiedTask {
  const QualifiedTask({this.task, this.pool});

  QualifiedTask.fromTask(TaskDocument task)
      : task = task.taskName,
        pool = task.bringup ? 'luci.flutter.staging' : 'luci.flutter.prod';

  final String? pool;
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
    throw Exception('Failed to get source configuration url for $task.');
  }

  /// Whether the task was run on the LUCI infrastructure.
  bool get isLuci => !dartInternalTasks.contains(task);

  /// Whether this task was run on internal infrastructure (example: luci dart-internal).
  bool get isDartInternal => dartInternalTasks.contains(task);

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType) {
      return false;
    }

    if (isLuci) {
      return other is QualifiedTask && other.task == task;
    }

    return other is QualifiedTask && other.isDartInternal && isDartInternal && other.task == task;
  }

  @override
  int get hashCode {
    // Ensure tasks from Cocoon or LUCI share the same columns.
    if (isLuci) {
      return StageName.luci.hashCode ^ task.hashCode;
    }

    return StageName.dartInternal.hashCode ^ task.hashCode;
  }
}
