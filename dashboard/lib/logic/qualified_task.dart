// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';

import '../model/commit.pb.dart';
import '../model/task.pb.dart';

/// [Task.stageName] that maps to StageName enums.
// TODO(chillers): Remove these and use StageName enum when available. https://github.com/flutter/cocoon/issues/441
class StageName {
  static const String cirrus = 'cirrus';
  static const String cocoon = 'cocoon';
  static const String legacyLuci = 'chromebot';
  static const String luci = 'luci';
}

/// Base URLs for various endpoints that can relate to a [Task].
const String _cirrusUrl = 'https://cirrus-ci.com/github/flutter/flutter';
const String _cirrusLogUrl = 'https://cirrus-ci.com/build/flutter/flutter';
const String _luciUrl = 'https://ci.chromium.org/p/flutter';

@immutable
class QualifiedTask {
  const QualifiedTask({this.stage, this.task, this.pool});

  QualifiedTask.fromTask(Task task)
      : stage = task.stageName,
        task = task.builderName,
        pool = task.isFlaky ? 'luci.flutter.staging' : 'luci.flutter.prod';

  final String? pool;
  final String? stage;
  final String? task;

  /// Get the URL for the configuration of this task.
  ///
  /// Luci tasks are stored on Luci.
  /// Cirrus tasks are stored on Cirrus.
  String get sourceConfigurationUrl {
    assert(isLuci || isCirrus);
    if (isCirrus) {
      return '$_cirrusUrl/master';
    } else if (isLuci) {
      return '$_luciUrl/builders/$pool/$task';
    }
    throw Exception('Failed to get source configuration url for $stage.');
  }

  /// Whether this task was run on Cirrus CI.
  bool get isCirrus => stage == StageName.cirrus;

  /// Whether the task was run on the LUCI infrastructre.
  bool get isLuci => stage == StageName.cocoon || stage == StageName.legacyLuci || stage == StageName.luci;

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

/// Get the URL for [Task] to view its log.
///
/// Cirrus logs are located via their [Commit.sha].
/// Otherwise, we can redirect to the LUCI build page for [Task].
String logUrl(Task task, {Commit? commit}) {
  if (task.stageName == StageName.cirrus) {
    if (commit != null) {
      return '$_cirrusLogUrl/${commit.sha}?branch=${commit.branch}';
    } else {
      return '$_cirrusUrl/master';
    }
  }
  return QualifiedTask.fromTask(task).sourceConfigurationUrl;
}
