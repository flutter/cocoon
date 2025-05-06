// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_common/task_status.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

typedef ShowSnackBarCallback =
    ScaffoldFeatureController<SnackBar, SnackBarClosedReason> Function(
      SnackBar snackBar,
    );

class TaskBox extends StatelessWidget {
  const TaskBox({super.key, this.cellSize, required this.child});

  final Widget child;
  final double? cellSize;

  static const double _kDefaultCellSize = 20;
  static const double _kWebCellSize = 36;

  /// A lookup table to define the background color for this TaskBox.
  ///
  /// The status messages are based on the messages the backend sends.
  ///
  /// These colors should map to the MILO color scheme.
  static final statusColor = {
    TaskStatus.cancelled: Colors.lightBlue,
    TaskStatus.failed: Colors.red,
    TaskStatus.waitingForBackfill: Colors.grey,
    TaskStatus.skipped: Colors.grey.shade800,
    TaskStatus.succeeded: Colors.green,
    TaskStatus.infraFailure: Colors.purple,
    TaskStatus.inProgress: Colors.yellow,
  };

  static const statusColorFailedAndRerunning = Color(0xFF8A3324);

  static final statusColorInProgressButQueued = Colors.yellow.shade200;

  /// Returns the cell size of the nearest task box, or null if there is no
  /// nearest task box.
  static double? maybeOf(BuildContext context) {
    final box = context.dependOnInheritedWidgetOfExactType<_TaskBox>();
    return box?.size;
  }

  /// Returns the cell size of the nearest task box.
  static double of(BuildContext context) {
    return maybeOf(context) ?? _kDefaultCellSize;
  }

  @override
  Widget build(BuildContext context) {
    final size = cellSize ?? (kIsWeb ? _kWebCellSize : _kDefaultCellSize);
    return _TaskBox(size: TaskBox.maybeOf(context) ?? size, child: child);
  }
}

class _TaskBox extends InheritedWidget {
  const _TaskBox({required this.size, required super.child});

  final double size;

  @override
  bool updateShouldNotify(covariant _TaskBox oldWidget) =>
      size != oldWidget.size;
}
