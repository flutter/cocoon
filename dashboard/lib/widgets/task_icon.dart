// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../logic/qualified_task.dart';

import 'task_box.dart';

/// Header icon for all [Task]s that map to the same [Task.stageName]
/// and [Task.name].
///
/// Intended to be used in the first row of [TaskGrid]. Shows an
/// icon based on [qualifiedTask.stage], defaulting to [Icons.help] if
/// it can't be mapped. On tap, shows the task.
class TaskIcon extends StatelessWidget {
  const TaskIcon({super.key, required this.qualifiedTask});

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
    final blendFilter = brightness == Brightness.dark ? Colors.white : null;

    if (!(qualifiedTask.isLuci || qualifiedTask.isDartInternal)) {
      return Icon(Icons.help, color: blendFilter);
    }

    final matchedName = qualifiedTask.task.toLowerCase();
    final isWebTest =
        matchedName.contains('_web') || matchedName.contains('web_');
    final isToolTest =
        matchedName.contains('_tool') || matchedName.contains('tool_');
    final isAndroidTest =
        matchedName.contains('_android') ||
        matchedName.contains('_mokey') ||
        matchedName.contains('_pixel_7pro');

    if (matchedName.contains('_fuchsia')) {
      return Padding(
        padding: const EdgeInsets.all(2.0),
        child: Image.asset('assets/fuchsia.png', color: blendFilter),
      );
    } else if (isWebTest && !isToolTest) {
      return Padding(
        padding: const EdgeInsets.all(2.0),
        child: Image.asset('assets/chromium.png', color: blendFilter),
      );
    } else if (isAndroidTest) {
      return Icon(Icons.android, color: blendFilter);
    } else if (matchedName.startsWith('linux')) {
      return Padding(
        padding: const EdgeInsets.all(2.0),
        child: Image.asset('assets/linux.png', color: blendFilter),
      );
    } else if (matchedName.startsWith('mac')) {
      if (matchedName.contains('_ios')) {
        return Icon(Icons.phone_iphone, color: blendFilter);
      } else {
        return Padding(
          padding: const EdgeInsets.all(2.0),
          child: Image.asset('assets/apple.png', color: blendFilter),
        );
      }
    } else if (matchedName.startsWith('win')) {
      return Image.asset('assets/windows.png', color: blendFilter);
    }

    return Icon(Icons.help, color: blendFilter);
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final icon = stageIconForBrightness(brightness);

    return IconTheme.merge(
      data: IconThemeData(size: TaskBox.of(context) - 5),
      child: InkWell(
        onTap: () async {
          await launchUrl(qualifiedTask.sourceConfigurationUrl);
        },
        child: Tooltip(
          message: qualifiedTask.task,
          child: Align(alignment: Alignment.bottomCenter, child: icon),
        ),
      ),
    );
  }
}
