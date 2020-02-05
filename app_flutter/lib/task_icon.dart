// Copyright (c) 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:cocoon_service/protos.dart' show Task;

import 'task_helper.dart';

/// Header icon for all [Task] that map to the same [task.stageName] and [task.name].
///
/// Intended to be used in the first row of [StatusGrid].
/// Shows an icon based on [task.stageName], defaulting to [Icons.help] if it can't be mapped.
/// On tap, shows [task.name].
class TaskIcon extends StatelessWidget {
  const TaskIcon({Key key, @required this.task}) : super(key: key);

  /// [Task] to get information from.
  final Task task;

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
    if (task.stageName == StageName.luci && task.name == 'linux_bot') {
      icon = Image.asset('assets/fuchsia.png');
    } else if (stageIcons.containsKey(task.stageName)) {
      icon = stageIcons[task.stageName];
    }
    return GestureDetector(
      onTap: () => launch(sourceConfigurationUrl(task)),
      child: Tooltip(
        message: task.name,
        child: Container(
          margin: const EdgeInsets.all(7.5),
          child: icon,
          width: 100,
          height: 100,
        ),
      ),
    );
  }
}
