// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

typedef ShowSnackBarCallback = ScaffoldFeatureController<SnackBar, SnackBarClosedReason> Function(SnackBar snackBar);

// ignore: avoid_classes_with_only_static_members
class TaskBox {
  /// How big to make each square in the grid.
  static const double cellSize = 36;

  /// Status messages that map to [TaskStatus] enums.
  // TODO(chillers): Remove these and use TaskStatus enum when available. https://github.com/flutter/cocoon/issues/441
  static const String statusFailed = 'Failed';
  static const String statusNew = 'New';
  static const String statusSkipped = 'Skipped';
  static const String statusSucceeded = 'Succeeded';
  static const String statusInfraFailure = 'Infra Failure';
  static const String statusInProgress = 'In Progress';

  /// A lookup table to define the background color for this TaskBox.
  ///
  /// The status messages are based on the messages the backend sends.
  static const Map<String, Color> statusColor = <String, Color>{
    statusFailed: Colors.red,
    statusNew: Colors.grey,
    statusSkipped: Colors.transparent,
    statusSucceeded: Colors.green,
    statusInfraFailure: Colors.purple,
    statusInProgress: Colors.yellow,
  };

  /// The color to highlight a row that matches a commit search query.
  ///
  /// This color was chosen to contrast well with the status colors.
  static final Color highlightColor = Colors.cyan.shade200;
}
