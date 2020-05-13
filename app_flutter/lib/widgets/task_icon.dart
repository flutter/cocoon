// Copyright (c) 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../logic/qualified_task.dart';

/// Header icon for all [Task]s that map to the same [Task.stageName]
/// and [Task.name].
///
/// Intended to be used in the first row of [TaskGrid]. Shows an
/// icon based on [qualifiedTask.stage], defaulting to [Icons.help] if
/// it can't be mapped. On tap, shows the task.
class TaskIcon extends StatelessWidget {
  const TaskIcon({
    Key key,
    @required this.qualifiedTask,
  }) : super(key: key);

  /// [Task] to get information from.
  final QualifiedTask qualifiedTask;

  /// A lookup table for matching [stageName] to [Image].
  ///
  /// [stageName] is based on the backend.
  Widget stageIconForBrightness(Brightness brightness) {
    // Pass this as the `color` for Image's that are black and white icons.
    // This only works in the CanvasKit implementation currently, not in DOM. If
    // this needs to run in the DOM implementation, it will need to include
    // different assets.
    final Color blendFilter = brightness == Brightness.dark ? Colors.white : null;

    if (qualifiedTask.stage == StageName.luci && qualifiedTask.task == 'linux_bot') {
      return Image.asset(
        'assets/fuchsia.png',
      );
    }
    switch (qualifiedTask.stage) {
      case StageName.cirrus:
        return Image.asset(
          'assets/cirrus.png',
          color: blendFilter,
        );
      case StageName.luci:
        return Image.asset(
          'assets/chromium.png',
        );
      case StageName.devicelab:
        return Image.asset(
          'assets/android.png',
        );
      case StageName.devicelabWin:
        return Image.asset(
          'assets/windows.png',
        );
      case StageName.devicelabIOs:
        return Image.asset(
          'assets/apple.png',
          color: blendFilter,
        );
    }
    return const Icon(Icons.help);
  }

  @override
  Widget build(BuildContext context) {
    final Brightness brightness = Theme.of(context).brightness;
    final Widget icon = stageIconForBrightness(brightness);

    return InkWell(
      onTap: () => launch(qualifiedTask.sourceConfigurationUrl),
      child: Tooltip(
        message: '${qualifiedTask.task} (${qualifiedTask.stage})',
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: icon,
        ),
      ),
    );
  }
}
