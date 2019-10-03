// Copyright (c) 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

import 'package:cocoon_service/protos.dart' show Task;

/// Header icon for all [Task] that map to the same [task.stageName] and [task.name].
///
/// Intended to be used in the first row of [StatusGrid].
/// Shows an icon based on [task.stageName], defaulting to [Icons.help] if it can't be mapped.
/// On tap, shows [task.name].
class TaskIcon extends StatelessWidget {
  const TaskIcon({Key key, @required this.task}) : super(key: key);

  /// [Task] to get information from.
  final Task task;

  /// [stageName] that maps to StageName enums.
  // TODO(chillers): Remove these and use StageName enum when available. https://github.com/flutter/cocoon/issues/441
  static const String stageCirrus = 'cirrus';
  static const String stageLuci = 'chromebot';
  static const String stageDevicelab = 'devicelab';
  static const String stageDevicelabWin = 'devicelab_win';
  static const String stageDevicelabIOs = 'devicelab_ios';

  /// A lookup table for matching [stageName] to [Image].
  ///
  /// [stageName] is based on the backend.
  static final Map<String, Image> stageIcons = <String, Image>{
    stageCirrus: Image.asset('assets/cirrus.png'),
    stageLuci: Image.asset('assets/chromium.png'),
    stageDevicelab: Image.asset('assets/android.png'),
    stageDevicelabWin: Image.asset('assets/windows.png'),
    stageDevicelabIOs: Image.asset('assets/apple.png'),
  };

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: task.name,
      child: Container(
        margin: const EdgeInsets.all(7.5),
        child: stageIcons.containsKey(task.stageName)
            ? stageIcons[task.stageName]
            : const Icon(Icons.help),
        width: 100,
        height: 100,
      ),
    );
  }
}
