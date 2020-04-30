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
  static final Map<String, Image> stageIcons = <String, Image>{
    StageName.cirrus: Image.asset('assets/cirrus.png'),
    StageName.luci: Image.asset('assets/chromium.png'),
    StageName.devicelab: Image.asset('assets/android.png'),
    StageName.devicelabWin: Image.asset('assets/windows.png'),
    StageName.devicelabIOs: Image.asset('assets/apple.png'),
  };

  @override
  Widget build(BuildContext context) {
    Widget icon = const Icon(Icons.help);
    if (qualifiedTask.stage == StageName.luci &&
        qualifiedTask.task == 'linux_bot') {
      icon = Image.asset('assets/fuchsia.png');
    } else if (stageIcons.containsKey(qualifiedTask.stage)) {
      icon = stageIcons[qualifiedTask.stage];
    }
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
