// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_common/is_dart_internal.dart';
import 'package:cocoon_common/rpc_model.dart';
import 'package:flutter/foundation.dart';

/// Base URLs for various endpoints that can relate to a [Task].
final _luciUrl = Uri.parse('https://ci.chromium.org/p/flutter');
final _dartInternalUrl = Uri.parse('https://ci.chromium.org/p/dart-internal');

@immutable
final class QualifiedTask {
  const QualifiedTask({
    required this.task,
    required this.pool,
    this.isBringup = false,
  });

  QualifiedTask.fromTask(Task task)
    : task = task.builderName,
      pool = task.isBringup ? 'luci.flutter.staging' : 'luci.flutter.prod',
      isBringup = task.isBringup;

  final String pool;
  final String task;

  /// Whether this task originated as a `bringup: true` task.
  final bool isBringup;

  /// Get the URL for the configuration of this task.
  ///
  /// Luci tasks are stored on Luci.
  Uri get sourceConfigurationUrl {
    assert(isLuci || isDartInternal);
    if (isLuci) {
      return _luciUrl.replace(
        pathSegments: [..._luciUrl.pathSegments, 'builders', pool, task],
      );
    } else if (isDartInternal) {
      return _dartInternalUrl.replace(
        pathSegments: [
          ..._dartInternalUrl.pathSegments,
          'builders',
          pool,
          task,
        ],
      );
    }
    throw Exception('Failed to get source configuration url for $pool/$task.');
  }

  /// Whether the task was run on the LUCI infrastructure.
  bool get isLuci => !isDartInternal;

  /// Whether this task was run on internal infrastructure (example: luci dart-internal).
  bool get isDartInternal => isTaskFromDartInternalBuilder(builderName: task);

  @override
  bool operator ==(Object other) {
    return other is QualifiedTask && task == other.task;
  }

  @override
  int get hashCode => task.hashCode;
}
